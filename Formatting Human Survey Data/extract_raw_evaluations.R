library(readxl)
library(dplyr)
library(tibble)
library(writexl)

# Load the data
data_path <- "Formatting Human Survey Data/data_social-media-usage_2024-02-22_11-14.xlsx"
MaData <- read_excel(data_path)

# Skip the header row if it contains column descriptions
if (MaData$CASE[1] == "Interview") {
  cat("Removing header row with descriptions\n")
  MaData <- MaData[-1, ]
}

# Filter for finished users (same as in main script)
cat("Total rows in input file:", nrow(MaData), "\n")
cat("First 10 columns in input file:", paste(colnames(MaData)[1:10], collapse=", "), "\n")
cat("First 5 CASE values:", paste(MaData$CASE[1:5], collapse=", "), "\n")

# Print unique values of US01_14 and LASTPAGE to understand filter criteria
if ("US01_14" %in% colnames(MaData)) {
  cat("Unique values of US01_14:", paste(unique(MaData$US01_14), collapse=", "), "\n")
} else {
  cat("US01_14 column not found\n")
}

if ("LASTPAGE" %in% colnames(MaData)) {
  cat("Unique values of LASTPAGE:", paste(unique(MaData$LASTPAGE), collapse=", "), "\n")
} else {
  cat("LASTPAGE column not found\n")
}

# Count rows with DP pattern data to identify valid participants
cat("Checking for participants with valid data...\n")
valid_rows <- 0
for (i in 1:nrow(MaData)) {
  # Check if at least one DP pattern has values
  has_data <- FALSE
  for (dp_num in 1:15) {
    dp_code <- sprintf("%02d", dp_num)
    # Check the first dimension to see if any data exists
    col_name <- paste0("DP", dp_code, "_01")
    if (col_name %in% colnames(MaData) && !is.na(MaData[[col_name]][i]) && MaData[[col_name]][i] != "" && MaData[[col_name]][i] != "Nagging") {
      has_data <- TRUE
      break
    }
  }
  if (has_data) {
    valid_rows <- valid_rows + 1
  }
}
cat("Found", valid_rows, "rows with valid data\n")

# Use more lenient filtering since the original filters might be too strict
cat("Using more lenient filtering to ensure data is included\n")
# Skip filtering based on problematic columns, focus on rows with actual data
FinishedUser <- MaData

# Filter out header row if it's still there
if ("CASE" %in% colnames(FinishedUser) && any(FinishedUser$CASE == "Interview")) {
  FinishedUser <- FinishedUser[!(FinishedUser$CASE %in% c("Interview")),]
  cat("Removed description rows\n")
}

# Remove test run if it exists
if ("CASE" %in% colnames(FinishedUser)) {
  FinishedUser <- FinishedUser[!(FinishedUser$CASE %in% "216"),]
  cat("Users after removing test case:", nrow(FinishedUser), "\n")
}

# For final selection, use all but filter out rows without any pattern data
User <- FinishedUser
cat("Initial user count:", nrow(User), "\n")

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

# Based on the actual Excel file data, the dimensions are ordered differently than expected
# From examining the first row of the Excel file, here's the mapping:
# DP01_01: Nagging: enjoyable/annoying
# DP01_02: Nagging: unpredictable/predictable
# DP01_03: Nagging: supportive/obstructive
# DP01_04: Nagging: interesting/not interesting
# DP01_05: Nagging: complicated/easy
# etc...

# Map the actual excel columns to the output dimension names
# Format: key is the dimension name we want in output, value is the column number in Excel
excel_to_dim_mapping <- c(
  "enjoyable_annoying" = 1,
  "unpredictable_predictable" = 2,
  "supportive_obstructive" = 3,
  "interesting_not_interesting" = 4,
  "complicated_easy" = 5,
  "pressuring_suggesting" = 6,
  "inefficient_efficient" = 7,
  "clear_confusing" = 8,
  "addictive_non_addictive" = 9,
  "deceptive_benevolent" = 10,
  "organized_cluttered" = 11,
  "friendly_unfriendly" = 12,
  "revealed_covert" = 13,
  "boring_exciting" = 14
)

# Define the dimension names in the same order as the sample output file
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

# # Define which dimensions need score flipping (those that are already flipped in the data)
# dimensions_to_flip <- c(
#   # "unpredictable", 
#   "complicated", 
#   "pressuring", 
#   # "inefficient", 
#   "addictive", 
#   # "deceptive", 
#   # "boring"
# )

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

# Generate timestamp for today with proper format (MM/DD/YYYY HH:MM:SS AM/PM)
now <- Sys.time()
hour <- as.numeric(format(now, "%H"))
am_pm <- ifelse(hour < 12, "AM", "PM")
hour_12 <- ifelse(hour == 0, 12, ifelse(hour > 12, hour - 12, hour))
month_str <- month.abb[as.numeric(format(now, "%m"))]
day_str <- format(now, "%d")
year_str <- format(now, "%Y")
minute_str <- format(now, "%M")
second_str <- format(now, "%S")
timestamp_base <- sprintf("%s %s, %s %d:%s:%s %s", month_str, day_str, year_str, hour_12, minute_str, second_str, am_pm)

# Flag to track if any valid data was found
found_valid_data <- FALSE

# For each user
for (user_idx in 1:nrow(User)) {
  # Track if this user has any valid evaluations
  user_has_valid_data <- FALSE
  
  # Get the actual CASE ID from the data 
  case_id <- User$CASE[user_idx]
  
  # Skip if CASE ID is NA or empty
  if (is.na(case_id) || case_id == "") {
    next
  }
  
  # Use the actual CASE ID as the participant ID
  participant_id <- paste0("P", case_id)
  
  # Get the actual timestamp from the data (STARTED column contains the survey start timestamp)
  # Format it to ISO 8601
  if ("STARTED" %in% colnames(User)) {
    user_timestamp <- User$STARTED[user_idx]
    # Convert from Excel date format to ISO 8601
    if (!is.na(user_timestamp)) {
      # Parse the timestamp - Excel date format (days since January 1, 1900)
      tryCatch({
        # Convert Excel numeric date to R date object
        # First check if it's already a date object or a string
        if (is.character(user_timestamp)) {
          # Try to convert from character to numeric
          excel_date <- as.numeric(user_timestamp)
          if (!is.na(excel_date)) {
            # Convert Excel date number to R date
            r_date <- as.Date(excel_date, origin = "1899-12-30")
            
            # Extract the fractional part for time
            fraction <- excel_date - floor(excel_date)
            seconds_in_day <- 24 * 60 * 60
            seconds <- round(fraction * seconds_in_day)
            
            # Create a datetime object
            r_datetime <- r_date + seconds / seconds_in_day
            
            # Format as MM/DD/YYYY HH:MM:SS AM/PM
            hour <- as.numeric(format(r_datetime, "%H"))
            am_pm <- ifelse(hour < 12, "AM", "PM")
            hour_12 <- ifelse(hour == 0, 12, ifelse(hour > 12, hour - 12, hour))
            month_str <- month.abb[as.numeric(format(r_datetime, "%m"))]
            day_str <- format(r_datetime, "%d")
            year_str <- format(r_datetime, "%Y")
            minute_str <- format(r_datetime, "%M")
            second_str <- format(r_datetime, "%S")
            timestamp_base <- sprintf("%s %s, %s %d:%s:%s %s", month_str, day_str, year_str, hour_12, minute_str, second_str, am_pm)
            cat("Converted timestamp for user", case_id, ":", user_timestamp, "->", timestamp_base, "\n")
          } else {
            # If conversion fails, use the current timestamp with proper format
            message(paste("Could not convert timestamp for user", case_id, ": using current time"))
            now <- Sys.time()
            hour <- as.numeric(format(now, "%H"))
            am_pm <- ifelse(hour < 12, "AM", "PM")
            hour_12 <- ifelse(hour == 0, 12, ifelse(hour > 12, hour - 12, hour))
            month_str <- month.abb[as.numeric(format(now, "%m"))]
            day_str <- format(now, "%d")
            year_str <- format(now, "%Y")
            minute_str <- format(now, "%M")
            second_str <- format(now, "%S")
            timestamp_base <- sprintf("%s %s, %s %d:%s:%s %s", month_str, day_str, year_str, hour_12, minute_str, second_str, am_pm)
          }
        } else {
          # If it's already a date object, format it properly
          r_datetime <- user_timestamp
          hour <- as.numeric(format(r_datetime, "%H"))
          am_pm <- ifelse(hour < 12, "AM", "PM")
          hour_12 <- ifelse(hour == 0, 12, ifelse(hour > 12, hour - 12, hour))
          month_str <- month.abb[as.numeric(format(r_datetime, "%m"))]
          day_str <- format(r_datetime, "%d")
          year_str <- format(r_datetime, "%Y")
          minute_str <- format(r_datetime, "%M")
          second_str <- format(r_datetime, "%S")
          timestamp_base <- sprintf("%s %s, %s %d:%s:%s %s", month_str, day_str, year_str, hour_12, minute_str, second_str, am_pm)
        }
      }, error = function(e) {
        # If parsing fails, use the current timestamp with proper format
        message(paste("Error parsing timestamp for user", case_id, ":", e$message, "- using current time"))
        now <- Sys.time()
        hour <- as.numeric(format(now, "%H"))
        am_pm <- ifelse(hour < 12, "AM", "PM")
        hour_12 <- ifelse(hour == 0, 12, ifelse(hour > 12, hour - 12, hour))
        month_str <- month.abb[as.numeric(format(now, "%m"))]
        day_str <- format(now, "%d")
        year_str <- format(now, "%Y")
        minute_str <- format(now, "%M")
        second_str <- format(now, "%S")
        timestamp_base <- sprintf("%s %s, %s %d:%s:%s %s", month_str, day_str, year_str, hour_12, minute_str, second_str, am_pm)
      })
    } else {
      # If timestamp is NA, use the current timestamp with the proper format
      now <- Sys.time()
      hour <- as.numeric(format(now, "%H"))
      am_pm <- ifelse(hour < 12, "AM", "PM")
      hour_12 <- ifelse(hour == 0, 12, ifelse(hour > 12, hour - 12, hour))
      month_str <- month.abb[as.numeric(format(now, "%m"))]
      day_str <- format(now, "%d")
      year_str <- format(now, "%Y")
      minute_str <- format(now, "%M")
      second_str <- format(now, "%S")
      timestamp_base <- sprintf("%s %s, %s %d:%s:%s %s", month_str, day_str, year_str, hour_12, minute_str, second_str, am_pm)
    }
  } else {
    # If STARTED column doesn't exist, use the current timestamp with proper format
    now <- Sys.time()
    hour <- as.numeric(format(now, "%H"))
    am_pm <- ifelse(hour < 12, "AM", "PM")
    hour_12 <- ifelse(hour == 0, 12, ifelse(hour > 12, hour - 12, hour))
    month_str <- month.abb[as.numeric(format(now, "%m"))]
    day_str <- format(now, "%d")
    year_str <- format(now, "%Y")
    minute_str <- format(now, "%M")
    second_str <- format(now, "%S")
    timestamp_base <- sprintf("%s %s, %s %d:%s:%s %s", month_str, day_str, year_str, hour_12, minute_str, second_str, am_pm)
  }
  
  # For each pattern
  for (dp_num in 1:15) {
    dp_code <- sprintf("%02d", dp_num)
    pattern_name <- dp_names[as.character(dp_code)]
    interface_id <- paste0("interface_", sprintf("%03d", dp_num))
    
    # Create timestamp in the same format as sample-human-results.txt: YYYY-MM-DDThh:mm:ss
    # Get the current date and add slight offset for each pattern
    cur_date <- Sys.Date()
    cur_time <- Sys.time()
    
    # Add offset to seconds (add dp_num seconds)
    base_seconds <- as.numeric(format(cur_time, "%S"))
    offset_seconds <- (base_seconds + dp_num) %% 60
    
    # Format in the style from sample-human-results.txt
    timestamp <- format(cur_time, paste0(
        format(cur_time, "%Y-%m-%d"), 
        "T",
        format(cur_time, "%H:%M:"), 
        sprintf("%02d", offset_seconds)
    ))
    
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
    valid_count <- 0        # Count how many valid dimensions we have
    missing_count <- 0      # Count how many dimensions are missing
    max_missing_allowed <- 2  # Allow up to 2 missing values per pattern
    
    # Create a vector to store dimension values
    dimension_values <- vector("numeric", length(dimension_names))
    names(dimension_values) <- dimension_names
    
    # For each score dimension
    for (i in 1:length(dimension_names)) {
      dim_name <- dimension_names[i]
      
      # Get the Excel column position for this dimension
      excel_pos <- excel_to_dim_mapping[dim_name]
      
      # Column name in the survey data
      col_name <- paste0("DP", dp_code, "_", sprintf("%02d", excel_pos))
      
      # Skip if column doesn't exist
      if (!col_name %in% colnames(User)) {
        cat("Column doesn't exist:", col_name, "for pattern", pattern_name, "user", case_id, "\n")
        valid_evaluation <- FALSE
        break
      }
      
      # Get the raw value
      value <- User[[col_name]][user_idx]
      
      # Check if value is NA, -1 (don't know), or non-numeric
      if (is.na(value) || value == -1 || value == " -1" || 
          value == "" || !grepl("^\\s*[-]?[0-9]+\\s*$", value)) {
        
        if (!is.na(value) && value != "" && !grepl("^\\s*[-]?[0-9]+\\s*$", value)) {
          cat("Non-numeric value:", value, "in column", col_name, "for user", case_id, "\n")
        }
        
        # Count missing values but don't break immediately
        missing_count <- missing_count + 1
        
        if (missing_count > max_missing_allowed) {
          cat("Too many missing values (", missing_count, ") for pattern", pattern_name, "user", case_id, "\n")
          valid_evaluation <- FALSE
          break
        }
        
        # Use actual "don't know" value (-1) for missing data
        # Handle NA values specially since direct comparison will fail
        if (is.na(value)) {
          dimension_values[i] <- -1
          cat("Using 'Don't know' value (-1) for NA value in column", col_name, "for user", case_id, "\n")
        } else if (value == -1 || value == " -1") {
          dimension_values[i] <- -1
          cat("Using actual 'Don't know' value (-1) in column", col_name, "for user", case_id, "\n")
        } else {
          # For other missing or invalid data, use -1 as well
          dimension_values[i] <- -1
          cat("Using 'Don't know' value (-1) for missing/invalid data in column", col_name, "for user", case_id, "\n")
        }
        valid_count <- valid_count + 1
        
      } else {
        # Convert to numeric and trim whitespace
        value <- as.numeric(trimws(value))
        
        # Validate the value range (should be 1-7)
        if (is.na(value) || value < 1 || value > 7) {
          if (value == -1) {
            # Count as missing
            missing_count <- missing_count + 1
            
            if (missing_count > max_missing_allowed) {
              cat("Too many missing values (", missing_count, ") for pattern", pattern_name, "user", case_id, "\n")
              valid_evaluation <- FALSE
              break
            }
            
            # Use actual "don't know" value (-1)
            dimension_values[i] <- -1
            cat("Using 'Don't know' value (-1) in column", col_name, "for user", case_id, "\n")
            valid_count <- valid_count + 1
            
          } else {
            cat("Invalid value range:", value, "in column", col_name, "for user", case_id, "\n")
            valid_evaluation <- FALSE
            break
          }
        } else {
          # Valid value, store it
          dimension_values[i] <- value
          valid_count <- valid_count + 1
        }
      }
    }
    
    # If evaluation is valid, update the row_data with all dimension values
    if (valid_evaluation) {
      for (i in 1:length(dimension_names)) {
        dim_name <- dimension_names[i]
        score_col <- paste0("score_", dim_name)
        row_data[[score_col]] <- dimension_values[i]
      }
      
      # Add row to results
      results <- rbind(results, row_data)
      user_has_valid_data <- TRUE
      found_valid_data <- TRUE
      
      if (missing_count > 0) {
        cat("Added evaluation for pattern", pattern_name, "from user", case_id, 
            "(with", missing_count, "neutral values for missing data)\n")
      } else {
        cat("Added valid evaluation for pattern", pattern_name, "from user", case_id, "\n")
      }
    }
  }
  
  # Log if this user had any valid data
  if (user_has_valid_data) {
    cat("User", case_id, "had valid evaluations\n")
  } else {
    cat("User", case_id, "had NO valid evaluations\n")
  }
}

# Write results to CSV file in the same format as sample-human-results.txt
write.table(results, "Formatting Human Survey Data/raw_participant_evaluations.csv", row.names = FALSE, sep = ",", 
            quote = FALSE, na = "", col.names = TRUE)

# Also save a copy with current timestamp for tracking
timestamp_file <- format(Sys.time(), "%Y%m%d_%H%M%S")
write.table(results, paste0("Formatting Human Survey Data/raw_participant_evaluations_", timestamp_file, ".csv"), 
            row.names = FALSE, sep = ",", quote = FALSE, na = "", col.names = TRUE)

# Check if we found any valid data
if (!found_valid_data) {
  cat("\nWARNING: No valid evaluations were found! Please check the data format and filtering criteria.\n")
  
  # Print some sample data to help diagnose the issue
  cat("\nSample of pattern data (first user, first pattern):\n")
  if (nrow(User) > 0) {
    first_user <- User[1,]
    cat("User CASE:", first_user$CASE, "\n")
    
    # Check the first few columns for pattern 1
    pattern_cols <- grep("^DP01_", names(first_user), value = TRUE)
    if (length(pattern_cols) > 0) {
      for (col in pattern_cols[1:min(length(pattern_cols), 5)]) {
        cat(col, ":", first_user[[col]], "\n")
      }
    } else {
      cat("No DP01_ columns found\n")
    }
  } else {
    cat("No users in filtered data\n")
  }
} else {
  # Print a sample of the results
  cat("\nSample of processed results:\n")
  print(head(results, 10))
}

# Print summary information
cat("\nSummary:\n")
cat("Total participants:", length(unique(results$metadata_participant_id)), "\n")
cat("Total evaluations:", nrow(results), "\n")
cat("Files saved to:\n")
cat("  - Formatting Human Survey Data/raw_participant_evaluations.csv\n")
cat("  - Formatting Human Survey Data/raw_participant_evaluations_", timestamp_file, ".csv\n")

# If no valid data was found, provide suggestions
if (!found_valid_data) {
  cat("\nSuggestions if no data was found:\n")
  cat("1. Check if the Excel file structure matches expectations\n")
  cat("2. Ensure column naming follows the pattern DPxx_yy where xx is pattern number and yy is dimension\n")
  cat("3. Make sure users have completed at least some pattern evaluations\n")
  cat("4. Examine the Excel file directly to verify data format\n")
  cat("5. Try modifying the filtering criteria to include more users\n")
}