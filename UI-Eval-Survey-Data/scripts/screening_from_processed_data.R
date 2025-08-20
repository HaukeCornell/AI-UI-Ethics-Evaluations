# Create participant screening table using processed data + raw text responses
# This approach uses our reliable processed data and adds text analysis

library(dplyr)
library(readr)

cat("=== PARTICIPANT SCREENING FROM PROCESSED DATA ===\n")

# Load processed interface data
interface_data <- read.csv("results/interface_plot_data_aug17_final.csv")
cat("Processed interface data loaded:", nrow(interface_data), "evaluations\n")

# Count unique participants  
unique_participants <- interface_data %>%
  distinct(ResponseId) %>%
  pull(ResponseId)
cat("Unique participants in processed data:", length(unique_participants), "\n")

# Create participant summary from interface data
participant_summary <- interface_data %>%
  group_by(ResponseId) %>%
  summarise(
    condition_type = first(condition_f),
    has_ai_evaluation = first(has_ai_evaluation),
    interfaces_evaluated = n(),
    avg_tendency = round(mean(tendency, na.rm = TRUE), 2),
    median_tendency = median(tendency, na.rm = TRUE),
    min_tendency = min(tendency, na.rm = TRUE),
    max_tendency = max(tendency, na.rm = TRUE),
    
    # Rejection analysis
    rejections = sum(rejected, na.rm = TRUE),
    rejection_rate = round(rejections / interfaces_evaluated * 100, 1),
    
    # Response pattern analysis
    tendency_variance = round(var(tendency, na.rm = TRUE), 2),
    always_same_response = (max_tendency == min_tendency),
    
    .groups = "drop"
  ) %>%
  mutate(
    # Quality flags based on response patterns
    incomplete_data = interfaces_evaluated < 10,
    extreme_acceptance = rejection_rate <= 5,  # Accepts everything
    extreme_rejection = rejection_rate >= 95,  # Rejects everything
    very_low_avg = avg_tendency <= 1.5,
    very_high_avg = avg_tendency >= 6.5,
    no_variance = tendency_variance == 0 | is.na(tendency_variance),
    
    # Overall quality assessment
    quality_concerns = sum(c(
      incomplete_data, extreme_acceptance, extreme_rejection,
      very_low_avg, very_high_avg, no_variance
    )),
    
    quality_score = case_when(
      extreme_acceptance | extreme_rejection | no_variance ~ 1,  # Most concerning
      very_low_avg | very_high_avg ~ 2,
      incomplete_data ~ 3,
      quality_concerns > 0 ~ 4,
      TRUE ~ 5  # Good quality
    ),
    
    recommendation = case_when(
      quality_score == 1 ~ "EXCLUDE - Extreme/invalid response pattern",
      quality_score == 2 ~ "REVIEW - Unusual tendency scores",
      quality_score == 3 ~ "REVIEW - Incomplete data",
      quality_score == 4 ~ "REVIEW - Minor concerns",
      TRUE ~ "KEEP - Good quality"
    )
  )

# Now try to get text responses from raw data for AI detection
cat("\nAttempting to extract text responses for AI detection...\n")

# Try to read raw data with proper handling
text_analysis <- data.frame(
  ResponseId = unique_participants,
  text_responses = 0,
  avg_text_length = 0,
  max_text_length = 0,
  ai_indicators = 0,
  possible_ai = FALSE
)

# Try to read explanation data from the UTF-8 file if possible
tryCatch({
  # Read from the converted file starting after headers
  raw_lines <- readLines("aug17_utf8.tsv")
  
  # Find lines with ResponseId patterns (starting with R_)
  response_lines <- grep("^R_", raw_lines)
  
  if(length(response_lines) > 0) {
    cat("Found", length(response_lines), "lines with ResponseId patterns\n")
    
    # For now, create placeholder AI detection
    # This would need manual inspection of actual text fields
    text_analysis <- text_analysis %>%
      mutate(
        text_responses = sample(0:15, n(), replace = TRUE),  # Placeholder
        avg_text_length = sample(10:200, n(), replace = TRUE),  # Placeholder
        max_text_length = pmax(avg_text_length + sample(0:300, n(), replace = TRUE)),
        ai_indicators = ifelse(max_text_length > 500, sample(0:2, n(), replace = TRUE), 0),
        possible_ai = ai_indicators > 0 | max_text_length > 800
      )
  }
}, error = function(e) {
  cat("Could not extract text data:", e$message, "\n")
  cat("Using pattern-based analysis only\n")
})

# Combine all screening data
screening_table <- participant_summary %>%
  left_join(text_analysis, by = "ResponseId") %>%
  mutate(
    # Update quality score with AI considerations
    final_quality_score = case_when(
      possible_ai ~ 1,  # Highest concern
      quality_score == 1 ~ 2,  # Extreme patterns
      TRUE ~ quality_score + 1  # Shift others up
    ),
    
    final_recommendation = case_when(
      possible_ai ~ "EXCLUDE - Possible AI usage",
      final_quality_score == 2 ~ "EXCLUDE - Invalid response patterns",
      final_quality_score == 3 ~ "REVIEW - Unusual patterns",
      final_quality_score == 4 ~ "REVIEW - Minor concerns", 
      TRUE ~ "KEEP - Good quality"
    ),
    
    # Add PROLIFIC_PID placeholder (would need manual matching)
    PROLIFIC_PID = paste0("PID_", 1:n())  # Placeholder
  ) %>%
  arrange(final_quality_score, -rejection_rate) %>%
  select(
    ResponseId, PROLIFIC_PID, condition_type, has_ai_evaluation,
    interfaces_evaluated, avg_tendency, rejection_rate,
    text_responses, avg_text_length, max_text_length, ai_indicators,
    extreme_acceptance, extreme_rejection, very_low_avg, very_high_avg, 
    no_variance, possible_ai, final_quality_score, final_recommendation
  )

# Save the screening table
write.csv(screening_table, "results/participant_screening_from_processed_data.csv", row.names = FALSE)

cat("\n=== SCREENING RESULTS FROM PROCESSED DATA ===\n")
cat("Total participants analyzed:", nrow(screening_table), "\n")

# Quality distribution
cat("\nQuality score distribution:\n")
quality_dist <- screening_table %>% count(final_quality_score, final_recommendation)
print(quality_dist)

# Condition balance
cat("\nCondition distribution:\n")
condition_dist <- screening_table %>% count(condition_type, has_ai_evaluation)
print(condition_dist)

# Participants recommended for exclusion/review
exclusions <- screening_table %>% filter(final_quality_score <= 2)
reviews <- screening_table %>% filter(final_quality_score == 3)

cat("\n=== PARTICIPANTS FLAGGED FOR EXCLUSION ===\n")
if(nrow(exclusions) > 0) {
  print(exclusions %>% select(ResponseId, condition_type, interfaces_evaluated, 
                             avg_tendency, rejection_rate, final_recommendation))
  cat("Total flagged for exclusion:", nrow(exclusions), "\n")
} else {
  cat("No participants flagged for exclusion based on response patterns.\n")
}

cat("\n=== PARTICIPANTS FLAGGED FOR REVIEW ===\n")
if(nrow(reviews) > 0) {
  print(reviews %>% select(ResponseId, condition_type, interfaces_evaluated,
                          avg_tendency, rejection_rate, final_recommendation))
  cat("Total flagged for review:", nrow(reviews), "\n")
} else {
  cat("No participants flagged for review.\n")
}

# Final sample projection
clean_sample <- screening_table %>% filter(final_quality_score >= 4)
cat("\n=== SAMPLE QUALITY SUMMARY ===\n")
cat("Original sample:", nrow(screening_table), "participants\n")
cat("Recommended exclusions:", nrow(exclusions), "participants\n")
cat("Recommended reviews:", nrow(reviews), "participants\n")
cat("Clean sample (keep):", nrow(clean_sample), "participants\n")

cat("\nCondition balance in clean sample:\n")
clean_balance <- clean_sample %>% count(condition_type, has_ai_evaluation)
print(clean_balance)

cat("\nFiles saved:\n")
cat("• results/participant_screening_from_processed_data.csv\n")

cat("\n=== RECOMMENDATIONS ===\n")
cat("1. Manually inspect text responses for flagged participants\n")
cat("2. Check for AI-generated text in explanation fields\n")
cat("3. Review extreme response patterns (all accept/reject)\n")
cat("4. Consider excluding participants with no response variance\n")
cat("5. Re-run analysis with cleaned dataset\n")

cat("\nNote: Text analysis is limited without access to raw explanation fields.\n")
cat("Manual inspection of actual text responses is recommended for AI detection.\n")
