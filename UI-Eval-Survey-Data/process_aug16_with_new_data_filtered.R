# Complete Data Processing Pipeline - Aug16 Base + New Data + Filtered
# Using aug16_utf8.tsv as base, adding new participants from aug17, filtering bad data

library(dplyr)
library(readr)
library(tidyr)

cat("=== PROCESSING AUG16 + NEW DATA (FILTERED) ===\n")
cat("Base: aug16_utf8.tsv + new participants from aug17_utf8.tsv\n")
cat("Filtering: Remove 10 suspicious participants (correct list)\n\n")

# ===== LOAD FLAGGED PARTICIPANTS =====
cat("1. LOADING FLAGGED PARTICIPANTS...\n")
flagged_ids <- read.csv("results/correct_exclusion_list.csv")$PROLIFIC_PID
cat("• Flagged participants to exclude:", length(flagged_ids), "\n")

# ===== LOAD AND MERGE DATA =====
cat("\n2. LOADING AND MERGING DATA...\n")

# Load aug16 data (baseline)
aug16_data <- read_tsv("aug16_utf8.tsv", show_col_types = FALSE)
cat("• Aug16 total rows:", nrow(aug16_data), "\n")

# Load aug17 data (includes new participants)
aug17_data <- read_tsv("aug17_utf8.tsv", show_col_types = FALSE)
cat("• Aug17 total rows:", nrow(aug17_data), "\n")

# Clean both datasets (remove header rows)
clean_aug16 <- aug16_data %>%
  filter(
    !is.na(ResponseId),
    !grepl("Response ID|ImportId|Understanding How User", ResponseId, ignore.case = TRUE),
    !ResponseId %in% c("Response ID", "{\"ImportId\":\"_recordId\"}")
  )

clean_aug17 <- aug17_data %>%
  filter(
    !is.na(ResponseId),
    !grepl("Response ID|ImportId|Understanding How User", ResponseId, ignore.case = TRUE),
    !ResponseId %in% c("Response ID", "{\"ImportId\":\"_recordId\"}")
  )

cat("• Aug16 clean participants:", nrow(clean_aug16), "\n")
cat("• Aug17 clean participants:", nrow(clean_aug17), "\n")

# Find new participants in aug17 that weren't in aug16
aug16_ids <- clean_aug16$ResponseId
new_participants <- clean_aug17 %>%
  filter(!ResponseId %in% aug16_ids)

cat("• New participants in aug17:", nrow(new_participants), "\n")

# Combine: use aug16 as base + add new participants from aug17
combined_data <- bind_rows(clean_aug16, new_participants)
cat("• Combined dataset participants:", nrow(combined_data), "\n")

# ===== FILTER OUT FLAGGED PARTICIPANTS =====
cat("\n3. FILTERING OUT FLAGGED PARTICIPANTS...\n")

# Find matches between ResponseId and PROLIFIC_PID
# The flagged IDs are PROLIFIC_PIDs, but we need to match to ResponseIds
flagged_response_ids <- combined_data %>%
  filter(PROLIFIC_PID %in% flagged_ids) %>%
  pull(ResponseId)

cat("• Found flagged ResponseIds:", length(flagged_response_ids), "\n")

# Remove flagged participants
filtered_data <- combined_data %>%
  filter(!PROLIFIC_PID %in% flagged_ids)

cat("• After filtering:", nrow(filtered_data), "participants\n")
cat("• Removed:", nrow(combined_data) - nrow(filtered_data), "flagged participants\n")

# ===== ANALYZE DATA STRUCTURE =====
cat("\n4. ANALYZING DATA STRUCTURE...\n")

# Find UEQ and UEEQ columns
ueq_tendency_cols <- grep("_UEQ Tendency", names(filtered_data), value = TRUE)
ueq_release_cols <- grep("_UEQ Release", names(filtered_data), value = TRUE)
ueeq_tendency_cols <- grep("_UEEQ Tendency", names(filtered_data), value = TRUE)
ueeq_release_cols <- grep("_UEEQ Release", names(filtered_data), value = TRUE)

cat("Found columns:\n")
cat("• UEQ Tendency:", length(ueq_tendency_cols), "\n")
cat("• UEQ Release:", length(ueq_release_cols), "\n")
cat("• UEEQ Tendency:", length(ueeq_tendency_cols), "\n")
cat("• UEEQ Release:", length(ueeq_release_cols), "\n")

# ===== DETERMINE CONDITIONS =====
cat("\n5. DETERMINING PARTICIPANT CONDITIONS...\n")

# Function to determine condition for each participant
determine_condition <- function(participant_data) {
  # Count non-NA responses in UEQ vs UEEQ
  ueq_responses <- sum(!is.na(participant_data[ueq_tendency_cols]))
  ueeq_responses <- sum(!is.na(participant_data[ueeq_tendency_cols]))
  
  if(ueq_responses > ueeq_responses) {
    return("UEQ")
  } else if(ueeq_responses > ueq_responses) {
    return("UEQ+Autonomy")
  } else {
    return(NA)  # Unclear condition
  }
}

# Apply condition determination
participant_conditions <- filtered_data %>%
  rowwise() %>%
  mutate(
    ueq_count = sum(!is.na(c_across(all_of(ueq_tendency_cols)))),
    ueeq_count = sum(!is.na(c_across(all_of(ueeq_tendency_cols)))),
    condition = case_when(
      ueq_count > ueeq_count ~ "UEQ",
      ueeq_count > ueq_count ~ "UEQ+Autonomy",
      TRUE ~ NA_character_
    )
  ) %>%
  ungroup()

# Check condition distribution
condition_summary <- participant_conditions %>%
  count(condition, name = "n_participants")
cat("Condition distribution:\n")
print(condition_summary)

# ===== DETERMINE AI EVALUATION STATUS =====
cat("\n6. DETERMINING AI EVALUATION STATUS...\n")

if("Evaluation Data" %in% names(participant_conditions)) {
  participant_conditions <- participant_conditions %>%
    mutate(
      has_ai_evaluation = grepl("Combined AI-human evaluation", `Evaluation Data`, ignore.case = TRUE, fixed = FALSE)
    )
  
  ai_summary <- participant_conditions %>%
    count(has_ai_evaluation, name = "n_participants")
  cat("AI evaluation distribution:\n")
  print(ai_summary)
} else {
  cat("No 'Evaluation Data' column found. Setting all to FALSE.\n")
  participant_conditions <- participant_conditions %>%
    mutate(has_ai_evaluation = FALSE)
}

# ===== RESHAPE TO LONG FORMAT =====
cat("\n7. RESHAPING DATA TO LONG FORMAT...\n")

# Create interface evaluation data
create_interface_data <- function(participant_data, condition_type) {
  if(condition_type == "UEQ") {
    tendency_cols <- ueq_tendency_cols
    release_cols <- ueq_release_cols
  } else {
    tendency_cols <- ueeq_tendency_cols
    release_cols <- ueeq_release_cols
  }
  
  # Extract interface numbers from column names
  interface_numbers <- as.numeric(gsub("^(\\d+)_.*", "\\1", tendency_cols))
  
  # Create data frame for this participant
  tendency_values <- as.numeric(participant_data[tendency_cols])
  release_values <- participant_data[release_cols]
  
  interface_data <- data.frame(
    ResponseId = participant_data$ResponseId,
    condition = condition_type,
    has_ai_evaluation = participant_data$has_ai_evaluation,
    interface = interface_numbers,
    tendency = tendency_values,
    release = as.character(unlist(release_values)),
    stringsAsFactors = FALSE
  )
  
  # Remove rows with missing data
  interface_data <- interface_data %>%
    filter(!is.na(tendency) & !is.na(release) & release != "") %>%
    mutate(
      rejected = ifelse(release == "No", 1, 0),
      rejection_pct = rejected * 100,
      condition_f = condition_type,
      interface_num = interface
    )
  
  return(interface_data)
}

# Process all participants
all_interface_data <- list()

for(i in 1:nrow(participant_conditions)) {
  participant <- participant_conditions[i, ]
  
  if(!is.na(participant$condition)) {
    interface_data <- create_interface_data(participant, participant$condition)
    if(nrow(interface_data) > 0) {
      all_interface_data[[i]] <- interface_data
    }
  }
}

# Combine all data
final_interface_data <- do.call(rbind, all_interface_data)

cat("Final interface data:\n")
cat("• Total evaluations:", nrow(final_interface_data), "\n")
cat("• Unique participants:", length(unique(final_interface_data$ResponseId)), "\n")
cat("• Average evaluations per participant:", round(nrow(final_interface_data) / length(unique(final_interface_data$ResponseId)), 1), "\n")

# ===== FINAL CONDITION SUMMARY =====
cat("\n8. FINAL CONDITION SUMMARY...\n")

final_summary <- final_interface_data %>%
  distinct(ResponseId, condition_f, has_ai_evaluation) %>%
  count(condition_f, has_ai_evaluation)

print(final_summary)

# ===== SAVE PROCESSED DATA =====
cat("\n9. SAVING PROCESSED DATA...\n")

# Save the new interface data
write.csv(final_interface_data, "results/interface_plot_data_aug16_plus_new_filtered.csv", row.names = FALSE)

# Create participant-level summary
participant_summary <- final_interface_data %>%
  group_by(ResponseId, condition_f, has_ai_evaluation) %>%
  summarise(
    n_evaluations = n(),
    avg_tendency = mean(tendency, na.rm = TRUE),
    rejection_rate = mean(rejected, na.rm = TRUE),
    .groups = "drop"
  )

write.csv(participant_summary, "results/participant_summary_aug16_plus_new_filtered.csv", row.names = FALSE)

cat("\n✓ Data processing complete!\n")
cat("• Interface data: results/interface_plot_data_aug16_plus_new_filtered.csv\n")
cat("• Participant summary: results/participant_summary_aug16_plus_new_filtered.csv\n")
cat("• Final N =", length(unique(final_interface_data$ResponseId)), "participants\n")
cat("• This should give us the full dataset with latest data, minus bad participants\n")
