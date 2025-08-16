# AI vs Human Evaluation Analysis
# Analyzing within-subjects differences between AI and Human evaluation sources

library(readr)
library(dplyr)
library(ggplot2)
library(emmeans)
library(lme4)

# Read the UTF-8 converted data
data <- read_tsv("survey_data_utf8.tsv", show_col_types = FALSE)

cat("=== AI vs Human Analysis ===\n")
cat("Data dimensions:", nrow(data), "x", ncol(data), "\n\n")

# Examine the relevant columns for AI vs Human evaluation source
ai_human_cols <- data %>% 
  select(contains("AI"), contains("eval"), contains("Evaluation"), contains("Data")) %>%
  select_if(~ !all(is.na(.)))

cat("Columns potentially related to AI/Human evaluation source:\n")
print(names(ai_human_cols))
cat("\n")

# Look at unique values in key columns
if("AI eval" %in% names(data)) {
  cat("AI eval column values:\n")
  print(table(data$`AI eval`, useNA = "always"))
  cat("\n")
}

if("Evaluation Data" %in% names(data)) {
  cat("Evaluation Data column values:\n")
  print(table(data$`Evaluation Data`, useNA = "always"))
  cat("\n")
}

# Check for any embedded data columns that might contain source information
embedded_cols <- names(data)[grepl("embedded|source|generator|type", names(data), ignore.case = TRUE)]
if(length(embedded_cols) > 0) {
  cat("Potential embedded data columns:\n")
  print(embedded_cols)
  for(col in embedded_cols) {
    cat("\n", col, "values:\n")
    print(table(data[[col]], useNA = "always"))
  }
  cat("\n")
}

# Also check if there's any pattern in the interface names or evaluation data paths
# that might indicate AI vs Human source

# Print first few rows of key columns to understand the structure
cat("Sample of relevant columns (first 5 rows):\n")
sample_cols <- names(data)[grepl("AI|eval|Data", names(data), ignore.case = TRUE)]
if(length(sample_cols) > 0) {
  print(data[1:5, sample_cols])
}
cat("\n")

# Check if the VLM-UI-Evaluations folder contains mapping information
cat("Note: May need to cross-reference with VLM-UI-Evaluations folder for AI source mapping\n")
cat("Particularly check: bright-interfaces.json, dark-interfaces.json, etc.\n")
