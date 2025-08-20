library(dplyr)
library(tidyr)

cat("=== COMPLETE TEXT EXTRACTION FOR ALL PARTICIPANTS ===\n")

# Load the raw data and participant screening data
raw_data <- read.csv("aug17_utf8.tsv", sep = "\t", header = TRUE, stringsAsFactors = FALSE)
screening_data <- read.csv("results/participant_screening_with_text_and_variance.csv")

# Get all participants with complete data
complete_participants <- screening_data %>% 
  filter(interfaces_evaluated > 0) %>%
  pull(PROLIFIC_PID)

cat("Raw data loaded:", nrow(raw_data), "rows\n")
cat("Participants with complete data:", length(complete_participants), "\n")

# Get column names for text fields
explanation_cols <- names(raw_data)[grepl("Explanation", names(raw_data))]
feedback_cols <- names(raw_data)[grepl("Open Feedback|Feedback", names(raw_data))]

cat("Found explanation columns:", length(explanation_cols), "\n")
cat("Found feedback columns:", length(feedback_cols), "\n")

# Function to extract and clean text from a participant
extract_participant_text <- function(participant_data, prolific_id) {
  
  # Get all explanation text
  explanations <- list()
  for(col in explanation_cols) {
    if(col %in% names(participant_data)) {
      val <- participant_data[[col]]
      if(!is.na(val) && val != "" && nchar(trimws(val)) > 0) {
        # Clean column name for display
        clean_col <- gsub("1_UEQ\\s*", "", col)
        clean_col <- gsub("1_UEEQ\\s*", "", clean_col)
        explanations[[clean_col]] <- trimws(val)
      }
    }
  }
  
  # Get all feedback text
  feedback <- list()
  for(col in feedback_cols) {
    if(col %in% names(participant_data)) {
      val <- participant_data[[col]]
      if(!is.na(val) && val != "" && nchar(trimws(val)) > 0) {
        feedback[[col]] <- trimws(val)
      }
    }
  }
  
  return(list(explanations = explanations, feedback = feedback))
}

# Extract text for all participants with complete data
cat("\n=== EXTRACTING TEXT FOR ALL PARTICIPANTS ===\n")

all_text_data <- list()
extraction_summary <- data.frame(
  PROLIFIC_PID = character(),
  found = logical(),
  explanation_count = integer(),
  feedback_count = integer(),
  total_chars = integer(),
  stringsAsFactors = FALSE
)

for(pid in complete_participants) {
  # Find participant in raw data
  participant_rows <- which(raw_data$PROLIFIC_PID == pid)
  
  if(length(participant_rows) > 0) {
    # Use the first matching row (should be unique)
    participant_data <- raw_data[participant_rows[1], ]
    
    # Extract text
    text_data <- extract_participant_text(participant_data, pid)
    all_text_data[[pid]] <- text_data
    
    # Calculate summary stats
    all_text_values <- c(unlist(text_data$explanations), unlist(text_data$feedback))
    total_chars <- sum(nchar(all_text_values[!is.na(all_text_values)]))
    
    extraction_summary <- rbind(extraction_summary, data.frame(
      PROLIFIC_PID = pid,
      found = TRUE,
      explanation_count = length(text_data$explanations),
      feedback_count = length(text_data$feedback),
      total_chars = total_chars,
      stringsAsFactors = FALSE
    ))
    
    participant_index <- which(complete_participants == pid)[1]  # Get first match
    if(length(complete_participants) <= 20 || (participant_index %% 10) == 0) {
      cat("✓", pid, "- explanations:", length(text_data$explanations), 
          "feedback:", length(text_data$feedback), "total chars:", total_chars, "\n")
    }
  } else {
    extraction_summary <- rbind(extraction_summary, data.frame(
      PROLIFIC_PID = pid,
      found = FALSE,
      explanation_count = 0,
      feedback_count = 0,
      total_chars = 0,
      stringsAsFactors = FALSE
    ))
    cat("✗", pid, "- NOT FOUND\n")
  }
}

# Save extraction summary
write.csv(extraction_summary, "results/all_participants_text_extraction_summary.csv", row.names = FALSE)

# Create comprehensive text output for manual review
cat("\n=== CREATING COMPLETE TEXT REVIEW FILE ===\n")

# Create a comprehensive text file for manual review
review_file <- "results/all_participants_text_review.txt"
cat("", file = review_file) # Clear the file

# Add header
cat(rep("=", 80), "\n", file = review_file, append = TRUE)
cat("ALL PARTICIPANTS - COMPLETE TEXT REVIEW\n", file = review_file, append = TRUE)
cat("Generated:", Sys.time(), "\n", file = review_file, append = TRUE)
cat("Total participants with complete data:", length(complete_participants), "\n", file = review_file, append = TRUE)
cat(rep("=", 80), "\n\n", file = review_file, append = TRUE)

# Load participant screening info for context
participant_info <- screening_data %>% 
  filter(interfaces_evaluated > 0) %>%
  select(PROLIFIC_PID, condition, interfaces_evaluated, avg_tendency, var_tendency, 
         rejection_rate, avg_char_count, var_char_count)

# Load flagging info if available
flagging_file <- "results/flagged_participants_summary.csv"
if(file.exists(flagging_file)) {
  flagging_summary <- read.csv(flagging_file)
} else {
  flagging_summary <- data.frame(PROLIFIC_PID = character(), flag_reasons = character())
}

for(pid in complete_participants) {
  if(pid %in% names(all_text_data)) {
    text_data <- all_text_data[[pid]]
    participant_stats <- participant_info[participant_info$PROLIFIC_PID == pid, ]
    flag_info <- flagging_summary[flagging_summary$PROLIFIC_PID == pid, ]
    
    # Participant header
    cat("\n", rep("=", 80), "\n", file = review_file, append = TRUE)
    cat("PARTICIPANT:", pid, "\n", file = review_file, append = TRUE)
    cat("CONDITION:", participant_stats$condition, "\n", file = review_file, append = TRUE)
    cat("INTERFACES EVALUATED:", participant_stats$interfaces_evaluated, "\n", file = review_file, append = TRUE)
    cat("AVG TENDENCY:", round(participant_stats$avg_tendency, 2), 
        "| VAR TENDENCY:", round(participant_stats$var_tendency, 2), "\n", file = review_file, append = TRUE)
    cat("REJECTION RATE:", participant_stats$rejection_rate, "%\n", file = review_file, append = TRUE)
    cat("AVG CHAR COUNT:", round(participant_stats$avg_char_count, 1), 
        "| VAR CHAR COUNT:", round(participant_stats$var_char_count, 1), "\n", file = review_file, append = TRUE)
    
    if(nrow(flag_info) > 0) {
      cat("FLAGS:", flag_info$flag_reasons, "\n", file = review_file, append = TRUE)
    } else {
      cat("FLAGS: None\n", file = review_file, append = TRUE)
    }
    
    cat("AI_SUSPICIOUS: [  ]  (Mark TRUE/FALSE after review)\n", file = review_file, append = TRUE)
    cat("QUALITY_NOTES: _________________________________________________\n", file = review_file, append = TRUE)
    cat(rep("=", 80), "\n", file = review_file, append = TRUE)
    
    # Interface explanations
    if(length(text_data$explanations) > 0) {
      cat("\n--- INTERFACE EXPLANATIONS ---\n", file = review_file, append = TRUE)
      for(i in seq_along(text_data$explanations)) {
        cat("\n[", i, "]", names(text_data$explanations)[i], ":\n", file = review_file, append = TRUE)
        cat(text_data$explanations[[i]], "\n", file = review_file, append = TRUE)
      }
    } else {
      cat("\n--- NO INTERFACE EXPLANATIONS FOUND ---\n", file = review_file, append = TRUE)
    }
    
    # Feedback
    if(length(text_data$feedback) > 0) {
      cat("\n--- FEEDBACK ---\n", file = review_file, append = TRUE)
      for(feedback_name in names(text_data$feedback)) {
        cat("\n", feedback_name, ":\n", file = review_file, append = TRUE)
        cat(text_data$feedback[[feedback_name]], "\n", file = review_file, append = TRUE)
      }
    } else {
      cat("\n--- NO FEEDBACK PROVIDED ---\n", file = review_file, append = TRUE)
    }
    
    cat("\n", rep("-", 80), "\n", file = review_file, append = TRUE)
  }
}

cat("Complete text review file created:", review_file, "\n")
cat("File size:", file.size(review_file), "bytes\n")

# Show summary statistics
cat("\n=== EXTRACTION SUMMARY ===\n")
cat("Total participants processed:", nrow(extraction_summary), "\n")
cat("Participants with text found:", sum(extraction_summary$found), "\n")
cat("Total characters extracted:", sum(extraction_summary$total_chars), "\n")
cat("Average explanations per participant:", round(mean(extraction_summary$explanation_count), 1), "\n")
cat("Average feedback responses per participant:", round(mean(extraction_summary$feedback_count), 1), "\n")
cat("Average characters per participant:", round(mean(extraction_summary$total_chars), 1), "\n")

cat("\n=== FILES CREATED ===\n")
cat("- results/all_participants_text_review.txt (complete text for manual review)\n")
cat("- results/all_participants_text_extraction_summary.csv (extraction statistics)\n")
cat("\nReady for comprehensive manual review!\n")
