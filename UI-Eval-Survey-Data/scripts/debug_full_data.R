# Complete investigation of August 17 data - reading all participant data
library(readr)

cat("=== COMPLETE AUGUST 17 DATA INVESTIGATION ===\n")

# Try reading the original file directly  
orig_file <- "UX+Metrics+Design+Decision+Impact_August+17%2C+2025_17.59.tsv"

# First check file encoding and structure
cat("Checking file structure...\n")

# Read first few lines to understand structure
first_lines <- readLines(orig_file, n = 10)
cat("First few lines:\n")
for(i in 1:min(5, length(first_lines))) {
  cat("Line", i, ":", substr(first_lines[i], 1, 100), "...\n")
}

# Try different approaches to read the data
cat("\nTrying different reading approaches...\n")

# Approach 1: Auto-detect
tryCatch({
  data1 <- read_tsv(orig_file, locale = locale(encoding = "UTF-16"), show_col_types = FALSE)
  cat("UTF-16 reading: ", nrow(data1), "rows\n")
}, error = function(e) {
  cat("UTF-16 reading failed:", e$message, "\n")
})

# Approach 2: Skip different numbers of rows
for(skip_rows in c(0, 1, 2, 3, 4, 5)) {
  tryCatch({
    data_test <- read_tsv(orig_file, skip = skip_rows, show_col_types = FALSE)
    prolific_col <- which(grepl("PROLIFIC", names(data_test), ignore.case = TRUE))
    if(length(prolific_col) > 0) {
      valid_prolific <- sum(!is.na(data_test[[prolific_col]]) & 
                           nchar(as.character(data_test[[prolific_col]])) >= 20)
      cat("Skip", skip_rows, "rows:", nrow(data_test), "total rows,", valid_prolific, "valid participants\n")
    }
  }, error = function(e) {
    cat("Skip", skip_rows, "failed\n")
  })
}

# Try reading as UTF-8 with different skip values
cat("\nTrying UTF-8 converted file with different skip values...\n")
utf8_file <- "aug17_utf8.tsv"

for(skip_rows in c(0, 1, 2, 3, 4, 5)) {
  tryCatch({
    data_test <- read_tsv(utf8_file, skip = skip_rows, show_col_types = FALSE)
    prolific_col <- which(grepl("PROLIFIC", names(data_test), ignore.case = TRUE))
    if(length(prolific_col) > 0) {
      valid_prolific <- sum(!is.na(data_test[[prolific_col]]) & 
                           nchar(as.character(data_test[[prolific_col]])) >= 20)
      cat("UTF-8 Skip", skip_rows, "rows:", nrow(data_test), "total rows,", valid_prolific, "valid participants\n")
    }
  }, error = function(e) {
    cat("UTF-8 Skip", skip_rows, "failed\n")
  })
}

# Check if data is spread across multiple sections
cat("\nChecking for multiple data sections...\n")
all_lines <- readLines(utf8_file)
prolific_lines <- grep("^[0-9a-f]{20,}", all_lines)
cat("Lines with 20+ character hex strings (potential PROLIFIC_PIDs):", length(prolific_lines), "\n")
if(length(prolific_lines) > 0) {
  cat("First few line numbers:", head(prolific_lines, 10), "\n")
  cat("Last few line numbers:", tail(prolific_lines, 10), "\n")
}

# Also check for any lines with "5" or "6" at start (prolific IDs often start with these)
prolific_pattern_lines <- grep("^[56][0-9a-f]{20,}", all_lines)
cat("Lines starting with 5/6 + 20+ hex chars:", length(prolific_pattern_lines), "\n")

cat("\nTo help debug, you mentioned 104 participants. Let me check for that pattern...\n")
