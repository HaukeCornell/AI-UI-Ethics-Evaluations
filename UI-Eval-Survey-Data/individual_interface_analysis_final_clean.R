# Individual Interface Analysis - Final Clean Dataset (N=65)
# One-tailed statistical tests on individual interfaces with multiple comparison corrections
# Using cleaned data: aug16 base + new participants - flagged participants

library(dplyr)
library(readr)

cat("=== INDIVIDUAL INTERFACE ANALYSIS - FINAL CLEAN DATASET ===\n")
cat("Using: aug16 base + new participants - flagged participants\n")
cat("Expected N: ~65 participants\n\n")

# ===== LOAD CLEANED INTERFACE DATA =====
cat("1. LOADING CLEANED INTERFACE DATA...\n")

interface_data <- read.csv("results/interface_plot_data_aug16_plus_new_filtered.csv")

cat("Loaded interface data:\n")
cat("• Total evaluations:", nrow(interface_data), "\n")
cat("• Unique participants:", length(unique(interface_data$ResponseId)), "\n")
cat("• Interfaces:", length(unique(interface_data$interface)), "\n")

# Check condition distribution
condition_dist <- table(interface_data$condition_f)
cat("• Condition distribution:\n")
print(condition_dist)

# ===== INTERFACE PATTERN MAPPING =====
cat("\n2. SETTING UP INTERFACE PATTERN MAPPING...\n")

# Map interfaces to pattern names
interface_patterns <- data.frame(
  interface = 1:15,
  pattern_name = c(
    "Bad Defaults",           # UI 1
    "Content Customization",  # UI 2 
    "Endlessness",           # UI 3
    "Expectation Result Mismatch", # UI 4
    "False Hierarchy",       # UI 5
    "Forced Access",         # UI 6
    "Gamification",          # UI 7
    "Hindering Account Deletion", # UI 8
    "Nagging",               # UI 9
    "Overcomplicated Process", # UI 10
    "Pull to Refresh",       # UI 11
    "Social Connector",      # UI 12
    "Social Pressure",       # UI 13
    "Toying with Emotion",   # UI 14
    "Trick Wording"          # UI 15
  )
)

# Add pattern names to data
interface_data <- interface_data %>%
  left_join(interface_patterns, by = "interface")

cat("• Interface patterns mapped successfully\n")

# ===== DIRECTIONAL HYPOTHESES =====
cat("\n3. DIRECTIONAL HYPOTHESES SETUP...\n")

# Set up directional predictions for one-tailed tests
# UEQ+Autonomy should have:
# - LOWER tendency ratings (more critical/aware)
# - HIGHER rejection rates (more likely to reject)

cat("Directional hypotheses:\n")
cat("• Tendency: UEQ+Autonomy < UEQ (one-tailed, expect lower ratings)\n")
cat("• Rejection: UEQ+Autonomy > UEQ (one-tailed, expect more rejections)\n\n")

# ===== INDIVIDUAL INTERFACE TESTS =====
cat("4. RUNNING INDIVIDUAL INTERFACE TESTS...\n")

interface_results <- data.frame()

for(ui in 1:15) {
  
  # Filter data for this interface
  ui_data <- interface_data %>%
    filter(interface == ui, !is.na(tendency), !is.na(rejected))
  
  pattern_name <- interface_patterns$pattern_name[ui]
  
  cat(sprintf("Interface %d (%s):\n", ui, pattern_name))
  
  # Sample sizes
  n_ueq <- sum(ui_data$condition_f == "UEQ")
  n_ueeq <- sum(ui_data$condition_f == "UEQ+Autonomy")
  
  cat(sprintf("  • N: UEQ=%d, UEQ+Autonomy=%d\n", n_ueq, n_ueeq))
  
  if(n_ueq < 5 || n_ueeq < 5) {
    cat("  • SKIPPED: Insufficient sample size\n\n")
    next
  }
  
  # Separate by condition
  ueq_data <- ui_data %>% filter(condition_f == "UEQ")
  ueeq_data <- ui_data %>% filter(condition_f == "UEQ+Autonomy")
  
  # ===== TENDENCY TEST (one-tailed: UEQ+Autonomy < UEQ) =====
  
  # Descriptives
  ueq_tend_mean <- mean(ueq_data$tendency, na.rm = TRUE)
  ueeq_tend_mean <- mean(ueeq_data$tendency, na.rm = TRUE)
  ueq_tend_sd <- sd(ueq_data$tendency, na.rm = TRUE)
  ueeq_tend_sd <- sd(ueeq_data$tendency, na.rm = TRUE)
  
  # One-tailed t-test (alternative = "less" because we expect UEQ+Autonomy < UEQ)
  tend_test <- t.test(ueeq_data$tendency, ueq_data$tendency, 
                      alternative = "less", var.equal = FALSE)
  
  # Effect size (Cohen's d)
  pooled_sd <- sqrt(((n_ueeq-1)*ueeq_tend_sd^2 + (n_ueq-1)*ueq_tend_sd^2) / (n_ueeq + n_ueq - 2))
  cohens_d_tend <- (ueeq_tend_mean - ueq_tend_mean) / pooled_sd
  
  cat(sprintf("  • Tendency: UEQ=%.2f(%.2f), UEQ+Autonomy=%.2f(%.2f)\n", 
              ueq_tend_mean, ueq_tend_sd, ueeq_tend_mean, ueeq_tend_sd))
  cat(sprintf("  • Tendency test: t=%.3f, p=%.4f (one-tailed), d=%.3f\n", 
              tend_test$statistic, tend_test$p.value, cohens_d_tend))
  
  # ===== REJECTION TEST (one-tailed: UEQ+Autonomy > UEQ) =====
  
  # Rejection rates
  ueq_reject_rate <- mean(ueq_data$rejected, na.rm = TRUE)
  ueeq_reject_rate <- mean(ueeq_data$rejected, na.rm = TRUE)
  
  # One-tailed proportion test (alternative = "greater" because we expect UEQ+Autonomy > UEQ)
  ueq_rejects <- sum(ueq_data$rejected, na.rm = TRUE)
  ueeq_rejects <- sum(ueeq_data$rejected, na.rm = TRUE)
  
  reject_test <- prop.test(c(ueeq_rejects, ueq_rejects), c(n_ueeq, n_ueq), 
                          alternative = "greater")
  
  # Effect size for proportions (Cohen's h)
  p1_arc <- asin(sqrt(ueeq_reject_rate))
  p2_arc <- asin(sqrt(ueq_reject_rate))
  cohens_h <- 2 * (p1_arc - p2_arc)
  
  cat(sprintf("  • Rejection: UEQ=%.1f%%, UEQ+Autonomy=%.1f%%\n", 
              ueq_reject_rate*100, ueeq_reject_rate*100))
  cat(sprintf("  • Rejection test: χ²=%.3f, p=%.4f (one-tailed), h=%.3f\n", 
              reject_test$statistic, reject_test$p.value, cohens_h))
  
  # Store results
  result_row <- data.frame(
    interface = ui,
    pattern_name = pattern_name,
    n_ueq = n_ueq,
    n_ueeq = n_ueeq,
    ueq_tendency_mean = ueq_tend_mean,
    ueq_tendency_sd = ueq_tend_sd,
    ueeq_tendency_mean = ueeq_tend_mean,
    ueeq_tendency_sd = ueeq_tend_sd,
    tendency_t = tend_test$statistic,
    tendency_p_onetailed = tend_test$p.value,
    tendency_cohens_d = cohens_d_tend,
    ueq_rejection_rate = ueq_reject_rate,
    ueeq_rejection_rate = ueeq_reject_rate,
    rejection_chi2 = reject_test$statistic,
    rejection_p_onetailed = reject_test$p.value,
    rejection_cohens_h = cohens_h
  )
  
  interface_results <- rbind(interface_results, result_row)
  cat("\n")
}

# ===== MULTIPLE COMPARISON CORRECTIONS =====
cat("5. APPLYING MULTIPLE COMPARISON CORRECTIONS...\n")

n_tests <- nrow(interface_results)
cat("Number of interfaces tested:", n_tests, "\n")

# Apply corrections to tendency tests
interface_results$tendency_p_fdr <- p.adjust(interface_results$tendency_p_onetailed, method = "fdr")
interface_results$tendency_p_holm <- p.adjust(interface_results$tendency_p_onetailed, method = "holm")
interface_results$tendency_p_bonferroni <- p.adjust(interface_results$tendency_p_onetailed, method = "bonferroni")

# Apply corrections to rejection tests
interface_results$rejection_p_fdr <- p.adjust(interface_results$rejection_p_onetailed, method = "fdr")
interface_results$rejection_p_holm <- p.adjust(interface_results$rejection_p_onetailed, method = "holm")
interface_results$rejection_p_bonferroni <- p.adjust(interface_results$rejection_p_onetailed, method = "bonferroni")

# ===== SIGNIFICANCE SUMMARY =====
cat("\n6. SIGNIFICANCE SUMMARY...\n")

# Count significant results
tend_uncorrected <- sum(interface_results$tendency_p_onetailed < 0.05, na.rm = TRUE)
tend_fdr <- sum(interface_results$tendency_p_fdr < 0.05, na.rm = TRUE)
tend_holm <- sum(interface_results$tendency_p_holm < 0.05, na.rm = TRUE)
tend_bonf <- sum(interface_results$tendency_p_bonferroni < 0.05, na.rm = TRUE)

reject_uncorrected <- sum(interface_results$rejection_p_onetailed < 0.05, na.rm = TRUE)
reject_fdr <- sum(interface_results$rejection_p_fdr < 0.05, na.rm = TRUE)
reject_holm <- sum(interface_results$rejection_p_holm < 0.05, na.rm = TRUE)
reject_bonf <- sum(interface_results$rejection_p_bonferroni < 0.05, na.rm = TRUE)

cat("TENDENCY EFFECTS (UEQ+Autonomy < UEQ):\n")
cat(sprintf("• Uncorrected (p < .05): %d/%d interfaces\n", tend_uncorrected, n_tests))
cat(sprintf("• FDR corrected: %d/%d interfaces\n", tend_fdr, n_tests))
cat(sprintf("• Holm corrected: %d/%d interfaces\n", tend_holm, n_tests))
cat(sprintf("• Bonferroni corrected: %d/%d interfaces\n", tend_bonf, n_tests))

cat("\nREJECTION EFFECTS (UEQ+Autonomy > UEQ):\n")
cat(sprintf("• Uncorrected (p < .05): %d/%d interfaces\n", reject_uncorrected, n_tests))
cat(sprintf("• FDR corrected: %d/%d interfaces\n", reject_fdr, n_tests))
cat(sprintf("• Holm corrected: %d/%d interfaces\n", reject_holm, n_tests))
cat(sprintf("• Bonferroni corrected: %d/%d interfaces\n", reject_bonf, n_tests))

# ===== DETAILED SIGNIFICANT RESULTS =====
cat("\n7. DETAILED SIGNIFICANT RESULTS (FDR CORRECTED)...\n")

sig_tendency <- interface_results %>%
  filter(tendency_p_fdr < 0.05) %>%
  arrange(tendency_p_fdr)

sig_rejection <- interface_results %>%
  filter(rejection_p_fdr < 0.05) %>%
  arrange(rejection_p_fdr)

if(nrow(sig_tendency) > 0) {
  cat("SIGNIFICANT TENDENCY EFFECTS:\n")
  for(i in 1:nrow(sig_tendency)) {
    row <- sig_tendency[i, ]
    cat(sprintf("• %s (UI %d): d=%.2f, p=%.4f\n", 
                row$pattern_name, row$interface, row$tendency_cohens_d, row$tendency_p_fdr))
  }
} else {
  cat("NO SIGNIFICANT TENDENCY EFFECTS after FDR correction\n")
}

if(nrow(sig_rejection) > 0) {
  cat("\nSIGNIFICANT REJECTION EFFECTS:\n")
  for(i in 1:nrow(sig_rejection)) {
    row <- sig_rejection[i, ]
    cat(sprintf("• %s (UI %d): h=%.2f, p=%.4f\n", 
                row$pattern_name, row$interface, row$rejection_cohens_h, row$rejection_p_fdr))
  }
} else {
  cat("\nNO SIGNIFICANT REJECTION EFFECTS after FDR correction\n")
}

# ===== SAVE RESULTS =====
cat("\n8. SAVING RESULTS...\n")

write.csv(interface_results, "results/individual_interface_analysis_final_clean_N65.csv", row.names = FALSE)

cat("\n✓ Analysis complete!\n")
cat("• Results saved to: results/individual_interface_analysis_final_clean_N65.csv\n")
cat(sprintf("• Final sample: N=%d participants\n", length(unique(interface_data$ResponseId))))
cat("• Statistical approach: One-tailed tests with FDR correction\n")
cat("• This is the cleanest, largest dataset possible with current data\n")
