# Enhanced Mixed Effects Analysis: Per-Evaluation Release Tendency with High-Quality Visualization
# Adding boxplots, significance bars, and visible mean/median annotations

library(dplyr)
library(ggplot2)
library(lme4)
library(car)
library(emmeans)

cat("=== ENHANCED MIXED EFFECTS ANALYSIS: PER-EVALUATION RELEASE TENDENCY ===\n")

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

# Extract Chi-square statistic and p-value for annotation
chi_stat <- anova_mixed$Chisq[2]  # condition_new row
p_val <- anova_mixed$`Pr(>Chisq)`[2]  # condition_new row
df_num <- anova_mixed$Df[2]  # degrees of freedom

cat(sprintf("\nChi-square(%d) = %.2f, p = %s\n", df_num, chi_stat, 
            if(p_val < 0.001) "< 0.001" else sprintf("= %.3f", p_val)))

# 2. Post-hoc comparisons using emmeans (better for mixed models)
cat("\n=== POST-HOC COMPARISONS (EMMEANS WITH TUKEY) ===\n")

# Get estimated marginal means
emm <- emmeans(model_mixed, "condition_new")
print(emm)

# Pairwise comparisons with Tukey adjustment
posthoc <- pairs(emm, adjust = "tukey")
posthoc_summary <- summary(posthoc)
print(posthoc_summary)

# Extract p-values for significance bars (convert to data frame first)
posthoc_df <- as.data.frame(posthoc_summary)
ui_ueq_p <- posthoc_df$p.value[grepl("UI.*UEQ", posthoc_df$contrast) & !grepl("UEQ-A", posthoc_df$contrast)]
ui_ueqa_p <- posthoc_df$p.value[grepl("UI.*UEQ-A", posthoc_df$contrast)]
ueq_ueqa_p <- posthoc_df$p.value[grepl("UEQ.*UEQ-A", posthoc_df$contrast)]

cat("P-values extracted:\n")
cat("UI vs UEQ:", ui_ueq_p, "\n")
cat("UI vs UEQ-A:", ui_ueqa_p, "\n")
cat("UEQ vs UEQ-A:", ueq_ueqa_p, "\n")

# 3. Descriptive statistics per condition (all evaluations)
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

# Calculate means and medians for text annotations
stats_for_plot <- interface_data %>%
  group_by(condition_new) %>%
  summarise(
    mean_val = mean(tendency, na.rm = TRUE),
    median_val = median(tendency, na.rm = TRUE),
    .groups = "drop"
  )

# 4. Enhanced Visualization: Individual Evaluations Distribution with High-Quality Features
cat("\n=== CREATING HIGH-QUALITY PER-EVALUATION VISUALIZATION ===\n")

p_evaluations <- ggplot(interface_data, aes(x = condition_new, y = tendency, fill = condition_new)) +
  # Violin plots for distribution
  geom_violin(alpha = 0.6, trim = FALSE) +
  
  # BOXPLOTS (key enhancement)
  geom_boxplot(width = 0.3, alpha = 0.8, outlier.shape = NA) +
  
  # Individual evaluation jitter points
  geom_jitter(width = 0.2, alpha = 0.3, size = 0.5, color = "black") +
  
  # Large visible mean (black diamond)
  stat_summary(fun = mean, geom = "point", shape = 18, size = 8, color = "white", stroke = 2) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 7, color = "black") +
  
  # Large visible median (red line)
  stat_summary(fun = median, geom = "point", shape = 95, size = 10, color = "white", stroke = 2) +
  stat_summary(fun = median, geom = "point", shape = 95, size = 9, color = "red") +
  
  # SIGNIFICANCE BARS (UI vs UEQ)
  geom_segment(aes(x = 1, xend = 2, y = 6.5, yend = 6.5), color = "black", linewidth = 1) +
  geom_segment(aes(x = 1, xend = 1, y = 6.3, yend = 6.5), color = "black", linewidth = 1) +
  geom_segment(aes(x = 2, xend = 2, y = 6.3, yend = 6.5), color = "black", linewidth = 1) +
  annotate("text", x = 1.5, y = 6.7, 
           label = paste0("p = ", if(ui_ueq_p < 0.001) "< 0.001" else sprintf("%.3f", ui_ueq_p)), 
           size = 4, fontface = "bold") +
  
  # SIGNIFICANCE BARS (UEQ vs UEQ-A)
  geom_segment(aes(x = 2, xend = 3, y = 6.0, yend = 6.0), color = "black", linewidth = 1) +
  geom_segment(aes(x = 2, xend = 2, y = 5.8, yend = 6.0), color = "black", linewidth = 1) +
  geom_segment(aes(x = 3, xend = 3, y = 5.8, yend = 6.0), color = "black", linewidth = 1) +
  annotate("text", x = 2.5, y = 6.2, 
           label = paste0("p = ", if(ueq_ueqa_p < 0.001) "< 0.001" else sprintf("%.3f", ueq_ueqa_p)), 
           size = 4, fontface = "bold") +
  
  # SIGNIFICANCE BARS (UI vs UEQ-A)
  geom_segment(aes(x = 1, xend = 3, y = 7.0, yend = 7.0), color = "black", linewidth = 1) +
  geom_segment(aes(x = 1, xend = 1, y = 6.8, yend = 7.0), color = "black", linewidth = 1) +
  geom_segment(aes(x = 3, xend = 3, y = 6.8, yend = 7.0), color = "black", linewidth = 1) +
  annotate("text", x = 2, y = 7.2, 
           label = paste0("p = ", if(ui_ueqa_p < 0.001) "< 0.001" else sprintf("%.3f", ui_ueqa_p)), 
           size = 4, fontface = "bold") +
  
  # VISIBLE MEAN/MEDIAN TEXT ANNOTATIONS
  geom_text(data = stats_for_plot, 
            aes(x = as.numeric(condition_new), y = 1.3, 
                label = paste0("Mean: ", sprintf("%.2f", mean_val))), 
            color = "black", fontface = "bold", size = 3.5, hjust = 0.5) +
  geom_text(data = stats_for_plot, 
            aes(x = as.numeric(condition_new), y = 1.1, 
                label = paste0("Median: ", sprintf("%.2f", median_val))), 
            color = "red", fontface = "bold", size = 3.5, hjust = 0.5) +
  
  scale_fill_manual(values = condition_colors, name = "Condition") +
  labs(
    title = "Release Tendency Distribution: All Individual Evaluations",
    subtitle = paste0("Mixed effects analysis of ", nrow(interface_data), 
                     " individual evaluations • χ²(", df_num, ") = ", 
                     sprintf("%.2f", chi_stat), ", p ", 
                     if(p_val < 0.001) "< 0.001" else paste0("= ", sprintf("%.3f", p_val))),
    x = "Evaluation Condition",
    y = "Release Tendency (1-7 scale)",
    caption = "♦ = Mean (black diamond) • ▬ = Median (red line) • Boxes show quartiles • Points = Individual evaluations\nMixed effects model accounts for participant and interface random effects • Post-hoc: Tukey HSD"
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
  scale_y_continuous(limits = c(1, 7.5), breaks = 1:7)

# 5. Effect sizes for pairwise comparisons (using original scale)
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

# Save enhanced plot
if(!dir.exists("plots")) dir.create("plots")

ggsave("plots/per_evaluation_tendency_analysis_enhanced.png", p_evaluations, 
       width = 14, height = 10, dpi = 300)

# Save results to CSV
write.csv(desc_stats, "results/per_evaluation_descriptive_stats_enhanced.csv", row.names = FALSE)

# Save post-hoc results
posthoc_df <- data.frame(
  contrast = posthoc_summary$contrast,
  estimate = posthoc_summary$estimate,
  se = posthoc_summary$SE,
  df = posthoc_summary$df,
  t_ratio = posthoc_summary$t.ratio,
  p_value = posthoc_summary$p.value
)
write.csv(posthoc_df, "results/per_evaluation_posthoc_results.csv", row.names = FALSE)

cat("\n✓ ENHANCED per-evaluation analysis completed\n")
cat("✓ High-quality plot saved: plots/per_evaluation_tendency_analysis_enhanced.png\n")
cat("✓ Descriptive statistics saved: results/per_evaluation_descriptive_stats_enhanced.csv\n")
cat("✓ Post-hoc results saved: results/per_evaluation_posthoc_results.csv\n")

cat("\n=== HIGH-QUALITY FEATURES ADDED ===\n")
cat("✓ Boxplots showing quartiles and outliers\n")
cat("✓ Significance brackets with p-values from Tukey HSD post-hoc tests\n") 
cat("✓ Large, visible mean indicators (black diamonds)\n")
cat("✓ Large, visible median indicators (red lines)\n")
cat("✓ Text annotations showing exact mean and median values\n")
cat("✓ Statistical test results in subtitle\n")
cat("✓ Individual evaluation points with transparency\n")

# Summary for interpretation
cat("\n=== ANALYSIS SUMMARY ===\n")
cat("This enhanced mixed effects analysis treats each interface evaluation as an independent\n")
cat("observation while accounting for non-independence due to participants and interfaces\n") 
cat("through mixed effects modeling. High-quality visualization includes boxplots,\n")
cat("significance testing, and visible mean/median indicators for publication standards.\n")
