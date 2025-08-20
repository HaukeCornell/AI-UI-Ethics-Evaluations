# Quick Data Processing Fix for August 17 Data
# Simplified approach to get the analysis running

library(dplyr)
library(readr)
library(tidyr)

cat("=== QUICK DATA PROCESSING FOR AUG 17 ===\n")

# Load data and clean
raw_data <- read_tsv("aug17_utf8.tsv", show_col_types = FALSE)

clean_data <- raw_data %>%
  filter(
    !is.na(ResponseId),
    !grepl("Response ID|ImportId|Understanding How User", ResponseId, ignore.case = TRUE),
    !ResponseId %in% c("Response ID", "{\"ImportId\":\"_recordId\"}")
  )

cat("Valid participants:", nrow(clean_data), "\n")

# Find columns correctly
ueq_tendency_cols <- names(clean_data)[grepl("^\\d+_UEQ Tendency", names(clean_data))]
ueq_release_cols <- names(clean_data)[grepl("^\\d+_UEQ Release$", names(clean_data))]
ueeq_tendency_cols <- names(clean_data)[grepl("^\\d+_UEEQ Tendency", names(clean_data))]
ueeq_release_cols <- names(clean_data)[grepl("^\\d+_UEEQ Release$", names(clean_data))]

cat("UEQ tendency cols:", length(ueq_tendency_cols), "\n")
cat("UEQ release cols:", length(ueq_release_cols), "\n")
cat("UEEQ tendency cols:", length(ueeq_tendency_cols), "\n")
cat("UEEQ release cols:", length(ueeq_release_cols), "\n")

# Determine conditions
participant_conditions <- clean_data %>%
  rowwise() %>%
  mutate(
    ueq_count = sum(!is.na(c_across(all_of(ueq_tendency_cols)))),
    ueeq_count = sum(!is.na(c_across(all_of(ueeq_tendency_cols)))),
    condition = case_when(
      ueq_count > ueeq_count ~ "UEQ",
      ueeq_count > ueq_count ~ "UEQ+Autonomy",
      TRUE ~ NA_character_
    ),
    has_ai_evaluation = ifelse(
      !is.na(`Evaluation Data`) & grepl("Combined AI-human evaluation", `Evaluation Data`, ignore.case = TRUE),
      TRUE, FALSE
    )
  ) %>%
  ungroup()

condition_summary <- participant_conditions %>%
  filter(!is.na(condition)) %>%
  count(condition, has_ai_evaluation)

print(condition_summary)

# Create interface data the simple way
all_interface_data <- data.frame()

for(i in 1:nrow(participant_conditions)) {
  participant <- participant_conditions[i, ]
  
  if(is.na(participant$condition)) next
  
  if(participant$condition == "UEQ") {
    tendency_cols <- ueq_tendency_cols
    release_cols <- ueq_release_cols
  } else {
    tendency_cols <- ueeq_tendency_cols
    release_cols <- ueeq_release_cols
  }
  
  # Extract interface data for this participant
  for(j in 1:length(tendency_cols)) {
    interface_num <- as.numeric(gsub("^(\\d+)_.*", "\\1", tendency_cols[j]))
    tendency_val <- as.numeric(participant[[tendency_cols[j]]])
    release_val <- participant[[release_cols[j]]]
    
    if(!is.na(tendency_val) && !is.na(release_val)) {
      new_row <- data.frame(
        ResponseId = participant$ResponseId,
        condition = participant$condition,
        has_ai_evaluation = participant$has_ai_evaluation,
        interface = interface_num,
        tendency = tendency_val,
        release = release_val,
        rejected = ifelse(release_val == "No", 1, 0),
        condition_f = participant$condition,
        interface_num = interface_num,
        rejection_pct = ifelse(release_val == "No", 100, 0)
      )
      all_interface_data <- rbind(all_interface_data, new_row)
    }
  }
}

cat("\nFinal data:\n")
cat("• Total evaluations:", nrow(all_interface_data), "\n")
cat("• Unique participants:", length(unique(all_interface_data$ResponseId)), "\n")

final_summary <- all_interface_data %>%
  distinct(ResponseId, condition_f, has_ai_evaluation) %>%
  count(condition_f, has_ai_evaluation)

print(final_summary)

# Save data
write.csv(all_interface_data, "results/interface_plot_data_aug17_final.csv", row.names = FALSE)

cat("Data saved to: results/interface_plot_data_aug17_final.csv\n")
cat("Ready for analysis!\n")
