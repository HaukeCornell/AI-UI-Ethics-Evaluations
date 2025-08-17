# Complete UI Ethics Evaluation Analysis - Updated Dataset
# Analysis with UEQ vs UEQ+Autonomy and AI exposure effects
# Using enhanced statistical plotting functions

# Load required libraries
library(readr)
library(dplyr)
library(ggplot2)
library(tidyr)
library(emmeans)
library(lme4)

# Source the enhanced plotting functions
source("scripts/r_functionality.R")

cat("=== UI ETHICS EVALUATION ANALYSIS - UPDATED DATASET ===\n")
cat("Comparing UEQ vs UEQ+Autonomy with AI exposure effects\n")
cat("Using enhanced statistical visualization\n\n")

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
# PREPARE DATA FOR INTERFACE-LEVEL PLOTTING
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
cat("Interfaces range:", min(interface_plot_data$interface_num), "to", max(interface_plot_data$interface_num), "\n\n")

# Save all results
write.csv(participant_means_clean, "results/participant_means_updated.csv", row.names = FALSE)
write.csv(interface_plot_data, "results/interface_plot_data_updated.csv", row.names = FALSE)

cat("=== DATA PREPARATION COMPLETE ===\n")
cat("Participant-level data saved to: results/participant_means_updated.csv\n")
cat("Interface-level data saved to: results/interface_plot_data_updated.csv\n")
cat("Ready for enhanced statistical plotting...\n")
