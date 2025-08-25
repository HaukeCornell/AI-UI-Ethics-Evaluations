# Simple Interface Data Regeneration
library(dplyr)

cat("=== DEBUGGING INTERFACE DATA EXTRACTION ===\n")

# Load data 
data <- read.delim("aug17_utf8.tsv", sep = "\t", header = TRUE, 
                   stringsAsFactors = FALSE, encoding = "UTF-8")

cat("Data loaded:", nrow(data), "rows,", ncol(data), "columns\n")

# Check column names
ueq_tendency_cols <- grep("UEQ Tendency", names(data), value = TRUE)
ueeq_tendency_cols <- grep("UEEQ Tendency", names(data), value = TRUE)

cat("UEQ Tendency columns found:", length(ueq_tendency_cols), "\n")
cat("UEEQ Tendency columns found:", length(ueeq_tendency_cols), "\n")

if(length(ueq_tendency_cols) > 0) {
  cat("First few UEQ columns:", head(ueq_tendency_cols, 3), "\n")
}
if(length(ueeq_tendency_cols) > 0) {
  cat("First few UEEQ columns:", head(ueeq_tendency_cols, 3), "\n")
}

# Check data types for key columns
cat("\nProgress column class:", class(data$Progress), "\n")
cat("Progress values:", unique(data$Progress)[1:5], "\n")

# Filter completed responses
completed_data <- data %>% filter(Progress == 100)
cat("Completed responses:", nrow(completed_data), "\n")

# Check which participants have UEQ vs UEEQ data
if(length(ueq_tendency_cols) > 0 && length(ueeq_tendency_cols) > 0) {
  first_ueq_col <- ueq_tendency_cols[1]
  first_ueeq_col <- ueeq_tendency_cols[1]
  
  has_ueq <- !is.na(completed_data[[first_ueq_col]]) & completed_data[[first_ueq_col]] != ""
  has_ueeq <- !is.na(completed_data[[first_ueeq_col]]) & completed_data[[first_ueeq_col]] != ""
  
  cat("Participants with UEQ data:", sum(has_ueq), "\n")
  cat("Participants with UEEQ data:", sum(has_ueeq), "\n")
  cat("Total participants with interface data:", sum(has_ueq | has_ueeq), "\n")
}
