# Complete Data Processing Pipeline for August 17 Data
# Properly handling all participants and checking data quality

library(dplyr)
library(readr)
library(tidyr)

cat("=== COMPLETE DATA PROCESSING PIPELINE ===\n")
cat("Processing August 17, 2025 data with proper validation\n\n")

# ===== LOAD AND CLEAN RAW DATA =====
cat("1. LOADING RAW DATA...\n")

# Load the latest data
raw_data <- read_tsv("aug17_utf8.tsv", show_col_types = FALSE)

cat("Raw data loaded:\n")
cat("• Total rows:", nrow(raw_data), "\n")
cat("• Total columns:", ncol(raw_data), "\n")

# Remove header rows and metadata
# First row is column names, second is import ID info, third might be description
cat("\n2. CLEANING DATA STRUCTURE...\n")

# Check for header rows
cat("First few ResponseIds:\n")
print(head(raw_data$ResponseId, 10))

# Remove non-data rows (header descriptions, import IDs, etc.)
clean_data <- raw_data %>%
  filter(
    !is.na(ResponseId),
    !grepl("Response ID|ImportId|Understanding How User", ResponseId, ignore.case = TRUE),
    !ResponseId %in% c("Response ID", "{\"ImportId\":\"_recordId\"}")
  )

cat("After cleaning:\n")
cat("• Valid participant rows:", nrow(clean_data), "\n")
cat("• Unique ResponseIds:", length(unique(clean_data$ResponseId)), "\n")

# ===== UNDERSTAND DATA STRUCTURE =====
cat("\n3. ANALYZING DATA STRUCTURE...\n")

# Find UEQ and UEEQ columns
ueq_tendency_cols <- grep("_UEQ Tendency", names(clean_data), value = TRUE)
ueq_release_cols <- grep("_UEQ Release", names(clean_data), value = TRUE)
ueeq_tendency_cols <- grep("_UEEQ Tendency", names(clean_data), value = TRUE)
ueeq_release_cols <- grep("_UEEQ Release", names(clean_data), value = TRUE)

cat("Found columns:\n")
cat("• UEQ Tendency:", length(ueq_tendency_cols), "\n")
cat("• UEQ Release:", length(ueq_release_cols), "\n")
cat("• UEEQ Tendency:", length(ueeq_tendency_cols), "\n")
cat("• UEEQ Release:", length(ueeq_release_cols), "\n")

# Show example column names
cat("\nExample UEQ columns:", head(ueq_tendency_cols, 3), "\n")
cat("Example UEEQ columns:", head(ueeq_tendency_cols, 3), "\n")

# ===== DETERMINE CONDITIONS =====
cat("\n4. DETERMINING PARTICIPANT CONDITIONS...\n")

# Function to determine condition for each participant
determine_condition <- function(participant_data) {
  # Count non-NA responses in UEQ vs UEEQ
  ueq_responses <- sum(!is.na(participant_data[ueq_tendency_cols]))
  ueeq_responses <- sum(!is.na(participant_data[ueeq_tendency_cols]))
  
  if(ueq_responses > ueeq_responses) {
    return("UEQ")
  } else if(ueeq_responses > ueq_responses) {
    return("UEQ+Autonomy")  # Changed from UEEQ
  } else {
    return(NA)  # Unclear condition
  }
}

# Apply condition determination
participant_conditions <- clean_data %>%
  rowwise() %>%
  mutate(
    condition = determine_condition(cur_data()),
    ueq_count = sum(!is.na(c_across(all_of(ueq_tendency_cols)))),
    ueeq_count = sum(!is.na(c_across(all_of(ueeq_tendency_cols))))
  ) %>%
  ungroup()

# Check condition distribution
condition_summary <- participant_conditions %>%
  count(condition, name = "n_participants")
cat("Condition distribution:\n")
print(condition_summary)

# Check data quality
unclear_conditions <- sum(is.na(participant_conditions$condition))
cat("Participants with unclear conditions:", unclear_conditions, "\n")

# ===== DETERMINE AI EVALUATION STATUS =====
cat("\n5. DETERMINING AI EVALUATION STATUS...\n")

# Check AI evaluation assignment
if("Evaluation Data" %in% names(participant_conditions)) {
  # Participants who selected "Combined AI-human evaluation" have AI data
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
cat("\n6. RESHAPING DATA TO LONG FORMAT...\n")

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
  interface_data <- data.frame(
    ResponseId = participant_data$ResponseId,
    condition = condition_type,
    has_ai_evaluation = participant_data$has_ai_evaluation,
    interface = interface_numbers,
    tendency = as.numeric(participant_data[tendency_cols]),
    release = participant_data[release_cols],
    stringsAsFactors = FALSE
  )
  
  # Remove rows with missing data
  interface_data <- interface_data %>%
    filter(!is.na(tendency) & !is.na(release)) %>%
    mutate(
      rejected = ifelse(release == "No", 1, 0),
      rejection_pct = rejected * 100,
      condition_f = condition,
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
cat("\n7. FINAL CONDITION SUMMARY...\n")

final_summary <- final_interface_data %>%
  distinct(ResponseId, condition_f, has_ai_evaluation) %>%
  count(condition_f, has_ai_evaluation)

print(final_summary)

# ===== SAVE PROCESSED DATA =====
cat("\n8. SAVING PROCESSED DATA...\n")

# Save the new interface data
write.csv(final_interface_data, "results/interface_plot_data_aug17.csv", row.names = FALSE)

# Create participant-level summary
participant_summary <- final_interface_data %>%
  group_by(ResponseId, condition_f, has_ai_evaluation) %>%
  summarise(
    n_evaluations = n(),
    mean_tendency = mean(tendency, na.rm = TRUE),
    mean_rejection_pct = mean(rejection_pct, na.rm = TRUE),
    .groups = 'drop'
  )

write.csv(participant_summary, "results/participant_summary_aug17.csv", row.names = FALSE)

cat("Files saved:\n")
cat("• results/interface_plot_data_aug17.csv - Interface-level data\n")
cat("• results/participant_summary_aug17.csv - Participant-level summary\n")

# ===== DATA QUALITY REPORT =====
cat("\n=== DATA QUALITY REPORT ===\n")

cat("PARTICIPANTS:\n")
cat("• Total in raw file:", nrow(raw_data), "\n")
cat("• Valid participants:", nrow(participant_conditions), "\n")
cat("• With clear conditions:", sum(!is.na(participant_conditions$condition)), "\n")
cat("• In final analysis:", length(unique(final_interface_data$ResponseId)), "\n")

cat("\nINTERFACE EVALUATIONS:\n")
cat("• Total evaluations:", nrow(final_interface_data), "\n")
cat("• Expected (participants × 10):", length(unique(final_interface_data$ResponseId)) * 10, "\n")
cat("• Coverage:", round(nrow(final_interface_data) / (length(unique(final_interface_data$ResponseId)) * 10) * 100, 1), "%\n")

cat("\nCONDITION BALANCE:\n")
print(final_summary)

cat("\n=== PROCESSING COMPLETE ===\n")
cat("Ready for statistical analysis with Aug 17 data!\n")
