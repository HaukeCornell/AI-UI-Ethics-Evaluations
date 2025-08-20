# Final Data Quality Investigation - Properly parsing the TSV
library(dplyr)
library(readr)

cat("=== FINAL DATA QUALITY INVESTIGATION ===\n")

# Read the data starting from row 74 (where actual data begins)
cat("Reading data from row 74 onwards...\n")

# Read header from row 1
header_line <- readLines("aug17_utf8.tsv", n = 1)
column_names <- strsplit(header_line, "\t")[[1]]

# Read actual data starting from row 74
raw_data <- read_tsv("aug17_utf8.tsv", 
                     skip = 73,  # Skip to row 74
                     col_names = column_names,
                     show_col_types = FALSE)

cat("Raw data loaded:", nrow(raw_data), "rows,", ncol(raw_data), "columns\n")

# Filter valid participants (those with proper PROLIFIC_PID)
valid_data <- raw_data %>%
  filter(!is.na(PROLIFIC_PID), 
         nchar(PROLIFIC_PID) >= 20,  # Valid prolific IDs
         !grepl("ImportId", PROLIFIC_PID))  # Remove metadata rows

cat("Valid participants after filtering:", nrow(valid_data), "\n")

# Show unique participants
unique_pids <- unique(valid_data$PROLIFIC_PID)
cat("Unique participant IDs:", length(unique_pids), "\n\n")

# Find relevant columns
ueq_tendency_cols <- grep("UEQ Tendency", names(valid_data), value = TRUE)
ueeq_tendency_cols <- grep("UEEQ Tendency", names(valid_data), value = TRUE)
explanation_cols <- grep("Explanation", names(valid_data), value = TRUE)

cat("UEQ tendency columns:", length(ueq_tendency_cols), "\n")
cat("UEEQ tendency columns:", length(ueeq_tendency_cols), "\n") 
cat("Explanation columns:", length(explanation_cols), "\n\n")

# Function to detect AI-generated text
detect_ai_usage <- function(text_vector) {
  if(length(text_vector) == 0 || all(is.na(text_vector))) return(0)
  
  text_vector <- text_vector[!is.na(text_vector) & text_vector != ""]
  if(length(text_vector) == 0) return(0)
  
  # AI detection phrases
  ai_phrases <- c(
    "as an ai", "as a language model", "i'm an ai", "i am an ai",
    "artificial intelligence", "large language model", "machine learning",
    "i cannot", "i don't have personal", "i don't have the ability",
    "i'm not able to", "i cannot provide", "as a responsible ai",
    "i apologize, but i", "i'm sorry, but i", "i don't have access",
    "neural network", "training data", "algorithm"
  )
  
  text_combined <- tolower(paste(text_vector, collapse = " "))
  ai_count <- sum(sapply(ai_phrases, function(phrase) grepl(phrase, text_combined, fixed = TRUE)))
  
  # Check for suspiciously long responses (potential AI)
  very_long_count <- sum(nchar(text_vector) > 500)
  
  # Check for repetitive patterns
  unique_responses <- length(unique(text_vector))
  repetitive_flag <- ifelse(length(text_vector) > 5 && unique_responses < 3, 1, 0)
  
  return(ai_count + (very_long_count > 3) + repetitive_flag)
}

# Create comprehensive screening table
screening_table <- valid_data %>%
  group_by(PROLIFIC_PID) %>%
  summarise(
    # Determine condition based on which questions were answered
    ueq_responses = sum(!is.na(c_across(all_of(ueq_tendency_cols))) & 
                       c_across(all_of(ueq_tendency_cols)) != "", na.rm = TRUE),
    ueeq_responses = sum(!is.na(c_across(all_of(ueeq_tendency_cols))) & 
                        c_across(all_of(ueeq_tendency_cols)) != "", na.rm = TRUE),
    
    # Get all tendency scores
    all_ueq_scores = list(as.numeric(c_across(all_of(ueq_tendency_cols))) %>% 
                         unlist() %>% .[!is.na(.)]),
    all_ueeq_scores = list(as.numeric(c_across(all_of(ueeq_tendency_cols))) %>% 
                          unlist() %>% .[!is.na(.)]),
    
    # Get all explanation text
    all_explanations = list(c_across(all_of(explanation_cols)) %>% 
                           unlist() %>% .[!is.na(.) & . != ""]),
    
    .groups = "drop"
  ) %>%
  rowwise() %>%
  mutate(
    # Determine condition
    condition_type = case_when(
      ueq_responses > 0 ~ "UEQ",
      ueeq_responses > 0 ~ "UEQ+Autonomy", 
      TRUE ~ "Unknown"
    ),
    
    # Combine all tendency scores
    all_tendency = list(c(all_ueq_scores, all_ueeq_scores)),
    interfaces_evaluated = length(all_tendency),
    
    # Calculate tendency metrics
    avg_tendency = ifelse(interfaces_evaluated > 0, 
                         round(mean(all_tendency, na.rm = TRUE), 2), NA),
    
    # Calculate rejection rates (assuming rejection when score >= 4)
    rejections = sum(all_tendency >= 4, na.rm = TRUE),
    acceptance_rate = ifelse(interfaces_evaluated > 0, 
                           round((interfaces_evaluated - rejections) / interfaces_evaluated * 100, 1), 
                           NA),
    rejection_rate = ifelse(interfaces_evaluated > 0, 
                          round(rejections / interfaces_evaluated * 100, 1), 
                          NA),
    
    # Text analysis
    text_responses = length(all_explanations),
    avg_text_length = ifelse(text_responses > 0, 
                           round(mean(nchar(all_explanations)), 1), 0),
    max_text_length = ifelse(text_responses > 0, max(nchar(all_explanations)), 0),
    
    # AI detection
    ai_indicators = detect_ai_usage(all_explanations),
    
    # Quality flags
    very_low_tendency = !is.na(avg_tendency) && avg_tendency < 1.5,
    very_high_tendency = !is.na(avg_tendency) && avg_tendency > 6.5,
    extreme_rejection = !is.na(rejection_rate) && rejection_rate > 95,
    extreme_acceptance = !is.na(acceptance_rate) && acceptance_rate > 95,
    possible_ai = ai_indicators > 0 || max_text_length > 800,
    incomplete_data = interfaces_evaluated < 10,
    no_text_responses = text_responses == 0,
    
    # Overall quality assessment
    quality_concerns = sum(c(
      very_low_tendency, very_high_tendency, extreme_rejection, 
      extreme_acceptance, possible_ai, incomplete_data, no_text_responses
    )),
    
    quality_score = case_when(
      possible_ai ~ 1,  # Highest concern
      extreme_rejection || extreme_acceptance ~ 2,
      very_low_tendency || very_high_tendency ~ 3,
      incomplete_data || no_text_responses ~ 4,
      TRUE ~ 5  # Good quality
    ),
    
    recommendation = case_when(
      quality_score == 1 ~ "EXCLUDE - Likely AI usage",
      quality_score == 2 ~ "EXCLUDE - Extreme/invalid responses",
      quality_score == 3 ~ "REVIEW - Unusual response patterns",
      quality_score == 4 ~ "REVIEW - Incomplete data",
      TRUE ~ "KEEP - Good quality"
    )
  ) %>%
  ungroup() %>%
  select(-all_ueq_scores, -all_ueeq_scores, -all_tendency, -all_explanations) %>%
  arrange(quality_score, -ai_indicators, -avg_text_length)

# Save the complete screening table
write.csv(screening_table, "results/participant_screening_table_complete.csv", row.names = FALSE)

cat("=== SCREENING RESULTS SUMMARY ===\n")
cat("Total participants found:", nrow(screening_table), "\n")

# Quality distribution
cat("\nQuality score distribution:\n")
quality_dist <- screening_table %>% count(quality_score, recommendation)
print(quality_dist)

# Condition balance
cat("\nCondition distribution:\n")
condition_dist <- screening_table %>% count(condition_type)
print(condition_dist)

# Detailed flag summary
cat("\nQuality flags summary:\n")
flags <- screening_table %>%
  summarise(
    possible_ai = sum(possible_ai),
    extreme_rejection = sum(extreme_rejection),
    extreme_acceptance = sum(extreme_acceptance),
    very_low_tendency = sum(very_low_tendency),
    very_high_tendency = sum(very_high_tendency),
    incomplete_data = sum(incomplete_data),
    no_text_responses = sum(no_text_responses)
  )
print(flags)

# Show participants recommended for exclusion
exclusion_candidates <- screening_table %>%
  filter(quality_score <= 2) %>%
  select(PROLIFIC_PID, condition_type, interfaces_evaluated, avg_tendency, 
         rejection_rate, text_responses, avg_text_length, max_text_length,
         ai_indicators, quality_score, recommendation)

cat("\n=== PARTICIPANTS RECOMMENDED FOR EXCLUSION ===\n")
if(nrow(exclusion_candidates) > 0) {
  print(exclusion_candidates)
  cat("\nTotal exclusions recommended:", nrow(exclusion_candidates), "\n")
} else {
  cat("No participants recommended for exclusion based on quality flags.\n")
}

# Show final sample projection
final_sample <- screening_table %>% filter(quality_score >= 3)
cat("\n=== FINAL SAMPLE PROJECTION ===\n")
cat("Original sample:", nrow(screening_table), "participants\n")
cat("Recommended exclusions:", nrow(exclusion_candidates), "participants\n") 
cat("Clean sample size:", nrow(final_sample), "participants\n")

final_condition_balance <- final_sample %>% count(condition_type)
cat("\nCondition balance in clean sample:\n")
print(final_condition_balance)

cat("\nFiles saved:\n")
cat("• results/participant_screening_table_complete.csv\n")

cat("\n=== NEXT STEPS ===\n")
cat("1. Review excluded participants manually\n")
cat("2. Check text responses of flagged participants\n")
cat("3. Decide final exclusion criteria\n")
cat("4. Re-run analysis with cleaned data\n")
