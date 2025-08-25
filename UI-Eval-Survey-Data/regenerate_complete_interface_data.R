# Regenerate Complete Interface Data from Full Aug17 Dataset
# This creates interface data for ALL 104 participants, then applies exclusions

library(dplyr)
library(tidyr)

cat("=== REGENERATING COMPLETE INTERFACE DATA FROM AUG17 DATASET ===\n")
cat("Problem: Previous interface data was from older, incomplete dataset\n")
cat("Solution: Extract interface data from full aug17_utf8.tsv (104 participants)\n\n")

# Load the full August 17 dataset
data <- read.delim("aug17_utf8.tsv", sep = "\t", header = TRUE, 
                   stringsAsFactors = FALSE, encoding = "UTF-8")

cat("Full raw data loaded:", nrow(data), "rows\n")

# Filter to completed responses and identify condition
analysis_data <- data %>%
  filter(Progress == 100) %>%
  mutate(
    condition = case_when(
      !is.na(`1_UEQ Tendency_1`) ~ "UEQ",
      !is.na(`1_UEEQ Tendency_1`) ~ "UEQ+Autonomy",
      TRUE ~ "Unknown"
    )
  ) %>%
  filter(condition %in% c("UEQ", "UEQ+Autonomy"))

cat("Completed responses with valid conditions:", nrow(analysis_data), "\n")
cat("UEQ condition:", sum(analysis_data$condition == "UEQ"), "\n")
cat("UEQ+Autonomy condition:", sum(analysis_data$condition == "UEQ+Autonomy"), "\n\n")

# Extract UEQ interfaces (1-15)
cat("Extracting UEQ interface data...\n")
ueq_interfaces <- analysis_data %>%
  filter(condition == "UEQ") %>%
  select(ResponseId, condition,
         matches("^\\d+_UEQ (Tendency_1|Release)$")) %>%
  pivot_longer(cols = matches("^\\d+_UEQ"), 
               names_to = "variable", values_to = "value") %>%
  filter(!is.na(value), value != "") %>%
  extract(variable, c("interface", "measure"), "(\\d+)_UEQ (Tendency_1|Release)") %>%
  pivot_wider(names_from = measure, values_from = value) %>%
  rename(tendency = `Tendency_1`, release = Release) %>%
  mutate(
    tendency = as.numeric(tendency),
    rejected = case_when(
      release == "No" ~ 1,
      release == "Yes" ~ 0,
      TRUE ~ NA_real_
    )
  ) %>%
  filter(!is.na(tendency), !is.na(rejected))

cat("UEQ interfaces extracted:", nrow(ueq_interfaces), "evaluations\n")

# Extract UEQ+Autonomy interfaces (1-15)  
cat("Extracting UEQ+Autonomy interface data...\n")
ueeq_interfaces <- analysis_data %>%
  filter(condition == "UEQ+Autonomy") %>%
  select(ResponseId, condition,
         matches("^\\d+_UEEQ (Tendency_1|Release)$")) %>%
  pivot_longer(cols = matches("^\\d+_UEEQ"), 
               names_to = "variable", values_to = "value") %>%
  filter(!is.na(value), value != "") %>%
  extract(variable, c("interface", "measure"), "(\\d+)_UEEQ (Tendency_1|Release)") %>%
  pivot_wider(names_from = measure, values_from = value) %>%
  rename(tendency = `Tendency_1`, release = Release) %>%
  mutate(
    tendency = as.numeric(tendency),
    rejected = case_when(
      release == "No" ~ 1,
      release == "Yes" ~ 0,
      TRUE ~ NA_real_
    )
  ) %>%
  filter(!is.na(tendency), !is.na(rejected))

cat("UEQ+Autonomy interfaces extracted:", nrow(ueeq_interfaces), "evaluations\n")

# Combine all interface data
all_interfaces <- bind_rows(ueq_interfaces, ueeq_interfaces)

cat("\n=== COMPLETE INTERFACE DATA SUMMARY ===\n")
cat("Total interface evaluations:", nrow(all_interfaces), "\n")
cat("Unique participants:", length(unique(all_interfaces$ResponseId)), "\n")

# Check condition distribution
condition_dist <- table(all_interfaces$condition)
cat("Condition distribution:\n")
print(condition_dist)

# Check participants per interface
interfaces_per_participant <- all_interfaces %>%
  group_by(ResponseId) %>%
  summarise(n_interfaces = n(), .groups = "drop")

cat("\nInterfaces per participant summary:\n")
print(summary(interfaces_per_participant$n_interfaces))

# Prepare final interface data for analysis
interface_plot_data_complete <- all_interfaces %>%
  mutate(
    condition_f = factor(condition, levels = c("UEQ", "UEQ+Autonomy")),
    interface_num = as.numeric(interface),
    rejection_pct = rejected * 100
  )

# Save complete interface data
write.csv(interface_plot_data_complete, "results/interface_plot_data_complete.csv", row.names = FALSE)

cat("\n✓ Complete interface data saved to: results/interface_plot_data_complete.csv\n")

# Now apply exclusions to create clean version
cat("\n=== APPLYING EXCLUSIONS TO CREATE CLEAN VERSION ===\n")

# Load PROLIFIC_PID mapping
prolific_mapping <- data %>%
  filter(!is.na(PROLIFIC_PID), PROLIFIC_PID != "") %>%
  select(ResponseId, PROLIFIC_PID)

# List of suspicious PROLIFIC_PIDs to exclude
exclude_prolific_ids <- c(
  "67d2ba7e8fadacc3db804a1b",
  "677cea851b45fb93eab1cf15", 
  "673594215b1a0b92d5835525",
  "67dc387f88088fd4aca51d89",
  "65583ffa38bfc41805a553cd",
  "67d299d6194fca1b65760b11",
  "667f0276a34ff38c12fda451",
  "6743278eba3a6dfeeeb53b00",
  "67c712364ec9ad3f92b3a339",
  "6728a33bf6aa750798eb8088"
)

# Get ResponseIds to exclude
exclude_response_ids <- prolific_mapping$ResponseId[prolific_mapping$PROLIFIC_PID %in% exclude_prolific_ids]
exclude_response_ids <- exclude_response_ids[!is.na(exclude_response_ids)]

cat("Suspicious ResponseIds to exclude: N =", length(exclude_response_ids), "\n")

# Create clean interface data
interface_plot_data_clean <- interface_plot_data_complete %>%
  filter(!ResponseId %in% exclude_response_ids)

cat("Clean interface data:\n")
cat("• Total evaluations:", nrow(interface_plot_data_clean), "\n")
cat("• Unique participants:", length(unique(interface_plot_data_clean$ResponseId)), "\n")

clean_condition_dist <- table(interface_plot_data_clean$condition)
cat("• Condition distribution:\n")
print(clean_condition_dist)

# Save clean interface data
write.csv(interface_plot_data_clean, "results/interface_plot_data_cleaned_complete.csv", row.names = FALSE)

cat("\n✓ Clean interface data saved to: results/interface_plot_data_cleaned_complete.csv\n")

cat("\n=== COMPARISON WITH EXPECTED NUMBERS ===\n")
cat("Expected total participants: 104 (from aug17_utf8.tsv)\n")
cat("Expected after exclusions: 94 (104 - 10 suspicious)\n")
cat("Expected clean with interface data: ~80-85 (some may not have completed interfaces)\n")
cat("Actual clean with interface data:", length(unique(interface_plot_data_clean$ResponseId)), "\n")

if(length(unique(interface_plot_data_clean$ResponseId)) < 75) {
  cat("\n⚠️  Still low participant count. May need to check for other filtering issues.\n")
} else {
  cat("\n✅ Participant count looks reasonable!\n")
}

cat("\n=== INTERFACE DATA REGENERATION COMPLETE ===\n")
