# Comprehensive investigation of 0 values in tendency data
library(dplyr)

# Load data
interface_data <- read.csv("results/three_condition_interface_data.csv")

cat("=== INVESTIGATING 0 VALUES IN TENDENCY DATA ===\n")

# Check the raw data structure
cat("\n=== RAW DATA OVERVIEW ===\n")
cat("Total rows in dataset:", nrow(interface_data), "\n")
cat("Columns related to tendency:\n")
tendency_cols <- names(interface_data)[grepl("tendency|tend", names(interface_data), ignore.case = TRUE)]
print(tendency_cols)

# Check all tendency-related values
cat("\n=== TENDENCY COLUMN ANALYSIS ===\n")
if("tendency" %in% names(interface_data)) {
  cat("Tendency column summary:\n")
  print(summary(interface_data$tendency))
  
  cat("\nTendency value counts:\n")
  print(table(interface_data$tendency, useNA = "always"))
  
  cat("\nZero values by condition:\n")
  zero_analysis <- interface_data %>%
    group_by(condition) %>%
    summarise(
      total = n(),
      zeros = sum(tendency == 0, na.rm = TRUE),
      NAs = sum(is.na(tendency)),
      percent_zeros = round((sum(tendency == 0, na.rm = TRUE) / n()) * 100, 2),
      percent_NAs = round((sum(is.na(tendency)) / n()) * 100, 2)
    )
  print(zero_analysis)
}

# Check if there are other tendency-related columns
other_tend_cols <- tendency_cols[tendency_cols != "tendency"]
if(length(other_tend_cols) > 0) {
  cat("\n=== OTHER TENDENCY COLUMNS ===\n")
  for(col in other_tend_cols) {
    cat("\n", col, "summary:\n")
    print(summary(interface_data[[col]]))
    cat("Zero count:", sum(interface_data[[col]] == 0, na.rm = TRUE), "\n")
  }
}

# Check participant data for similar issues
cat("\n=== CHECKING PARTICIPANT-LEVEL DATA ===\n")
participant_files <- c("results/three_condition_participant_data.csv")
for(file in participant_files) {
  if(file.exists(file)) {
    cat("\nAnalyzing:", file, "\n")
    part_data <- read.csv(file)
    
    # Check for tendency-related columns
    part_tend_cols <- names(part_data)[grepl("tendency|tend", names(part_data), ignore.case = TRUE)]
    
    for(col in part_tend_cols) {
      if(col %in% names(part_data)) {
        cat(col, "- Zero count:", sum(part_data[[col]] == 0, na.rm = TRUE), "\n")
        cat(col, "- Summary:\n")
        print(summary(part_data[[col]]))
      }
    }
  }
}

# Check for rejection data too (might have same issue)
cat("\n=== CHECKING REJECTION DATA ===\n")
rejection_cols <- names(interface_data)[grepl("rejection|reject", names(interface_data), ignore.case = TRUE)]
for(col in rejection_cols) {
  if(col %in% names(interface_data)) {
    cat("\n", col, "summary:\n")
    print(summary(interface_data[[col]]))
    cat("Value counts:\n")
    print(table(interface_data[[col]], useNA = "always"))
  }
}

# Look at a few specific 0-value records to understand the pattern
cat("\n=== SAMPLE RECORDS WITH TENDENCY = 0 ===\n")
zero_records <- interface_data[interface_data$tendency == 0 & !is.na(interface_data$tendency), ]
if(nrow(zero_records) > 0) {
  cat("Number of records with tendency = 0:", nrow(zero_records), "\n")
  cat("Sample records (first 5):\n")
  relevant_cols <- c("PROLIFIC_PID", "interface", "condition", "tendency", 
                     names(interface_data)[grepl("rejection|reject", names(interface_data))])
  relevant_cols <- relevant_cols[relevant_cols %in% names(interface_data)]
  print(head(zero_records[, relevant_cols], 5))
}

cat("\n=== RECOMMENDATION ===\n")
cat("If 0 values represent missing data, they should be converted to NA\n")
cat("This would affect the following analyses:\n")
cat("- Mixed effects models (lmer)\n") 
cat("- Descriptive statistics\n")
cat("- All visualizations\n")
cat("- Effect size calculations\n")
