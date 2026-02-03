# 01_process_data.R - Data Processing Pipeline for Replication
# Processes raw survey data into the format used for paper figures

library(dplyr)
library(readr)
library(tidyr)

cat("=== 01: PROCESSING SURVEY DATA ===\n")

# 1. Load Exclusion List
exclusion_list <- read.csv("data/exclusion_list.csv")
flagged_ids <- exclusion_list$PROLIFIC_PID
cat("• Participants to exclude:", length(flagged_ids), "\n")

# 2. Load Raw Data
# Note: The raw data is a tab-separated file from Qualtrics
raw_data <- read_tsv("data/sep2_completed_utf8.tsv", show_col_types = FALSE)
cat("• Total rows in raw dataset:", nrow(raw_data), "\n")

# 3. Basic Cleaning
clean_data <- raw_data %>%
  filter(
    !is.na(ResponseId),
    !grepl("Response ID|ImportId", ResponseId, ignore.case = TRUE)
  ) %>%
  filter(!PROLIFIC_PID %in% flagged_ids)

cat("• Rows after cleaning and exclusions:", nrow(clean_data), "\n")

# 4. Extract Interface Evaluations
all_interface_data <- list()
for(interface_num in 1:15) {
  ui_code <- sprintf("ui%03d", interface_num)
  
  # Map columns for this interface across three conditions
  # RAW (No evaluation), UEQ (Standard metrics), UEEQ-P (Ethical persuasion metrics)
  
  extract_cond <- function(data, prefix, cond_name) {
    tendency_col <- paste0(interface_num, "_", prefix, " Tendency_1")
    release_col <- paste0(interface_num, "_", prefix, " Release")
    
    data %>%
      filter(!is.na(.data[[tendency_col]])) %>%
      select(ResponseId, PROLIFIC_PID, 
             tendency = all_of(tendency_col),
             release = all_of(release_col)) %>%
      mutate(condition = cond_name, 
             interface = ui_code,
             tendency_numeric = as.numeric(tendency),
             release_binary = ifelse(grepl("Yes", release, ignore.case = TRUE), 1, 0))
  }
  
  all_interface_data[[ui_code]] <- bind_rows(
    extract_cond(clean_data, "RAW", "RAW"),
    extract_cond(clean_data, "UEQ", "UEQ"),
    extract_cond(clean_data, "UEEQ", "UEQ+Autonomy")
  )
}

final_data <- bind_rows(all_interface_data)

# 5. Save Processed Data
if(!dir.exists("results")) dir.create("results")
write.csv(final_data, "results/three_condition_interface_data.csv", row.names = FALSE)

cat("✓ Data processing complete. Created results/three_condition_interface_data.csv\n")
