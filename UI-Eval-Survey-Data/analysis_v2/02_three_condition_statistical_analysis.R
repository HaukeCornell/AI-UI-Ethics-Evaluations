# Three-Condition Statistical Analysis
# ANOVA and Planned Comparisons for UEQ vs UEQ+Autonomy vs RAW
# September 2025

library(dplyr)
library(readr)
library(ggplot2)
library(gridExtra)
library(broom)

cat("=== THREE-CONDITION STATISTICAL ANALYSIS ===\n")

# ===== LOAD DATA =====
cat("1. LOADING PROCESSED DATA...\n")
data <- read.csv("results/three_condition_interface_data.csv")

cat("• Total evaluations:", nrow(data), "\n")
cat("• Participants per condition:\n")
print(table(data$condition))

# ===== INTERFACE-BY-INTERFACE ANOVA =====
cat("\n2. INTERFACE-BY-INTERFACE ANOVA ANALYSIS...\n")

interfaces <- unique(data$interface)
anova_results <- list()

for(ui in interfaces) {
  cat("Analyzing", ui, "...\n")
  
  ui_data <- data %>% filter(interface == ui)
  
  # Skip if insufficient data
  if(nrow(ui_data) < 6) {
    cat("  Insufficient data, skipping\n")
    next
  }
  
  # ANOVA for tendency
  tendency_aov <- aov(tendency_numeric ~ condition, data = ui_data)
  tendency_summary <- summary(tendency_aov)
  
  # ANOVA for rejection rate (release_binary inverted)
  ui_data$rejection <- 1 - ui_data$release_binary
  rejection_aov <- aov(rejection ~ condition, data = ui_data)
  rejection_summary <- summary(rejection_aov)
  
  # Extract F-statistics and p-values
  tendency_f <- tendency_summary[[1]][["F value"]][1]
  tendency_p <- tendency_summary[[1]][["Pr(>F)"]][1]
  
  rejection_f <- rejection_summary[[1]][["F value"]][1]
  rejection_p <- rejection_summary[[1]][["Pr(>F)"]][1]
  
  # Post-hoc pairwise comparisons (planned contrasts)
  # UEQ vs UEQ+Autonomy (original hypothesis)
  ueq_data <- ui_data %>% filter(condition == "UEQ")
  ueq_autonomy_data <- ui_data %>% filter(condition == "UEQ+Autonomy")
  raw_data <- ui_data %>% filter(condition == "RAW")
  
  # Tendency comparisons
  if(nrow(ueq_data) > 0 & nrow(ueq_autonomy_data) > 0) {
    ueq_vs_autonomy_tend <- t.test(ueq_data$tendency_numeric, ueq_autonomy_data$tendency_numeric, 
                                   alternative = "greater") # UEQ > UEQ+Autonomy
    ueq_autonomy_tend_p <- ueq_vs_autonomy_tend$p.value
    ueq_autonomy_tend_d <- (mean(ueq_data$tendency_numeric) - mean(ueq_autonomy_data$tendency_numeric)) / 
      sqrt(((nrow(ueq_data)-1)*var(ueq_data$tendency_numeric) + (nrow(ueq_autonomy_data)-1)*var(ueq_autonomy_data$tendency_numeric)) / 
           (nrow(ueq_data) + nrow(ueq_autonomy_data) - 2))
  } else {
    ueq_autonomy_tend_p <- NA
    ueq_autonomy_tend_d <- NA
  }
  
  # Rejection rate comparisons  
  if(nrow(ueq_data) > 0 & nrow(ueq_autonomy_data) > 0) {
    ueq_vs_autonomy_rej <- t.test(ueq_data$rejection, ueq_autonomy_data$rejection, 
                                  alternative = "less") # UEQ < UEQ+Autonomy (lower rejection)
    ueq_autonomy_rej_p <- ueq_vs_autonomy_rej$p.value
    ueq_autonomy_rej_d <- (mean(ueq_data$rejection) - mean(ueq_autonomy_data$rejection)) / 
      sqrt(((nrow(ueq_data)-1)*var(ueq_data$rejection) + (nrow(ueq_autonomy_data)-1)*var(ueq_autonomy_data$rejection)) / 
           (nrow(ueq_data) + nrow(ueq_autonomy_data) - 2))
  } else {
    ueq_autonomy_rej_p <- NA
    ueq_autonomy_rej_d <- NA
  }
  
  # RAW comparisons
  if(nrow(raw_data) > 0 & nrow(ueq_data) > 0) {
    raw_vs_ueq_tend <- t.test(raw_data$tendency_numeric, ueq_data$tendency_numeric)
    raw_ueq_tend_p <- raw_vs_ueq_tend$p.value
  } else {
    raw_ueq_tend_p <- NA
  }
  
  if(nrow(raw_data) > 0 & nrow(ueq_autonomy_data) > 0) {
    raw_vs_autonomy_tend <- t.test(raw_data$tendency_numeric, ueq_autonomy_data$tendency_numeric)
    raw_autonomy_tend_p <- raw_vs_autonomy_tend$p.value
  } else {
    raw_autonomy_tend_p <- NA
  }
  
  # Store results
  anova_results[[ui]] <- data.frame(
    interface = ui,
    tendency_f = tendency_f,
    tendency_p = tendency_p,
    rejection_f = rejection_f,
    rejection_p = rejection_p,
    ueq_autonomy_tend_p = ueq_autonomy_tend_p,
    ueq_autonomy_tend_d = ueq_autonomy_tend_d,
    ueq_autonomy_rej_p = ueq_autonomy_rej_p,
    ueq_autonomy_rej_d = ueq_autonomy_rej_d,
    raw_ueq_tend_p = raw_ueq_tend_p,
    raw_autonomy_tend_p = raw_autonomy_tend_p,
    n_ueq = nrow(ueq_data),
    n_autonomy = nrow(ueq_autonomy_data),
    n_raw = nrow(raw_data),
    mean_tendency_ueq = ifelse(nrow(ueq_data) > 0, mean(ueq_data$tendency_numeric), NA),
    mean_tendency_autonomy = ifelse(nrow(ueq_autonomy_data) > 0, mean(ueq_autonomy_data$tendency_numeric), NA),
    mean_tendency_raw = ifelse(nrow(raw_data) > 0, mean(raw_data$tendency_numeric), NA),
    mean_rejection_ueq = ifelse(nrow(ueq_data) > 0, mean(ueq_data$rejection), NA),
    mean_rejection_autonomy = ifelse(nrow(ueq_autonomy_data) > 0, mean(ueq_autonomy_data$rejection), NA),
    mean_rejection_raw = ifelse(nrow(raw_data) > 0, mean(raw_data$rejection), NA)
  )
}

# ===== COMBINE RESULTS =====
cat("\n3. COMBINING RESULTS...\n")
all_results <- bind_rows(anova_results)

# ===== FDR CORRECTION =====
cat("\n4. APPLYING FDR CORRECTION...\n")

# FDR correction for UEQ vs UEQ+Autonomy comparisons (original hypothesis)
all_results$ueq_autonomy_tend_p_fdr <- p.adjust(all_results$ueq_autonomy_tend_p, method = "fdr")
all_results$ueq_autonomy_rej_p_fdr <- p.adjust(all_results$ueq_autonomy_rej_p, method = "fdr")

# FDR correction for ANOVA p-values
all_results$tendency_p_fdr <- p.adjust(all_results$tendency_p, method = "fdr")
all_results$rejection_p_fdr <- p.adjust(all_results$rejection_p, method = "fdr")

# ===== IDENTIFY SIGNIFICANT INTERFACES =====
cat("\n5. IDENTIFYING SIGNIFICANT INTERFACES...\n")

# Significant UEQ vs UEQ+Autonomy differences (FDR corrected)
sig_tendency <- all_results %>%
  filter(ueq_autonomy_tend_p_fdr < 0.05) %>%
  arrange(ueq_autonomy_tend_p_fdr)

sig_rejection <- all_results %>%
  filter(ueq_autonomy_rej_p_fdr < 0.05) %>%
  arrange(ueq_autonomy_rej_p_fdr)

cat("Significant tendency differences (UEQ > UEQ+Autonomy):\n")
if(nrow(sig_tendency) > 0) {
  print(sig_tendency %>% select(interface, ueq_autonomy_tend_p_fdr, ueq_autonomy_tend_d, 
                               mean_tendency_ueq, mean_tendency_autonomy))
} else {
  cat("None\n")
}

cat("\nSignificant rejection rate differences (UEQ < UEQ+Autonomy):\n")
if(nrow(sig_rejection) > 0) {
  print(sig_rejection %>% select(interface, ueq_autonomy_rej_p_fdr, ueq_autonomy_rej_d,
                                mean_rejection_ueq, mean_rejection_autonomy))
} else {
  cat("None\n")
}

# ===== SAVE RESULTS =====
cat("\n6. SAVING RESULTS...\n")

write.csv(all_results, "results/three_condition_anova_results.csv", row.names = FALSE)

# Create summary of significant results
significant_summary <- data.frame(
  Analysis = c("Tendency Differences (UEQ > UEQ+Autonomy)", "Rejection Rate Differences (UEQ < UEQ+Autonomy)"),
  Significant_Interfaces = c(nrow(sig_tendency), nrow(sig_rejection)),
  Total_Tested = c(nrow(all_results), nrow(all_results))
)

write.csv(significant_summary, "results/significance_summary.csv", row.names = FALSE)

cat("Files created:\n")
cat("• results/three_condition_anova_results.csv - Complete statistical results\n")
cat("• results/significance_summary.csv - Summary of significant findings\n")

cat("\n✓ Statistical analysis complete!\n")
