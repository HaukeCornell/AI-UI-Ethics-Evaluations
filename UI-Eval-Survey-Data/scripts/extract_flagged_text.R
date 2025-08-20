library(dplyr)
library(tidyr)

cat("=== TEXT EXTRACTION FOR FLAGGED PARTICIPANTS ===\n")

# Load the raw data and flagged participant list
raw_data <- read.csv("aug17_utf8.tsv", sep = "\t", header = TRUE, stringsAsFactors = FALSE)
flagged_ids <- read.csv("results/flagged_participant_ids.csv")$PROLIFIC_PID

cat("Raw data loaded:", nrow(raw_data), "rows\n")
cat("Flagged participants to extract:", length(flagged_ids), "\n")

# Define column patterns for text fields
explanation_patterns <- c("Explanation") # Will match both UEQ and UEEQ explanations
feedback_patterns <- c("Open Feedback", "Feedback")

# Get column names that match our patterns
explanation_cols <- names(raw_data)[grepl("Explanation", names(raw_data))]
feedback_cols <- names(raw_data)[grepl(paste(feedback_patterns, collapse = "|"), names(raw_data))]

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

# Extract text for all flagged participants
cat("\n=== EXTRACTING TEXT FOR FLAGGED PARTICIPANTS ===\n")

all_text_data <- list()
extraction_summary <- data.frame(
  PROLIFIC_PID = character(),
  found = logical(),
  explanation_count = integer(),
  feedback_count = integer(),
  total_chars = integer(),
  stringsAsFactors = FALSE
)

for(pid in flagged_ids) {
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
    
    cat("✓", pid, "- explanations:", length(text_data$explanations), 
        "feedback:", length(text_data$feedback), "total chars:", total_chars, "\n")
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
write.csv(extraction_summary, "results/text_extraction_summary.csv", row.names = FALSE)

# Create detailed text output for manual review
cat("\n=== CREATING DETAILED TEXT REVIEW FILE ===\n")

# Create a comprehensive text file for manual review
review_file <- "results/flagged_participants_text_review.txt"
cat("", file = review_file) # Clear the file

# Add header
cat(rep("=", 80), "\n", file = review_file, append = TRUE)
cat("FLAGGED PARTICIPANTS - FULL TEXT REVIEW\n", file = review_file, append = TRUE)
cat("Generated:", Sys.time(), "\n", file = review_file, append = TRUE)
cat("Total flagged participants:", length(flagged_ids), "\n", file = review_file, append = TRUE)
cat(rep("=", 80), "\n\n", file = review_file, append = TRUE)

# Load flagging info for context
flagging_summary <- read.csv("results/flagged_participants_summary.csv")

for(pid in flagged_ids) {
  if(pid %in% names(all_text_data)) {
    text_data <- all_text_data[[pid]]
    flag_info <- flagging_summary[flagging_summary$PROLIFIC_PID == pid, ]
    
    # Participant header
    cat("\n", rep("=", 80), "\n", file = review_file, append = TRUE)
    cat("PARTICIPANT:", pid, "\n", file = review_file, append = TRUE)
    cat("CONDITION:", flag_info$condition, "\n", file = review_file, append = TRUE)
    cat("FLAG REASONS:", flag_info$flag_reasons, "\n", file = review_file, append = TRUE)
    cat("AI_SUSPICIOUS: [  ]  (Mark TRUE/FALSE after review)\n", file = review_file, append = TRUE)
    cat("NOTES: _________________________________________________\n", file = review_file, append = TRUE)
    cat(rep("=", 80), "\n", file = review_file, append = TRUE)
    
    # Interface explanations
    if(length(text_data$explanations) > 0) {
      cat("\n--- INTERFACE EXPLANATIONS ---\n", file = review_file, append = TRUE)
      for(i in seq_along(text_data$explanations)) {
        cat("\n[", i, "]", names(text_data$explanations)[i], ":\n", file = review_file, append = TRUE)
        cat(text_data$explanations[[i]], "\n", file = review_file, append = TRUE)
      }
    }
    
    # Feedback
    if(length(text_data$feedback) > 0) {
      cat("\n--- FEEDBACK ---\n", file = review_file, append = TRUE)
      for(feedback_name in names(text_data$feedback)) {
        cat("\n", feedback_name, ":\n", file = review_file, append = TRUE)
        cat(text_data$feedback[[feedback_name]], "\n", file = review_file, append = TRUE)
      }
    }
    
    cat("\n", rep("-", 80), "\n", file = review_file, append = TRUE)
  }
}

cat("Text review file created:", review_file, "\n")
cat("File size:", file.size(review_file), "bytes\n")

# Create a CSV version for easier data handling
cat("\n=== CREATING CSV VERSION FOR DATA ANALYSIS ===\n")

csv_data <- data.frame(
  PROLIFIC_PID = character(),
  condition = character(),
  flag_reasons = character(),
  explanation_text = character(),
  feedback_text = character(),
  AI_SUSPICIOUS = character(),
  NOTES = character(),
  stringsAsFactors = FALSE
)

for(pid in flagged_ids) {
  if(pid %in% names(all_text_data)) {
    text_data <- all_text_data[[pid]]
    flag_info <- flagging_summary[flagging_summary$PROLIFIC_PID == pid, ]
    
    # Combine all explanations
    all_explanations <- paste(text_data$explanations, collapse = " ||| ")
    
    # Combine all feedback
    all_feedback <- paste(text_data$feedback, collapse = " ||| ")
    
    csv_data <- rbind(csv_data, data.frame(
      PROLIFIC_PID = pid,
      condition = flag_info$condition,
      flag_reasons = flag_info$flag_reasons,
      explanation_text = all_explanations,
      feedback_text = all_feedback,
      AI_SUSPICIOUS = "", # To be filled manually
      NOTES = "",        # To be filled manually
      stringsAsFactors = FALSE
    ))
  }
}

write.csv(csv_data, "results/flagged_participants_for_manual_review.csv", row.names = FALSE)

cat("\n=== EXTRACTION COMPLETE ===\n")
cat("Files created:\n")
cat("- results/flagged_participants_text_review.txt (for manual reading)\n")
cat("- results/flagged_participants_for_manual_review.csv (for data entry)\n")
cat("- results/text_extraction_summary.csv (extraction statistics)\n")
cat("\nReady for manual AI detection review!\n")
