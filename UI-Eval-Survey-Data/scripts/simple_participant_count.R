# Simple count of all participants in the August 17 data
library(readr)

cat("=== SIMPLE PARTICIPANT COUNT ===\n")

# Read data starting from row 74 with proper headers
header_line <- readLines("aug17_utf8.tsv", n = 1)
column_names <- strsplit(header_line, "\t")[[1]]

cat("Total columns in header:", length(column_names), "\n")
cat("PROLIFIC_PID column position:", which(column_names == "PROLIFIC_PID"), "\n")

# Read all data from row 74 onwards
all_data <- read_tsv("aug17_utf8.tsv", 
                     skip = 73,
                     col_names = column_names,
                     show_col_types = FALSE)

cat("Total rows read:", nrow(all_data), "\n")

# Check PROLIFIC_PID column
cat("Non-empty PROLIFIC_PID values:", sum(!is.na(all_data$PROLIFIC_PID) & all_data$PROLIFIC_PID != ""), "\n")

# Show first few PROLIFIC_PIDs
prolific_values <- all_data$PROLIFIC_PID[!is.na(all_data$PROLIFIC_PID) & all_data$PROLIFIC_PID != ""]
cat("First 10 PROLIFIC_PIDs:\n")
print(head(prolific_values, 10))

# Check for valid prolific IDs (length >= 20)
valid_prolific <- prolific_values[nchar(prolific_values) >= 20]
cat("Valid PROLIFIC_PIDs (length >= 20):", length(valid_prolific), "\n")

# Check for unique participants
unique_prolific <- unique(valid_prolific)
cat("Unique valid participants:", length(unique_prolific), "\n")

# Show some sample values to check
cat("\nSample PROLIFIC_PID lengths:\n")
sample_lengths <- nchar(head(prolific_values, 10))
print(data.frame(PROLIFIC_PID = head(prolific_values, 10), length = sample_lengths))

# Check if there are any unusual values
cat("\nUnusual PROLIFIC_PID values (length < 20):\n")
short_ids <- prolific_values[nchar(prolific_values) < 20]
if(length(short_ids) > 0) {
  print(head(short_ids, 10))
} else {
  cat("None found.\n")
}

cat("\nAll", length(unique_prolific), "participants should be included in the screening table.\n")
