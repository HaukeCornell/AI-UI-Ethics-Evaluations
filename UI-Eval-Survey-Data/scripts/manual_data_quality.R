# Simple data quality investigation using manual data loading
library(dplyr)
library(readr)

cat("=== MANUAL DATA LOADING FOR QUALITY INVESTIGATION ===\n")

# Read all lines first
all_lines <- readLines("aug17_utf8.tsv")
cat("Total lines in file:", length(all_lines), "\n")

# Find the header row (contains column names)
header_line <- which(grepl("PROLIFIC_PID.*StartDate", all_lines))[1]
cat("Header row found at line:", header_line, "\n")

# Find the first data row (after headers and description)
data_start <- which(grepl("^[0-9a-f]{24}", all_lines))[1]  # Looking for prolific IDs
if(is.na(data_start)) {
  # Try alternative pattern
  data_start <- which(grepl("^[0-9a-f]{20,}", all_lines))[1]
}
cat("Data starts at line:", data_start, "\n")

# Read the data properly
header <- strsplit(all_lines[header_line], "\t")[[1]]
cat("Number of columns:", length(header), "\n")

# Find key columns
prolific_col <- which(header == "PROLIFIC_PID")
cat("PROLIFIC_PID column:", prolific_col, "\n")

# Get all data lines starting from data_start
data_lines <- all_lines[data_start:length(all_lines)]
data_lines <- data_lines[data_lines != ""]  # Remove empty lines

cat("Number of data rows:", length(data_lines), "\n")

# Parse the data manually
parse_row <- function(line) {
  parts <- strsplit(line, "\t")[[1]]
  # Extend to match header length if needed
  if(length(parts) < length(header)) {
    parts <- c(parts, rep("", length(header) - length(parts)))
  } else if(length(parts) > length(header)) {
    parts <- parts[1:length(header)]
  }
  return(parts)
}

# Parse all data rows
cat("Parsing data rows...\n")
data_matrix <- do.call(rbind, lapply(data_lines, parse_row))
colnames(data_matrix) <- header

# Convert to data frame
raw_data <- as.data.frame(data_matrix, stringsAsFactors = FALSE)

# Filter valid participants
valid_data <- raw_data %>%
  filter(!is.na(PROLIFIC_PID), 
         PROLIFIC_PID != "",
         nchar(PROLIFIC_PID) >= 20)  # Valid prolific IDs are long

cat("Valid participants:", nrow(valid_data), "\n")

# Find tendency and explanation columns
ueq_tendency_cols <- grep("UEQ Tendency", names(valid_data), value = TRUE)
ueeq_tendency_cols <- grep("UEEQ Tendency", names(valid_data), value = TRUE)
explanation_cols <- grep("Explanation", names(valid_data), value = TRUE)

cat("UEQ tendency columns:", length(ueq_tendency_cols), "\n")
cat("UEEQ tendency columns:", length(ueeq_tendency_cols), "\n")
cat("Explanation columns:", length(explanation_cols), "\n")

# Create simplified screening table
cat("Creating participant screening table...\n")

create_screening_row <- function(pid) {
  participant_data <- valid_data[valid_data$PROLIFIC_PID == pid, ]
  
  # Determine condition
  ueq_responses <- sum(!is.na(participant_data[ueq_tendency_cols]) & 
                      participant_data[ueq_tendency_cols] != "")
  ueeq_responses <- sum(!is.na(participant_data[ueeq_tendency_cols]) & 
                       participant_data[ueeq_tendency_cols] != "")
  
  condition <- ifelse(ueq_responses > 0, "UEQ", 
                     ifelse(ueeq_responses > 0, "UEQ+Autonomy", "Unknown"))
  
  # Get all tendency scores
  all_tendency <- c(
    as.numeric(participant_data[ueq_tendency_cols]),
    as.numeric(participant_data[ueeq_tendency_cols])
  )
  all_tendency <- all_tendency[!is.na(all_tendency)]
  
  # Get all text responses
  all_text <- c()
  for(col in explanation_cols) {
    if(col %in% names(participant_data)) {
      text_val <- participant_data[[col]]
      if(!is.na(text_val) && text_val != "") {
        all_text <- c(all_text, text_val)
      }
    }
  }
  
  # Calculate metrics
  interfaces_evaluated <- length(all_tendency)
  avg_tendency <- ifelse(interfaces_evaluated > 0, round(mean(all_tendency), 2), NA)
  rejections <- sum(all_tendency >= 4)
  rejection_rate <- ifelse(interfaces_evaluated > 0, 
                          round(rejections / interfaces_evaluated * 100, 1), NA)
  
  # Text analysis
  text_responses <- length(all_text)
  avg_text_length <- ifelse(text_responses > 0, round(mean(nchar(all_text)), 1), 0)
  
  # AI detection (simple)
  ai_phrases <- c("as an ai", "language model", "i cannot", "i'm not able", 
                  "artificial intelligence", "i don't have")
  all_text_lower <- tolower(paste(all_text, collapse = " "))
  ai_indicators <- sum(sapply(ai_phrases, function(p) grepl(p, all_text_lower)))
  
  # Quality flags
  very_long_responses <- sum(nchar(all_text) > 500)
  possible_ai <- ai_indicators > 0 || very_long_responses > 3 || avg_text_length > 300
  extreme_responses <- (rejection_rate > 95 || rejection_rate < 5) && !is.na(rejection_rate)
  incomplete <- interfaces_evaluated < 10
  
  # Quality score
  quality_score <- case_when(
    possible_ai ~ 1,
    extreme_responses ~ 2,
    avg_tendency < 1.5 || avg_tendency > 6.5 ~ 3,
    incomplete ~ 4,
    TRUE ~ 5
  )
  
  return(data.frame(
    PROLIFIC_PID = pid,
    condition_type = condition,
    interfaces_evaluated = interfaces_evaluated,
    avg_tendency = avg_tendency,
    rejection_rate = rejection_rate,
    text_responses = text_responses,
    avg_text_length = avg_text_length,
    ai_indicators = ai_indicators,
    very_long_responses = very_long_responses,
    possible_ai = possible_ai,
    extreme_responses = extreme_responses,
    incomplete = incomplete,
    quality_score = quality_score
  ))
}

# Create screening table
unique_pids <- unique(valid_data$PROLIFIC_PID)
cat("Processing", length(unique_pids), "unique participants...\n")

screening_list <- lapply(unique_pids, create_screening_row)
screening_table <- do.call(rbind, screening_list)

# Add recommendations
screening_table <- screening_table %>%
  mutate(
    recommendation = case_when(
      quality_score == 1 ~ "EXCLUDE - Likely AI",
      quality_score == 2 ~ "EXCLUDE - Extreme responses",
      quality_score == 3 ~ "REVIEW - Unusual patterns", 
      quality_score == 4 ~ "REVIEW - Incomplete",
      TRUE ~ "KEEP - Good quality"
    )
  ) %>%
  arrange(quality_score, -avg_text_length)

# Save results
write.csv(screening_table, "results/participant_screening_table_final.csv", row.names = FALSE)

# Print summary
cat("\n=== SCREENING RESULTS ===\n")
cat("Total participants:", nrow(screening_table), "\n\n")

print("Quality distribution:")
print(table(screening_table$quality_score, screening_table$recommendation))

cat("\nCondition distribution:\n")
print(table(screening_table$condition_type))

cat("\nRecommended exclusions (quality score 1-2):\n")
exclusions <- screening_table %>% filter(quality_score <= 2)
print(exclusions %>% select(PROLIFIC_PID, condition_type, interfaces_evaluated, 
                           avg_tendency, rejection_rate, text_responses, 
                           avg_text_length, ai_indicators, recommendation))

cat("\nFinal sample after exclusions:", nrow(screening_table) - nrow(exclusions), "\n")

cat("\nFile saved: results/participant_screening_table_final.csv\n")
