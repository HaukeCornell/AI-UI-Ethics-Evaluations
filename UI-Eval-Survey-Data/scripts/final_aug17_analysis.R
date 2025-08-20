# Complete Analysis with August 17 Data (N=94)
# Using proper multiple comparisons correction

library(dplyr)
library(ggplot2)
library(ggstatsplot)
library(patchwork)

cat("=== COMPLETE ANALYSIS WITH AUGUST 17 DATA ===\n")
cat("Sample: 94 participants, 940 interface evaluations\n")
cat("With proper multiple comparisons correction\n\n")

# Load the new data
interface_data <- read.csv("results/interface_plot_data_aug17_final.csv")

# Create pattern mapping
ui_mapping <- data.frame(
  interface_num = 1:15,
  pattern_short = c(
    "Bad Defaults", "Content Custom", "Endlessness", "Expect. Mismatch",
    "False Hierarchy", "Forced Access", "Gamification", "Hinder Deletion",
    "Nagging", "Overcomplex", "Pull to Refresh", "Social Connect",
    "Toy w/ Emotion", "Trick Wording", "Social Pressure"
  )
)

cat("1. SAMPLE SUMMARY:\n")
sample_summary <- interface_data %>%
  distinct(ResponseId, condition_f, has_ai_evaluation) %>%
  count(condition_f, has_ai_evaluation)
print(sample_summary)

# ===== PERFORM ALL STATISTICAL TESTS =====
cat("\n2. STATISTICAL TESTING (15 interfaces × 2 measures = 30 tests):\n")

# Function to test all interfaces
test_all_interfaces <- function() {
  results <- list()
  
  for(ui_num in 1:15) {
    ui_data <- interface_data %>%
      filter(interface_num == ui_num)
    
    if(nrow(ui_data) >= 6 && length(unique(ui_data$condition_f)) == 2) {
      # Test rejection rates
      ui_binary <- ui_data %>%
        mutate(rejected_binary = ifelse(rejection_pct > 0, 1, 0))
      
      contingency_table <- table(ui_binary$condition_f, ui_binary$rejected_binary)
      
      # Choose appropriate test
      if(all(contingency_table >= 5)) {
        rejection_test <- chisq.test(contingency_table)
        rejection_p <- rejection_test$p.value
      } else {
        rejection_test <- fisher.test(contingency_table)
        rejection_p <- rejection_test$p.value
      }
      
      # Test tendency scores
      tendency_test <- t.test(tendency ~ condition_f, data = ui_data)
      tendency_p <- tendency_test$p.value
      
      # Store results
      results[[ui_num]] <- data.frame(
        interface = ui_num,
        pattern_name = ui_mapping$pattern_short[ui_num],
        n_total = nrow(ui_data),
        rejection_p_raw = rejection_p,
        tendency_p_raw = tendency_p
      )
    }
  }
  
  return(do.call(rbind, results))
}

# Get all test results
all_results <- test_all_interfaces()

# Apply multiple comparisons corrections
rejection_p_values <- all_results$rejection_p_raw
tendency_p_values <- all_results$tendency_p_raw

# Correct for 15 tests each
rejection_corrected <- data.frame(
  interface = all_results$interface,
  pattern_name = all_results$pattern_name,
  rejection_p_raw = rejection_p_values,
  rejection_p_fdr = p.adjust(rejection_p_values, method = "BH"),
  rejection_p_bonferroni = p.adjust(rejection_p_values, method = "bonferroni")
)

tendency_corrected <- data.frame(
  interface = all_results$interface,
  pattern_name = all_results$pattern_name,
  tendency_p_raw = tendency_p_values,
  tendency_p_fdr = p.adjust(tendency_p_values, method = "BH"),
  tendency_p_bonferroni = p.adjust(tendency_p_values, method = "bonferroni")
)

# Determine significance levels
rejection_corrected <- rejection_corrected %>%
  mutate(
    sig_uncorrected = rejection_p_raw < 0.05,
    sig_fdr = rejection_p_fdr < 0.05,
    sig_bonferroni = rejection_p_bonferroni < 0.05
  )

tendency_corrected <- tendency_corrected %>%
  mutate(
    sig_uncorrected = tendency_p_raw < 0.05,
    sig_fdr = tendency_p_fdr < 0.05,
    sig_bonferroni = tendency_p_bonferroni < 0.05
  )

# ===== RESULTS SUMMARY =====
cat("\n3. MULTIPLE COMPARISONS CORRECTION RESULTS (N=94):\n")

cat("REJECTION DIFFERENCES:\n")
cat("• Uncorrected significant:", sum(rejection_corrected$sig_uncorrected), "of 15\n")
cat("• FDR corrected significant:", sum(rejection_corrected$sig_fdr), "of 15\n")
cat("• Bonferroni corrected significant:", sum(rejection_corrected$sig_bonferroni), "of 15\n")

cat("\nTENDENCY DIFFERENCES:\n")
cat("• Uncorrected significant:", sum(tendency_corrected$sig_uncorrected), "of 15\n")
cat("• FDR corrected significant:", sum(tendency_corrected$sig_fdr), "of 15\n")
cat("• Bonferroni corrected significant:", sum(tendency_corrected$sig_bonferroni), "of 15\n")

# Show uncorrected "significant" results
if(sum(rejection_corrected$sig_uncorrected) > 0) {
  cat("\nUncorrected 'significant' rejection patterns:\n")
  rejection_uncorrected <- rejection_corrected %>% 
    filter(sig_uncorrected) %>%
    arrange(rejection_p_raw)
  print(rejection_uncorrected %>% select(pattern_name, rejection_p_raw, rejection_p_fdr))
}

if(sum(tendency_corrected$sig_uncorrected) > 0) {
  cat("\nUncorrected 'significant' tendency patterns:\n")
  tendency_uncorrected <- tendency_corrected %>% 
    filter(sig_uncorrected) %>%
    arrange(tendency_p_raw)
  print(tendency_uncorrected %>% select(pattern_name, tendency_p_raw, tendency_p_fdr))
}

# ===== SAVE RESULTS =====
complete_results <- rejection_corrected %>%
  left_join(tendency_corrected, by = c("interface", "pattern_name"))

write.csv(complete_results, "results/aug17_complete_statistical_results.csv", row.names = FALSE)

# ===== FINAL CONCLUSION =====
cat("\n=== FINAL STATISTICAL CONCLUSION (N=94) ===\n")

total_fdr_significant <- sum(rejection_corrected$sig_fdr) + sum(tendency_corrected$sig_fdr)
total_bonferroni_significant <- sum(rejection_corrected$sig_bonferroni) + sum(tendency_corrected$sig_bonferroni)

if(total_fdr_significant == 0 && total_bonferroni_significant == 0) {
  cat("RESULT: NO SIGNIFICANT DIFFERENCES after multiple comparisons correction\n")
  cat("\nInterpretation:\n")
  cat("• With larger sample (N=94 vs 65), no robust interface-level effects detected\n")
  cat("• Previous 'significant' findings were likely false positives\n")
  cat("• UEQ and UEQ+Autonomy perform equivalently at interface level\n")
  cat("• Confirms participant-level null findings\n")
} else {
  cat("RESULT: Some effects survive multiple comparisons correction\n")
  if(sum(rejection_corrected$sig_fdr) > 0) {
    cat("• FDR-significant rejection differences in patterns:", 
        paste(rejection_corrected$pattern_name[rejection_corrected$sig_fdr], collapse = ", "), "\n")
  }
  if(sum(tendency_corrected$sig_fdr) > 0) {
    cat("• FDR-significant tendency differences in patterns:", 
        paste(tendency_corrected$pattern_name[tendency_corrected$sig_fdr], collapse = ", "), "\n")
  }
}

cat("\nFiles saved:\n")
cat("• results/aug17_complete_statistical_results.csv - Complete results with corrections\n")
cat("• results/interface_plot_data_aug17_final.csv - Interface-level data (N=94)\n")

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Ready for visualization if any effects survive correction!\n")
