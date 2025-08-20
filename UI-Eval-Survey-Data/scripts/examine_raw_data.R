# First, let's examine the raw data structure
library(dplyr)
library(readr)

cat("=== EXAMINING RAW DATA STRUCTURE ===\n")

# Load the raw data
raw_data <- read_tsv("aug17_utf8.tsv")

cat("Raw data dimensions:", nrow(raw_data), "rows,", ncol(raw_data), "columns\n\n")

# Show first few column names
cat("First 20 column names:\n")
print(head(names(raw_data), 20))

cat("\nColumn names containing 'UEQ':\n")
ueq_cols <- grep("UEQ", names(raw_data), value = TRUE)
print(ueq_cols)

cat("\nColumn names containing 'reason':\n")
reason_cols <- grep("reason", names(raw_data), value = TRUE, ignore.case = TRUE)
print(reason_cols)

cat("\nColumn names containing 'interface':\n")  
interface_cols <- grep("interface", names(raw_data), value = TRUE, ignore.case = TRUE)
print(interface_cols)

cat("\nColumn names containing 'PROLIFIC':\n")
prolific_cols <- grep("PROLIFIC", names(raw_data), value = TRUE)
print(prolific_cols)

cat("\nLet's look at the first few rows of key columns:\n")
key_cols <- c("PROLIFIC_PID", ueq_cols[1:5], reason_cols[1:3])
if(length(key_cols[key_cols %in% names(raw_data)]) > 0) {
  print(raw_data[1:3, key_cols[key_cols %in% names(raw_data)]])
}

# Check for any patterns in column naming
cat("\nAll column names (first 50):\n")
print(head(names(raw_data), 50))
