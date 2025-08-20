# Participant screening with correct Prolific ID columns, text response count, and tendency variance
library(dplyr)
library(readr)

cat("=== PARTICIPANT SCREENING WITH PROLIFIC ID AND TEXT RESPONSES ===\n")

# Read the data - participants are scattered throughout the file
header_line <- readLines("aug17_utf8.tsv", n = 1)
column_names <- strsplit(header_line, "\t")[[1]]

# Read all data without skipping rows since participants are scattered
raw_data <- read_tsv("aug17_utf8.tsv", col_names = column_names, show_col_types = FALSE)

cat("Raw data loaded:", nrow(raw_data), "rows,", ncol(raw_data), "columns\n")

# Check how many rows have valid PROLIFIC_PID before filtering
prolific_pid_col_temp <- names(raw_data)[ncol(raw_data)]
valid_prolific_count <- sum(!is.na(raw_data[[prolific_pid_col_temp]]) & 
                           nchar(as.character(raw_data[[prolific_pid_col_temp]])) >= 20)
cat("Rows with valid PROLIFIC_PID (length >= 20):", valid_prolific_count, "\n")

# Use the last two columns for Prolific ID
prolific_id_col <- names(raw_data)[ncol(raw_data)-1]
prolific_pid_col <- names(raw_data)[ncol(raw_data)]

cat("Prolific ID columns:", prolific_id_col, ",", prolific_pid_col, "\n")

# Find all UEQ and UEEQ tendency, explanation, release, and confidence columns
ueq_tendency_cols <- grep("^[0-9]+_UEQ Tendency", names(raw_data), value = TRUE)
ueq_explanation_cols <- grep("^[0-9]+_UEQ Explanation", names(raw_data), value = TRUE)
ueq_release_cols <- grep("^[0-9]+_UEQ Release", names(raw_data), value = TRUE)
ueq_confidence_cols <- grep("^[0-9]+_UEQ Confidence", names(raw_data), value = TRUE)

ueeq_tendency_cols <- grep("^[0-9]+_UEEQ Tendency", names(raw_data), value = TRUE)
ueeq_explanation_cols <- grep("^[0-9]+_UEEQ Explanation", names(raw_data), value = TRUE)
ueeq_release_cols <- grep("^[0-9]+_UEEQ Release", names(raw_data), value = TRUE)
ueeq_confidence_cols <- grep("^[0-9]+_UEEQ Confidence", names(raw_data), value = TRUE)

cat("UEQ tendency columns:", length(ueq_tendency_cols), "\n")
cat("UEQ explanation columns:", length(ueq_explanation_cols), "\n")
cat("UEQ release columns:", length(ueq_release_cols), "\n")
cat("UEQ confidence columns:", length(ueq_confidence_cols), "\n")
cat("UEEQ tendency columns:", length(ueeq_tendency_cols), "\n")
cat("UEEQ explanation columns:", length(ueeq_explanation_cols), "\n")
cat("UEEQ release columns:", length(ueeq_release_cols), "\n")
cat("UEEQ confidence columns:", length(ueeq_confidence_cols), "\n")

# Filter valid participants - include all rows with valid PROLIFIC_PID
valid_data <- raw_data %>%
  filter(!is.na(.data[[prolific_pid_col]]),
         .data[[prolific_pid_col]] != "",
         nchar(as.character(.data[[prolific_pid_col]])) >= 20,
         # Remove header rows and metadata 
         !grepl("PROLIFIC_PID", .data[[prolific_pid_col]]),
         !grepl("ImportId", .data[[prolific_pid_col]]))

cat("Valid participants after filtering:", nrow(valid_data), "\n")
cat("Unique participants:", length(unique(valid_data[[prolific_pid_col]])), "\n")

# Create screening table
screening_table <- valid_data %>%
  rowwise() %>%
  mutate(
    # Determine condition based on which questions were answered
    ueq_responses = sum(!is.na(c_across(all_of(ueq_tendency_cols))) & 
                       c_across(all_of(ueq_tendency_cols)) != "", na.rm = TRUE),
    ueeq_responses = sum(!is.na(c_across(all_of(ueeq_tendency_cols))) & 
                        c_across(all_of(ueeq_tendency_cols)) != "", na.rm = TRUE),
    
    condition = case_when(
      ueq_responses > 0 ~ "UEQ",
      ueeq_responses > 0 ~ "UEQ+Autonomy",
      TRUE ~ "Unknown"
    ),
    
    # Count non-empty explanation fields and calculate character counts (both UEQ and UEEQ)
    ueq_text_responses = sum(sapply(ueq_explanation_cols, function(col) {
      val <- cur_data()[[col]]
      !is.na(val) && val != ""
    })),
    ueeq_text_responses = sum(sapply(ueeq_explanation_cols, function(col) {
      val <- cur_data()[[col]]
      !is.na(val) && val != ""
    })),
    text_responses = ueq_text_responses + ueeq_text_responses,
    
    # Calculate character counts for explanations
    ueq_char_counts = list(sapply(ueq_explanation_cols, function(col) {
      val <- cur_data()[[col]]
      if (!is.na(val) && val != "") nchar(as.character(val)) else 0
    })),
    ueeq_char_counts = list(sapply(ueeq_explanation_cols, function(col) {
      val <- cur_data()[[col]]
      if (!is.na(val) && val != "") nchar(as.character(val)) else 0
    })),
    all_char_counts = list(c(unlist(ueq_char_counts), unlist(ueeq_char_counts))),
    char_counts_nonzero = list(unlist(all_char_counts)[unlist(all_char_counts) > 0]),
    
    total_characters = sum(unlist(all_char_counts)),
    avg_char_count = ifelse(length(char_counts_nonzero) > 0, mean(char_counts_nonzero), NA),
    var_char_count = ifelse(length(char_counts_nonzero) > 1, var(char_counts_nonzero), NA),
    
    # Get all tendency scores (combine UEQ and UEEQ)
    ueq_scores = list(as.numeric(c_across(all_of(ueq_tendency_cols)))),
    ueeq_scores = list(as.numeric(c_across(all_of(ueeq_tendency_cols)))),
    all_tendency_scores = list(c(unlist(ueq_scores), unlist(ueeq_scores))),
    tendency_scores_clean = list(unlist(all_tendency_scores)[!is.na(unlist(all_tendency_scores))]),
    
    # Get all release responses (actual rejection/acceptance decisions)
    ueq_releases = list(c_across(all_of(ueq_release_cols))),
    ueeq_releases = list(c_across(all_of(ueeq_release_cols))),
    all_releases = list(c(unlist(ueq_releases), unlist(ueeq_releases))),
    releases_clean = list(unlist(all_releases)[!is.na(unlist(all_releases)) & unlist(all_releases) != ""]),
    
    # Get all confidence scores
    ueq_confidences = list(as.numeric(c_across(all_of(ueq_confidence_cols)))),
    ueeq_confidences = list(as.numeric(c_across(all_of(ueeq_confidence_cols)))),
    all_confidences = list(c(unlist(ueq_confidences), unlist(ueeq_confidences))),
    confidences_clean = list(unlist(all_confidences)[!is.na(unlist(all_confidences))]),
    
    interfaces_evaluated = length(tendency_scores_clean),
    avg_tendency = ifelse(interfaces_evaluated > 0, mean(tendency_scores_clean), NA),
    var_tendency = ifelse(interfaces_evaluated > 1, var(tendency_scores_clean), NA),
    
    # Calculate rejection rate based on actual Release responses ("No" = rejection)
    rejection_count = sum(releases_clean == "No", na.rm = TRUE),
    release_responses = length(releases_clean),
    rejection_rate = ifelse(release_responses > 0, rejection_count / release_responses * 100, NA),
    
    # Calculate confidence metrics
    avg_confidence = ifelse(length(confidences_clean) > 0, mean(confidences_clean), NA),
    var_confidence = ifelse(length(confidences_clean) > 1, var(confidences_clean), NA)
  ) %>%
  ungroup() %>%
  select(
    !!prolific_id_col, !!prolific_pid_col, condition,
    interfaces_evaluated, avg_tendency, var_tendency, rejection_rate, 
    avg_confidence, var_confidence, text_responses, 
    total_characters, avg_char_count, var_char_count
  )

# Save the screening table
write.csv(screening_table, "results/participant_screening_with_text_and_variance.csv", row.names = FALSE)

cat("\nScreening table saved: results/participant_screening_with_text_and_variance.csv\n")
cat("Columns: Prolific ID, PROLIFIC_PID, condition, interfaces_evaluated, avg_tendency, var_tendency, rejection_rate, avg_confidence, var_confidence, text_responses, total_characters, avg_char_count, var_char_count\n")

# Show summary statistics
cat("\n=== SUMMARY STATISTICS ===\n")
cat("Total participants:", nrow(screening_table), "\n")
cat("Participants with interface evaluations:", sum(screening_table$interfaces_evaluated > 0), "\n")

condition_summary <- screening_table %>%
  filter(interfaces_evaluated > 0) %>%
  count(condition)
cat("\nCondition distribution (participants with data):\n")
print(condition_summary)
