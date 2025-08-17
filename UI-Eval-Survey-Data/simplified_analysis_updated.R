# Simplified Complete Analysis - Updated Dataset
# Analysis with UEQ vs UEQ+Autonomy and AI exposure effects

# Load required libraries
library(readr)
library(dplyr)
library(ggplot2)
library(tidyr)
library(emmeans)
library(lme4)

cat("=== UI ETHICS EVALUATION ANALYSIS - UPDATED DATASET ===\n")
cat("Comparing UEQ vs UEQ+Autonomy with AI exposure effects\n\n")

# Read the updated UTF-8 converted data
data <- read_tsv("survey_data_updated.tsv", show_col_types = FALSE)

cat("Raw data dimensions:", nrow(data), "x", ncol(data), "\n")

# Filter to completed responses only
completed_data <- data %>% 
  filter(Progress == 100) %>%
  filter(!is.na(`1_UEQ Tendency_1`) | !is.na(`1_UEEQ Tendency_1`))

cat("Completed responses:", nrow(completed_data), "\n\n")

# Create AI evaluation indicator
completed_data <- completed_data %>%
  mutate(
    has_ai_evaluation = case_when(
      is.na(`Evaluation Data`) ~ NA,
      grepl("Combined AI-human evaluation", `Evaluation Data`, ignore.case = TRUE) ~ TRUE,
      TRUE ~ FALSE
    )
  )

# Determine condition assignment - using UEQ+Autonomy label
completed_data <- completed_data %>%
  mutate(
    has_ueq = !is.na(`1_UEQ Tendency_1`),
    has_ueeq = !is.na(`1_UEEQ Tendency_1`),
    condition = case_when(
      has_ueq & !has_ueeq ~ "UEQ",
      !has_ueq & has_ueeq ~ "UEQ+Autonomy",  # Changed from UEEQ
      has_ueq & has_ueeq ~ "Mixed",
      TRUE ~ "Neither"
    )
  )

# Filter to valid conditions only
analysis_data <- completed_data %>%
  filter(condition %in% c("UEQ", "UEQ+Autonomy"), !is.na(has_ai_evaluation))

cat("Final analysis sample:", nrow(analysis_data), "participants\n")

# Create design summary
design_summary <- analysis_data %>%
  count(condition, has_ai_evaluation) %>%
  pivot_wider(names_from = has_ai_evaluation, values_from = n, names_prefix = "AI_") %>%
  mutate(Total = AI_FALSE + AI_TRUE)

cat("\nDesign Summary (2x2):\n")
print(design_summary)
cat("\n")

# ===============================
# PARTICIPANT-LEVEL AGGREGATION
# ===============================

# Collect UEQ interfaces
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
      release == "No" ~ 1,
      release == "Yes" ~ 0,
      TRUE ~ NA_real_
    )
  )

# Collect UEQ+Autonomy interfaces  
ueeq_interfaces <- analysis_data %>%
  filter(condition == "UEQ+Autonomy") %>%
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
      release == "No" ~ 1,
      release == "Yes" ~ 0,
      TRUE ~ NA_real_
    )
  )

# Combine interface data
all_interfaces <- bind_rows(ueq_interfaces, ueeq_interfaces)

# Calculate participant-level means
participant_means <- all_interfaces %>%
  group_by(ResponseId, condition, has_ai_evaluation) %>%
  summarise(
    mean_rejection_rate = mean(rejected, na.rm = TRUE) * 100,
    mean_tendency = mean(tendency, na.rm = TRUE),
    n_interfaces = n(),
    .groups = "drop"
  )

# Clean data
participant_means_clean <- participant_means %>%
  filter(!is.nan(mean_rejection_rate), !is.nan(mean_tendency)) %>%
  mutate(
    condition_f = factor(condition, levels = c("UEQ", "UEQ+Autonomy")),
    ai_exposed_f = factor(has_ai_evaluation, labels = c("Non-AI", "AI"))
  )

cat("Clean participant data:", nrow(participant_means_clean), "participants\n\n")

# ===============================
# STATISTICAL ANALYSIS
# ===============================

cat("=== 2x2 ANOVA RESULTS ===\n")

# Rejection rates analysis
rejection_anova <- aov(mean_rejection_rate ~ condition_f * ai_exposed_f, data = participant_means_clean)
cat("REJECTION RATES:\n")
print(summary(rejection_anova))
cat("\n")

# Tendency scores analysis
tendency_anova <- aov(mean_tendency ~ condition_f * ai_exposed_f, data = participant_means_clean)
cat("TENDENCY SCORES:\n")
print(summary(tendency_anova))
cat("\n")

# ===============================
# EFFECT SIZES
# ===============================

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

# Main effect of condition (UEQ vs UEQ+Autonomy)
ueq_rejection <- participant_means_clean$mean_rejection_rate[participant_means_clean$condition == "UEQ"]
ueeq_rejection <- participant_means_clean$mean_rejection_rate[participant_means_clean$condition == "UEQ+Autonomy"]
ueq_tendency <- participant_means_clean$mean_tendency[participant_means_clean$condition == "UEQ"]
ueeq_tendency <- participant_means_clean$mean_tendency[participant_means_clean$condition == "UEQ+Autonomy"]

d_condition_rejection <- calculate_cohens_d(ueeq_rejection, ueq_rejection)
d_condition_tendency <- calculate_cohens_d(ueq_tendency, ueeq_tendency)

# Main effect of AI exposure
ai_rejection <- participant_means_clean$mean_rejection_rate[participant_means_clean$has_ai_evaluation == TRUE]
no_ai_rejection <- participant_means_clean$mean_rejection_rate[participant_means_clean$has_ai_evaluation == FALSE]
ai_tendency <- participant_means_clean$mean_tendency[participant_means_clean$has_ai_evaluation == TRUE]
no_ai_tendency <- participant_means_clean$mean_tendency[participant_means_clean$has_ai_evaluation == FALSE]

d_ai_rejection <- calculate_cohens_d(ai_rejection, no_ai_rejection)
d_ai_tendency <- calculate_cohens_d(ai_tendency, no_ai_tendency)

cat("=== EFFECT SIZES ===\n")
cat(sprintf("Cohen's d for UEQ vs UEQ+Autonomy (rejection rates): %.3f\n", d_condition_rejection))
cat(sprintf("Cohen's d for UEQ vs UEQ+Autonomy (tendency scores): %.3f\n", d_condition_tendency))
cat(sprintf("Cohen's d for AI vs Non-AI (rejection rates): %.3f\n", d_ai_rejection))
cat(sprintf("Cohen's d for AI vs Non-AI (tendency scores): %.3f\n", d_ai_tendency))
cat("\n")

# ===============================
# SUMMARY STATISTICS
# ===============================

cat("=== SUMMARY STATISTICS ===\n")

# Condition summary
condition_summary <- participant_means_clean %>%
  group_by(condition_f) %>%
  summarise(
    n = n(),
    mean_tendency = round(mean(mean_tendency), 2),
    sd_tendency = round(sd(mean_tendency), 2),
    mean_rejection = round(mean(mean_rejection_rate), 1),
    sd_rejection = round(sd(mean_rejection_rate), 1),
    .groups = "drop"
  )

cat("CONDITION COMPARISON:\n")
print(condition_summary)
cat("\n")

# AI exposure summary
ai_summary <- participant_means_clean %>%
  group_by(ai_exposed_f) %>%
  summarise(
    n = n(),
    mean_tendency = round(mean(mean_tendency), 2),
    sd_tendency = round(sd(mean_tendency), 2), 
    mean_rejection = round(mean(mean_rejection_rate), 1),
    sd_rejection = round(sd(mean_rejection_rate), 1),
    .groups = "drop"
  )

cat("AI EXPOSURE COMPARISON:\n")
print(ai_summary)
cat("\n")

# 2x2 interaction summary
interaction_summary <- participant_means_clean %>%
  group_by(condition_f, ai_exposed_f) %>%
  summarise(
    n = n(),
    mean_tendency = round(mean(mean_tendency), 2),
    mean_rejection = round(mean(mean_rejection_rate), 1),
    .groups = "drop"
  )

cat("2x2 INTERACTION SUMMARY:\n")
print(interaction_summary)
cat("\n")

# ===============================
# PREPARE DATA FOR PLOTTING
# ===============================

# Create interface-level data for plotting
interface_plot_data <- all_interfaces %>%
  filter(!is.na(tendency), !is.na(rejected)) %>%
  mutate(
    condition_f = factor(condition, levels = c("UEQ", "UEQ+Autonomy")),
    interface_num = as.numeric(interface),
    rejection_pct = rejected * 100
  )

cat("Interface-level data prepared:", nrow(interface_plot_data), "observations\n")

# Save all results
write.csv(participant_means_clean, "results/participant_means_updated.csv", row.names = FALSE)
write.csv(interface_plot_data, "results/interface_plot_data_updated.csv", row.names = FALSE)

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Participant-level data saved to: results/participant_means_updated.csv\n")
cat("Interface-level data saved to: results/interface_plot_data_updated.csv\n")
