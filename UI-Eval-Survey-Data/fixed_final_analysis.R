# Final Corrected Analysis: UEQ vs UEEQ (Between-Subjects) - FIXED
# Based on proper understanding of data structure

library(readr)
library(dplyr)
library(ggplot2)

# ==============================================================================
# 1. LOAD DATA AND ESTABLISH DESIGN
# ==============================================================================

cat("=== FINAL CORRECTED ANALYSIS (FIXED) ===\n")
cat("Between-subjects design: UEQ vs UEEQ conditions\n\n")

# Load and clean data
data_raw <- read_tsv("survey_data_utf8.tsv", show_col_types = FALSE)
data_clean <- data_raw[-c(1:2), ]

cat("Total participants:", nrow(data_clean), "\n")

# Fixed condition assignment logic
# Check if participant has ANY UEQ responses vs ANY UEEQ responses
ueq_tendency_cols <- names(data_clean)[grepl("_UEQ Tendency_1$", names(data_clean))]
ueeq_tendency_cols <- names(data_clean)[grepl("_UEEQ Tendency_1$", names(data_clean))]

# For each participant, check if they have responses in UEQ vs UEEQ
data_clean$has_ueq <- FALSE
data_clean$has_ueeq <- FALSE

for (i in 1:nrow(data_clean)) {
  # Check UEQ responses
  ueq_responses <- sapply(ueq_tendency_cols, function(col) {
    !is.na(as.numeric(data_clean[i, col]))
  })
  data_clean$has_ueq[i] <- any(ueq_responses)
  
  # Check UEEQ responses
  ueeq_responses <- sapply(ueeq_tendency_cols, function(col) {
    !is.na(as.numeric(data_clean[i, col]))
  })
  data_clean$has_ueeq[i] <- any(ueeq_responses)
}

# Assign conditions based on which type of responses they have
data_clean$condition <- NA
data_clean$condition[data_clean$has_ueq & !data_clean$has_ueeq] <- "UEQ"
data_clean$condition[data_clean$has_ueeq & !data_clean$has_ueq] <- "UEEQ"

cat("\nCondition assignment:\n")
print(table(data_clean$condition, useNA = "always"))

# Check for participants with both or neither (should be 0 for proper between-subjects design)
both_conditions <- sum(data_clean$has_ueq & data_clean$has_ueeq, na.rm = TRUE)
neither_condition <- sum(!data_clean$has_ueq & !data_clean$has_ueeq, na.rm = TRUE)

cat("Participants with both UEQ and UEEQ:", both_conditions, "\n")
cat("Participants with neither UEQ nor UEEQ:", neither_condition, "\n")

# ==============================================================================
# 2. CREATE PARTICIPANT-LEVEL DATA
# ==============================================================================

participant_data <- data.frame()

for (i in 1:nrow(data_clean)) {
  participant_id <- data_clean$ResponseId[i]
  condition <- data_clean$condition[i]
  
  if (is.na(condition)) next
  
  # Collect all responses for this participant based on their condition
  all_rejections <- c()
  all_tendencies <- c()
  all_confidences <- c()
  
  for (interface_num in 1:15) {
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
      tendency_val <- as.numeric(data_clean[i, tendency_col])
      release_val <- data_clean[i, release_col]
      confidence_val <- as.numeric(data_clean[i, confidence_col])
      
      if (!is.na(tendency_val) && !is.na(release_val) && release_val != "") {
        all_tendencies <- c(all_tendencies, tendency_val)
        all_rejections <- c(all_rejections, ifelse(release_val == "No", 1, 0))
        if (!is.na(confidence_val)) {
          all_confidences <- c(all_confidences, confidence_val)
        }
      }
    }
  }
  
  if (length(all_tendencies) > 0) {
    participant_data <- rbind(participant_data, data.frame(
      participant_id = participant_id,
      condition = condition,
      n_interfaces = length(all_tendencies),
      rejection_rate = mean(all_rejections),
      tendency_mean = mean(all_tendencies),
      tendency_sd = ifelse(length(all_tendencies) > 1, sd(all_tendencies), 0),
      confidence_mean = ifelse(length(all_confidences) > 0, mean(all_confidences), NA),
      stringsAsFactors = FALSE
    ))
  }
}

cat("\nParticipant-level summary:\n")
participant_summary <- participant_data %>% 
  group_by(condition) %>%
  summarise(
    n_participants = n(),
    interfaces_per_participant = mean(n_interfaces),
    .groups = 'drop'
  )
print(participant_summary)

# ==============================================================================
# 3. DESCRIPTIVE STATISTICS
# ==============================================================================

cat("\n=== DESCRIPTIVE STATISTICS ===\n")

descriptive_stats <- participant_data %>%
  group_by(condition) %>%
  summarise(
    n_participants = n(),
    
    # Rejection rates
    rejection_rate_mean = mean(rejection_rate, na.rm = TRUE),
    rejection_rate_sd = sd(rejection_rate, na.rm = TRUE),
    rejection_rate_se = sd(rejection_rate, na.rm = TRUE) / sqrt(n()),
    
    # Tendency scores
    tendency_mean = mean(tendency_mean, na.rm = TRUE),
    tendency_sd = sd(tendency_mean, na.rm = TRUE),
    tendency_se = sd(tendency_mean, na.rm = TRUE) / sqrt(n()),
    
    # Confidence
    confidence_mean = mean(confidence_mean, na.rm = TRUE),
    confidence_sd = sd(confidence_mean, na.rm = TRUE),
    
    .groups = 'drop'
  )

print(descriptive_stats)

# ==============================================================================
# 4. STATISTICAL TESTS (BETWEEN-SUBJECTS)
# ==============================================================================

cat("\n=== STATISTICAL TESTS (BETWEEN-SUBJECTS) ===\n")

# Check if we have both conditions
conditions_available <- unique(participant_data$condition)
n_conditions <- length(conditions_available)

cat("Available conditions:", paste(conditions_available, collapse = ", "), "\n")
cat("Number of conditions:", n_conditions, "\n\n")

if (n_conditions == 2) {
  # Independent samples t-test for rejection rates
  rejection_t_test <- t.test(rejection_rate ~ condition, data = participant_data)
  cat("Rejection Rate Analysis:\n")
  cat("========================\n")
  print(rejection_t_test)
  
  # Effect size (Cohen's d) for rejection rates
  ueq_rejection <- participant_data$rejection_rate[participant_data$condition == "UEQ"]
  ueeq_rejection <- participant_data$rejection_rate[participant_data$condition == "UEEQ"]
  
  pooled_sd_rejection <- sqrt(((length(ueq_rejection) - 1) * var(ueq_rejection) + 
                              (length(ueeq_rejection) - 1) * var(ueeq_rejection)) / 
                             (length(ueq_rejection) + length(ueeq_rejection) - 2))
  
  cohens_d_rejection <- (mean(ueeq_rejection) - mean(ueq_rejection)) / pooled_sd_rejection
  
  cat("\nRejection Rate Effect Size:\n")
  cat(sprintf("Cohen's d = %.3f\n", cohens_d_rejection))
  
  # Independent samples t-test for tendency scores
  tendency_t_test <- t.test(tendency_mean ~ condition, data = participant_data)
  cat("\nTendency Score Analysis:\n")
  cat("========================\n")
  print(tendency_t_test)
  
  # Effect size (Cohen's d) for tendency scores
  ueq_tendency <- participant_data$tendency_mean[participant_data$condition == "UEQ"]
  ueeq_tendency <- participant_data$tendency_mean[participant_data$condition == "UEEQ"]
  
  pooled_sd_tendency <- sqrt(((length(ueq_tendency) - 1) * var(ueq_tendency) + 
                             (length(ueeq_tendency) - 1) * var(ueeq_tendency)) / 
                            (length(ueq_tendency) + length(ueeq_tendency) - 2))
  
  cohens_d_tendency <- (mean(ueeq_tendency) - mean(ueq_tendency)) / pooled_sd_tendency
  
  cat("\nTendency Score Effect Size:\n")
  cat(sprintf("Cohen's d = %.3f\n", cohens_d_tendency))
  
} else {
  cat("WARNING: Only", n_conditions, "condition(s) found in the data.\n")
  cat("Cannot perform between-subjects comparison.\n")
  
  rejection_t_test <- list(p.value = NA)
  tendency_t_test <- list(p.value = NA)
  cohens_d_rejection <- NA
  cohens_d_tendency <- NA
}

# ==============================================================================
# 5. VISUALIZATIONS
# ==============================================================================

if (n_conditions == 2) {
  cat("\n=== CREATING VISUALIZATIONS ===\n")
  
  # Rejection rate comparison
  p1 <- descriptive_stats %>%
    ggplot(aes(x = condition, y = rejection_rate_mean, fill = condition)) +
    geom_col(alpha = 0.7, width = 0.6) +
    geom_errorbar(aes(ymin = rejection_rate_mean - 1.96 * rejection_rate_se,
                      ymax = rejection_rate_mean + 1.96 * rejection_rate_se),
                  width = 0.1) +
    scale_y_continuous(labels = scales::percent_format(), limits = c(0, 0.8)) +
    scale_fill_manual(values = c("UEQ" = "#3498db", "UEEQ" = "#e74c3c")) +
    labs(title = "Interface Rejection Rates by Condition (Between-Subjects)",
         subtitle = sprintf("UEQ: %.1f%%, UEEQ: %.1f%% (p = %.3f)", 
                           descriptive_stats$rejection_rate_mean[descriptive_stats$condition == "UEQ"] * 100,
                           descriptive_stats$rejection_rate_mean[descriptive_stats$condition == "UEEQ"] * 100,
                           rejection_t_test$p.value),
         x = "Condition",
         y = "Mean Rejection Rate",
         caption = sprintf("Error bars: 95% CI, Cohen's d = %.3f", cohens_d_rejection)) +
    theme_minimal() +
    theme(legend.position = "none")
  
  # Tendency score comparison
  p2 <- descriptive_stats %>%
    ggplot(aes(x = condition, y = tendency_mean, fill = condition)) +
    geom_col(alpha = 0.7, width = 0.6) +
    geom_errorbar(aes(ymin = tendency_mean - 1.96 * tendency_se,
                      ymax = tendency_mean + 1.96 * tendency_se),
                  width = 0.1) +
    scale_fill_manual(values = c("UEQ" = "#3498db", "UEEQ" = "#e74c3c")) +
    labs(title = "Mean Tendency Scores by Condition (Between-Subjects)",
         subtitle = sprintf("UEQ: %.2f, UEEQ: %.2f (p = %.3f)", 
                           descriptive_stats$tendency_mean[descriptive_stats$condition == "UEQ"],
                           descriptive_stats$tendency_mean[descriptive_stats$condition == "UEEQ"],
                           tendency_t_test$p.value),
         x = "Condition",
         y = "Mean Tendency Score",
         caption = sprintf("Error bars: 95% CI, Cohen's d = %.3f", cohens_d_tendency)) +
    theme_minimal() +
    theme(legend.position = "none")
  
  # Save plots
  ggsave("final_rejection_rates_comparison.png", p1, width = 8, height = 6, dpi = 300)
  ggsave("final_tendency_scores_comparison.png", p2, width = 8, height = 6, dpi = 300)
  
  cat("Visualizations saved.\n")
}

# ==============================================================================
# 6. FINAL SUMMARY
# ==============================================================================

cat("\n" %>% rep(3) %>% paste(collapse = ""))
cat("=== FINAL ANALYSIS SUMMARY ===\n")
cat("===============================\n")

cat("EXPERIMENTAL DESIGN:\n")
cat("- Between-subjects comparison: UEQ vs UEEQ conditions\n")
if (n_conditions == 2) {
  cat("- Sample sizes: UEQ =", sum(participant_data$condition == "UEQ"), 
      "participants, UEEQ =", sum(participant_data$condition == "UEEQ"), "participants\n")
} else {
  cat("- WARNING: Only one condition found in data\n")
}
cat("- Average interfaces per participant:", round(mean(participant_data$n_interfaces), 1), "\n\n")

if (n_conditions == 2) {
  cat("PRIMARY FINDINGS:\n")
  cat("=================\n")
  
  # Rejection rates
  ueq_reject_mean <- descriptive_stats$rejection_rate_mean[descriptive_stats$condition == "UEQ"]
  ueeq_reject_mean <- descriptive_stats$rejection_rate_mean[descriptive_stats$condition == "UEEQ"]
  reject_diff <- ueeq_reject_mean - ueq_reject_mean
  
  cat(sprintf("Rejection Rates:\n"))
  cat(sprintf("- UEQ: %.1f%% (SE: %.1f%%)\n", ueq_reject_mean * 100, 
              descriptive_stats$rejection_rate_se[descriptive_stats$condition == "UEQ"] * 100))
  cat(sprintf("- UEEQ: %.1f%% (SE: %.1f%%)\n", ueeq_reject_mean * 100,
              descriptive_stats$rejection_rate_se[descriptive_stats$condition == "UEEQ"] * 100))
  cat(sprintf("- Difference: %.1f percentage points\n", reject_diff * 100))
  cat(sprintf("- Statistical significance: p = %.4f\n", rejection_t_test$p.value))
  cat(sprintf("- Effect size: Cohen's d = %.3f\n", cohens_d_rejection))
  
  # Tendency scores
  ueq_tend_mean <- descriptive_stats$tendency_mean[descriptive_stats$condition == "UEQ"]
  ueeq_tend_mean <- descriptive_stats$tendency_mean[descriptive_stats$condition == "UEEQ"]
  tend_diff <- ueeq_tend_mean - ueq_tend_mean
  
  cat(sprintf("\nTendency Scores:\n"))
  cat(sprintf("- UEQ: %.2f (SE: %.2f)\n", ueq_tend_mean,
              descriptive_stats$tendency_se[descriptive_stats$condition == "UEQ"]))
  cat(sprintf("- UEEQ: %.2f (SE: %.2f)\n", ueeq_tend_mean,
              descriptive_stats$tendency_se[descriptive_stats$condition == "UEEQ"]))
  cat(sprintf("- Difference: %.2f points\n", tend_diff))
  cat(sprintf("- Statistical significance: p = %.4f\n", tendency_t_test$p.value))
  cat(sprintf("- Effect size: Cohen's d = %.3f\n", cohens_d_tendency))
  
  # Interpretation
  cat("\nINTERPRETATION:\n")
  cat("===============\n")
  if (rejection_t_test$p.value < 0.05) {
    cat("✓ Significant difference in rejection rates between UEQ and UEEQ conditions\n")
  } else {
    cat("✗ No significant difference in rejection rates between UEQ and UEEQ conditions\n")
  }
  
  if (tendency_t_test$p.value < 0.05) {
    cat("✓ Significant difference in tendency scores between UEQ and UEEQ conditions\n")
  } else {
    cat("✗ No significant difference in tendency scores between UEQ and UEEQ conditions\n")
  }
} else {
  cat("Cannot provide statistical comparisons with only one condition.\n")
}

cat("\nAnalysis completed successfully!\n")
