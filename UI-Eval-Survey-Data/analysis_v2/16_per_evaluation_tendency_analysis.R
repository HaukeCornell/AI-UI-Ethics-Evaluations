# Alternative Analysis: Per-Evaluation Release Tendency Analysis 
# Since release tendency is continuous Likert scale data, analyze individual evaluations
# rather than participant-level aggregations

library(dplyr)
library(ggplot2)
library(lme4)
library(car)

cat("=== ALTERNATIVE ANALYSIS: PER-EVALUATION RELEASE TENDENCY ===\n")

# Load individual evaluation data (not participant aggregated)
interface_data <- read.csv("results/three_condition_interface_data.csv")

# Update condition names
interface_data$condition_new <- case_when(
  interface_data$condition == "RAW" ~ "UI",
  interface_data$condition == "UEQ" ~ "UEQ", 
  interface_data$condition == "UEQ+Autonomy" ~ "UEQ-A",
  TRUE ~ interface_data$condition
)

# Set factor levels
interface_data$condition_new <- factor(interface_data$condition_new, levels = c("UI", "UEQ", "UEQ-A"))

# Define consistent color scheme
condition_colors <- c("UI" = "#FF8888", "UEQ" = "#ABE2AB", "UEQ-A" = "#AE80FF")

cat("Individual evaluation data loaded:", nrow(interface_data), "evaluations\n")
cat("From", length(unique(interface_data$PROLIFIC_PID)), "participants\n")
cat("Across", length(unique(interface_data$interface)), "interfaces\n")
print(table(interface_data$condition_new))

# Remove missing tendency values
interface_data <- interface_data[!is.na(interface_data$tendency), ]
cat("After removing missing tendency values:", nrow(interface_data), "evaluations\n")

# 1. Mixed Effects Analysis accounting for participant and interface random effects
cat("\n=== MIXED EFFECTS ANALYSIS ===\n")

# Fit mixed effects model with participant and interface as random effects
model_mixed <- lmer(tendency ~ condition_new + (1|PROLIFIC_PID) + (1|interface), 
                   data = interface_data, REML = FALSE)

# ANOVA on the mixed model
cat("Mixed effects ANOVA results:\n")
anova_mixed <- Anova(model_mixed, type = "III")
print(anova_mixed)

# Extract model summary
summary_mixed <- summary(model_mixed)
print(summary_mixed)

# 2. Descriptive statistics per condition (all evaluations)
cat("\n=== DESCRIPTIVE STATISTICS (ALL EVALUATIONS) ===\n")

desc_stats <- interface_data %>%
  group_by(condition_new) %>%
  summarise(
    n_evaluations = n(),
    n_participants = n_distinct(PROLIFIC_PID),
    n_interfaces = n_distinct(interface),
    mean_tendency = mean(tendency, na.rm = TRUE),
    sd_tendency = sd(tendency, na.rm = TRUE),
    median_tendency = median(tendency, na.rm = TRUE),
    q25 = quantile(tendency, 0.25, na.rm = TRUE),
    q75 = quantile(tendency, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

print(desc_stats)

# 3. Visualization: Individual Evaluations Distribution
cat("\n=== CREATING PER-EVALUATION VISUALIZATION ===\n")

p_evaluations <- ggplot(interface_data, aes(x = condition_new, y = tendency, fill = condition_new)) +
  geom_violin(alpha = 0.6, trim = FALSE) +
  geom_jitter(width = 0.3, alpha = 0.3, size = 0.8, color = "black") +
  # Large visible mean
  stat_summary(fun = mean, geom = "point", shape = 18, size = 6, color = "white", stroke = 1.5) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 5, color = "black") +
  # Large visible median
  stat_summary(fun = median, geom = "point", shape = 95, size = 8, color = "white", stroke = 2) +
  stat_summary(fun = median, geom = "point", shape = 95, size = 7, color = "red") +
  scale_fill_manual(values = condition_colors, name = "Condition") +
  labs(
    title = "Release Tendency Distribution: All Individual Evaluations",
    subtitle = paste0("Mixed effects analysis of ", nrow(interface_data), " individual interface evaluations"),
    x = "Evaluation Condition",
    y = "Release Tendency (1-7 scale)",
    caption = "♦ = Mean (black diamond) • ▬ = Median (red line) • Points = Individual evaluations\nMixed effects model accounts for participant and interface random effects"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray50"),
    plot.caption = element_text(size = 10, hjust = 0.5, color = "gray50"),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text = element_text(size = 12),
    axis.text.x = element_text(size = 13, face = "bold"),
    legend.position = "none",
    panel.grid.minor.y = element_blank(),
    panel.grid.major.x = element_blank()
  ) +
  scale_y_continuous(limits = c(1, 7), breaks = 1:7)

# 4. Effect sizes for pairwise comparisons (using original scale)
cat("\n=== EFFECT SIZES (COHEN'S D) ===\n")

# Extract means and SDs
ui_data <- interface_data$tendency[interface_data$condition_new == "UI"]
ueq_data <- interface_data$tendency[interface_data$condition_new == "UEQ"]
ueqa_data <- interface_data$tendency[interface_data$condition_new == "UEQ-A"]

# Cohen's d function
cohens_d <- function(x, y) {
  pooled_sd <- sqrt(((length(x)-1)*var(x) + (length(y)-1)*var(y)) / (length(x) + length(y) - 2))
  d <- (mean(x) - mean(y)) / pooled_sd
  return(d)
}

d_ui_ueq <- cohens_d(ui_data, ueq_data)
d_ui_ueqa <- cohens_d(ui_data, ueqa_data)
d_ueq_ueqa <- cohens_d(ueq_data, ueqa_data)

cat(sprintf("UI vs UEQ: d = %.3f\n", d_ui_ueq))
cat(sprintf("UI vs UEQ-A: d = %.3f\n", d_ui_ueqa))
cat(sprintf("UEQ vs UEQ-A: d = %.3f\n", d_ueq_ueqa))

# Save plot
if(!dir.exists("plots")) dir.create("plots")

ggsave("plots/per_evaluation_tendency_analysis.png", p_evaluations, 
       width = 12, height = 8, dpi = 300)

# Save results to CSV
write.csv(desc_stats, "results/per_evaluation_descriptive_stats.csv", row.names = FALSE)

cat("\n✓ Per-evaluation analysis completed\n")
cat("✓ Plot saved: plots/per_evaluation_tendency_analysis.png\n")
cat("✓ Descriptive statistics saved: results/per_evaluation_descriptive_stats.csv\n")

# Summary for interpretation
cat("\n=== ANALYSIS SUMMARY ===\n")
cat("This alternative analysis treats each interface evaluation as an independent observation\n")
cat("while accounting for non-independence due to participants and interfaces through\n") 
cat("mixed effects modeling. This approach is appropriate for continuous Likert data\n")
cat("and provides more statistical power than participant-level aggregation.\n")
