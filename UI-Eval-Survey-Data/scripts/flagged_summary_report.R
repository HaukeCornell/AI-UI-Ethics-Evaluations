library(dplyr)

cat("=== FLAGGED PARTICIPANTS SUMMARY REPORT ===\n")
cat("Generated:", Sys.time(), "\n\n")

# Load summary data
flagged_summary <- read.csv("results/flagged_participants_summary.csv")
extraction_summary <- read.csv("results/text_extraction_summary.csv")

cat("TOTAL FLAGGED PARTICIPANTS:", nrow(flagged_summary), "\n")
cat("Text successfully extracted for:", sum(extraction_summary$found), "participants\n\n")

# Category breakdown
cat("=== FLAGGING CATEGORIES ===\n")
cat("AI Suspicious:", sum(flagged_summary$ai_suspicious), "\n")
cat("Poor Quality:", sum(flagged_summary$poor_quality), "\n")
cat("Inconsistent:", sum(flagged_summary$inconsistent), "\n\n")

# Most common flag reasons
cat("=== MOST COMMON FLAG REASONS ===\n")
flag_reason_counts <- table(unlist(strsplit(flagged_summary$flag_reasons, " ")))
flag_reason_counts <- sort(flag_reason_counts, decreasing = TRUE)
for(i in seq_len(min(length(flag_reason_counts), 8))) {
  if(names(flag_reason_counts)[i] != "") {
    cat(names(flag_reason_counts)[i], ":", flag_reason_counts[i], "\n")
  }
}

cat("\n=== TEXT EXTRACTION STATISTICS ===\n")
cat("Average explanations per participant:", round(mean(extraction_summary$explanation_count), 1), "\n")
cat("Average feedback responses per participant:", round(mean(extraction_summary$feedback_count), 1), "\n")
cat("Total characters extracted:", sum(extraction_summary$total_chars), "\n")
cat("Average characters per participant:", round(mean(extraction_summary$total_chars), 1), "\n")

cat("\n=== CONDITION BREAKDOWN ===\n")
condition_breakdown <- flagged_summary %>%
  group_by(condition) %>%
  summarise(
    count = n(),
    ai_suspicious = sum(ai_suspicious),
    poor_quality = sum(poor_quality),
    inconsistent = sum(inconsistent),
    .groups = 'drop'
  )
print(condition_breakdown)

cat("\n=== NEXT STEPS ===\n")
cat("1. Review the detailed text file: results/flagged_participants_text_review.txt\n")
cat("2. For each participant, mark AI_SUSPICIOUS as TRUE/FALSE in the review file\n")
cat("3. Add notes about specific concerns or patterns observed\n")
cat("4. Use the CSV file (results/flagged_participants_for_manual_review.csv) for systematic data entry\n")
cat("5. Consider creating exclusion criteria based on the manual review results\n\n")

cat("Files ready for manual review:\n")
cat("- results/flagged_participants_text_review.txt (", file.size("results/flagged_participants_text_review.txt"), "bytes)\n")
cat("- results/flagged_participants_for_manual_review.csv\n")
cat("- results/flagged_participants_summary.csv\n")
cat("- results/text_extraction_summary.csv\n")
