# Enhanced Statistical Plotting for UI Ethics Evaluation
# Using ggbetweenstatsWithPriorNormalityCheckAsterisk and ggwithinstatsWithPriorNormalityCheckAsterisk
# Interface-level comparisons between UEQ and UEQ+Autonomy conditions

# Load required libraries
library(readr)
library(dplyr)
library(ggplot2)
library(tidyr)

# Source the enhanced plotting functions
source("scripts/r_functionality.R")

cat("=== ENHANCED STATISTICAL PLOTTING ===\n")
cat("Interface-level comparisons: UEQ vs UEQ+Autonomy\n\n")

# Read the prepared data
interface_data <- read.csv("results/interface_plot_data_updated.csv")
participant_data <- read.csv("results/participant_means_updated.csv")

cat("Loaded interface data:", nrow(interface_data), "observations\n")
cat("Loaded participant data:", nrow(participant_data), "participants\n\n")

# ===============================
# INTERFACE-LEVEL BETWEEN-SUBJECTS PLOTS
# ===============================

cat("Creating interface-level between-subjects plots...\n")

# Prepare data for between-subjects interface analysis
# Each interface comparison between UEQ and UEQ+Autonomy conditions

# 1. Tendency Scores by Interface - Between Conditions
cat("1. Creating tendency scores comparison by interface...\n")

p1 <- ggbetweenstatsWithPriorNormalityCheckAsterisk(
  data = interface_data,
  x = "condition_f", 
  y = "tendency",
  ylab = "Release Tendency Score (1-7)",
  xlabels = c("UEQ", "UEQ+Autonomy"),
  plotType = "boxviolin"
)

# Save the plot
ggsave("plots/interface_tendency_between_conditions.png", p1, 
       width = 12, height = 8, dpi = 300)

cat("   Saved: plots/interface_tendency_between_conditions.png\n")

# 2. Rejection Rates by Interface - Between Conditions  
cat("2. Creating rejection rates comparison by interface...\n")

p2 <- ggbetweenstatsWithPriorNormalityCheckAsterisk(
  data = interface_data,
  x = "condition_f",
  y = "rejection_pct", 
  ylab = "Interface Rejection Rate (%)",
  xlabels = c("UEQ", "UEQ+Autonomy"),
  plotType = "boxviolin"
)

# Save the plot
ggsave("plots/interface_rejection_between_conditions.png", p2,
       width = 12, height = 8, dpi = 300)

cat("   Saved: plots/interface_rejection_between_conditions.png\n")

# ===============================
# PARTICIPANT-LEVEL BETWEEN-SUBJECTS PLOTS
# ===============================

cat("3. Creating participant-level tendency scores comparison...\n")

p3 <- ggbetweenstatsWithPriorNormalityCheckAsterisk(
  data = participant_data,
  x = "condition_f",
  y = "mean_tendency",
  ylab = "Mean Release Tendency Score (1-7)", 
  xlabels = c("UEQ", "UEQ+Autonomy"),
  plotType = "boxviolin"
)

ggsave("plots/participant_tendency_between_conditions.png", p3,
       width = 12, height = 8, dpi = 300)

cat("   Saved: plots/participant_tendency_between_conditions.png\n")

cat("4. Creating participant-level rejection rates comparison...\n")

p4 <- ggbetweenstatsWithPriorNormalityCheckAsterisk(
  data = participant_data,
  x = "condition_f",
  y = "mean_rejection_rate", 
  ylab = "Mean Interface Rejection Rate (%)",
  xlabels = c("UEQ", "UEQ+Autonomy"),
  plotType = "boxviolin"
)

ggsave("plots/participant_rejection_between_conditions.png", p4,
       width = 12, height = 8, dpi = 300)

cat("   Saved: plots/participant_rejection_between_conditions.png\n")

# ===============================
# AI EXPOSURE EFFECTS
# ===============================

cat("5. Creating AI exposure effects plots...\n")

# AI exposure effect on tendency scores
p5 <- ggbetweenstatsWithPriorNormalityCheckAsterisk(
  data = participant_data,
  x = "ai_exposed_f",
  y = "mean_tendency",
  ylab = "Mean Release Tendency Score (1-7)",
  xlabels = c("Non-AI Exposed", "AI Exposed"), 
  plotType = "boxviolin"
)

ggsave("plots/ai_exposure_tendency_effect.png", p5,
       width = 12, height = 8, dpi = 300)

cat("   Saved: plots/ai_exposure_tendency_effect.png\n")

# AI exposure effect on rejection rates
p6 <- ggbetweenstatsWithPriorNormalityCheckAsterisk(
  data = participant_data,
  x = "ai_exposed_f", 
  y = "mean_rejection_rate",
  ylab = "Mean Interface Rejection Rate (%)",
  xlabels = c("Non-AI Exposed", "AI Exposed"),
  plotType = "boxviolin"
)

ggsave("plots/ai_exposure_rejection_effect.png", p6,
       width = 12, height = 8, dpi = 300)

cat("   Saved: plots/ai_exposure_rejection_effect.png\n")

# ===============================
# INTERFACE-SPECIFIC ANALYSES
# ===============================

cat("6. Creating interface-specific comparisons...\n")

# Get interfaces that appear in both conditions for fair comparison
interface_counts <- interface_data %>%
  count(interface_num, condition_f) %>%
  count(interface_num) %>%
  filter(n == 2)  # Interfaces that appear in both conditions

common_interfaces <- interface_counts$interface_num

if(length(common_interfaces) > 0) {
  # Filter to common interfaces only
  common_interface_data <- interface_data %>%
    filter(interface_num %in% common_interfaces)
  
  cat("   Found", length(common_interfaces), "interfaces common to both conditions\n")
  
  # Create faceted plot for common interfaces
  p7 <- common_interface_data %>%
    filter(interface_num %in% common_interfaces[1:min(9, length(common_interfaces))]) %>%  # Limit to first 9 for clarity
    ggplot(aes(x = condition_f, y = tendency)) +
    geom_boxplot(aes(fill = condition_f), alpha = 0.7) +
    geom_jitter(width = 0.2, alpha = 0.6) +
    facet_wrap(~ paste("Interface", interface_num), scales = "free_y") +
    scale_fill_manual(values = c("UEQ" = "#3498db", "UEQ+Autonomy" = "#e74c3c")) +
    theme_minimal() +
    theme(legend.position = "bottom",
          axis.text.x = element_text(angle = 45, hjust = 1)) +
    labs(x = "Evaluation Framework", 
         y = "Release Tendency Score (1-7)",
         title = "Interface-Specific Tendency Scores: UEQ vs UEQ+Autonomy",
         fill = "Framework")
  
  ggsave("plots/interface_specific_tendency_comparison.png", p7,
         width = 15, height = 10, dpi = 300)
  
  cat("   Saved: plots/interface_specific_tendency_comparison.png\n")
} else {
  cat("   No common interfaces found between conditions\n")
}

# ===============================
# SUMMARY STATISTICS
# ===============================

cat("\n=== SUMMARY STATISTICS ===\n")

# Condition summary
condition_summary <- participant_data %>%
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
ai_summary <- participant_data %>%
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
interaction_summary <- participant_data %>%
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

cat("=== ENHANCED PLOTTING COMPLETE ===\n")
cat("All plots saved to plots/ directory\n")
cat("Summary statistics exported above\n")
cat("\nKey files created:\n")
cat("• plots/interface_tendency_between_conditions.png\n")
cat("• plots/interface_rejection_between_conditions.png\n") 
cat("• plots/participant_tendency_between_conditions.png\n")
cat("• plots/participant_rejection_between_conditions.png\n")
cat("• plots/ai_exposure_tendency_effect.png\n")
cat("• plots/ai_exposure_rejection_effect.png\n")
if(length(common_interfaces) > 0) {
  cat("• plots/interface_specific_tendency_comparison.png\n")
}
