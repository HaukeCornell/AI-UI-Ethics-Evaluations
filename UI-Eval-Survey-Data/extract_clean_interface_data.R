# Extract Interface Data for Clean Participants Only
# Use the clean participant list to ensure we get the right 83 participants

library(dplyr)
library(tidyr)

cat("=== EXTRACTING INTERFACE DATA FOR CLEAN PARTICIPANTS ===\n")

# Load clean participants (these are the correct 83 after exclusions)
clean_participants <- read.csv("results/clean_data_for_analysis.csv")

cat("Clean participants loaded: N =", nrow(clean_participants), "\n")
cat("UEQ condition:", sum(clean_participants$condition == "UEQ"), "\n")
cat("UEQ+Autonomy condition:", sum(clean_participants$condition == "UEQ+Autonomy"), "\n\n")

# Load raw data
raw_data <- read.delim("aug17_utf8.tsv", sep = "\t", header = TRUE, 
                       stringsAsFactors = FALSE, encoding = "UTF-8")

# Create ResponseId to PROLIFIC_PID mapping
response_mapping <- raw_data %>%
  filter(!is.na(PROLIFIC_PID), PROLIFIC_PID != "") %>%
  select(ResponseId, PROLIFIC_PID)

# Also include participants without PROLIFIC_PID (different reimbursement)
# Map by using other available data
additional_mapping <- raw_data %>%
  filter(is.na(PROLIFIC_PID) | PROLIFIC_PID == "") %>%
  filter(Progress == 100) %>%
  select(ResponseId)

# For clean participants, get their ResponseIds
clean_response_ids <- c()

# First get those with PROLIFIC_PID
for(pid in clean_participants$PROLIFIC_PID) {
  rid <- response_mapping$ResponseId[response_mapping$PROLIFIC_PID == pid][1]
  if(!is.na(rid)) {
    clean_response_ids <- c(clean_response_ids, rid)
  }
}

cat("Clean participants with ResponseIds found:", length(clean_response_ids), "\n")

# Now use the existing interface data and filter to these ResponseIds
existing_interface_data <- read.csv("results/interface_plot_data_updated.csv")

cat("Existing interface data: N =", nrow(existing_interface_data), "evaluations\n")
cat("Unique participants in existing interface data:", length(unique(existing_interface_data$ResponseId)), "\n")

# Filter existing interface data to clean participants
clean_interface_data <- existing_interface_data %>%
  filter(ResponseId %in% clean_response_ids)

cat("\n=== FILTERED INTERFACE DATA ===\n")
cat("Interface evaluations for clean participants:", nrow(clean_interface_data), "\n")
cat("Unique clean participants with interface data:", length(unique(clean_interface_data$ResponseId)), "\n")

# Check condition distribution
condition_dist <- table(clean_interface_data$condition)
cat("Condition distribution:\n")
print(condition_dist)

# The discrepancy explanation:
missing_participants <- length(clean_response_ids) - length(unique(clean_interface_data$ResponseId))
cat("\nDISCREPANCY EXPLANATION:\n")
cat("Clean participants total:", nrow(clean_participants), "\n")
cat("Clean participants with ResponseIds:", length(clean_response_ids), "\n") 
cat("Clean participants with interface data:", length(unique(clean_interface_data$ResponseId)), "\n")
cat("Missing from interface data:", missing_participants, "\n")

if(missing_participants > 20) {
  cat("\n⚠️  LARGE DISCREPANCY DETECTED\n")
  cat("Possible causes:\n")
  cat("1. Interface data was created from older dataset\n")
  cat("2. Some participants didn't complete interface evaluations\n")
  cat("3. Data processing excluded participants for other reasons\n")
  
  # Check if missing participants are in raw data
  missing_response_ids <- setdiff(clean_response_ids, unique(clean_interface_data$ResponseId))
  cat("Missing ResponseIds sample:", head(missing_response_ids, 3), "\n")
  
} else {
  cat("\n✅ Discrepancy is reasonable (some participants may not have completed interface evaluations)\n")
}

# Save the filtered clean interface data
write.csv(clean_interface_data, "results/interface_plot_data_clean_filtered.csv", row.names = FALSE)

cat("\n✓ Clean interface data saved: results/interface_plot_data_clean_filtered.csv\n")
cat("This file contains interface data for participants after AI/suspicious exclusions\n")
