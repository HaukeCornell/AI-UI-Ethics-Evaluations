# Fixed Complete 2x2 Between-Subjects Analysis
# UEQ/UEEQ x AI-Exposed/Non-AI-Exposed

library(readr)
library(dplyr)
library(ggplot2)
library(emmeans)
library(lme4)
library(tidyr)

# Read the UTF-8 converted data
data <- read_tsv("survey_data_utf8.tsv", show_col_types = FALSE)

cat("=== Fixed Complete 2x2 Between-Subjects Analysis ===\n")
cat("Factors: UEQ/UEEQ x AI-Exposed/Non-AI-Exposed\n\n")

# Filter to completed responses only
completed_data <- data %>% 
  filter(Progress == 100) %>%
  filter(!is.na(`1_UEQ Tendency_1`) | !is.na(`1_UEEQ Tendency_1`))

# Create AI evaluation indicator
completed_data <- completed_data %>%
  mutate(
    has_ai_evaluation = case_when(
      is.na(`Evaluation Data`) ~ NA,
      grepl("Combined AI-human evaluation", `Evaluation Data`, ignore.case = TRUE) ~ TRUE,
      TRUE ~ FALSE
    )
  )

# Determine UEQ vs UEEQ condition
completed_data <- completed_data %>%
  mutate(
    has_ueq = !is.na(`1_UEQ Tendency_1`),
    has_ueeq = !is.na(`1_UEEQ Tendency_1`),
    condition = case_when(
      has_ueq & !has_ueeq ~ "UEQ",
      !has_ueq & has_ueeq ~ "UEEQ", 
      has_ueq & has_ueeq ~ "Mixed",
      TRUE ~ "Neither"
    )
  )

# Filter to valid conditions only
analysis_data <- completed_data %>%
  filter(condition %in% c("UEQ", "UEEQ"), !is.na(has_ai_evaluation))

cat("Final analysis sample:", nrow(analysis_data), "participants\n")

# Create 2x2 design summary
design_summary <- analysis_data %>%
  count(condition, has_ai_evaluation) %>%
  pivot_wider(names_from = has_ai_evaluation, values_from = n, names_prefix = "AI_") %>%
  mutate(Total = AI_FALSE + AI_TRUE)

cat("\nDesign Summary (2x2):\n")
print(design_summary)
cat("\n")

# Calculate interface-level data for rejection rates and tendency scores
# Collect all UEQ interfaces (1-15) - FIXED: using correct response values
ueq_interfaces <- analysis_data %>%
  filter(condition == "UEQ") %>%
  select(ResponseId, condition, has_ai_evaluation, 
         matches("^\\d+_UEQ (Tendency_1|Release)$")) %>%
  pivot_longer(cols = matches("^\\d+_UEQ"), 
               names_to = "variable", values_to = "value") %>%
  filter(!is.na(value)) %>%
  extract(variable, c("interface", "measure"), "(\\d+)_UEQ (Tendency_1|Release)") %>%
  pivot_wider(names_from = measure, values_from = value) %>%
  rename(tendency = `Tendency_1`, release = Release) %>%
  mutate(
    tendency = as.numeric(tendency),
    rejected = case_when(
      release == "No" ~ 1,    # FIXED: "No" means rejected
      release == "Yes" ~ 0,   # FIXED: "Yes" means not rejected  
      TRUE ~ NA_real_
    )
  )

# Collect all UEEQ interfaces (1-15) - FIXED: using correct response values
ueeq_interfaces <- analysis_data %>%
  filter(condition == "UEEQ") %>%
  select(ResponseId, condition, has_ai_evaluation,
         matches("^\\d+_UEEQ (Tendency_1|Release)$")) %>%
  pivot_longer(cols = matches("^\\d+_UEEQ"), 
               names_to = "variable", values_to = "value") %>%
  filter(!is.na(value)) %>%
  extract(variable, c("interface", "measure"), "(\\d+)_UEEQ (Tendency_1|Release)") %>%
  pivot_wider(names_from = measure, values_from = value) %>%
  rename(tendency = `Tendency_1`, release = Release) %>%
  mutate(
    tendency = as.numeric(tendency),
    rejected = case_when(
      release == "No" ~ 1,    # FIXED: "No" means rejected
      release == "Yes" ~ 0,   # FIXED: "Yes" means not rejected
      TRUE ~ NA_real_
    )
  )

# Combine interface data
all_interfaces <- bind_rows(ueq_interfaces, ueeq_interfaces)

cat("Debug: Sample of interface data:\n")
print(head(all_interfaces, 10))
cat("\n")

# Calculate participant-level means
participant_means <- all_interfaces %>%
  group_by(ResponseId, condition, has_ai_evaluation) %>%
  summarise(
    mean_rejection_rate = mean(rejected, na.rm = TRUE),
    mean_tendency = mean(tendency, na.rm = TRUE),
    n_interfaces = n(),
    .groups = "drop"
  ) %>%
  # Convert rejection rate to percentage
  mutate(mean_rejection_rate = mean_rejection_rate * 100)

cat("Participant-level data summary:\n")
summary_counts <- participant_means %>% count(condition, has_ai_evaluation)
print(summary_counts)
cat("\n")

# Check for any NaN values
nan_check <- participant_means %>%
  filter(is.nan(mean_rejection_rate) | is.nan(mean_tendency))

cat("Participants with NaN values:", nrow(nan_check), "\n")
if(nrow(nan_check) > 0) {
  print(nan_check)
  cat("\n")
}

# Remove any participants with invalid data
participant_means_clean <- participant_means %>%
  filter(!is.nan(mean_rejection_rate), !is.nan(mean_tendency))

cat("Clean participant data:", nrow(participant_means_clean), "participants\n\n")

# ===== MAIN ANALYSIS: REJECTION RATES =====
cat("=== REJECTION RATES ANALYSIS ===\n")

# Calculate group means and SEs for rejection rates
rejection_summary <- participant_means_clean %>%
  group_by(condition, has_ai_evaluation) %>%
  summarise(
    n = n(),
    mean_rejection = mean(mean_rejection_rate, na.rm = TRUE),
    se_rejection = sd(mean_rejection_rate, na.rm = TRUE) / sqrt(n),
    .groups = "drop"
  ) %>%
  mutate(
    ai_label = ifelse(has_ai_evaluation, "AI-Exposed", "Non-AI-Exposed"),
    group = paste(condition, ai_label, sep = "_")
  )

print(rejection_summary)
cat("\n")

# 2x2 ANOVA for rejection rates - need to convert logical to factor
participant_means_clean <- participant_means_clean %>%
  mutate(
    condition_f = factor(condition),
    ai_exposed_f = factor(has_ai_evaluation, labels = c("Non-AI", "AI"))
  )

rejection_anova <- aov(mean_rejection_rate ~ condition_f * ai_exposed_f, data = participant_means_clean)
cat("2x2 ANOVA for Rejection Rates:\n")
print(summary(rejection_anova))
cat("\n")

# Post-hoc tests for rejection rates
rejection_emm <- emmeans(rejection_anova, ~ condition_f * ai_exposed_f)
cat("Estimated marginal means for rejection rates:\n")
print(rejection_emm)
cat("\n")

# Pairwise comparisons
cat("Pairwise comparisons for rejection rates:\n")
print(pairs(rejection_emm))
cat("\n")

# ===== MAIN ANALYSIS: TENDENCY SCORES =====
cat("=== TENDENCY SCORES ANALYSIS ===\n")

# Calculate group means and SEs for tendency scores
tendency_summary <- participant_means_clean %>%
  group_by(condition, has_ai_evaluation) %>%
  summarise(
    n = n(),
    mean_tendency = mean(mean_tendency, na.rm = TRUE),
    se_tendency = sd(mean_tendency, na.rm = TRUE) / sqrt(n),
    .groups = "drop"
  ) %>%
  mutate(
    ai_label = ifelse(has_ai_evaluation, "AI-Exposed", "Non-AI-Exposed"),
    group = paste(condition, ai_label, sep = "_")
  )

print(tendency_summary)
cat("\n")

# 2x2 ANOVA for tendency scores
tendency_anova <- aov(mean_tendency ~ condition_f * ai_exposed_f, data = participant_means_clean)
cat("2x2 ANOVA for Tendency Scores:\n")
print(summary(tendency_anova))
cat("\n")

# Post-hoc tests for tendency scores
tendency_emm <- emmeans(tendency_anova, ~ condition_f * ai_exposed_f)
cat("Estimated marginal means for tendency scores:\n")
print(tendency_emm)
cat("\n")

# Pairwise comparisons
cat("Pairwise comparisons for tendency scores:\n")
print(pairs(tendency_emm))
cat("\n")

# ===== EFFECT SIZES =====
cat("=== EFFECT SIZES ===\n")

# Calculate Cohen's d for main effects and interaction contrasts
calculate_cohens_d <- function(group1_data, group2_data) {
  m1 <- mean(group1_data, na.rm = TRUE)
  m2 <- mean(group2_data, na.rm = TRUE)
  s1 <- sd(group1_data, na.rm = TRUE)
  s2 <- sd(group2_data, na.rm = TRUE)
  n1 <- length(group1_data[!is.na(group1_data)])
  n2 <- length(group2_data[!is.na(group2_data)])
  
  pooled_sd <- sqrt(((n1-1)*s1^2 + (n2-1)*s2^2) / (n1+n2-2))
  cohens_d <- (m1 - m2) / pooled_sd
  return(cohens_d)
}

# Main effect of condition (UEQ vs UEEQ)
ueq_rejection <- participant_means_clean$mean_rejection_rate[participant_means_clean$condition == "UEQ"]
ueeq_rejection <- participant_means_clean$mean_rejection_rate[participant_means_clean$condition == "UEEQ"]
ueq_tendency <- participant_means_clean$mean_tendency[participant_means_clean$condition == "UEQ"]
ueeq_tendency <- participant_means_clean$mean_tendency[participant_means_clean$condition == "UEEQ"]

d_condition_rejection <- calculate_cohens_d(ueeq_rejection, ueq_rejection)
d_condition_tendency <- calculate_cohens_d(ueq_tendency, ueeq_tendency)

# Main effect of AI exposure
ai_rejection <- participant_means_clean$mean_rejection_rate[participant_means_clean$has_ai_evaluation == TRUE]
no_ai_rejection <- participant_means_clean$mean_rejection_rate[participant_means_clean$has_ai_evaluation == FALSE]
ai_tendency <- participant_means_clean$mean_tendency[participant_means_clean$has_ai_evaluation == TRUE]
no_ai_tendency <- participant_means_clean$mean_tendency[participant_means_clean$has_ai_evaluation == FALSE]

d_ai_rejection <- calculate_cohens_d(ai_rejection, no_ai_rejection)
d_ai_tendency <- calculate_cohens_d(ai_tendency, no_ai_tendency)

cat(sprintf("Cohen's d for UEQ vs UEEQ (rejection rates): %.3f\n", d_condition_rejection))
cat(sprintf("Cohen's d for UEQ vs UEEQ (tendency scores): %.3f\n", d_condition_tendency))
cat(sprintf("Cohen's d for AI vs Non-AI (rejection rates): %.3f\n", d_ai_rejection))
cat(sprintf("Cohen's d for AI vs Non-AI (tendency scores): %.3f\n", d_ai_tendency))
cat("\n")

# Save results for visualization
write.csv(participant_means_clean, "participant_means_2x2_fixed.csv", row.names = FALSE)
write.csv(rejection_summary, "rejection_summary_2x2_fixed.csv", row.names = FALSE)
write.csv(tendency_summary, "tendency_summary_2x2_fixed.csv", row.names = FALSE)

cat("=== SUMMARY ===\n")
cat("Fixed complete 2x2 between-subjects analysis completed.\n")
cat("Data files saved for visualization.\n")
cat("Check ANOVA results for main effects and interactions.\n")
