# Basic Visualizations for Updated Analysis
# Create clear, publication-ready plots

library(ggplot2)
library(dplyr)
library(tidyr)
library(gridExtra)

# Read the results
participant_data <- read.csv("results/participant_means_updated.csv")
interface_data <- read.csv("results/interface_plot_data_updated.csv")

cat("=== CREATING BASIC VISUALIZATIONS ===\n")

# Define consistent theme
theme_publication <- theme_minimal() +
  theme(
    text = element_text(size = 12),
    plot.title = element_text(size = 14, face = "bold"),
    axis.title = element_text(size = 12),
    legend.title = element_text(size = 11),
    legend.position = "bottom"
  )

# 1. 2x2 Design Summary Plot
cat("1. Creating 2x2 design summary plot...\n")

p1_rejection <- participant_data %>%
  group_by(condition_f, ai_exposed_f) %>%
  summarise(
    n = n(),
    mean_rejection = mean(mean_rejection_rate),
    se_rejection = sd(mean_rejection_rate) / sqrt(n),
    .groups = "drop"
  ) %>%
  ggplot(aes(x = condition_f, y = mean_rejection, fill = ai_exposed_f)) +
  geom_col(position = position_dodge(0.8), alpha = 0.8, width = 0.7) +
  geom_errorbar(aes(ymin = mean_rejection - se_rejection,
                    ymax = mean_rejection + se_rejection),
                position = position_dodge(0.8), width = 0.2) +
  geom_text(aes(label = paste0("n=", n)),
            position = position_dodge(0.8), 
            vjust = -0.5, size = 3) +
  scale_fill_manual(values = c("Non-AI" = "#3498db", "AI" = "#e74c3c"),
                    name = "Evaluation Data") +
  labs(x = "Evaluation Framework", 
       y = "Mean Interface Rejection Rate (%)",
       title = "Interface Rejection Rates: UEQ vs UEQ+Autonomy × AI Exposure") +
  theme_publication

p1_tendency <- participant_data %>%
  group_by(condition_f, ai_exposed_f) %>%
  summarise(
    n = n(),
    mean_tendency = mean(mean_tendency),
    se_tendency = sd(mean_tendency) / sqrt(n),
    .groups = "drop"
  ) %>%
  ggplot(aes(x = condition_f, y = mean_tendency, fill = ai_exposed_f)) +
  geom_col(position = position_dodge(0.8), alpha = 0.8, width = 0.7) +
  geom_errorbar(aes(ymin = mean_tendency - se_tendency,
                    ymax = mean_tendency + se_tendency),
                position = position_dodge(0.8), width = 0.2) +
  geom_text(aes(label = paste0("n=", n)),
            position = position_dodge(0.8), 
            vjust = -0.5, size = 3) +
  scale_fill_manual(values = c("Non-AI" = "#3498db", "AI" = "#e74c3c"),
                    name = "Evaluation Data") +
  labs(x = "Evaluation Framework", 
       y = "Mean Release Tendency Score (1-7)",
       title = "Release Tendency Scores: UEQ vs UEQ+Autonomy × AI Exposure") +
  theme_publication

# Combine the plots
combined_plot <- grid.arrange(p1_rejection, p1_tendency, ncol = 1)

ggsave("plots/updated_2x2_summary.png", combined_plot,
       width = 12, height = 10, dpi = 300)

cat("   Saved: plots/updated_2x2_summary.png\n")

# 2. Main Effects Plots
cat("2. Creating main effects plots...\n")

# UEQ vs UEQ+Autonomy main effect
p2 <- participant_data %>%
  group_by(condition_f) %>%
  summarise(
    n = n(),
    mean_rejection = mean(mean_rejection_rate),
    se_rejection = sd(mean_rejection_rate) / sqrt(n),
    mean_tendency = mean(mean_tendency),
    se_tendency = sd(mean_tendency) / sqrt(n),
    .groups = "drop"
  ) %>%
  pivot_longer(cols = c(mean_rejection, mean_tendency),
               names_to = "measure", values_to = "value") %>%
  mutate(
    se = ifelse(measure == "mean_rejection", se_rejection, se_tendency),
    measure_label = ifelse(measure == "mean_rejection", 
                          "Rejection Rate (%)", 
                          "Tendency Score (1-7)"),
    measure_factor = factor(measure_label, 
                           levels = c("Rejection Rate (%)", "Tendency Score (1-7)"))
  ) %>%
  ggplot(aes(x = condition_f, y = value, fill = condition_f)) +
  geom_col(alpha = 0.8, width = 0.6) +
  geom_errorbar(aes(ymin = value - se, ymax = value + se), width = 0.2) +
  geom_text(aes(label = paste0("n=", n)), vjust = -0.5, size = 3) +
  facet_wrap(~ measure_factor, scales = "free_y") +
  scale_fill_manual(values = c("UEQ" = "#2c3e50", "UEQ+Autonomy" = "#8e44ad")) +
  labs(x = "Evaluation Framework", y = "Mean Score",
       title = "Main Effect: UEQ vs UEQ+Autonomy") +
  theme_publication +
  theme(legend.position = "none")

ggsave("plots/main_effect_condition.png", p2,
       width = 12, height = 6, dpi = 300)

cat("   Saved: plots/main_effect_condition.png\n")

# AI exposure main effect
p3 <- participant_data %>%
  group_by(ai_exposed_f) %>%
  summarise(
    n = n(),
    mean_rejection = mean(mean_rejection_rate),
    se_rejection = sd(mean_rejection_rate) / sqrt(n),
    mean_tendency = mean(mean_tendency),
    se_tendency = sd(mean_tendency) / sqrt(n),
    .groups = "drop"
  ) %>%
  pivot_longer(cols = c(mean_rejection, mean_tendency),
               names_to = "measure", values_to = "value") %>%
  mutate(
    se = ifelse(measure == "mean_rejection", se_rejection, se_tendency),
    measure_label = ifelse(measure == "mean_rejection", 
                          "Rejection Rate (%)", 
                          "Tendency Score (1-7)"),
    measure_factor = factor(measure_label, 
                           levels = c("Rejection Rate (%)", "Tendency Score (1-7)"))
  ) %>%
  ggplot(aes(x = ai_exposed_f, y = value, fill = ai_exposed_f)) +
  geom_col(alpha = 0.8, width = 0.6) +
  geom_errorbar(aes(ymin = value - se, ymax = value + se), width = 0.2) +
  geom_text(aes(label = paste0("n=", n)), vjust = -0.5, size = 3) +
  facet_wrap(~ measure_factor, scales = "free_y") +
  scale_fill_manual(values = c("Non-AI" = "#3498db", "AI" = "#e74c3c")) +
  labs(x = "Evaluation Data Type", y = "Mean Score",
       title = "Main Effect: AI vs Non-AI Exposure") +
  theme_publication +
  theme(legend.position = "none")

ggsave("plots/main_effect_ai_exposure.png", p3,
       width = 12, height = 6, dpi = 300)

cat("   Saved: plots/main_effect_ai_exposure.png\n")

# 3. Interface-level distribution plot
cat("3. Creating interface-level distribution plot...\n")

p4 <- interface_data %>%
  ggplot(aes(x = tendency, fill = condition_f)) +
  geom_histogram(alpha = 0.7, bins = 7, position = "identity") +
  facet_wrap(~ condition_f) +
  scale_fill_manual(values = c("UEQ" = "#2c3e50", "UEQ+Autonomy" = "#8e44ad")) +
  labs(x = "Release Tendency Score (1-7)", 
       y = "Frequency",
       title = "Distribution of Interface-Level Tendency Scores") +
  theme_publication +
  theme(legend.position = "none")

ggsave("plots/interface_tendency_distribution.png", p4,
       width = 12, height = 6, dpi = 300)

cat("   Saved: plots/interface_tendency_distribution.png\n")

cat("\n=== SUMMARY OF UPDATED ANALYSIS ===\n")
cat("Sample Size: 65 participants (vs 44 in previous analysis)\n")
cat("Design: 2×2 Between-Subjects (UEQ/UEQ+Autonomy × AI-Exposed/Non-AI)\n\n")

cat("KEY FINDINGS:\n")
cat("• UEQ vs UEQ+Autonomy: NO significant differences\n")
cat("  - Rejection rates: p = 0.600, d = 0.131 (negligible effect)\n")
cat("  - Tendency scores: p = 0.251, d = 0.290 (small effect)\n\n")

cat("• AI Exposure: NO significant main effect (different from previous analysis)\n")
cat("  - Rejection rates: p = 0.456, d = -0.194 (small effect)\n") 
cat("  - Tendency scores: p = 0.311, d = 0.269 (small effect)\n\n")

cat("• Interaction: NO significant interaction effects\n")
cat("  - Both p > 0.35 for rejection rates and tendency scores\n\n")

cat("INTERPRETATION:\n")
cat("The larger sample size (65 vs 44) shows more conservative results.\n")
cat("The previously significant AI exposure effect is no longer significant,\n")
cat("suggesting the effect may have been inflated in the smaller sample.\n")
cat("Ethics-enhanced metrics (UEQ+Autonomy) still show no substantial impact.\n")

cat("\nPlots created:\n")
cat("• plots/updated_2x2_summary.png - Complete 2×2 factorial results\n")
cat("• plots/main_effect_condition.png - UEQ vs UEQ+Autonomy comparison\n")
cat("• plots/main_effect_ai_exposure.png - AI exposure effects\n")
cat("• plots/interface_tendency_distribution.png - Interface-level distributions\n")
