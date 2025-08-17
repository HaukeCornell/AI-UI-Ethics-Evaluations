library(readr)
library(dplyr)

# Load data
data_raw <- read_tsv("survey_data_utf8.tsv", show_col_types = FALSE)
data_clean <- data_raw[-c(1:2), ]

cat("Total rows in data:", nrow(data_clean), "\n")

# Check first few participants
cat("\nFirst 5 ResponseIds:\n")
print(head(data_clean$ResponseId, 5))

# Check column names with UEQ/UEEQ
ueq_cols <- names(data_clean)[grepl("UEQ", names(data_clean))]
ueeq_cols <- names(data_clean)[grepl("UEEQ", names(data_clean))]

cat("\nUEQ columns found:", length(ueq_cols), "\n")
cat("UEEQ columns found:", length(ueeq_cols), "\n")

if (length(ueq_cols) > 0) {
  cat("Sample UEQ columns:", head(ueq_cols, 3), "\n")
}
if (length(ueeq_cols) > 0) {
  cat("Sample UEEQ columns:", head(ueeq_cols, 3), "\n")
}

# Check specific columns for interface 1
ueq_1_col <- "1_UEQ Tendency_1"
ueeq_1_col <- "1_UEEQ Tendency_1"

cat("\nChecking interface 1 columns:\n")
cat("UEQ column exists:", ueq_1_col %in% names(data_clean), "\n")
cat("UEEQ column exists:", ueeq_1_col %in% names(data_clean), "\n")

if (ueq_1_col %in% names(data_clean)) {
  ueq_1_values <- as.numeric(data_clean[[ueq_1_col]])
  cat("UEQ interface 1 non-missing:", sum(!is.na(ueq_1_values)), "\n")
  cat("UEQ interface 1 sample values:", head(ueq_1_values[!is.na(ueq_1_values)], 3), "\n")
}

if (ueeq_1_col %in% names(data_clean)) {
  ueeq_1_values <- as.numeric(data_clean[[ueeq_1_col]])
  cat("UEEQ interface 1 non-missing:", sum(!is.na(ueeq_1_values)), "\n")
  cat("UEEQ interface 1 sample values:", head(ueeq_1_values[!is.na(ueeq_1_values)], 3), "\n")
}
