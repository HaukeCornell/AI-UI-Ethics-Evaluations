# Data Validation and Processing Check
# Checking data pipeline correctness and comparing file versions

library(dplyr)
library(readr)
library(tidyr)

cat("=== DATA VALIDATION AND PROCESSING CHECK ===\n")

# ===== CHECK CURRENT PROCESSED DATA =====
cat("\n1. CURRENT PROCESSED DATA CHECK:\n")

# Load current processed data
current_data <- read.csv("results/interface_plot_data_updated.csv")

cat("Current processed data (interface_plot_data_updated.csv):\n")
cat("• Total rows:", nrow(current_data), "\n")
cat("• Unique participants:", length(unique(current_data$ResponseId)), "\n")
cat("• Unique interfaces per participant:", round(nrow(current_data) / length(unique(current_data$ResponseId)), 1), "\n")

# Check condition distribution
condition_dist <- current_data %>%
  distinct(ResponseId, condition_f, has_ai_evaluation) %>%
  count(condition_f, has_ai_evaluation)

cat("• Condition distribution:\n")
print(condition_dist)

# ===== CHECK ORIGINAL DATA FILES =====
cat("\n2. ORIGINAL DATA FILES COMPARISON:\n")

# Check August 16 file
if(file.exists("aug16_utf8.tsv")) {
  aug16_raw <- read_tsv("aug16_utf8.tsv", show_col_types = FALSE)
  cat("August 16 file:\n")
  cat("• Total rows:", nrow(aug16_raw), "\n")
  cat("• Unique ResponseIds:", length(unique(aug16_raw$ResponseId)), "\n")
  
  # Check if we have both UEQ and UEEQ columns
  ueq_cols <- sum(grepl("_UEQ ", names(aug16_raw)))
  ueeq_cols <- sum(grepl("_UEEQ ", names(aug16_raw)))
  cat("• UEQ columns:", ueq_cols, "\n")
  cat("• UEEQ columns:", ueeq_cols, "\n")
}

# Check August 17 file
if(file.exists("aug17_utf8.tsv")) {
  aug17_raw <- read_tsv("aug17_utf8.tsv", show_col_types = FALSE)
  cat("\nAugust 17 file (NEW):\n")
  cat("• Total rows:", nrow(aug17_raw), "\n")
  cat("• Unique ResponseIds:", length(unique(aug17_raw$ResponseId)), "\n")
  
  # Check if we have both UEQ and UEEQ columns
  ueq_cols_new <- sum(grepl("_UEQ ", names(aug17_raw)))
  ueeq_cols_new <- sum(grepl("_UEEQ ", names(aug17_raw)))
  cat("• UEQ columns:", ueq_cols_new, "\n")
  cat("• UEEQ columns:", ueeq_cols_new, "\n")
  
  # Check increase
  if(exists("aug16_raw")) {
    new_participants <- nrow(aug17_raw) - nrow(aug16_raw)
    cat("• NEW participants added:", new_participants, "\n")
  }
}

# ===== VALIDATE DATA PROCESSING LOGIC =====
cat("\n3. DATA PROCESSING VALIDATION:\n")

# Let's manually process a small sample to check logic
if(exists("aug16_raw")) {
  # Check first few rows to understand the structure
  cat("Sample ResponseIds from August 16 data:\n")
  sample_ids <- head(aug16_raw$ResponseId[!is.na(aug16_raw$ResponseId)], 3)
  print(sample_ids)
  
  # Check how condition assignment works
  cat("\nChecking condition assignment logic...\n")
  
  # Look for participants with UEQ vs UEEQ data
  sample_participant <- aug16_raw[1, ]
  
  # Check which columns have data for this participant
  ueq_tendency_cols <- grep("_UEQ Tendency", names(aug16_raw), value = TRUE)
  ueeq_tendency_cols <- grep("_UEEQ Tendency", names(aug16_raw), value = TRUE)
  
  cat("UEQ tendency columns found:", length(ueq_tendency_cols), "\n")
  cat("UEEQ tendency columns found:", length(ueeq_tendency_cols), "\n")
  
  # Check a sample participant's data pattern
  if(length(ueq_tendency_cols) > 0 && length(ueeq_tendency_cols) > 0) {
    first_participant <- aug16_raw[1, ]
    
    ueq_data <- first_participant[ueq_tendency_cols]
    ueeq_data <- first_participant[ueeq_tendency_cols]
    
    ueq_non_na <- sum(!is.na(ueq_data))
    ueeq_non_na <- sum(!is.na(ueeq_data))
    
    cat("First participant - UEQ responses:", ueq_non_na, "of", length(ueq_tendency_cols), "\n")
    cat("First participant - UEEQ responses:", ueeq_non_na, "of", length(ueeq_tendency_cols), "\n")
    
    # This tells us the condition assignment logic
    if(ueq_non_na > ueeq_non_na) {
      cat("→ This participant appears to be in UEQ condition\n")
    } else if(ueeq_non_na > ueq_non_na) {
      cat("→ This participant appears to be in UEEQ condition\n")
    } else {
      cat("→ Unclear condition assignment\n")
    }
  }
}

# ===== CHECK AI EVALUATION ASSIGNMENT =====
cat("\n4. AI EVALUATION ASSIGNMENT CHECK:\n")

# Look for AI evaluation columns
if(exists("aug16_raw")) {
  ai_cols <- grep("AI|ai|Evaluation Data", names(aug16_raw), value = TRUE)
  cat("Potential AI evaluation columns:\n")
  print(ai_cols)
  
  if("Evaluation Data" %in% names(aug16_raw)) {
    ai_responses <- table(aug16_raw$`Evaluation Data`, useNA = "ifany")
    cat("\nEvaluation Data responses:\n")
    print(ai_responses)
  }
  
  if("AI eval" %in% names(aug16_raw)) {
    ai_eval_responses <- table(aug16_raw$`AI eval`, useNA = "ifany")
    cat("\nAI eval responses:\n")
    print(ai_eval_responses)
  }
}

# ===== PROCESSING COMPLETENESS CHECK =====
cat("\n5. PROCESSING COMPLETENESS CHECK:\n")

# Check if current processed data covers all participants from original
if(exists("aug16_raw")) {
  original_participants <- unique(aug16_raw$ResponseId[!is.na(aug16_raw$ResponseId)])
  processed_participants <- unique(current_data$ResponseId)
  
  cat("Original file participants:", length(original_participants), "\n")
  cat("Processed data participants:", length(processed_participants), "\n")
  
  missing_participants <- setdiff(original_participants, processed_participants)
  if(length(missing_participants) > 0) {
    cat("WARNING: Missing participants in processed data:", length(missing_participants), "\n")
    cat("Missing IDs:", head(missing_participants, 5), "...\n")
  } else {
    cat("✓ All participants from original data are included\n")
  }
  
  # Check total expected interface evaluations
  # Each participant should evaluate 10 interfaces (randomly selected)
  expected_total <- length(original_participants) * 10
  actual_total <- nrow(current_data)
  
  cat("Expected total evaluations (", length(original_participants), "× 10):", expected_total, "\n")
  cat("Actual total evaluations:", actual_total, "\n")
  
  if(actual_total < expected_total * 0.9) {
    cat("WARNING: Significantly fewer evaluations than expected\n")
  } else {
    cat("✓ Evaluation count seems reasonable\n")
  }
}

cat("\n=== VALIDATION COMPLETE ===\n")
cat("Next step: Process the new August 17 data if validation looks good\n")
