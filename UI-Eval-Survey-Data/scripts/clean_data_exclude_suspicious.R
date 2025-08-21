library(dplyr)
library(ggplot2)

cat("=== EXCLUDING SUSPICIOUS/LOW QUALITY PARTICIPANTS ===\n")

# Load the complete participant data
screening_data <- read.csv("results/participant_screening_with_text_and_variance.csv")

# List of participants to exclude (identified as AI suspicious or very low quality)
exclude_ids <- c(
  "67d2ba7e8fadacc3db804a1b",
  "677cea851b45fb93eab1cf15", 
  "673594215b1a0b92d5835525",
  "67dc387f88088fd4aca51d89",
  "65583ffa38bfc41805a553cd",
  "67d299d6194fca1b65760b11",
  "667f0276a34ff38c12fda451",
  "6743278eba3a6dfeeeb53b00",
  "67c712364ec9ad3f92b3a339",
  "6728a33bf6aa750798eb8088"
)

cat("Participants to exclude:", length(exclude_ids), "\n")

# Filter out suspicious participants and keep only those with complete data
clean_data <- screening_data %>%
  filter(interfaces_evaluated > 0,  # Has complete data
         !PROLIFIC_PID %in% exclude_ids,  # Not in exclusion list
         condition %in% c("UEQ", "UEQ+Autonomy"))  # Valid conditions only

cat("Original participants with complete data:", sum(screening_data$interfaces_evaluated > 0), "\n")
cat("Participants after exclusions:", nrow(clean_data), "\n")
cat("Excluded:", sum(screening_data$interfaces_evaluated > 0) - nrow(clean_data), "participants\n")

# Check sample sizes by condition
condition_counts <- clean_data %>%
  count(condition) %>%
  arrange(condition)

cat("\n=== SAMPLE SIZES BY CONDITION ===\n")
print(condition_counts)

# Check if we have sufficient sample sizes (rule of thumb: n >= 20 per group for t-tests)
min_sample <- min(condition_counts$n)
cat("\nMinimum sample size per condition:", min_sample, "\n")
cat("Sufficient for statistical tests (>= 20):", min_sample >= 20, "\n")

# Calculate descriptive statistics by condition
descriptives <- clean_data %>%
  group_by(condition) %>%
  summarise(
    n = n(),
    mean_tendency = round(mean(avg_tendency, na.rm = TRUE), 3),
    sd_tendency = round(sd(avg_tendency, na.rm = TRUE), 3),
    mean_rejection_rate = round(mean(rejection_rate, na.rm = TRUE), 1),
    sd_rejection_rate = round(sd(rejection_rate, na.rm = TRUE), 1),
    median_tendency = round(median(avg_tendency, na.rm = TRUE), 3),
    median_rejection_rate = round(median(rejection_rate, na.rm = TRUE), 1),
    .groups = 'drop'
  )

cat("\n=== DESCRIPTIVE STATISTICS BY CONDITION ===\n")
print(descriptives)

# Calculate effect sizes (Cohen's d) for tendency
ueq_tendency <- clean_data %>% filter(condition == "UEQ") %>% pull(avg_tendency)
ueq_autonomy_tendency <- clean_data %>% filter(condition == "UEQ+Autonomy") %>% pull(avg_tendency)

pooled_sd_tendency <- sqrt(((length(ueq_tendency) - 1) * var(ueq_tendency) + 
                           (length(ueq_autonomy_tendency) - 1) * var(ueq_autonomy_tendency)) / 
                          (length(ueq_tendency) + length(ueq_autonomy_tendency) - 2))

cohens_d_tendency <- (mean(ueq_tendency) - mean(ueq_autonomy_tendency)) / pooled_sd_tendency

cat("\n=== EFFECT SIZE ESTIMATES ===\n")
cat("Cohen's d for tendency (UEQ vs UEQ+Autonomy):", round(cohens_d_tendency, 3), "\n")
cat("Interpretation: |d| < 0.2 = small, |d| < 0.5 = medium, |d| < 0.8 = large\n")

# Save clean data for further analysis
write.csv(clean_data, "results/clean_data_for_analysis.csv", row.names = FALSE)
cat("\nClean data saved: results/clean_data_for_analysis.csv\n")

cat("\n=== READY FOR STATISTICAL TESTING ===\n")
cat("Next steps:\n")
cat("1. Check normality assumptions\n") 
cat("2. Test tendency differences between conditions\n")
cat("3. Test rejection rate differences between conditions\n")
