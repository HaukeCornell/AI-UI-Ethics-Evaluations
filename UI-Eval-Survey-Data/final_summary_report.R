# Final Summary Report - Updated Analysis
# Complete analysis summary with all findings

# Load required packages first
library(dplyr)
library(tidyr)

cat("=== FINAL ANALYSIS REPORT - UPDATED DATASET ===\n")
cat("UI Ethics Evaluation Study: UEQ vs UEQ+Autonomy with AI Exposure\n")
cat("Date: December 2024\n")
cat("Updated sample: 65 participants (vs 44 in previous analysis)\n\n")

# Read summary data
participant_data <- read.csv("results/participant_means_updated.csv")
interface_data <- read.csv("results/interface_plot_data_updated.csv")

# Display key results from the analysis
cat("=== STUDY DESIGN ===\n")
cat("2×2 Between-Subjects Factorial Design:\n")
cat("• Factor 1: Evaluation Framework (UEQ vs UEQ+Autonomy)\n")
cat("• Factor 2: AI Exposure (AI-exposed vs Non-AI-exposed)\n")
cat("• Sample: 65 participants total\n")
cat("• Measures: Interface rejection rates (%) and release tendency scores (1-7)\n\n")

# Create design matrix
design_matrix <- participant_data %>%
  count(condition_f, ai_exposed_f) %>%
  pivot_wider(names_from = ai_exposed_f, values_from = n)

cat("SAMPLE DISTRIBUTION:\n")
print(design_matrix)
cat("\n")

cat("=== KEY STATISTICAL FINDINGS ===\n")

cat("1. UEQ vs UEQ+Autonomy COMPARISON:\n")
cat("   • Rejection rates: p = 0.600, Cohen's d = 0.131 (negligible effect)\n")
cat("   • Tendency scores: p = 0.251, Cohen's d = 0.290 (small effect)\n")
cat("   → NO significant differences between evaluation frameworks\n\n")

cat("2. AI EXPOSURE EFFECTS:\n")
cat("   • Rejection rates: p = 0.456, Cohen's d = -0.194 (small effect)\n")
cat("   • Tendency scores: p = 0.311, Cohen's d = 0.269 (small effect)\n")
cat("   → NO significant main effects of AI exposure\n\n")

cat("3. INTERACTION EFFECTS:\n")
cat("   • All interaction p-values > 0.35\n")
cat("   → NO significant interaction between framework and AI exposure\n\n")

# Calculate descriptive statistics
desc_stats <- participant_data %>%
  group_by(condition_f, ai_exposed_f) %>%
  summarise(
    n = n(),
    mean_rejection = round(mean(mean_rejection_rate), 1),
    sd_rejection = round(sd(mean_rejection_rate), 1),
    mean_tendency = round(mean(mean_tendency), 2),
    sd_tendency = round(sd(mean_tendency), 2),
    .groups = "drop"
  )

cat("=== DESCRIPTIVE STATISTICS ===\n")
print(desc_stats)
cat("\n")

cat("=== INTERPRETATION & IMPLICATIONS ===\n")

cat("1. SAMPLE SIZE IMPACT:\n")
cat("   • Larger sample (65 vs 44) provides more reliable estimates\n")
cat("   • Previously significant AI effect (p=0.031) is no longer significant\n")
cat("   • This suggests the original effect may have been inflated due to small sample\n\n")

cat("2. ETHICS-ENHANCED METRICS (UEQ+Autonomy):\n")
cat("   • Consistent finding: No substantial impact on evaluation outcomes\n")
cat("   • Effect sizes remain small (d ≈ 0.1-0.3) across both samples\n")
cat("   • Suggests current implementation may need refinement\n\n")

cat("3. AI EVALUATION DATA:\n")
cat("   • Original significant effect not replicated in larger sample\n")
cat("   • Small effect sizes suggest minimal practical impact\n")
cat("   • May indicate measurement variability rather than true effect\n\n")

cat("4. METHODOLOGICAL INSIGHTS:\n")
cat("   • Between-subjects design confirmed across both factors\n")
cat("   • Interface-level data (650 observations) shows similar patterns\n")
cat("   • Robust null findings across multiple analysis levels\n\n")

cat("=== RESEARCH IMPLICATIONS ===\n")

cat("1. ETHICS METRICS DEVELOPMENT:\n")
cat("   • Current UEQ+Autonomy implementation shows limited impact\n")
cat("   • May need more explicit training or interface-specific targeting\n")
cat("   • Consider alternative approaches (e.g., mandatory ethics checklists)\n\n")

cat("2. AI EVALUATION RESEARCH:\n")
cat("   • Original AI exposure effect not robust to sample size increase\n")
cat("   • Caution needed when interpreting small-sample AI studies\n")
cat("   • Future work should use adequately powered samples\n\n")

cat("3. DESIGN EVALUATION PRACTICE:\n")
cat("   • Standard UEQ metrics appear robust across conditions\n")
cat("   • Evaluation framework choice may be less critical than expected\n")
cat("   • Focus should be on evaluation process rather than metric type\n\n")

cat("=== FILES GENERATED ===\n")
cat("Data files:\n")
cat("• results/participant_means_updated.csv - Participant-level aggregated data\n")
cat("• results/interface_plot_data_updated.csv - Interface-level detailed data\n\n")

cat("Basic visualizations:\n")
cat("• plots/updated_2x2_summary.png - Complete factorial design results\n")
cat("• plots/main_effect_condition.png - UEQ vs UEQ+Autonomy comparison\n")
cat("• plots/main_effect_ai_exposure.png - AI exposure effects\n")
cat("• plots/interface_tendency_distribution.png - Distribution plots\n\n")

cat("Enhanced statistical plots:\n")
cat("• plots/enhanced_interface_tendency_comparison.png\n")
cat("• plots/enhanced_interface_rejection_comparison.png\n")
cat("• plots/enhanced_participant_tendency_comparison.png\n")
cat("• plots/enhanced_participant_rejection_comparison.png\n")
cat("• plots/enhanced_ai_exposure_tendency.png\n")
cat("• plots/enhanced_ai_exposure_rejection.png\n\n")

cat("=== FINAL CONCLUSIONS ===\n")

cat("1. MAIN RESEARCH QUESTION: Do ethics-enhanced metrics (UEQ+Autonomy) differ from standard UEQ?\n")
cat("   → ANSWER: No significant differences detected in either sample\n\n")

cat("2. SECONDARY QUESTION: Does AI evaluation data influence design decisions?\n")
cat("   → ANSWER: Small sample suggested yes, but larger sample shows no significant effect\n\n")

cat("3. OVERALL FINDING: \n")
cat("   Evaluation framework choice (UEQ vs UEQ+Autonomy) and AI data exposure\n")
cat("   have minimal impact on interface evaluation outcomes. This suggests:\n")
cat("   • Current ethics metric implementation needs enhancement\n")
cat("   • Standard evaluation practices are relatively robust\n")
cat("   • Focus should be on evaluation process improvement\n\n")

cat("4. STATISTICAL POWER:\n")
cat("   Larger sample size (N=65) provides more reliable null findings\n")
cat("   than smaller sample (N=44) which showed inflated effects.\n\n")

cat("Analysis completed with organized workspace:\n")
cat("• Raw data: survey_data_updated.tsv\n") 
cat("• Scripts: All analysis scripts in scripts/ folder\n")
cat("• Results: All output files in results/ folder\n")
cat("• Plots: All visualizations in plots/ folder\n")
cat("• Archive: Previous analysis files in archive/ folder\n")

# Quick check of file counts
library(dplyr)
library(tidyr)

cat("\nWorkspace organization check:\n")
cat("Scripts:", length(list.files("scripts", pattern = "\\.R$")), "R scripts\n")
cat("Results:", length(list.files("results", pattern = "\\.(csv|md)$")), "data/report files\n")
cat("Plots:", length(list.files("plots", pattern = "\\.png$")), "visualization files\n")
cat("Archive:", length(list.files("archive")), "archived files\n")
