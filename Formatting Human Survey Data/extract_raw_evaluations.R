library(readxl)
library(dplyr)
library(tibble)
library(writexl)

# Load the data
data_path <- "/Users/hgs52/Library/CloudStorage/GoogleDrive-hgs52@cornell.edu/My Drive/Bright Patterns/Master Doris - Bright Patterns/Auswertung -R/data_social-media-usage_2024-02-22_11-14.xlsx"
MaData <- read_excel(data_path)

# Filter for finished users (same as in main script)
FinishedUser <- filter(MaData, (US01_14 == 1 | US01_14 == 2) & LASTPAGE == 12)
FinishedUser <- FinishedUser[!(FinishedUser$CASE %in% "216"),] # remove test run
User <- filter(FinishedUser, US01_14 == 1)

# Define dark pattern names
dp_names <- c(
  "01" = "Nagging",
  "02" = "Overcomplicated Process", 
  "03" = "Hindering Account Deletion", 
  "04" = "Sneaking Bad Default", 
  "05" = "Expectation Result Mismatch", 
  "06" = "False Hierarchy", 
  "07" = "Trick Wording", 
  "08" = "Toying With Emotion", 
  "09" = "Forced Access", 
  "10" = "Gamification", 
  "11" = "Social Pressure", 
  "12" = "Social Connector", 
  "13" = "Content Customization", 
  "14" = "Endlessness", 
  "15" = "Pull To Refresh"
)

# Define mapping from the survey columns to the correct dimension output
# Format in survey: DP01_01, DP01_02, etc. (in 1-14 range)
# The values we need to map these to (from sample-human-results.txt)
score_positions <- c(
  "inefficient_efficient" = 1,
  "interesting_not_interesting" = 2,
  "clear_confusing" = 3,
  "enjoyable_annoying" = 4,
  "organized_cluttered" = 5,
  "addictive_non-addictive" = 6,
  "supportive_obstructive" = 7,
  "pressuring_suggesting" = 8,
  "boring_exciting" = 9,
  "revealed_covert" = 10,
  "complicated_easy" = 11,
  "unpredictable_predictable" = 12,
  "friendly_unfriendly" = 13,
  "deceptive_benevolent" = 14
)

# Map the pattern evaluation columns to scores
# Based on the format in the sample file (score_pressuring_suggesting, etc.)
dimension_names <- c(
  "inefficient_efficient",
  "interesting_not_interesting",
  "clear_confusing",
  "enjoyable_annoying", 
  "organized_cluttered",
  "addictive_non_addictive",
  "supportive_obstructive", 
  "pressuring_suggesting",
  "boring_exciting",
  "revealed_covert",
  "complicated_easy",
  "unpredictable_predictable",
  "friendly_unfriendly",
  "deceptive_benevolent"
)

# Define which dimensions need score flipping (those that are already flipped in the data)
dimensions_to_flip <- c(
  "unpredictable", 
  "complicated", 
  "pressuring", 
  "inefficient", 
  "addictive", 
  "deceptive", 
  "boring"
)

# Create result dataframe
result_columns <- c(
  "metadata_participant_id",
  "metadata_timestamp",
  "metadata_pattern_type",
  "metadata_interface_id",
  paste0("score_", dimension_names)
)

results <- data.frame(matrix(ncol = length(result_columns), nrow = 0))
colnames(results) <- result_columns

# Generate timestamp for today
timestamp_base <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S")

# For each user
for (user_idx in 1:nrow(User)) {
  case_id <- User$CASE[user_idx]
  participant_id <- paste0("P", sprintf("%03d", user_idx))
  
  # For each pattern
  for (dp_num in 1:15) {
    dp_code <- sprintf("%02d", dp_num)
    pattern_name <- dp_names[as.character(dp_code)]
    interface_id <- paste0("interface_", sprintf("%03d", dp_num))
    
    # Create timestamp with slight offset for each pattern
    timestamp <- gsub("\\d{2}$", sprintf("%02d", (as.integer(substr(timestamp_base, 18, 19)) + dp_num) %% 60), timestamp_base)
    
    # Initialize row
    row_data <- data.frame(matrix(ncol = length(result_columns), nrow = 1))
    colnames(row_data) <- result_columns
    
    # Set metadata fields
    row_data$metadata_participant_id <- participant_id
    row_data$metadata_timestamp <- timestamp
    row_data$metadata_pattern_type <- pattern_name
    row_data$metadata_interface_id <- interface_id
    
    # Get evaluations for this pattern
    valid_evaluation <- TRUE
    
    # For each score dimension
    for (i in 1:length(dimension_names)) {
      dim_name <- dimension_names[i]
      position <- score_positions[dim_name]
      
      # Column name in the survey data
      col_name <- paste0("DP", dp_code, "_", sprintf("%02d", position))
      
      # Skip if column doesn't exist
      if (!col_name %in% colnames(User)) {
        valid_evaluation <- FALSE
        break
      }
      
      # Get the raw value
      value <- User[[col_name]][user_idx]
      
      # Skip if value is NA or -1 (don't know)
      if (is.na(value) || value == -1 || value == " -1") {
        valid_evaluation <- FALSE
        break
      }
      
      # Convert to numeric
      value <- as.numeric(value)
      
      # Determine if we need to flip the score
      dim_base <- strsplit(dim_name, "_")[[1]][1]
      if (dim_base %in% dimensions_to_flip) {
        # Flipping 1-7 scale becomes 7-1
        value <- 8 - value
      }
      
      # Set the value
      score_col <- paste0("score_", dim_name)
      row_data[[score_col]] <- value
    }
    
    # Add row to results if all dimensions had valid data
    if (valid_evaluation) {
      results <- rbind(results, row_data)
    }
  }
}

# Write results to CSV file in the same format as sample-human-results.txt
write.table(results, "raw_participant_evaluations.csv", row.names = FALSE, sep = ",", 
            quote = FALSE, na = "", col.names = TRUE)

# Also write a sample to a text file in exactly the same format
write.table(head(results, 20), "/Users/hgs52/Library/CloudStorage/GoogleDrive-hgs52@cornell.edu/My Drive/Bright Patterns/Master Doris - Bright Patterns/Auswertung -R/participant-evaluations.txt", 
            row.names = FALSE, sep = ",", quote = FALSE, na = "", col.names = TRUE)

# Print a sample of the results
print(head(results, 10))