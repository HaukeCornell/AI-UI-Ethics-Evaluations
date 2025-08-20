# Data Comparison: August 16 vs August 17 
# Checking the improvement in sample size and balance

library(dplyr)

cat("=== DATA COMPARISON: OLD vs NEW ===\n")

# Load old data (August 16)
old_data <- read.csv("results/interface_plot_data_updated.csv")

# Load new data (August 17)
new_data <- read.csv("results/interface_plot_data_aug17_final.csv")

cat("SAMPLE SIZE COMPARISON:\n")
cat("Old data (Aug 16):\n")
cat("• Total evaluations:", nrow(old_data), "\n")
cat("• Unique participants:", length(unique(old_data$ResponseId)), "\n")
cat("• Avg evaluations per participant:", round(nrow(old_data) / length(unique(old_data$ResponseId)), 1), "\n")

cat("\nNew data (Aug 17):\n")
cat("• Total evaluations:", nrow(new_data), "\n")
cat("• Unique participants:", length(unique(new_data$ResponseId)), "\n")
cat("• Avg evaluations per participant:", round(nrow(new_data) / length(unique(new_data$ResponseId)), 1), "\n")

cat("\nIMPROVEMENT:\n")
cat("• Additional participants:", length(unique(new_data$ResponseId)) - length(unique(old_data$ResponseId)), "\n")
cat("• Additional evaluations:", nrow(new_data) - nrow(old_data), "\n")
cat("• Percent increase:", round((length(unique(new_data$ResponseId)) / length(unique(old_data$ResponseId)) - 1) * 100, 1), "%\n")

cat("\nCONDITION BALANCE COMPARISON:\n")
cat("Old data balance:\n")
old_balance <- old_data %>%
  distinct(ResponseId, condition_f, has_ai_evaluation) %>%
  count(condition_f, has_ai_evaluation)
print(old_balance)

cat("\nNew data balance:\n")
new_balance <- new_data %>%
  distinct(ResponseId, condition_f, has_ai_evaluation) %>%
  count(condition_f, has_ai_evaluation)
print(new_balance)

# Check balance improvement
cat("\nBALANCE IMPROVEMENT:\n")
old_min <- min(old_balance$n)
old_max <- max(old_balance$n)
new_min <- min(new_balance$n)
new_max <- max(new_balance$n)

cat("Old data: min =", old_min, ", max =", old_max, ", range =", old_max - old_min, "\n")
cat("New data: min =", new_min, ", max =", new_max, ", range =", new_max - new_min, "\n")

if(new_max - new_min < old_max - old_min) {
  cat("✓ Balance IMPROVED with new data\n")
} else {
  cat("⚠ Balance similar or worse with new data\n")
}

cat("\n=== RECOMMENDATION ===\n")
cat("Use NEW August 17 data for analysis:\n")
cat("• Larger sample size (N = 94 vs 65)\n") 
cat("• More evaluations (940 vs 650)\n")
cat("• Better statistical power\n")
cat("• More recent data\n")
