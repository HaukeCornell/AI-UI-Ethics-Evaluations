# Data Quality Investigation: Participant Screening Table (Corrected)
# Investigate all 104+ participants and potential AI usage

library(dplyr)
library(readr)

cat("=== DATA QUALITY INVESTIGATION (CORRECTED) ===\n")
cat("Creating comprehensive participant screening table\n\n")

# Load the raw August 17 data, skipping header rows
cat("Loading raw August 17 data...\n")
raw_data <- read_tsv("aug17_utf8.tsv", skip = 2)  # Skip the header rows

cat("Raw data dimensions:", nrow(raw_data), "rows,", ncol(raw_data), "columns\n")

# Remove test/incomplete rows
valid_data <- raw_data %>%
  filter(!is.na(PROLIFIC_PID), 
         PROLIFIC_PID != "",
         PROLIFIC_PID != "PROLIFIC_PID",  # Remove header remnants
         !grepl("ImportId", PROLIFIC_PID))  # Remove Qualtrics metadata

cat("Valid participants after filtering:", nrow(valid_data), "\n")

# Get unique participants
unique_participants <- valid_data %>%
  distinct(PROLIFIC_PID, .keep_all = TRUE)

cat("Unique participants:", nrow(unique_participants), "\n\n")

# Get text response columns (Explanation fields)
explanation_cols <- grep("Explanation", names(valid_data), value = TRUE)
cat("Text response columns found:", length(explanation_cols), "\n")
print(explanation_cols[1:10])  # Show first 10

# Get tendency columns
ueq_tendency_cols <- grep("UEQ Tendency", names(valid_data), value = TRUE)
ueeq_tendency_cols <- grep("UEEQ Tendency", names(valid_data), value = TRUE)

cat("\nUEQ tendency columns:", length(ueq_tendency_cols))
cat("\nUEEQ tendency columns:", length(ueeq_tendency_cols), "\n")

# Function to detect likely AI-generated text
detect_ai_indicators <- function(text_vector) {
  if(all(is.na(text_vector))) return(0)
  
  # Remove NA values
  text_vector <- text_vector[!is.na(text_vector) & text_vector != ""]
  if(length(text_vector) == 0) return(0)
  
  # AI indicators (case insensitive)
  ai_phrases <- c(
    "as an ai", "as a language model", "i'm an ai", "i am an ai",
    "artificial intelligence", "large language model", "i cannot", 
    "i don't have personal", "i don't have the ability",
    "i'm not able to", "i cannot provide", "as a responsible ai",
    "i'm sorry, but i", "i apologize, but i", "as an artificial",
    "i am unable to", "i don't have access", "i can't provide",
    "machine learning", "neural network"
  )
  
  # Convert to lowercase and check for AI phrases
  text_lower <- tolower(paste(text_vector, collapse = " "))
  ai_count <- sum(sapply(ai_phrases, function(phrase) grepl(phrase, text_lower, fixed = TRUE)))
  
  # Also check for repetitive/template-like responses
  unique_responses <- length(unique(text_vector))
  repetitive_flag <- ifelse(length(text_vector) > 5 && unique_responses < 3, 1, 0)
  
  return(ai_count + repetitive_flag)
}

# Function to calculate text statistics
calculate_text_stats <- function(text_vector) {
  if(all(is.na(text_vector))) return(list(avg_length = 0, total_responses = 0, very_long = 0))
  
  text_vector <- text_vector[!is.na(text_vector) & text_vector != ""]
  if(length(text_vector) == 0) return(list(avg_length = 0, total_responses = 0, very_long = 0))
  
  lengths <- nchar(text_vector)
  
  list(
    avg_length = round(mean(lengths), 1),
    total_responses = length(text_vector),
    very_long = sum(lengths > 500)  # Very long responses (potential AI)
  )
}

# Create comprehensive screening table
cat("Creating participant screening table...\n")

screening_table <- valid_data %>%
  group_by(PROLIFIC_PID) %>%
  summarise(
    # Basic info
    condition_type = case_when(
      any(!is.na(get(ueq_tendency_cols[1]))) ~ "UEQ",
      any(!is.na(get(ueeq_tendency_cols[1]))) ~ "UEQ+Autonomy", 
      TRUE ~ "Unknown"
    ),
    
    # Interface evaluation counts
    total_responses = n(),
    
    # Get all tendency scores
    ueq_scores = list(c(across(all_of(ueq_tendency_cols), ~as.numeric(.x)) %>% 
                       unlist() %>% 
                       .[!is.na(.)])),
    
    ueeq_scores = list(c(across(all_of(ueeq_tendency_cols), ~as.numeric(.x)) %>% 
                        unlist() %>% 
                        .[!is.na(.)])),
    
    # Get all text responses
    all_text = list(c(across(all_of(explanation_cols), ~as.character(.x)) %>% 
                     unlist() %>% 
                     .[!is.na(.) & . != ""])),
    
    .groups = "drop"
  ) %>%
  rowwise() %>%
  mutate(
    # Combine tendency scores
    all_tendency_scores = list(c(ueq_scores, ueeq_scores)),
    
    # Calculate metrics
    interfaces_evaluated = length(all_tendency_scores),
    avg_tendency = ifelse(interfaces_evaluated > 0, 
                         round(mean(all_tendency_scores, na.rm = TRUE), 2), 
                         NA),
    
    # Calculate rejection metrics (assuming rejection if score >= 4)
    rejections = sum(all_tendency_scores >= 4, na.rm = TRUE),
    acceptance_rate = ifelse(interfaces_evaluated > 0, 
                           round((interfaces_evaluated - rejections) / interfaces_evaluated * 100, 1), 
                           NA),
    rejection_rate = ifelse(interfaces_evaluated > 0, 
                          round(rejections / interfaces_evaluated * 100, 1), 
                          NA),
    
    # Text analysis
    text_responses = length(all_text),
    ai_indicators = detect_ai_indicators(all_text),
    text_stats = list(calculate_text_stats(all_text)),
    avg_text_length = text_stats$avg_length,
    very_long_responses = text_stats$very_long,
    
    # Data quality flags
    very_low_tendency = avg_tendency < 1.5 & !is.na(avg_tendency),
    very_high_tendency = avg_tendency > 6.5 & !is.na(avg_tendency),
    extreme_rejection = rejection_rate > 95 & !is.na(rejection_rate),
    extreme_acceptance = acceptance_rate > 95 & !is.na(acceptance_rate),
    possible_ai = ai_indicators > 0 | very_long_responses > 5 | avg_text_length > 300,
    incomplete_data = interfaces_evaluated < 10,
    no_text = text_responses == 0,
    
    # Overall quality score (1 = most concerning, 5 = good)
    quality_score = case_when(
      possible_ai ~ 1,  # Most concerning
      extreme_rejection | extreme_acceptance ~ 2,
      very_low_tendency | very_high_tendency ~ 3,
      incomplete_data | no_text ~ 4,
      TRUE ~ 5  # Good quality
    )
  ) %>%
  ungroup() %>%
  select(-ueq_scores, -ueeq_scores, -all_tendency_scores, -all_text, -text_stats) %>%
  arrange(quality_score, avg_text_length) %>%
  mutate(
    # Add recommendation
    recommendation = case_when(
      quality_score == 1 ~ "EXCLUDE - Likely AI",
      quality_score == 2 ~ "EXCLUDE - Extreme responses", 
      quality_score == 3 ~ "REVIEW - Unusual patterns",
      quality_score == 4 ~ "REVIEW - Incomplete data",
      TRUE ~ "KEEP - Good quality"
    )
  )

# Save the screening table
write.csv(screening_table, "results/participant_screening_table_complete.csv", row.names = FALSE)

cat("\n=== SCREENING RESULTS SUMMARY ===\n")
cat("Total participants in raw data:", nrow(screening_table), "\n")

# Quality distribution
quality_summary <- screening_table %>%
  count(quality_score, recommendation) %>%
  arrange(quality_score)

print(quality_summary)

# Condition distribution
cat("\nCondition distribution:\n")
condition_summary <- screening_table %>% 
  count(condition_type, recommendation) %>%
  arrange(condition_type, recommendation)
print(condition_summary)

# Flag summaries
cat("\nData quality flags summary:\n")
flag_summary <- screening_table %>%
  summarise(
    possible_ai = sum(possible_ai),
    extreme_rejection = sum(extreme_rejection), 
    extreme_acceptance = sum(extreme_acceptance),
    very_low_tendency = sum(very_low_tendency),
    very_high_tendency = sum(very_high_tendency),
    incomplete_data = sum(incomplete_data),
    no_text = sum(no_text)
  )
print(flag_summary)

# Show the most concerning participants (quality score 1-2)
cat("\n=== PARTICIPANTS RECOMMENDED FOR EXCLUSION ===\n")
concerning <- screening_table %>%
  filter(quality_score <= 2) %>%
  select(PROLIFIC_PID, condition_type, interfaces_evaluated, avg_tendency, 
         rejection_rate, text_responses, ai_indicators, avg_text_length, 
         very_long_responses, recommendation) %>%
  arrange(quality_score)

if(nrow(concerning) > 0) {
  print(concerning)
  cat("\nTotal recommended for exclusion:", nrow(concerning), "\n")
} else {
  cat("No participants recommended for exclusion.\n")
}

# Show final sample size after recommended exclusions
recommended_keep <- screening_table %>%
  filter(quality_score >= 3)

cat("\n=== FINAL SAMPLE PROJECTION ===\n")
cat("Original sample:", nrow(screening_table), "participants\n")
cat("Recommended exclusions:", nrow(concerning), "participants\n")
cat("Final clean sample:", nrow(recommended_keep), "participants\n")

cat("\nCondition balance in clean sample:\n")
clean_balance <- recommended_keep %>% count(condition_type)
print(clean_balance)

cat("\nFiles saved:\n")
cat("• results/participant_screening_table_complete.csv - Complete screening data\n")

cat("\n=== NEXT STEPS ===\n")
cat("1. Review participants with quality_score 1-2 for exclusion\n")
cat("2. Manually inspect text responses for AI indicators\n") 
cat("3. Consider excluding based on recommendation column\n")
cat("4. Re-run analysis with cleaned dataset\n")
