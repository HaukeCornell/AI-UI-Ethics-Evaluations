library(dplyr)
library(ggplot2)
library(car)      # For Levene's test

cat("=== STATISTICAL ANALYSIS: UEQ vs UEQ+AUTONOMY ===\n")

# Load clean data
clean_data <- read.csv("results/clean_data_for_analysis.csv")

cat("Sample sizes: UEQ =", sum(clean_data$condition == "UEQ"), 
    ", UEQ+Autonomy =", sum(clean_data$condition == "UEQ+Autonomy"), "\n\n")

# ===== NORMALITY TESTING =====
cat("=== NORMALITY TESTS ===\n")

# Extract data by condition
ueq_tendency <- clean_data %>% filter(condition == "UEQ") %>% pull(avg_tendency)
ueq_autonomy_tendency <- clean_data %>% filter(condition == "UEQ+Autonomy") %>% pull(avg_tendency)

ueq_rejection <- clean_data %>% filter(condition == "UEQ") %>% pull(rejection_rate)
ueq_autonomy_rejection <- clean_data %>% filter(condition == "UEQ+Autonomy") %>% pull(rejection_rate)

# Shapiro-Wilk tests for normality
cat("TENDENCY SCORES:\n")
cat("UEQ Shapiro-Wilk p-value:", round(shapiro.test(ueq_tendency)$p.value, 4), "\n")
cat("UEQ+Autonomy Shapiro-Wilk p-value:", round(shapiro.test(ueq_autonomy_tendency)$p.value, 4), "\n")

cat("\nREJECTION RATES:\n")
cat("UEQ Shapiro-Wilk p-value:", round(shapiro.test(ueq_rejection)$p.value, 4), "\n")
cat("UEQ+Autonomy Shapiro-Wilk p-value:", round(shapiro.test(ueq_autonomy_rejection)$p.value, 4), "\n")

# Anderson-Darling test (using base R alternative)
cat("\nKolmogorov-Smirnov normality tests:\n")
cat("UEQ tendency KS p-value:", round(ks.test(ueq_tendency, "pnorm", mean(ueq_tendency), sd(ueq_tendency))$p.value, 4), "\n")
cat("UEQ+Autonomy tendency KS p-value:", round(ks.test(ueq_autonomy_tendency, "pnorm", mean(ueq_autonomy_tendency), sd(ueq_autonomy_tendency))$p.value, 4), "\n")

# Determine which tests to use based on normality
tendency_normal <- shapiro.test(ueq_tendency)$p.value > 0.05 & 
                   shapiro.test(ueq_autonomy_tendency)$p.value > 0.05
rejection_normal <- shapiro.test(ueq_rejection)$p.value > 0.05 & 
                    shapiro.test(ueq_autonomy_rejection)$p.value > 0.05

cat("\nNormality assumption met for tendency scores:", tendency_normal, "\n")
cat("Normality assumption met for rejection rates:", rejection_normal, "\n")

# ===== VARIANCE HOMOGENEITY TESTING =====
cat("\n=== VARIANCE HOMOGENEITY TESTS ===\n")

# Levene's test for equal variances
levene_tendency <- leveneTest(avg_tendency ~ condition, data = clean_data)
levene_rejection <- leveneTest(rejection_rate ~ condition, data = clean_data)

cat("Levene's test for tendency scores p-value:", round(levene_tendency$`Pr(>F)`[1], 4), "\n")
cat("Levene's test for rejection rates p-value:", round(levene_rejection$`Pr(>F)`[1], 4), "\n")

equal_var_tendency <- levene_tendency$`Pr(>F)`[1] > 0.05
equal_var_rejection <- levene_rejection$`Pr(>F)`[1] > 0.05

cat("Equal variances assumption met for tendency:", equal_var_tendency, "\n")
cat("Equal variances assumption met for rejection:", equal_var_rejection, "\n")

# ===== RESEARCH QUESTION 1: TENDENCY TO RELEASE =====
cat("\n=== RESEARCH QUESTION 1: TENDENCY TO RELEASE ===\n")
cat("H0: No difference in tendency between UEQ and UEQ+Autonomy\n")
cat("H1: UEQ+Autonomy has lower tendency to release than UEQ\n\n")

# Descriptive statistics
cat("UEQ tendency: M =", round(mean(ueq_tendency), 3), ", SD =", round(sd(ueq_tendency), 3), "\n")
cat("UEQ+Autonomy tendency: M =", round(mean(ueq_autonomy_tendency), 3), ", SD =", round(sd(ueq_autonomy_tendency), 3), "\n")
cat("Difference (UEQ - UEQ+Autonomy):", round(mean(ueq_tendency) - mean(ueq_autonomy_tendency), 3), "\n\n")

# Choose appropriate test
if(tendency_normal && equal_var_tendency) {
  cat("Using: Independent samples t-test (assumptions met)\n")
  t_test_tendency <- t.test(ueq_tendency, ueq_autonomy_tendency, 
                           alternative = "greater", var.equal = TRUE)
} else if(tendency_normal && !equal_var_tendency) {
  cat("Using: Welch's t-test (normality met, unequal variances)\n")
  t_test_tendency <- t.test(ueq_tendency, ueq_autonomy_tendency, 
                           alternative = "greater", var.equal = FALSE)
} else {
  cat("Using: Mann-Whitney U test (normality violated)\n")
  t_test_tendency <- wilcox.test(ueq_tendency, ueq_autonomy_tendency, 
                                alternative = "greater")
}

cat("Test statistic:", round(t_test_tendency$statistic, 4), "\n")
cat("p-value:", round(t_test_tendency$p.value, 4), "\n")
cat("Significant at α = 0.05:", t_test_tendency$p.value < 0.05, "\n")

# Effect size
pooled_sd <- sqrt(((length(ueq_tendency) - 1) * var(ueq_tendency) + 
                   (length(ueq_autonomy_tendency) - 1) * var(ueq_autonomy_tendency)) / 
                  (length(ueq_tendency) + length(ueq_autonomy_tendency) - 2))
cohens_d <- (mean(ueq_tendency) - mean(ueq_autonomy_tendency)) / pooled_sd
cat("Cohen's d:", round(cohens_d, 3), "\n")

# ===== RESEARCH QUESTION 2: PROPORTION OF REJECTIONS =====
cat("\n=== RESEARCH QUESTION 2: PROPORTION OF REJECTIONS ===\n")
cat("H0: No difference in rejection rates between conditions\n")
cat("H1: UEQ+Autonomy has higher rejection rate than UEQ\n\n")

# Descriptive statistics
cat("UEQ rejection rate: M =", round(mean(ueq_rejection), 1), "%, SD =", round(sd(ueq_rejection), 1), "%\n")
cat("UEQ+Autonomy rejection rate: M =", round(mean(ueq_autonomy_rejection), 1), "%, SD =", round(sd(ueq_autonomy_rejection), 1), "%\n")
cat("Difference (UEQ+Autonomy - UEQ):", round(mean(ueq_autonomy_rejection) - mean(ueq_rejection), 1), "%\n\n")

# Choose appropriate test for rejection rates
if(rejection_normal && equal_var_rejection) {
  cat("Using: Independent samples t-test (assumptions met)\n")
  t_test_rejection <- t.test(ueq_autonomy_rejection, ueq_rejection, 
                            alternative = "greater", var.equal = TRUE)
} else if(rejection_normal && !equal_var_rejection) {
  cat("Using: Welch's t-test (normality met, unequal variances)\n") 
  t_test_rejection <- t.test(ueq_autonomy_rejection, ueq_rejection, 
                            alternative = "greater", var.equal = FALSE)
} else {
  cat("Using: Mann-Whitney U test (normality violated)\n")
  t_test_rejection <- wilcox.test(ueq_autonomy_rejection, ueq_rejection, 
                                 alternative = "greater")
}

cat("Test statistic:", round(t_test_rejection$statistic, 4), "\n")
cat("p-value:", round(t_test_rejection$p.value, 4), "\n")
cat("Significant at α = 0.05:", t_test_rejection$p.value < 0.05, "\n")

# Effect size for rejection rates
pooled_sd_rejection <- sqrt(((length(ueq_rejection) - 1) * var(ueq_rejection) + 
                            (length(ueq_autonomy_rejection) - 1) * var(ueq_autonomy_rejection)) / 
                           (length(ueq_rejection) + length(ueq_autonomy_rejection) - 2))
cohens_d_rejection <- (mean(ueq_autonomy_rejection) - mean(ueq_rejection)) / pooled_sd_rejection
cat("Cohen's d:", round(cohens_d_rejection, 3), "\n")

# ===== SUMMARY =====
cat("\n=== STATISTICAL ANALYSIS SUMMARY ===\n")
cat("Sample sizes: UEQ (n=", length(ueq_tendency), "), UEQ+Autonomy (n=", length(ueq_autonomy_tendency), ")\n")
cat("\nTENDENCY TO RELEASE:\n")
cat("  UEQ: M =", round(mean(ueq_tendency), 3), ", SD =", round(sd(ueq_tendency), 3), "\n")
cat("  UEQ+Autonomy: M =", round(mean(ueq_autonomy_tendency), 3), ", SD =", round(sd(ueq_autonomy_tendency), 3), "\n")
cat("  Difference:", round(mean(ueq_tendency) - mean(ueq_autonomy_tendency), 3), "\n")
cat("  p-value:", round(t_test_tendency$p.value, 4), ", Cohen's d =", round(cohens_d, 3), "\n")
cat("  Result: UEQ+Autonomy has", ifelse(t_test_tendency$p.value < 0.05, "SIGNIFICANTLY", "NON-SIGNIFICANTLY"), "lower tendency\n")

cat("\nREJECTION RATES:\n")
cat("  UEQ: M =", round(mean(ueq_rejection), 1), "%, SD =", round(sd(ueq_rejection), 1), "%\n")
cat("  UEQ+Autonomy: M =", round(mean(ueq_autonomy_rejection), 1), "%, SD =", round(sd(ueq_autonomy_rejection), 1), "%\n")
cat("  Difference:", round(mean(ueq_autonomy_rejection) - mean(ueq_rejection), 1), "%\n")
cat("  p-value:", round(t_test_rejection$p.value, 4), ", Cohen's d =", round(cohens_d_rejection, 3), "\n")
cat("  Result: UEQ+Autonomy has", ifelse(t_test_rejection$p.value < 0.05, "SIGNIFICANTLY", "NON-SIGNIFICANTLY"), "higher rejection rate\n")

# Save results
results_summary <- data.frame(
  measure = c("Tendency to Release", "Rejection Rate"),
  ueq_mean = c(round(mean(ueq_tendency), 3), round(mean(ueq_rejection), 1)),
  ueq_sd = c(round(sd(ueq_tendency), 3), round(sd(ueq_rejection), 1)),
  ueq_autonomy_mean = c(round(mean(ueq_autonomy_tendency), 3), round(mean(ueq_autonomy_rejection), 1)),
  ueq_autonomy_sd = c(round(sd(ueq_autonomy_tendency), 3), round(sd(ueq_autonomy_rejection), 1)),
  difference = c(round(mean(ueq_tendency) - mean(ueq_autonomy_tendency), 3), 
                 round(mean(ueq_autonomy_rejection) - mean(ueq_rejection), 1)),
  p_value = c(round(t_test_tendency$p.value, 4), round(t_test_rejection$p.value, 4)),
  cohens_d = c(round(cohens_d, 3), round(cohens_d_rejection, 3)),
  significant = c(t_test_tendency$p.value < 0.05, t_test_rejection$p.value < 0.05)
)

write.csv(results_summary, "results/statistical_analysis_results.csv", row.names = FALSE)
cat("\nResults saved: results/statistical_analysis_results.csv\n")
