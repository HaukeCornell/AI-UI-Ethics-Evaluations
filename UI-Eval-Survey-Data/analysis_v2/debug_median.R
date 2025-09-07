# Debug median calculation issue
library(dplyr)

# Load data exactly as in the main script
interface_data <- read.csv("results/three_condition_interface_data.csv")

# Update condition names exactly as in main script
interface_data$condition_new <- case_when(
  interface_data$condition == "RAW" ~ "UI",
  interface_data$condition == "UEQ" ~ "UEQ", 
  interface_data$condition == "UEQ+Autonomy" ~ "UEQ-A",
  TRUE ~ interface_data$condition
)

# Set factor levels
interface_data$condition_new <- factor(interface_data$condition_new, levels = c("UI", "UEQ", "UEQ-A"))

# Remove missing tendency values
interface_data <- interface_data[!is.na(interface_data$tendency), ]

cat("=== DATA OVERVIEW ===\n")
cat("Total evaluations:", nrow(interface_data), "\n")
print(table(interface_data$condition_new))

cat("\n=== MEDIAN VERIFICATION ===\n")
medians_by_condition <- interface_data %>%
  group_by(condition_new) %>%
  summarise(
    n = n(),
    median_val = median(tendency, na.rm = TRUE),
    mean_val = mean(tendency, na.rm = TRUE),
    .groups = "drop"
  )
print(medians_by_condition)

cat("\n=== DETAILED UEQ-A ANALYSIS ===\n")
ueqa_data <- interface_data$tendency[interface_data$condition_new == "UEQ-A"]
cat("UEQ-A sample size:", length(ueqa_data), "\n")
cat("UEQ-A tendency values summary:\n")
print(summary(ueqa_data))
cat("\nUEQ-A tendency value frequency table:\n")
print(table(ueqa_data))

cat("\n=== MANUAL MEDIAN CALCULATION ===\n")
sorted_ueqa <- sort(ueqa_data)
n_ueqa <- length(sorted_ueqa)
cat("Sorted UEQ-A values (first 20):", head(sorted_ueqa, 20), "\n")
cat("Sorted UEQ-A values (last 20):", tail(sorted_ueqa, 20), "\n")
cat("Middle position(s):", n_ueqa/2, "and", (n_ueqa/2)+1, "\n")
manual_median <- median(sorted_ueqa)
cat("Manual median calculation:", manual_median, "\n")

# Check if there are any data issues
cat("\n=== DATA QUALITY CHECK ===\n")
cat("Any infinite values:", any(is.infinite(ueqa_data)), "\n")
cat("Any NA values:", any(is.na(ueqa_data)), "\n")
cat("Min value:", min(ueqa_data), "\n")
cat("Max value:", max(ueqa_data), "\n")
