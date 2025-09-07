# Clean interface data: Convert 0 values to NA for tendency data
# 0 values on a 1-7 scale represent missing data, not valid responses

library(dplyr)

cat("=== CLEANING INTERFACE DATA: CONVERTING 0s TO NAs ===\n")

# Load original data
original_data <- read.csv("results/three_condition_interface_data.csv")

cat("Original data shape:", nrow(original_data), "rows x", ncol(original_data), "columns\n")

# Check zero values before cleaning
zero_count_before <- sum(original_data$tendency == 0, na.rm = TRUE)
cat("Zero values in tendency before cleaning:", zero_count_before, "\n")

# Create cleaned dataset
cleaned_data <- original_data %>%
  mutate(
    # Convert 0 values to NA for tendency (1-7 scale)
    tendency = ifelse(tendency == 0, NA, tendency),
    tendency_numeric = ifelse(tendency_numeric == 0, NA, tendency_numeric)
  )

# Check the cleaning results
zero_count_after <- sum(cleaned_data$tendency == 0, na.rm = TRUE)
na_count_after <- sum(is.na(cleaned_data$tendency))

cat("\nCleaning results:\n")
cat("Zero values in tendency after cleaning:", zero_count_after, "\n")
cat("NA values in tendency after cleaning:", na_count_after, "\n")
cat("Values converted (0 → NA):", zero_count_before, "\n")

# Show the impact by condition
impact_by_condition <- original_data %>%
  group_by(condition) %>%
  summarise(
    total = n(),
    zeros_before = sum(tendency == 0, na.rm = TRUE),
    percent_zeros = round((sum(tendency == 0, na.rm = TRUE) / n()) * 100, 2)
  )

cat("\nImpact by condition:\n")
print(impact_by_condition)

# Save cleaned dataset
write.csv(cleaned_data, "results/three_condition_interface_data_cleaned.csv", row.names = FALSE)

# Also create a backup of original
if(!file.exists("results/three_condition_interface_data_original.csv")) {
  write.csv(original_data, "results/three_condition_interface_data_original.csv", row.names = FALSE)
  cat("\nOriginal data backed up to: three_condition_interface_data_original.csv\n")
}

cat("Cleaned data saved to: three_condition_interface_data_cleaned.csv\n")

# Show summary of cleaned data
cat("\n=== CLEANED DATA SUMMARY ===\n")
cleaned_summary <- cleaned_data %>%
  group_by(condition) %>%
  summarise(
    total = n(),
    valid_tendency = sum(!is.na(tendency)),
    missing_tendency = sum(is.na(tendency)),
    mean_tendency = round(mean(tendency, na.rm = TRUE), 3),
    median_tendency = median(tendency, na.rm = TRUE),
    .groups = "drop"
  )

print(cleaned_summary)

cat("\n=== RECOMMENDATION ===\n")
cat("Replace the original file with cleaned version:\n")
cat("1. Backup: three_condition_interface_data_original.csv (done)\n")
cat("2. Replace: three_condition_interface_data.csv with cleaned version\n")
cat("3. All existing scripts will then use clean data automatically\n")
cat("\nAlternatively, update scripts to use three_condition_interface_data_cleaned.csv\n")
