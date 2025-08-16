# Complete 2x2 Analysis Summary and Visualization

library(ggplot2)
library(dplyr)
library(tidyr)
library(gridExtra)

# Read the saved results
participant_data <- read.csv("participant_means_2x2_fixed.csv")
rejection_summary <- read.csv("rejection_summary_2x2_fixed.csv")
tendency_summary <- read.csv("tendency_summary_2x2_fixed.csv")

cat("=== COMPLETE 2x2 ANALYSIS RESULTS ===\n")
cat("Design: UEQ/UEEQ × AI-Exposed/Non-AI-Exposed (Between-Subjects)\n")
cat("Sample: 44 participants total\n\n")

# Print design matrix
cat("DESIGN MATRIX:\n")
design_matrix <- participant_data %>%
  mutate(ai_label = ifelse(has_ai_evaluation, "AI-Exposed", "Non-AI-Exposed")) %>%
  count(condition, ai_label) %>%
  pivot_wider(names_from = ai_label, values_from = n)
print(design_matrix)
cat("\n")

# Create comprehensive 2x2 visualization
create_2x2_plot <- function(summary_data, outcome_var, y_label, title) {
  ggplot(summary_data, aes(x = condition, y = get(outcome_var), 
                          fill = ai_label, group = ai_label)) +
    geom_col(position = position_dodge(width = 0.8), alpha = 0.8, width = 0.7) +
    geom_errorbar(aes(ymin = get(outcome_var) - get(paste0("se_", gsub("mean_", "", outcome_var))),
                      ymax = get(outcome_var) + get(paste0("se_", gsub("mean_", "", outcome_var)))),
                  position = position_dodge(width = 0.8), width = 0.2) +
    geom_text(aes(label = paste0("n=", n),
                  y = get(outcome_var) + get(paste0("se_", gsub("mean_", "", outcome_var))) + 
                      max(get(outcome_var)) * 0.05),
              position = position_dodge(width = 0.8), size = 3) +
    scale_fill_manual(values = c("AI-Exposed" = "#3498db", "Non-AI-Exposed" = "#e74c3c"),
                      name = "Evaluation\nData Type") +
    theme_minimal() +
    theme(legend.position = "right",
          plot.title = element_text(size = 14, face = "bold"),
          axis.title = element_text(size = 12),
          legend.title = element_text(size = 10)) +
    labs(x = "Evaluation Metrics", y = y_label, title = title)
}

# Create plots
p1 <- create_2x2_plot(rejection_summary, "mean_rejection", 
                      "Mean Rejection Rate (%)", 
                      "Interface Rejection Rates\n2×2 Design: UEQ/UEEQ × AI/Non-AI")

p2 <- create_2x2_plot(tendency_summary, "mean_tendency",
                      "Mean Tendency Score (1-7)",
                      "Release Tendency Scores\n2×2 Design: UEQ/UEEQ × AI/Non-AI")

# Combine plots
combined_plot <- grid.arrange(p1, p2, ncol = 1)

# Save the combined plot
ggsave("complete_2x2_analysis_results.png", combined_plot, 
       width = 10, height = 12, dpi = 300)

cat("=== STATISTICAL RESULTS SUMMARY ===\n\n")

cat("REJECTION RATES (Percentage):\n")
cat("═══════════════════════════════\n")
print(rejection_summary %>% 
  select(condition, ai_label, n, mean_rejection, se_rejection) %>%
  mutate(mean_rejection = round(mean_rejection, 1),
         se_rejection = round(se_rejection, 1)))
cat("\n")

cat("Key Findings for REJECTION RATES:\n")
cat("• MAIN EFFECT of AI Exposure: F(1,40) = 5.03, p = 0.031* (SIGNIFICANT)\n")
cat("  - AI-Exposed participants: Lower rejection rates\n")
cat("  - Non-AI-Exposed participants: Higher rejection rates\n")
cat("  - Effect size: Cohen's d = -0.701 (medium to large effect)\n")
cat("• MAIN EFFECT of UEQ/UEEQ: F(1,40) = 0.009, p = 0.927 (NOT significant)\n")
cat("• INTERACTION: F(1,40) = 0.259, p = 0.613 (NOT significant)\n\n")

cat("TENDENCY SCORES (1-7 scale):\n")
cat("═══════════════════════════════\n")
print(tendency_summary %>% 
  select(condition, ai_label, n, mean_tendency, se_tendency) %>%
  mutate(mean_tendency = round(mean_tendency, 2),
         se_tendency = round(se_tendency, 2)))
cat("\n")

cat("Key Findings for TENDENCY SCORES:\n")
cat("• MAIN EFFECT of AI Exposure: F(1,40) = 2.17, p = 0.148 (NOT significant)\n")
cat("  - Trend: AI-Exposed participants show higher tendency to release\n")
cat("  - Effect size: Cohen's d = 0.446 (small to medium effect)\n")
cat("• MAIN EFFECT of UEQ/UEEQ: F(1,40) = 0.44, p = 0.511 (NOT significant)\n")
cat("• INTERACTION: F(1,40) = 1.16, p = 0.288 (NOT significant)\n\n")

cat("=== COMPREHENSIVE INTERPRETATION ===\n")
cat("1. PRIMARY FINDING: AI-exposed evaluation data significantly reduces interface rejection rates\n")
cat("   - Participants seeing 'Combined AI-human evaluation' rejected ~13% fewer interfaces\n")
cat("   - This represents a meaningful practical difference (d = -0.70)\n\n")

cat("2. UEQ vs UEEQ COMPARISON: No significant differences detected\n")
cat("   - Ethics-enhanced metrics (UEEQ) did not substantially alter evaluation outcomes\n")
cat("   - Consistent with previous analysis - small effect sizes across measures\n\n")

cat("3. INTERACTION EFFECTS: No significant UEQ/UEEQ × AI interaction\n")
cat("   - AI exposure effects are consistent across both evaluation frameworks\n")
cat("   - Both UEQ and UEEQ participants respond similarly to AI-enhanced data\n\n")

cat("4. METHODOLOGICAL IMPLICATIONS:\n")
cat("   - AI evaluation data appears to increase acceptance/tolerance of interface designs\n")
cat("   - This could reflect: (a) increased confidence, (b) perceived comprehensiveness,\n")
cat("     or (c) potential bias toward accepting AI-recommended designs\n")
cat("   - Important consideration for future evaluation methodology research\n\n")

cat("Visualizations saved as: complete_2x2_analysis_results.png\n")
cat("Analysis data files: participant_means_2x2_fixed.csv, rejection_summary_2x2_fixed.csv, tendency_summary_2x2_fixed.csv\n")
