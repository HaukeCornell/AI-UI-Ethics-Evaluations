library(dplyr)
library(tidyr)

# Load the screening data
cat("=== DATA QUALITY FLAGGING AND TEXT EXTRACTION ===\n")
screening_data <- read.csv('results/participant_screening_with_text_and_variance.csv')
complete_data <- screening_data %>% filter(interfaces_evaluated > 0)

# Define flagging criteria
cat("Applying flagging criteria...\n")

flagged_participants <- complete_data %>%
  mutate(
    # AI Suspicious indicators
    low_text_variance = ifelse(!is.na(var_char_count), var_char_count < 100, FALSE),
    very_long_responses = ifelse(!is.na(avg_char_count), avg_char_count > 300, FALSE),
    ai_suspicious = low_text_variance | very_long_responses,
    
    # Poor quality indicators  
    very_short_responses = ifelse(!is.na(avg_char_count), avg_char_count < 20, FALSE),
    very_low_tendency_var = ifelse(!is.na(var_tendency), var_tendency < 0.5, FALSE),
    very_high_tendency_var = ifelse(!is.na(var_tendency), var_tendency > 8, FALSE),
    poor_quality = very_short_responses | very_low_tendency_var | very_high_tendency_var,
    
    # Inconsistent indicators
    high_char_variance = ifelse(!is.na(var_char_count), var_char_count > 10000, FALSE),
    inconsistent = high_char_variance,
    
    # Overall flag
    flagged = ai_suspicious | poor_quality | inconsistent,
    
    # Create flag reasons
    flag_reasons = paste(
      ifelse(low_text_variance, "LOW_TEXT_VAR", ""),
      ifelse(very_long_responses, "LONG_RESPONSES", ""),
      ifelse(very_short_responses, "SHORT_RESPONSES", ""),
      ifelse(very_low_tendency_var, "LOW_TENDENCY_VAR", ""),
      ifelse(very_high_tendency_var, "HIGH_TENDENCY_VAR", ""),
      ifelse(high_char_variance, "HIGH_CHAR_VAR", ""),
      sep = " "
    ),
    flag_reasons = gsub("\\s+", " ", trimws(flag_reasons)) # Clean up spacing
  ) %>%
  select(PROLIFIC_PID, condition, interfaces_evaluated, avg_tendency, var_tendency,
         rejection_rate, avg_char_count, var_char_count, 
         ai_suspicious, poor_quality, inconsistent, flagged, flag_reasons)

# Summary of flagging
cat("\n=== FLAGGING SUMMARY ===\n")
cat("Total participants with complete data:", nrow(complete_data), "\n")
cat("AI Suspicious:", sum(flagged_participants$ai_suspicious), "\n")
cat("Poor Quality:", sum(flagged_participants$poor_quality), "\n") 
cat("Inconsistent:", sum(flagged_participants$inconsistent), "\n")
cat("Total Flagged:", sum(flagged_participants$flagged), "\n")
cat("Percentage Flagged:", round(sum(flagged_participants$flagged) / nrow(flagged_participants) * 100, 1), "%\n")

# Save flagged participants list
write.csv(flagged_participants, "results/flagged_participants_summary.csv", row.names = FALSE)
cat("\nFlagged participants summary saved: results/flagged_participants_summary.csv\n")

# Show flagged participants by category
cat("\n=== FLAGGED PARTICIPANTS BY CATEGORY ===\n")
if(sum(flagged_participants$ai_suspicious) > 0) {
  cat("\nAI SUSPICIOUS participants:\n")
  ai_flagged <- flagged_participants %>% 
    filter(ai_suspicious) %>%
    select(PROLIFIC_PID, condition, avg_char_count, var_char_count, flag_reasons)
  print(ai_flagged)
}

if(sum(flagged_participants$poor_quality) > 0) {
  cat("\nPOOR QUALITY participants:\n")
  quality_flagged <- flagged_participants %>% 
    filter(poor_quality) %>%
    select(PROLIFIC_PID, condition, avg_tendency, var_tendency, avg_char_count, flag_reasons)
  print(quality_flagged)
}

if(sum(flagged_participants$inconsistent) > 0) {
  cat("\nINCONSISTENT participants:\n")
  inconsistent_flagged <- flagged_participants %>% 
    filter(inconsistent) %>%
    select(PROLIFIC_PID, condition, var_char_count, flag_reasons)
  print(inconsistent_flagged)
}

# Get list of flagged participant IDs for text extraction
flagged_ids <- flagged_participants %>% 
  filter(flagged) %>% 
  pull(PROLIFIC_PID)

cat("\n=== PREPARING TEXT EXTRACTION ===\n")
cat("Flagged participant IDs for text extraction:", length(flagged_ids), "\n")
cat("IDs:", paste(head(flagged_ids, 10), collapse = ", "), 
    ifelse(length(flagged_ids) > 10, "...", ""), "\n")

# Save the list of flagged IDs for the text extraction script
write.csv(data.frame(PROLIFIC_PID = flagged_ids), "results/flagged_participant_ids.csv", row.names = FALSE)
cat("Flagged participant IDs saved: results/flagged_participant_ids.csv\n")

cat("\nNext step: Run text extraction script to get all text responses for flagged participants.\n")
