# Debug the rejection rate issue

library(readr)
library(dplyr)
library(tidyr)

# Read the UTF-8 converted data
data <- read_tsv("survey_data_utf8.tsv", show_col_types = FALSE)

# Filter to completed responses only
completed_data <- data %>% 
  filter(Progress == 100) %>%
  filter(!is.na(`1_UEQ Tendency_1`) | !is.na(`1_UEEQ Tendency_1`))

# Create AI evaluation indicator
completed_data <- completed_data %>%
  mutate(
    has_ai_evaluation = case_when(
      is.na(`Evaluation Data`) ~ NA,
      grepl("Combined AI-human evaluation", `Evaluation Data`, ignore.case = TRUE) ~ TRUE,
      TRUE ~ FALSE
    )
  )

# Determine UEQ vs UEEQ condition
completed_data <- completed_data %>%
  mutate(
    has_ueq = !is.na(`1_UEQ Tendency_1`),
    has_ueeq = !is.na(`1_UEEQ Tendency_1`),
    condition = case_when(
      has_ueq & !has_ueeq ~ "UEQ",
      !has_ueq & has_ueeq ~ "UEEQ", 
      has_ueq & has_ueeq ~ "Mixed",
      TRUE ~ "Neither"
    )
  )

# Filter to valid conditions only
analysis_data <- completed_data %>%
  filter(condition %in% c("UEQ", "UEEQ"), !is.na(has_ai_evaluation))

cat("Debug: Looking at Release response values\n")

# Check what Release response values we have
ueq_release_cols <- names(analysis_data)[grepl("^\\d+_UEQ Release$", names(analysis_data))]
ueeq_release_cols <- names(analysis_data)[grepl("^\\d+_UEEQ Release$", names(analysis_data))]

cat("UEQ Release columns:", length(ueq_release_cols), "\n")
cat("UEEQ Release columns:", length(ueeq_release_cols), "\n")

# Sample the release values
if(length(ueq_release_cols) > 0) {
  sample_ueq_values <- analysis_data %>%
    filter(condition == "UEQ") %>%
    select(all_of(ueq_release_cols[1:min(3, length(ueq_release_cols))])) %>%
    slice(1:5)
  
  cat("\nSample UEQ Release values:\n")
  print(sample_ueq_values)
}

if(length(ueeq_release_cols) > 0) {
  sample_ueeq_values <- analysis_data %>%
    filter(condition == "UEEQ") %>%
    select(all_of(ueeq_release_cols[1:min(3, length(ueeq_release_cols))])) %>%
    slice(1:5)
  
  cat("\nSample UEEQ Release values:\n")
  print(sample_ueeq_values)
}

# Check unique values across all release columns
all_release_values <- c()
for(col in c(ueq_release_cols, ueeq_release_cols)) {
  values <- analysis_data[[col]][!is.na(analysis_data[[col]])]
  all_release_values <- c(all_release_values, values)
}

cat("\nAll unique Release response values:\n")
print(table(all_release_values))

# Check if the issue is with tendency values instead
ueq_tendency_cols <- names(analysis_data)[grepl("^\\d+_UEQ Tendency_1$", names(analysis_data))]
ueeq_tendency_cols <- names(analysis_data)[grepl("^\\d+_UEEQ Tendency_1$", names(analysis_data))]

cat("\nUEQ Tendency columns:", length(ueq_tendency_cols), "\n")
cat("UEEQ Tendency columns:", length(ueeq_tendency_cols), "\n")

# Sample tendency values
if(length(ueq_tendency_cols) > 0) {
  sample_ueq_tend <- analysis_data %>%
    filter(condition == "UEQ") %>%
    select(all_of(ueq_tendency_cols[1:min(3, length(ueq_tendency_cols))])) %>%
    slice(1:5)
  
  cat("\nSample UEQ Tendency values:\n")
  print(sample_ueq_tend)
}
