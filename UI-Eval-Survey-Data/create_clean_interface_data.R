# Create Clean Interface Data by Filtering to Exclude AI/Suspicious Participants
# This script filters existing interface data to exclude the 10 flagged participants

# Load required packages
library(dplyr)

cat("=== CREATING CLEAN INTERFACE DATA ===\n")

# Load the list of suspicious participants to exclude
suspicious_participants <- c(
  "6570b325bfd2b4ecfb2e0b9e", "5c99ab1dc2ed5b0001b92cf7", "659bc30e8d20b8ba62a02b8c",
  "63eac92eeef77b3cc47b78b2", "60c8e52c10ecae1b2c00bb96", "63e44c13b00e8d6b50c86a2f",
  "64b0ae7e37a88f2b652d7c04", "660cbf1b3e6b7c8c80b4c90c", "5f7b0d8f2cd3e7001a56c42e",
  "66e8a237eb5cdefe9de8547a"
)

cat("Suspicious participants to exclude (N =", length(suspicious_participants), "):\n")
for(pid in suspicious_participants) {
  cat("•", pid, "\n")
}

# Load existing interface data
interface_data_all <- read.csv("results/interface_plot_data_updated.csv")

cat("\nOriginal interface data loaded with", nrow(interface_data_all), "interface evaluations\n")
cat("Original unique participants:", length(unique(interface_data_all$ResponseId)), "\n")

# Filter out suspicious participants - we need to map ResponseId to PROLIFIC_PID
# Load clean participant data to get the mapping
clean_data <- read.csv("results/clean_data_for_analysis.csv")

cat("Clean participants (N =", nrow(clean_data), "):\n")
cat("UEQ condition:", sum(clean_data$condition == "UEQ"), "participants\n")
cat("UEQ+Autonomy condition:", sum(clean_data$condition == "UEQ+Autonomy"), "participants\n\n")

# Get ResponseIds for clean participants by matching with raw data
raw_data <- read.delim("aug17_utf8.tsv", sep = "\t", header = TRUE, 
                       stringsAsFactors = FALSE, encoding = "UTF-8")

# Create mapping of PROLIFIC_PID to ResponseId for clean participants
clean_response_ids <- c()
for(pid in clean_data$PROLIFIC_PID) {
  response_id <- raw_data$ResponseId[raw_data$PROLIFIC_PID == pid][1]
  if(!is.na(response_id)) {
    clean_response_ids <- c(clean_response_ids, response_id)
  }
}

cat("Clean ResponseIds found:", length(clean_response_ids), "\n")

# Filter interface data to only include clean participants
interface_data <- interface_data_all %>%
  filter(ResponseId %in% clean_response_ids)

cat("✓ Filtered interface data to", nrow(interface_data), "interface evaluations\n")
cat("✓ Clean participants in interface data:", length(unique(interface_data$ResponseId)), "\n")

# Verify data integrity
cat("\n=== DATA INTEGRITY CHECK ===\n")
cat("Condition distribution:\n")
print(table(interface_data$condition))

cat("\nInterface coverage per participant:\n")
interfaces_per_participant <- interface_data %>%
  group_by(ResponseId) %>%
  summarise(n_interfaces = n(), .groups = "drop")

print(summary(interfaces_per_participant$n_interfaces))

cat("\nParticipants per interface:\n")
participants_per_interface <- interface_data %>%
  group_by(interface_num) %>%
  summarise(n_participants = n(), .groups = "drop")

print(participants_per_interface)

# Save the clean interface data
write.csv(interface_data, "results/interface_plot_data_cleaned.csv", row.names = FALSE)

cat("\n✓ Clean interface data saved to: results/interface_plot_data_cleaned.csv\n")
cat("Ready for individual interface analysis!\n")
