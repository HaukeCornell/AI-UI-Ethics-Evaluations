# UEQ vs UEEQ Interface Rejection Analysis
# Comprehensive statistical analysis comparing rejection rates and tendencies
# between UEQ (standard metrics) and UEEQ (ethics-enhanced metrics)

# Load required libraries and helper functions
# Install missing packages first
if (!require("usethis")) install.packages("usethis")
if (!require("tidyverse")) install.packages("tidyverse")

source("r_functionality.R")

library(tidyverse)
library(readr)
library(rstatix)
library(ggplot2)
library(dplyr)
library(afex)
library(emmeans)
library(psych)

# ==============================================================================
# 1. DATA LOADING AND PREPROCESSING
# ==============================================================================

# Load the data
cat("Loading data...\n")
data_raw <- read_tsv("UX+Metrics+Design+Decision+Impact_August+16%2C+2025_12.15.tsv", 
                     locale = locale(encoding = "UTF-8"))

# Check data dimensions
cat("Data dimensions:", dim(data_raw), "\n")
cat("Total responses:", nrow(data_raw) - 2, "\n")  # Subtract header rows

# Remove header rows (first 2 rows are metadata)
data_clean <- data_raw[-c(1:2), ]

# ==============================================================================
# 2. DATA RESTRUCTURING AND ANALYSIS DECISIONS
# ==============================================================================

cat("\n=== ANALYSIS DECISION POINT ===\n")
cat("We need to decide our unit of analysis:\n")
cat("1. Interface-level: Aggregate across participants for each interface\n")
cat("2. Participant-level: Compare UEQ vs UEEQ within each participant\n")
cat("3. Response-level: Each individual response as a data point\n")
cat("\nFor statistical power and ecological validity, we'll analyze at response-level\n")
cat("with appropriate mixed-effects modeling to account for participant clustering.\n\n")

# Extract UEQ and UEEQ columns for all interfaces (1-15)
interfaces <- 1:15

# Create long format data for analysis
data_long <- data.frame()

for (i in interfaces) {
  # UEQ data
  ueq_cols <- data_clean %>%
    select(ResponseId = ResponseId,
           starts_with(paste0(i, "_UEQ"))) %>%
    mutate(interface = i,
           metric_type = "UEQ",
           participant_id = ResponseId) %>%
    rename_with(~gsub(paste0("^", i, "_UEQ "), "", .), starts_with(paste0(i, "_UEQ")))
  
  # UEEQ data  
  ueeq_cols <- data_clean %>%
    select(ResponseId = ResponseId,
           starts_with(paste0(i, "_UEEQ"))) %>%
    mutate(interface = i,
           metric_type = "UEEQ",
           participant_id = ResponseId) %>%
    rename_with(~gsub(paste0("^", i, "_UEEQ "), "", .), starts_with(paste0(i, "_UEEQ")))
  
  # Combine and add to long data
  interface_data <- bind_rows(ueq_cols, ueeq_cols)
  data_long <- bind_rows(data_long, interface_data)
}

# Clean column names and convert data types
data_long <- data_long %>%
  mutate(
    tendency = as.numeric(`Tendency_1`),
    release = case_when(
      Release == "Yes" ~ 1,
      Release == "No" ~ 0,
      TRUE ~ NA_real_
    ),
    confidence = as.numeric(`Confidence_4`),
    interface = as.factor(interface),
    metric_type = as.factor(metric_type),
    participant_id = as.factor(participant_id)
  ) %>%
  filter(!is.na(tendency), !is.na(release)) %>%  # Remove missing responses
  select(participant_id, interface, metric_type, tendency, release, confidence, Explanation)

# ==============================================================================
# 3. DESCRIPTIVE STATISTICS
# ==============================================================================

cat("=== DESCRIPTIVE STATISTICS ===\n")

# Overall summary
overall_summary <- data_long %>%
  group_by(metric_type) %>%
  summarise(
    n_responses = n(),
    n_participants = n_distinct(participant_id),
    n_interfaces = n_distinct(interface),
    
    # Rejection rates (Release = No)
    rejection_rate = mean(release == 0, na.rm = TRUE),
    rejection_se = sqrt(rejection_rate * (1 - rejection_rate) / n()),
    
    # Tendency scores
    tendency_mean = mean(tendency, na.rm = TRUE),
    tendency_sd = sd(tendency, na.rm = TRUE),
    tendency_median = median(tendency, na.rm = TRUE),
    
    # Confidence
    confidence_mean = mean(confidence, na.rm = TRUE),
    confidence_sd = sd(confidence, na.rm = TRUE),
    
    .groups = 'drop'
  )

print(overall_summary)

# Interface-level summary
interface_summary <- data_long %>%
  group_by(interface, metric_type) %>%
  summarise(
    n_responses = n(),
    rejection_rate = mean(release == 0, na.rm = TRUE),
    tendency_mean = mean(tendency, na.rm = TRUE),
    tendency_sd = sd(tendency, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  pivot_wider(names_from = metric_type, 
              values_from = c(rejection_rate, tendency_mean, tendency_sd),
              names_sep = "_")

print("Interface-level comparison:")
print(interface_summary)

# ==============================================================================
# 4. ASSUMPTION CHECKS
# ==============================================================================

cat("\n=== ASSUMPTION CHECKS ===\n")

# Check for data completeness
data_completeness <- data_long %>%
  group_by(metric_type) %>%
  summarise(
    total_possible = n_distinct(participant_id) * n_distinct(interface),
    actual_responses = n(),
    completion_rate = actual_responses / total_possible,
    .groups = 'drop'
  )

cat("Data completeness:\n")
print(data_completeness)

# Check distribution of tendency scores
cat("\nDistribution of tendency scores by metric type:\n")
tendency_dist <- data_long %>%
  group_by(metric_type) %>%
  rstatix::get_summary_stats(tendency, type = "full")
print(tendency_dist)

# Normality tests for tendency scores
cat("\nNormality tests for tendency scores:\n")
normality_tests <- data_long %>%
  group_by(metric_type) %>%
  rstatix::shapiro_test(tendency)
print(normality_tests)

# Check for outliers
outliers <- data_long %>%
  group_by(metric_type) %>%
  rstatix::identify_outliers(tendency)

cat("\nOutliers detected:\n")
print(table(outliers$is.outlier, outliers$metric_type))

# ==============================================================================
# 5. PRIMARY ANALYSIS: REJECTION RATES
# ==============================================================================

cat("\n=== PRIMARY ANALYSIS: REJECTION RATES ===\n")

# For binary outcomes (rejection), we'll use generalized linear mixed models
# with participant as random effect

# Load lme4 for mixed models
if (!require("lme4")) install.packages("lme4")
library(lme4)

# Model 1: Rejection rate comparison
cat("Model 1: Comparing rejection rates between UEQ and UEEQ\n")

# Fit logistic mixed model
rejection_model <- glmer(release ~ metric_type + (1|participant_id) + (1|interface),
                        data = data_long,
                        family = binomial(link = "logit"),
                        control = glmerControl(optimizer = "bobyqa"))

# Model summary
cat("Logistic mixed model results:\n")
summary(rejection_model)

# Calculate effect size and confidence intervals
rejection_emmeans <- emmeans(rejection_model, ~ metric_type, type = "response")
rejection_contrasts <- contrast(rejection_emmeans, method = "pairwise")

cat("\nEstimated marginal means (probabilities):\n")
print(rejection_emmeans)

cat("\nPairwise contrasts:\n")
print(rejection_contrasts)

# ==============================================================================
# 6. SECONDARY ANALYSIS: TENDENCY SCORES
# ==============================================================================

cat("\n=== SECONDARY ANALYSIS: TENDENCY SCORES ===\n")

# For continuous tendency scores, use linear mixed models
tendency_model <- lmer(tendency ~ metric_type + (1|participant_id) + (1|interface),
                      data = data_long)

cat("Linear mixed model results for tendency scores:\n")
summary(tendency_model)

# Emmeans for tendency
tendency_emmeans <- emmeans(tendency_model, ~ metric_type)
tendency_contrasts <- contrast(tendency_emmeans, method = "pairwise")

cat("\nEstimated marginal means for tendency:\n")
print(tendency_emmeans)

cat("\nPairwise contrasts for tendency:\n")
print(tendency_contrasts)

# Effect size calculation (Cohen's d)
tendency_effect_size <- data_long %>%
  rstatix::cohens_d(tendency ~ metric_type, paired = FALSE)

cat("\nEffect size (Cohen's d) for tendency:\n")
print(tendency_effect_size)

# ==============================================================================
# 7. VISUALIZATION
# ==============================================================================

cat("\n=== CREATING VISUALIZATIONS ===\n")

# Visualization 1: Rejection rates by metric type
p1 <- data_long %>%
  group_by(metric_type) %>%
  summarise(rejection_rate = mean(release == 0, na.rm = TRUE),
            se = sqrt(rejection_rate * (1 - rejection_rate) / n()),
            .groups = 'drop') %>%
  ggplot(aes(x = metric_type, y = rejection_rate, fill = metric_type)) +
  geom_col(alpha = 0.7) +
  geom_errorbar(aes(ymin = rejection_rate - 1.96*se, 
                    ymax = rejection_rate + 1.96*se), 
                width = 0.2) +
  scale_y_continuous(labels = scales::percent_format(), limits = c(0, 1)) +
  labs(title = "Interface Rejection Rates by Metric Type",
       subtitle = "Error bars show 95% confidence intervals",
       x = "Metric Type",
       y = "Rejection Rate",
       fill = "Metric Type") +
  theme_minimal() +
  theme(legend.position = "none")

# Visualization 2: Tendency scores distribution
p2 <- ggplot(data_long, aes(x = metric_type, y = tendency, fill = metric_type)) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.3) +
  geom_point(position = position_jitter(width = 0.2), alpha = 0.1) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3, 
               fill = "white", color = "black") +
  labs(title = "Distribution of Tendency Scores by Metric Type",
       subtitle = "Diamond shows mean, box shows median and quartiles",
       x = "Metric Type",
       y = "Tendency Score",
       fill = "Metric Type") +
  theme_minimal() +
  theme(legend.position = "none")

# Visualization 3: Interface-level comparison
p3 <- interface_summary %>%
  select(interface, rejection_rate_UEQ, rejection_rate_UEEQ) %>%
  pivot_longer(cols = starts_with("rejection_rate"), 
               names_to = "metric_type", 
               values_to = "rejection_rate") %>%
  mutate(metric_type = gsub("rejection_rate_", "", metric_type)) %>%
  ggplot(aes(x = interface, y = rejection_rate, color = metric_type)) +
  geom_line(aes(group = metric_type), size = 1) +
  geom_point(size = 2) +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(title = "Rejection Rates by Interface and Metric Type",
       x = "Interface Number",
       y = "Rejection Rate",
       color = "Metric Type") +
  theme_minimal()

# Save plots
ggsave("rejection_rates_comparison.png", p1, width = 8, height = 6, dpi = 300)
ggsave("tendency_distribution.png", p2, width = 8, height = 6, dpi = 300)
ggsave("interface_rejection_trends.png", p3, width = 10, height = 6, dpi = 300)

# ==============================================================================
# 8. SUMMARY AND INTERPRETATION
# ==============================================================================

cat("\n=== ANALYSIS SUMMARY ===\n")

# Calculate key statistics for summary
ueq_rejection <- overall_summary$rejection_rate[overall_summary$metric_type == "UEQ"]
ueeq_rejection <- overall_summary$rejection_rate[overall_summary$metric_type == "UEEQ"]
rejection_diff <- ueeq_rejection - ueq_rejection

ueq_tendency <- overall_summary$tendency_mean[overall_summary$metric_type == "UEQ"]
ueeq_tendency <- overall_summary$tendency_mean[overall_summary$metric_type == "UEEQ"]
tendency_diff <- ueeq_tendency - ueq_tendency

cat("KEY FINDINGS:\n")
cat("=============\n")
cat(sprintf("UEQ rejection rate: %.2f%% (SE: %.3f)\n", 
            ueq_rejection * 100, 
            overall_summary$rejection_se[overall_summary$metric_type == "UEQ"]))
cat(sprintf("UEEQ rejection rate: %.2f%% (SE: %.3f)\n", 
            ueeq_rejection * 100,
            overall_summary$rejection_se[overall_summary$metric_type == "UEEQ"]))
cat(sprintf("Difference: %.2f percentage points\n", rejection_diff * 100))

cat(sprintf("\nUEQ tendency mean: %.2f (SD: %.2f)\n", 
            ueq_tendency, 
            overall_summary$tendency_sd[overall_summary$metric_type == "UEQ"]))
cat(sprintf("UEEQ tendency mean: %.2f (SD: %.2f)\n", 
            ueeq_tendency,
            overall_summary$tendency_sd[overall_summary$metric_type == "UEEQ"]))
cat(sprintf("Difference: %.2f points\n", tendency_diff))

cat("\nSTATISTICAL TESTS:\n")
cat("==================\n")
cat("Rejection rates: Mixed-effects logistic regression\n")
cat("Tendency scores: Mixed-effects linear regression\n")
cat("Random effects: Participant and Interface\n")

cat("\nDATA STRUCTURE:\n")
cat("===============\n")
cat(sprintf("Total responses: %d\n", nrow(data_long)))
cat(sprintf("Unique participants: %d\n", n_distinct(data_long$participant_id)))
cat(sprintf("Interfaces analyzed: %d\n", n_distinct(data_long$interface)))
cat(sprintf("Design: Within-subjects (each participant saw both UEQ and UEEQ)\n"))

cat("\nAnalysis complete. Check plots and model outputs above for detailed results.\n")
