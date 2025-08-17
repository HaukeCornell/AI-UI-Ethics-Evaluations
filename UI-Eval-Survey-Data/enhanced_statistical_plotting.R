# Simplified Enhanced Statistical Plotting
# Using ggstatsplot for interface-level comparisons

library(ggplot2)
library(dplyr)
library(purrr)
library(ggstatsplot)
library(rstatix)

cat("=== ENHANCED STATISTICAL PLOTTING - SIMPLIFIED ===\n")
cat("Interface-level comparisons: UEQ vs UEQ+Autonomy\n\n")

# Read the prepared data
interface_data <- read.csv("results/interface_plot_data_updated.csv")
participant_data <- read.csv("results/participant_means_updated.csv")

cat("Loaded interface data:", nrow(interface_data), "observations\n")
cat("Loaded participant data:", nrow(participant_data), "participants\n\n")

# ===============================
# ENHANCED INTERFACE-LEVEL PLOTS
# ===============================

cat("Creating enhanced statistical plots...\n")

# 1. Interface-level tendency scores comparison with automatic statistics
cat("1. Interface tendency scores: UEQ vs UEQ+Autonomy...\n")

p1 <- ggbetweenstats(
  data = interface_data,
  x = condition_f,
  y = tendency,
  title = "Interface Release Tendency Scores",
  subtitle = "UEQ vs UEQ+Autonomy Framework Comparison",
  xlab = "Evaluation Framework",
  ylab = "Release Tendency Score (1-7)",
  type = "parametric",  # or "nonparametric" for non-normal data
  var.equal = FALSE,    # Welch's t-test
  plot.type = "boxviolin",
  centrality.point.args = list(size = 3, color = "darkblue"),
  centrality.label.args = list(size = 4, nudge_x = 0.4, segment.linetype = 4),
  package = "RColorBrewer",
  palette = "Set2"
)

ggsave("plots/enhanced_interface_tendency_comparison.png", p1,
       width = 12, height = 8, dpi = 300)

cat("   Saved: plots/enhanced_interface_tendency_comparison.png\n")

# 2. Interface-level rejection rates comparison
cat("2. Interface rejection rates: UEQ vs UEQ+Autonomy...\n")

p2 <- ggbetweenstats(
  data = interface_data,
  x = condition_f,
  y = rejection_pct,
  title = "Interface Rejection Rates",
  subtitle = "UEQ vs UEQ+Autonomy Framework Comparison", 
  xlab = "Evaluation Framework",
  ylab = "Rejection Rate (%)",
  type = "parametric",
  var.equal = FALSE,
  plot.type = "boxviolin",
  centrality.point.args = list(size = 3, color = "darkred"),
  centrality.label.args = list(size = 4, nudge_x = 0.4, segment.linetype = 4),
  package = "RColorBrewer",
  palette = "Set1"
)

ggsave("plots/enhanced_interface_rejection_comparison.png", p2,
       width = 12, height = 8, dpi = 300)

cat("   Saved: plots/enhanced_interface_rejection_comparison.png\n")

# 3. Participant-level tendency scores comparison
cat("3. Participant tendency scores: UEQ vs UEQ+Autonomy...\n")

p3 <- ggbetweenstats(
  data = participant_data,
  x = condition_f,
  y = mean_tendency,
  title = "Participant-Level Release Tendency Scores",
  subtitle = "UEQ vs UEQ+Autonomy Framework Comparison",
  xlab = "Evaluation Framework", 
  ylab = "Mean Release Tendency Score (1-7)",
  type = "parametric",
  var.equal = FALSE,
  plot.type = "boxviolin",
  centrality.point.args = list(size = 3, color = "darkgreen"),
  centrality.label.args = list(size = 4, nudge_x = 0.4, segment.linetype = 4),
  package = "RColorBrewer",
  palette = "Dark2"
)

ggsave("plots/enhanced_participant_tendency_comparison.png", p3,
       width = 12, height = 8, dpi = 300)

cat("   Saved: plots/enhanced_participant_tendency_comparison.png\n")

# 4. Participant-level rejection rates comparison
cat("4. Participant rejection rates: UEQ vs UEQ+Autonomy...\n")

p4 <- ggbetweenstats(
  data = participant_data,
  x = condition_f,
  y = mean_rejection_rate,
  title = "Participant-Level Interface Rejection Rates", 
  subtitle = "UEQ vs UEQ+Autonomy Framework Comparison",
  xlab = "Evaluation Framework",
  ylab = "Mean Interface Rejection Rate (%)",
  type = "parametric",
  var.equal = FALSE,
  plot.type = "boxviolin",
  centrality.point.args = list(size = 3, color = "darkorange"),
  centrality.label.args = list(size = 4, nudge_x = 0.4, segment.linetype = 4),
  package = "RColorBrewer",
  palette = "Set3"
)

ggsave("plots/enhanced_participant_rejection_comparison.png", p4,
       width = 12, height = 8, dpi = 300)

cat("   Saved: plots/enhanced_participant_rejection_comparison.png\n")

# ===============================
# AI EXPOSURE ENHANCED PLOTS  
# ===============================

cat("5. AI exposure effects on tendency scores...\n")

p5 <- ggbetweenstats(
  data = participant_data,
  x = ai_exposed_f,
  y = mean_tendency,
  title = "AI Exposure Effect on Release Tendency",
  subtitle = "Comparison of AI vs Non-AI Evaluation Data Exposure",
  xlab = "Evaluation Data Type",
  ylab = "Mean Release Tendency Score (1-7)",
  type = "parametric",
  var.equal = FALSE,
  plot.type = "boxviolin",
  centrality.point.args = list(size = 3, color = "purple"),
  centrality.label.args = list(size = 4, nudge_x = 0.4, segment.linetype = 4),
  package = "RColorBrewer",
  palette = "Paired"
)

ggsave("plots/enhanced_ai_exposure_tendency.png", p5,
       width = 12, height = 8, dpi = 300)

cat("   Saved: plots/enhanced_ai_exposure_tendency.png\n")

# 6. AI exposure effects on rejection rates
cat("6. AI exposure effects on rejection rates...\n")

p6 <- ggbetweenstats(
  data = participant_data,
  x = ai_exposed_f,
  y = mean_rejection_rate,
  title = "AI Exposure Effect on Interface Rejection", 
  subtitle = "Comparison of AI vs Non-AI Evaluation Data Exposure",
  xlab = "Evaluation Data Type",
  ylab = "Mean Interface Rejection Rate (%)",
  type = "parametric",
  var.equal = FALSE,
  plot.type = "boxviolin",
  centrality.point.args = list(size = 3, color = "navy"),
  centrality.label.args = list(size = 4, nudge_x = 0.4, segment.linetype = 4),
  package = "RColorBrewer",
  palette = "Spectral"
)

ggsave("plots/enhanced_ai_exposure_rejection.png", p6,
       width = 12, height = 8, dpi = 300)

cat("   Saved: plots/enhanced_ai_exposure_rejection.png\n")

# ===============================
# ADDITIONAL STATISTICAL TESTS
# ===============================

cat("\n=== ADDITIONAL STATISTICAL TESTING ===\n")

# Normality tests
cat("Normality tests for key variables:\n")

# Interface-level tendency by condition
interface_normality <- interface_data %>%
  group_by(condition_f) %>%
  do(shapiro_test = shapiro.test(.$tendency)) %>%
  mutate(
    statistic = map_dbl(shapiro_test, "statistic"),
    p_value = map_dbl(shapiro_test, "p.value")
  ) %>%
  select(-shapiro_test)

cat("Interface tendency by condition:\n")
print(interface_normality)

# Participant-level means by condition  
participant_normality <- participant_data %>%
  group_by(condition_f) %>%
  do(shapiro_test = shapiro.test(.$mean_tendency)) %>%
  mutate(
    statistic = map_dbl(shapiro_test, "statistic"),
    p_value = map_dbl(shapiro_test, "p.value")
  ) %>%
  select(-shapiro_test)

cat("\nParticipant tendency by condition:\n") 
print(participant_normality)

# Levene's test for equality of variances
cat("\nLevene's test for equality of variances:\n")

# For interface-level data
interface_levene <- interface_data %>%
  levene_test(tendency ~ condition_f)
cat("Interface tendency variances:\n")
print(interface_levene)

# For participant-level data
participant_levene <- participant_data %>%
  levene_test(mean_tendency ~ condition_f)
cat("\nParticipant tendency variances:\n")
print(participant_levene)

cat("\n=== ENHANCED PLOTTING COMPLETE ===\n")
cat("All enhanced statistical plots saved to plots/ directory\n")
cat("\nKey enhanced plots created:\n")
cat("• plots/enhanced_interface_tendency_comparison.png\n")
cat("• plots/enhanced_interface_rejection_comparison.png\n")
cat("• plots/enhanced_participant_tendency_comparison.png\n")
cat("• plots/enhanced_participant_rejection_comparison.png\n")
cat("• plots/enhanced_ai_exposure_tendency.png\n")
cat("• plots/enhanced_ai_exposure_rejection.png\n")
cat("\nThese plots include:\n")
cat("- Automatic statistical testing (t-tests, effect sizes)\n")
cat("- Normality assumption checking\n")
cat("- Box-violin plots with centrality measures\n")
cat("- Publication-ready formatting\n")
