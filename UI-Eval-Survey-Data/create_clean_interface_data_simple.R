# Simple approach: Use existing interface data and map excluded participants by ResponseId
library(dplyr)

cat("=== CREATING COMPLETE INTERFACE DATA (EXCLUDING SUSPICIOUS PARTICIPANTS) ===\n")

# Load existing interface data (all participants)
interface_data_all <- read.csv("results/interface_plot_data_updated.csv")

cat("Original interface data: N =", nrow(interface_data_all), "evaluations\n")
cat("Original participants: N =", length(unique(interface_data_all$ResponseId)), "\n")

# Load raw data to get PROLIFIC_PID to ResponseId mapping
raw_data <- read.delim("aug17_utf8.tsv", sep = "\t", header = TRUE, 
                       stringsAsFactors = FALSE, encoding = "UTF-8")

# Create mapping of PROLIFIC_PID to ResponseId
prolific_to_response <- raw_data[!is.na(raw_data$PROLIFIC_PID) & raw_data$PROLIFIC_PID != "", 
                                 c("ResponseId", "PROLIFIC_PID")]

# List of suspicious PROLIFIC_PIDs to exclude (from clean_data_exclude_suspicious.R)
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

cat("Suspicious PROLIFIC_PIDs to exclude: N =", length(exclude_prolific_ids), "\n")

# Get ResponseIds for suspicious participants
exclude_response_ids <- prolific_to_response$ResponseId[prolific_to_response$PROLIFIC_PID %in% exclude_prolific_ids]
exclude_response_ids <- exclude_response_ids[!is.na(exclude_response_ids)]

cat("ResponseIds to exclude: N =", length(exclude_response_ids), "\n")
for(rid in exclude_response_ids) {
  cat("• ", rid, "\n")
}

# Filter interface data to exclude suspicious participants
# Keep all participants EXCEPT those with excluded ResponseIds
interface_data_clean <- interface_data_all %>%
  filter(!ResponseId %in% exclude_response_ids)

cat("\n=== RESULTS ===\n")
cat("Clean interface data: N =", nrow(interface_data_clean), "evaluations\n") 
cat("Clean participants: N =", length(unique(interface_data_clean$ResponseId)), "\n")

# Check condition distribution
condition_dist <- table(interface_data_clean$condition)
cat("\nCondition distribution:\n")
print(condition_dist)

# Check participants per interface
participants_per_interface <- interface_data_clean %>%
  group_by(interface_num) %>%
  summarise(n_participants = n(), .groups = "drop")

cat("\nParticipants per interface:\n")
print(participants_per_interface)

# Save clean interface data
write.csv(interface_data_clean, "results/interface_plot_data_cleaned.csv", row.names = FALSE)

cat("\n✓ Clean interface data saved to: results/interface_plot_data_cleaned.csv\n")
cat("Total participants should be close to 83 (some may not have interface data)\n")
