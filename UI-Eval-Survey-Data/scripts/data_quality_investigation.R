# Data Quality Investigation: Participant Screening Table
# Investigate 104 vs 94 participants and potential AI usage

library(dplyr)
library(readr)

cat("=== DATA QUALITY INVESTIGATION ===\n")
cat("Creating comprehensive participant screening table\n\n")

# Load the raw August 17 data
cat("Loading raw August 17 data...\n")
raw_data <- read_tsv("aug17_utf8.tsv")

cat("Raw data dimensions:", nrow(raw_data), "rows,", ncol(raw_data), "columns\n")

# Get unique participants
unique_participants <- raw_data %>%
  filter(!is.na(PROLIFIC_PID)) %>%
  distinct(PROLIFIC_PID, .keep_all = TRUE)

cat("Total unique participants:", nrow(unique_participants), "\n")

# Load processed interface data for comparison
processed_data <- read.csv("results/interface_plot_data_aug17_final.csv")
cat("Processed interface evaluations:", nrow(processed_data), "\n")
cat("Unique participants in processed data:", length(unique(processed_data$PROLIFIC_PID)), "\n\n")

# Create comprehensive participant screening table
cat("Creating participant screening table...\n")

# Function to detect likely AI-generated text
detect_ai_indicators <- function(text_vector) {
  if(all(is.na(text_vector))) return(0)
  
  # Remove NA values
  text_vector <- text_vector[!is.na(text_vector)]
  if(length(text_vector) == 0) return(0)
  
  # AI indicators
  ai_phrases <- c(
    "as an ai", "as a language model", "i'm an ai", "i am an ai",
    "artificial intelligence", "large language model", "i cannot", 
    "i don't have personal", "i don't have the ability",
    "i'm not able to", "i cannot provide", "as a responsible ai"
  )
  
  # Convert to lowercase and check for AI phrases
  text_lower <- tolower(paste(text_vector, collapse = " "))
  ai_count <- sum(sapply(ai_phrases, function(phrase) grepl(phrase, text_lower, fixed = TRUE)))
  
  return(ai_count)
}

# Function to calculate text statistics
calculate_text_stats <- function(text_vector) {
  if(all(is.na(text_vector))) return(list(avg_length = 0, total_responses = 0))
  
  text_vector <- text_vector[!is.na(text_vector) & text_vector != ""]
  if(length(text_vector) == 0) return(list(avg_length = 0, total_responses = 0))
  
  list(
    avg_length = round(mean(nchar(text_vector)), 1),
    total_responses = length(text_vector)
  )
}

# Get all text response columns (reason fields)
text_columns <- grep("reason", names(raw_data), value = TRUE, ignore.case = TRUE)
cat("Text response columns found:", length(text_columns), "\n")

# Create screening table
screening_table <- raw_data %>%
  filter(!is.na(PROLIFIC_PID)) %>%
  group_by(PROLIFIC_PID) %>%
  summarise(
    # Basic info
    condition_type = case_when(
      any(!is.na(UEQ_1)) ~ "UEQ",
      any(!is.na(UEEQ_1)) ~ "UEQ+Autonomy", 
      TRUE ~ "Unknown"
    ),
    
    # Interface evaluation counts
    total_responses = n(),
    
    # Calculate tendency scores and rejection rates
    tendency_scores = list(c(
      UEQ_1, UEQ_2, UEQ_3, UEQ_4, UEQ_5, UEQ_6, UEQ_7, UEQ_8, UEQ_9, UEQ_10, UEQ_11, UEQ_12, UEQ_13, UEQ_14, UEQ_15,
      UEEQ_1, UEEQ_2, UEEQ_3, UEEQ_4, UEEQ_5, UEEQ_6, UEEQ_7, UEEQ_8, UEEQ_9, UEEQ_10, UEEQ_11, UEEQ_12, UEEQ_13, UEEQ_14, UEEQ_15
    )[!is.na(c(
      UEQ_1, UEQ_2, UEQ_3, UEQ_4, UEQ_5, UEQ_6, UEQ_7, UEQ_8, UEQ_9, UEQ_10, UEQ_11, UEQ_12, UEQ_13, UEQ_14, UEQ_15,
      UEEQ_1, UEEQ_2, UEEQ_3, UEEQ_4, UEEQ_5, UEEQ_6, UEEQ_7, UEEQ_8, UEEQ_9, UEEQ_10, UEEQ_11, UEEQ_12, UEEQ_13, UEEQ_14, UEEQ_15
    ))]),
    
    # Count text responses across all reason fields
    text_responses = sum(sapply(text_columns, function(col) {
      if(col %in% names(cur_data())) {
        sum(!is.na(cur_data()[[col]]) & cur_data()[[col]] != "")
      } else {
        0
      }
    })),
    
    # Get all text for AI detection
    all_text = list(unlist(lapply(text_columns, function(col) {
      if(col %in% names(cur_data())) {
        cur_data()[[col]][!is.na(cur_data()[[col]]) & cur_data()[[col]] != ""]
      } else {
        character(0)
      }
    }))),
    
    .groups = "drop"
  ) %>%
  rowwise() %>%
  mutate(
    # Calculate metrics from tendency scores
    interfaces_evaluated = length(tendency_scores),
    avg_tendency = ifelse(length(tendency_scores) > 0, round(mean(tendency_scores, na.rm = TRUE), 2), NA),
    
    # Calculate rejection metrics (assuming rejection if score >= 4)
    rejections = sum(tendency_scores >= 4, na.rm = TRUE),
    acceptance_rate = ifelse(interfaces_evaluated > 0, 
                           round((interfaces_evaluated - rejections) / interfaces_evaluated * 100, 1), 
                           NA),
    rejection_rate = ifelse(interfaces_evaluated > 0, 
                          round(rejections / interfaces_evaluated * 100, 1), 
                          NA),
    
    # AI detection
    ai_indicators = detect_ai_indicators(all_text),
    text_stats = list(calculate_text_stats(all_text)),
    avg_text_length = text_stats$avg_length,
    
    # Data quality flags
    very_low_tendency = avg_tendency < 2 & !is.na(avg_tendency),
    very_high_tendency = avg_tendency > 6 & !is.na(avg_tendency),
    extreme_rejection = rejection_rate > 90 & !is.na(rejection_rate),
    extreme_acceptance = acceptance_rate > 90 & !is.na(acceptance_rate),
    possible_ai = ai_indicators > 0 | avg_text_length > 200,
    incomplete_data = interfaces_evaluated < 10,
    
    # Overall quality score (lower = more concerning)
    quality_score = case_when(
      possible_ai ~ 1,  # Most concerning
      extreme_rejection | extreme_acceptance ~ 2,
      very_low_tendency | very_high_tendency ~ 3,
      incomplete_data ~ 4,
      TRUE ~ 5  # Good quality
    )
  ) %>%
  ungroup() %>%
  select(-tendency_scores, -all_text, -text_stats) %>%
  arrange(quality_score, PROLIFIC_PID)

# Save the screening table
write.csv(screening_table, "results/participant_screening_table.csv", row.names = FALSE)

cat("\n=== SCREENING RESULTS SUMMARY ===\n")
cat("Total participants in raw data:", nrow(screening_table), "\n")

# Quality distribution
quality_summary <- screening_table %>%
  count(quality_score) %>%
  mutate(
    quality_label = case_when(
      quality_score == 1 ~ "Possible AI",
      quality_score == 2 ~ "Extreme responses", 
      quality_score == 3 ~ "Unusual tendencies",
      quality_score == 4 ~ "Incomplete data",
      quality_score == 5 ~ "Good quality"
    )
  )

print(quality_summary)

# Condition distribution
cat("\nCondition distribution:\n")
print(screening_table %>% count(condition_type))

# Flag summaries
cat("\nData quality flags:\n")
flag_summary <- screening_table %>%
  summarise(
    possible_ai = sum(possible_ai),
    extreme_rejection = sum(extreme_rejection), 
    extreme_acceptance = sum(extreme_acceptance),
    very_low_tendency = sum(very_low_tendency),
    very_high_tendency = sum(very_high_tendency),
    incomplete_data = sum(incomplete_data)
  )
print(flag_summary)

# Show the most concerning participants
cat("\n=== MOST CONCERNING PARTICIPANTS ===\n")
concerning <- screening_table %>%
  filter(quality_score <= 2) %>%
  select(PROLIFIC_PID, condition_type, interfaces_evaluated, avg_tendency, 
         rejection_rate, text_responses, ai_indicators, avg_text_length, quality_score)

if(nrow(concerning) > 0) {
  print(concerning)
} else {
  cat("No highly concerning participants found.\n")
}

# Recommended exclusions
recommended_exclusions <- screening_table %>%
  filter(quality_score <= 2 | incomplete_data)

cat("\n=== RECOMMENDED EXCLUSIONS ===\n")
cat("Participants recommended for exclusion:", nrow(recommended_exclusions), "\n")
cat("This would leave:", nrow(screening_table) - nrow(recommended_exclusions), "participants\n")

cat("\nFiles saved:\n")
cat("• results/participant_screening_table.csv - Complete screening data\n")

cat("\n=== NEXT STEPS ===\n")
cat("1. Review the screening table to identify participants to exclude\n")
cat("2. Look for AI-generated text in high-scoring participants\n") 
cat("3. Consider excluding quality_score 1-2 participants\n")
cat("4. Re-run analysis with cleaned dataset\n")
