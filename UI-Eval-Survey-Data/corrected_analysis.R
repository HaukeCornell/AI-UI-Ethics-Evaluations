# Corrected UEQ vs UEEQ Analysis with Proper Design Understanding
# UEEQ vs UEQ: Between-subjects design
# AI vs Human: Within-subjects design (first half human, second half AI)

# Set CRAN mirror and load required libraries
options(repos = c(CRAN = "https://cran.rstudio.com/"))

required_packages <- c("readr", "dplyr", "ggplot2", "tidyr", "lme4", "emmeans")

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  }
}

# ==============================================================================
# 1. DATA LOADING AND DESIGN UNDERSTANDING
# ==============================================================================

cat("=== CORRECTED ANALYSIS: PROPER EXPERIMENTAL DESIGN ===\n")
cat("UEEQ vs UEQ: BETWEEN-subjects (different participants)\n")
cat("AI vs Human: WITHIN-subjects (same participants, different interfaces)\n\n")

# Load data
data_raw <- read_tsv("survey_data_utf8.tsv", show_col_types = FALSE)
data_clean <- data_raw[-c(1:2), ]

cat("Data dimensions:", dim(data_clean), "\n")

# First, let's determine which participants got UEQ vs UEEQ
# This should be a between-subjects factor
# Let's check if we can identify this from the data patterns

# Extract all UEQ and UEEQ responses to see the pattern
sample_participant <- data_clean[1, ]

# Check which columns exist for first interface
ueq_cols_1 <- names(data_clean)[grepl("^1_UEQ", names(data_clean))]
ueeq_cols_1 <- names(data_clean)[grepl("^1_UEEQ", names(data_clean))]

cat("UEQ columns for interface 1:", length(ueq_cols_1), "\n")
cat("UEEQ columns for interface 1:", length(ueeq_cols_1), "\n")

# Check if participants have responses in both UEQ and UEEQ (which would be wrong)
# or only in one (which would be correct for between-subjects)

participants_ueq_1 <- !is.na(as.numeric(data_clean$`1_UEQ Tendency_1`))
participants_ueeq_1 <- !is.na(as.numeric(data_clean$`1_UEEQ Tendency_1`))

cat("Participants with UEQ responses for interface 1:", sum(participants_ueq_1, na.rm = TRUE), "\n")
cat("Participants with UEEQ responses for interface 1:", sum(participants_ueeq_1, na.rm = TRUE), "\n")
cat("Participants with BOTH UEQ and UEEQ for interface 1:", sum(participants_ueq_1 & participants_ueeq_1, na.rm = TRUE), "\n")

# Determine condition assignment for each participant
data_clean$condition <- NA
data_clean$condition[participants_ueq_1 & !participants_ueeq_1] <- "UEQ"
data_clean$condition[participants_ueeq_1 & !participants_ueq_1] <- "UEEQ"

cat("Participants in UEQ condition:", sum(data_clean$condition == "UEQ", na.rm = TRUE), "\n")
cat("Participants in UEEQ condition:", sum(data_clean$condition == "UEEQ", na.rm = TRUE), "\n")

# ==============================================================================
# 2. CREATE PROPER LONG FORMAT DATA
# ==============================================================================

cat("\n=== CREATING PROPER LONG FORMAT ===\n")

# Based on the routing logic: 10 interfaces total, first 5 = human, last 5 = AI
# But let's also check what the actual number is by examining the data

interfaces_available <- 1:15  # We know from previous analysis there are 15 interfaces

# Create long format with proper design understanding
data_long <- data.frame(
  participant_id = character(),
  condition = character(),
  interface = integer(),
  eval_source = character(),
  tendency = numeric(),
  release = character(),
  confidence = numeric(),
  stringsAsFactors = FALSE
)

# Create long format with proper design understanding
data_rows <- list()
row_counter <- 1

for (participant_idx in 1:nrow(data_clean)) {
  participant_id <- data_clean$ResponseId[participant_idx]
  condition <- data_clean$condition[participant_idx]
  
  if (is.na(condition)) next  # Skip participants without clear condition assignment
  
  for (interface_num in interfaces_available) {
    # Determine if this interface should have data for this condition
    if (condition == "UEQ") {
      tendency_col <- paste0(interface_num, "_UEQ Tendency_1")
      release_col <- paste0(interface_num, "_UEQ Release")
      confidence_col <- paste0(interface_num, "_UEQ Confidence_4")
    } else {
      tendency_col <- paste0(interface_num, "_UEEQ Tendency_1")
      release_col <- paste0(interface_num, "_UEEQ Release")
      confidence_col <- paste0(interface_num, "_UEEQ Confidence_4")
    }
    
    if (all(c(tendency_col, release_col) %in% names(data_clean))) {
      tendency_val <- as.numeric(data_clean[participant_idx, tendency_col])
      release_val <- data_clean[participant_idx, release_col]
      confidence_val <- as.numeric(data_clean[participant_idx, confidence_col])
      
      if (!is.na(tendency_val) && !is.na(release_val) && release_val != "") {
        # Determine evaluation source based on interface position
        # According to routing logic: first half = human, second half = AI
        # Assuming interfaces 1-5 = human, 6-10 = AI for now
        eval_source <- if (interface_num <= 5) "human" else if (interface_num <= 10) "ai" else NA
        
        if (!is.na(eval_source)) {
          data_rows[[row_counter]] <- data.frame(
            participant_id = participant_id,
            condition = condition,
            interface = interface_num,
            eval_source = eval_source,
            tendency = tendency_val,
            release = release_val,
            confidence = confidence_val,
            stringsAsFactors = FALSE
          )
          row_counter <- row_counter + 1
        }
      }
    }
  }
}

# Combine all rows
data_long <- do.call(rbind, data_rows)

# Clean the data
data_long <- data_long %>%
  mutate(
    release_binary = case_when(
      release == "Yes" ~ 1,
      release == "No" ~ 0,
      TRUE ~ NA_real_
    ),
    rejection = 1 - release_binary,
    condition = as.factor(condition),
    eval_source = as.factor(eval_source),
    interface = as.factor(interface),
    participant_id = as.factor(participant_id)
  ) %>%
  filter(!is.na(tendency), !is.na(release_binary), !is.na(eval_source))

cat("Long format data created with", nrow(data_long), "observations\n")
cat("Participants:", n_distinct(data_long$participant_id), "\n")
cat("UEQ condition participants:", n_distinct(data_long$participant_id[data_long$condition == "UEQ"]), "\n")
cat("UEEQ condition participants:", n_distinct(data_long$participant_id[data_long$condition == "UEEQ"]), "\n")
cat("Interfaces with human eval:", n_distinct(data_long$interface[data_long$eval_source == "human"]), "\n")
cat("Interfaces with AI eval:", n_distinct(data_long$interface[data_long$eval_source == "ai"]), "\n")

# ==============================================================================
# 3. DESCRIPTIVE STATISTICS WITH PROPER DESIGN
# ==============================================================================

cat("\n=== DESCRIPTIVE STATISTICS (CORRECTED DESIGN) ===\n")

# Overall summary by condition (between-subjects)
condition_summary <- data_long %>%
  group_by(condition) %>%
  summarise(
    n_responses = n(),
    n_participants = n_distinct(participant_id),
    n_interfaces = n_distinct(interface),
    rejection_rate = mean(rejection, na.rm = TRUE),
    rejection_se = sqrt(rejection_rate * (1 - rejection_rate) / n()),
    tendency_mean = mean(tendency, na.rm = TRUE),
    tendency_sd = sd(tendency, na.rm = TRUE),
    .groups = 'drop'
  )

cat("BETWEEN-SUBJECTS COMPARISON (UEQ vs UEEQ):\n")
print(condition_summary)

# Within-subjects summary by evaluation source
source_summary <- data_long %>%
  group_by(eval_source) %>%
  summarise(
    n_responses = n(),
    n_participants = n_distinct(participant_id),
    rejection_rate = mean(rejection, na.rm = TRUE),
    rejection_se = sqrt(rejection_rate * (1 - rejection_rate) / n()),
    tendency_mean = mean(tendency, na.rm = TRUE),
    tendency_sd = sd(tendency, na.rm = TRUE),
    .groups = 'drop'
  )

cat("\nWITHIN-SUBJECTS COMPARISON (Human vs AI evaluation data):\n")
print(source_summary)

# Two-way summary
twoway_summary <- data_long %>%
  group_by(condition, eval_source) %>%
  summarise(
    n_responses = n(),
    n_participants = n_distinct(participant_id),
    rejection_rate = mean(rejection, na.rm = TRUE),
    tendency_mean = mean(tendency, na.rm = TRUE),
    .groups = 'drop'
  )

cat("\nTWO-WAY SUMMARY (Condition × Evaluation Source):\n")
print(twoway_summary)

# ==============================================================================
# 4. CORRECTED STATISTICAL ANALYSIS
# ==============================================================================

cat("\n=== STATISTICAL ANALYSIS (CORRECTED DESIGN) ===\n")

# Model 1: Between-subjects comparison (UEQ vs UEEQ)
cat("1. BETWEEN-SUBJECTS ANALYSIS: UEQ vs UEEQ\n")
cat("Testing main effect of condition (aggregating across eval sources)\n")

# For between-subjects, we can use simpler models or aggregate by participant first
participant_summary <- data_long %>%
  group_by(participant_id, condition) %>%
  summarise(
    rejection_rate = mean(rejection, na.rm = TRUE),
    tendency_mean = mean(tendency, na.rm = TRUE),
    .groups = 'drop'
  )

# t-test for rejection rates (between-subjects)
rejection_t_test <- t.test(rejection_rate ~ condition, data = participant_summary)
cat("Rejection rate t-test (between-subjects):\n")
print(rejection_t_test)

# t-test for tendency scores (between-subjects)
tendency_t_test <- t.test(tendency_mean ~ condition, data = participant_summary)
cat("\nTendency score t-test (between-subjects):\n")
print(tendency_t_test)

# Model 2: Within-subjects comparison (Human vs AI evaluation)
cat("\n2. WITHIN-SUBJECTS ANALYSIS: Human vs AI evaluation data\n")

# Paired t-test for evaluation source effect
participant_source_summary <- data_long %>%
  group_by(participant_id, eval_source) %>%
  summarise(
    rejection_rate = mean(rejection, na.rm = TRUE),
    tendency_mean = mean(tendency, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  pivot_wider(names_from = eval_source, 
              values_from = c(rejection_rate, tendency_mean),
              names_sep = "_")

# Only include participants who have both human and AI data
complete_participants <- participant_source_summary %>%
  filter(!is.na(rejection_rate_human), !is.na(rejection_rate_ai))

cat("Participants with both human and AI data:", nrow(complete_participants), "\n")

if (nrow(complete_participants) > 0) {
  # Paired t-test for rejection rates
  rejection_paired_t <- t.test(complete_participants$rejection_rate_human, 
                              complete_participants$rejection_rate_ai, 
                              paired = TRUE)
  cat("Rejection rate paired t-test (human vs AI):\n")
  print(rejection_paired_t)
  
  # Paired t-test for tendency
  tendency_paired_t <- t.test(complete_participants$tendency_mean_human, 
                             complete_participants$tendency_mean_ai, 
                             paired = TRUE)
  cat("\nTendency paired t-test (human vs AI):\n")
  print(tendency_paired_t)
}

# ==============================================================================
# 5. SUMMARY OF CORRECTED FINDINGS
# ==============================================================================

cat("\n" %>% rep(3) %>% paste(collapse=""))
cat("=== CORRECTED ANALYSIS SUMMARY ===\n")
cat("===================================\n")

cat("EXPERIMENTAL DESIGN:\n")
cat("- BETWEEN-subjects: UEQ vs UEEQ conditions (different participants)\n")
cat("- WITHIN-subjects: Human vs AI evaluation data (same participants)\n\n")

cat("SAMPLE SIZES:\n")
cat(sprintf("- UEQ condition: %d participants\n", 
            sum(participant_summary$condition == "UEQ")))
cat(sprintf("- UEEQ condition: %d participants\n", 
            sum(participant_summary$condition == "UEEQ")))
cat(sprintf("- Participants with both human and AI data: %d\n", 
            nrow(complete_participants)))

cat("\nBETWEEN-SUBJECTS RESULTS (UEQ vs UEEQ):\n")
ueq_reject <- condition_summary$rejection_rate[condition_summary$condition == "UEQ"]
ueeq_reject <- condition_summary$rejection_rate[condition_summary$condition == "UEEQ"]
ueq_tend <- condition_summary$tendency_mean[condition_summary$condition == "UEQ"]
ueeq_tend <- condition_summary$tendency_mean[condition_summary$condition == "UEEQ"]

cat(sprintf("- UEQ rejection rate: %.1f%%\n", ueq_reject * 100))
cat(sprintf("- UEEQ rejection rate: %.1f%%\n", ueeq_reject * 100))
cat(sprintf("- Difference: %.1f percentage points\n", (ueeq_reject - ueq_reject) * 100))
cat(sprintf("- Rejection rate p-value: %.4f\n", rejection_t_test$p.value))

cat(sprintf("- UEQ tendency mean: %.2f\n", ueq_tend))
cat(sprintf("- UEEQ tendency mean: %.2f\n", ueeq_tend))
cat(sprintf("- Difference: %.2f points\n", ueeq_tend - ueq_tend))
cat(sprintf("- Tendency p-value: %.4f\n", tendency_t_test$p.value))

if (nrow(complete_participants) > 0) {
  cat("\nWITHIN-SUBJECTS RESULTS (Human vs AI evaluation):\n")
  human_reject <- mean(complete_participants$rejection_rate_human, na.rm = TRUE)
  ai_reject <- mean(complete_participants$rejection_rate_ai, na.rm = TRUE)
  human_tend <- mean(complete_participants$tendency_mean_human, na.rm = TRUE)
  ai_tend <- mean(complete_participants$tendency_mean_ai, na.rm = TRUE)
  
  cat(sprintf("- Human eval rejection rate: %.1f%%\n", human_reject * 100))
  cat(sprintf("- AI eval rejection rate: %.1f%%\n", ai_reject * 100))
  cat(sprintf("- Difference: %.1f percentage points\n", (ai_reject - human_reject) * 100))
  cat(sprintf("- Rejection rate p-value: %.4f\n", rejection_paired_t$p.value))
  
  cat(sprintf("- Human eval tendency mean: %.2f\n", human_tend))
  cat(sprintf("- AI eval tendency mean: %.2f\n", ai_tend))
  cat(sprintf("- Difference: %.2f points\n", ai_tend - human_tend))
  cat(sprintf("- Tendency p-value: %.4f\n", tendency_paired_t$p.value))
}

cat("\nAnalysis complete with corrected experimental design!\n")
