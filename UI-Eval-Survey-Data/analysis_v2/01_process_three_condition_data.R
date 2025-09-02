# Three-Condition Data Processing Pipeline
# UEQ vs UEQ+Autonomy vs RAW (No Evaluation Data)
# September 2025

library(dplyr)
library(readr)
library(tidyr)

cat("=== THREE-CONDITION DATA PROCESSING ===\n")
cat("Processing: UEQ vs UEQ+Autonomy vs RAW conditions\n")
cat("Data: sep2_completed_utf8.tsv (completed responses only)\n\n")

# ===== LOAD EXCLUSION LIST =====
cat("1. LOADING EXCLUSION LIST...\n")
exclusion_list <- read.csv("../results/correct_exclusion_list.csv")
flagged_ids <- exclusion_list$PROLIFIC_PID
cat("• Participants to exclude:", length(flagged_ids), "\n")
print(flagged_ids)

# ===== LOAD RAW DATA =====
cat("\n2. LOADING SEPTEMBER DATA (COMPLETED ONLY)...\n")
raw_data <- read_tsv("../sep2_completed_utf8.tsv", show_col_types = FALSE)
cat("• Total rows in dataset:", nrow(raw_data), "\n")

# ===== CLEAN DATA =====
cat("\n3. CLEANING DATA...\n")
clean_data <- raw_data %>%
  filter(
    !is.na(ResponseId),
    !grepl("Response ID|ImportId|Understanding How User", ResponseId, ignore.case = TRUE),
    !ResponseId %in% c("Response ID", "{\"ImportId\":\"_recordId\"}")
  )

cat("• Cleaned rows:", nrow(clean_data), "\n")

# ===== APPLY EXCLUSIONS =====
cat("\n4. APPLYING EXCLUSIONS...\n")
filtered_data <- clean_data %>%
  filter(!PROLIFIC_PID %in% flagged_ids)

cat("• After exclusions:", nrow(filtered_data), "\n")

# ===== EXTRACT INTERFACE DATA =====
cat("\n5. EXTRACTING INTERFACE EVALUATIONS...\n")

# Extract all interfaces (1-15, no exclusions)
interfaces <- 1:15
ui_codes <- sprintf("ui%03d", interfaces)

# Initialize results
all_interface_data <- list()

for(i in 1:length(interfaces)) {
  interface_num <- interfaces[i]
  ui_code <- ui_codes[i]
  
  cat("Processing", ui_code, "...\n")
  
  # Column patterns for this interface
  ueq_tendency_col <- paste0(interface_num, "_UEQ Tendency_1")
  ueq_release_col <- paste0(interface_num, "_UEQ Release")
  
  ueeq_tendency_col <- paste0(interface_num, "_UEEQ Tendency_1")
  ueeq_release_col <- paste0(interface_num, "_UEEQ Release")
  
  raw_tendency_col <- paste0(interface_num, "_RAW Tendency_1")
  raw_release_col <- paste0(interface_num, "_RAW Release")
  
  # Extract UEQ condition data
  ueq_data <- filtered_data %>%
    filter(!is.na(.data[[ueq_tendency_col]])) %>%
    select(
      ResponseId, PROLIFIC_PID, 
      tendency = all_of(ueq_tendency_col),
      release = all_of(ueq_release_col)
    ) %>%
    mutate(
      condition = "UEQ",
      interface = ui_code,
      interface_num = interface_num,
      tendency_numeric = as.numeric(tendency),
      release_binary = case_when(
        grepl("Yes", release, ignore.case = TRUE) ~ 1,
        grepl("No", release, ignore.case = TRUE) ~ 0,
        TRUE ~ NA_real_
      )
    ) %>%
    filter(!is.na(tendency_numeric), !is.na(release_binary))
  
  # Extract UEQ+Autonomy condition data (UEEQ)
  ueeq_data <- filtered_data %>%
    filter(!is.na(.data[[ueeq_tendency_col]])) %>%
    select(
      ResponseId, PROLIFIC_PID,
      tendency = all_of(ueeq_tendency_col),
      release = all_of(ueeq_release_col)
    ) %>%
    mutate(
      condition = "UEQ+Autonomy",
      interface = ui_code,
      interface_num = interface_num,
      tendency_numeric = as.numeric(tendency),
      release_binary = case_when(
        grepl("Yes", release, ignore.case = TRUE) ~ 1,
        grepl("No", release, ignore.case = TRUE) ~ 0,
        TRUE ~ NA_real_
      )
    ) %>%
    filter(!is.na(tendency_numeric), !is.na(release_binary))
  
  # Extract RAW condition data
  raw_condition_data <- filtered_data %>%
    filter(!is.na(.data[[raw_tendency_col]])) %>%
    select(
      ResponseId, PROLIFIC_PID,
      tendency = all_of(raw_tendency_col),
      release = all_of(raw_release_col)
    ) %>%
    mutate(
      condition = "RAW",
      interface = ui_code,
      interface_num = interface_num,
      tendency_numeric = as.numeric(tendency),
      release_binary = case_when(
        grepl("Yes", release, ignore.case = TRUE) ~ 1,
        grepl("No", release, ignore.case = TRUE) ~ 0,
        TRUE ~ NA_real_
      )
    ) %>%
    filter(!is.na(tendency_numeric), !is.na(release_binary))
  
  # Combine all conditions for this interface
  interface_combined <- bind_rows(ueq_data, ueeq_data, raw_condition_data)
  all_interface_data[[ui_code]] <- interface_combined
  
  cat("  UEQ:", nrow(ueq_data), "participants\n")
  cat("  UEQ+Autonomy:", nrow(ueeq_data), "participants\n") 
  cat("  RAW:", nrow(raw_condition_data), "participants\n")
}

# ===== COMBINE ALL DATA =====
cat("\n6. COMBINING ALL INTERFACE DATA...\n")
final_data <- bind_rows(all_interface_data)

cat("• Total evaluations:", nrow(final_data), "\n")
cat("• Unique participants:", length(unique(final_data$ResponseId)), "\n")

# ===== SUMMARY STATISTICS =====
cat("\n7. CONDITION SUMMARY...\n")
condition_summary <- final_data %>%
  group_by(condition) %>%
  summarise(
    participants = n_distinct(ResponseId),
    evaluations = n(),
    mean_tendency = round(mean(tendency_numeric), 2),
    mean_rejection_rate = round(1 - mean(release_binary), 2),
    .groups = "drop"
  )

print(condition_summary)

# ===== INTERFACE SUMMARY =====
cat("\n8. INTERFACE SUMMARY...\n")
interface_summary <- final_data %>%
  group_by(interface) %>%
  summarise(
    total_evaluations = n(),
    ueq_count = sum(condition == "UEQ"),
    ueq_autonomy_count = sum(condition == "UEQ+Autonomy"),
    raw_count = sum(condition == "RAW"),
    .groups = "drop"
  )

print(interface_summary)

# ===== SAVE RESULTS =====
cat("\n9. SAVING RESULTS...\n")

# Save main dataset
write.csv(final_data, "results/three_condition_interface_data.csv", row.names = FALSE)

# Save summaries
write.csv(condition_summary, "results/condition_summary.csv", row.names = FALSE)
write.csv(interface_summary, "results/interface_summary.csv", row.names = FALSE)

# Save participant mapping
participant_mapping <- final_data %>%
  select(ResponseId, PROLIFIC_PID, condition) %>%
  distinct() %>%
  arrange(condition, ResponseId)

write.csv(participant_mapping, "results/participant_condition_mapping.csv", row.names = FALSE)

cat("Files created:\n")
cat("• results/three_condition_interface_data.csv - Main dataset\n")
cat("• results/condition_summary.csv - Condition-level summary\n") 
cat("• results/interface_summary.csv - Interface-level summary\n")
cat("• results/participant_condition_mapping.csv - Participant mapping\n")

cat("\n✓ Data processing complete!\n")
