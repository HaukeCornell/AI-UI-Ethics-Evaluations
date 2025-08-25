# Individual Interface Analysis with Cleaned Data 
# One-tailed tests with multiple comparison corrections

library(dplyr)
library(ggplot2)
library(ggstatsplot)
library(patchwork)

# Create directories
dir.create("plots", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)

cat("=== INDIVIDUAL INTERFACE ANALYSIS (CLEANED DATA) ===\n")
cat("Using interface data with AI/suspicious participants excluded\n\n")

# ===== LOAD CLEANED INTERFACE DATA =====
interface_data <- read.csv("results/interface_plot_data_cleaned.csv")

cat("Clean interface data loaded:\n")
cat("• Interface evaluations: N =", nrow(interface_data), "\n")
cat("• Unique participants: N =", length(unique(interface_data$ResponseId)), "\n")

# Check condition distribution
condition_dist <- table(interface_data$condition)
cat("• Condition distribution:\n")
for(cond in names(condition_dist)) {
  cat("  -", cond, ":", condition_dist[cond], "evaluations\n")
}
cat("\n")

# ===== UI PATTERN MAPPING =====
ui_mapping <- data.frame(
  interface_num = 1:15,
  pattern_name = c(
    "bad defaults", "content customization", "endlessness", "expectation result mismatch",
    "false hierarchy", "forced access", "gamification", "hindering account deletion",
    "nagging", "overcomplicated process", "pull to refresh", "social connector",
    "toying with emotion", "trick wording", "social pressure"
  ),
  pattern_short = c(
    "Bad Defaults", "Content Custom", "Endlessness", "Expect. Mismatch",
    "False Hierarchy", "Forced Access", "Gamification", "Hinder Deletion",
    "Nagging", "Overcomplex", "Pull to Refresh", "Social Connect",
    "Toy w/ Emotion", "Trick Wording", "Social Pressure"
  )
)

# ===== ONE-TAILED STATISTICAL TESTS =====
cat("=== PERFORMING ONE-TAILED STATISTICAL TESTS ===\n")
cat("H1: UEQ+Autonomy will show LOWER tendency to release (more conservative)\n")
cat("H2: UEQ+Autonomy will show HIGHER rejection rates (more conservative)\n\n")

# Function to perform one-tailed tests for each interface
perform_interface_tests <- function() {
  results_list <- list()
  
  for(ui_num in 1:15) {
    ui_data <- interface_data %>%
      filter(interface_num == ui_num)
    
    if(nrow(ui_data) < 6 || length(unique(ui_data$condition)) != 2) {
      cat("Skipping UI", ui_num, "- insufficient data (n =", nrow(ui_data), ")\n")
      next
    }
    
    pattern_name <- ui_mapping$pattern_short[ui_mapping$interface_num == ui_num]
    
    # Sample sizes per condition
    n_ueq <- sum(ui_data$condition == "UEQ")
    n_uea <- sum(ui_data$condition == "UEQ+Autonomy") 
    
    cat("UI", ui_num, "(", pattern_name, "): n_UEQ =", n_ueq, ", n_UEQ+Autonomy =", n_uea, "\n")
    
    # Test 1: Rejection rates (binary) - One-tailed
    ueq_rejection_rate <- mean(ui_data$rejection_pct[ui_data$condition == "UEQ"], na.rm = TRUE)
    uea_rejection_rate <- mean(ui_data$rejection_pct[ui_data$condition == "UEQ+Autonomy"], na.rm = TRUE)
    
    # Chi-square or Fisher's exact test for binary data
    ui_binary <- ui_data %>%
      mutate(rejected_binary = ifelse(rejection_pct > 0, 1, 0))
    
    contingency_table <- table(ui_binary$condition, ui_binary$rejected_binary)
    
    if(all(contingency_table >= 5)) {
      rejection_test <- chisq.test(contingency_table)
      rejection_p_twotailed <- rejection_test$p.value
      rejection_method <- "Chi-square"
    } else {
      rejection_test <- fisher.test(contingency_table)
      rejection_p_twotailed <- rejection_test$p.value
      rejection_method <- "Fisher's exact"
    }
    
    # Convert to one-tailed p-value for rejection rates
    # H2: UEQ+Autonomy > UEQ (higher rejection rates)
    if(uea_rejection_rate > ueq_rejection_rate) {
      rejection_p_onetailed <- rejection_p_twotailed / 2  # Correct direction
    } else {
      rejection_p_onetailed <- 1 - (rejection_p_twotailed / 2)  # Wrong direction
    }
    
    # Test 2: Tendency scores (continuous) - One-tailed
    ueq_tendency <- ui_data$tendency[ui_data$condition == "UEQ"]
    uea_tendency <- ui_data$tendency[ui_data$condition == "UEQ+Autonomy"]
    
    # Two-tailed t-test first
    tendency_test <- t.test(ueq_tendency, uea_tendency, var.equal = TRUE)
    tendency_p_twotailed <- tendency_test$p.value
    
    # Convert to one-tailed p-value for tendency
    # H1: UEQ > UEQ+Autonomy (UEQ+Autonomy shows lower tendency)
    if(mean(ueq_tendency, na.rm = TRUE) > mean(uea_tendency, na.rm = TRUE)) {
      tendency_p_onetailed <- tendency_p_twotailed / 2  # Correct direction
    } else {
      tendency_p_onetailed <- 1 - (tendency_p_twotailed / 2)  # Wrong direction
    }
    
    # Calculate effect sizes
    pooled_sd <- sqrt(((length(ueq_tendency)-1)*var(ueq_tendency) + (length(uea_tendency)-1)*var(uea_tendency)) / 
                      (length(ueq_tendency) + length(uea_tendency) - 2))
    cohens_d <- (mean(uea_tendency, na.rm=TRUE) - mean(ueq_tendency, na.rm=TRUE)) / pooled_sd
    
    # Store results
    results_list[[length(results_list) + 1]] <- data.frame(
      interface = ui_num,
      pattern_name = pattern_name,
      n_ueq = n_ueq,
      n_uea = n_uea,
      n_total = nrow(ui_data),
      
      # Rejection results
      rejection_method = rejection_method,
      ueq_rejection_rate = ueq_rejection_rate,
      uea_rejection_rate = uea_rejection_rate,
      rejection_diff = uea_rejection_rate - ueq_rejection_rate,
      rejection_p_twotailed = rejection_p_twotailed,
      rejection_p_onetailed = rejection_p_onetailed,
      
      # Tendency results
      ueq_tendency_mean = mean(ueq_tendency, na.rm=TRUE),
      uea_tendency_mean = mean(uea_tendency, na.rm=TRUE),
      tendency_diff = mean(uea_tendency, na.rm=TRUE) - mean(ueq_tendency, na.rm=TRUE),
      tendency_cohens_d = cohens_d,
      tendency_p_twotailed = tendency_p_twotailed,
      tendency_p_onetailed = tendency_p_onetailed
    )
  }
  
  return(do.call(rbind, results_list))
}

# Get all test results
interface_results <- perform_interface_tests()

cat("\n=== ONE-TAILED TEST RESULTS (TOP 10 BY TENDENCY P-VALUE) ===\n")
top_results <- interface_results %>% 
  select(interface, pattern_name, n_total, tendency_p_onetailed, tendency_cohens_d) %>%
  arrange(tendency_p_onetailed) %>%
  head(10)
print(top_results)

# ===== MULTIPLE COMPARISONS CORRECTIONS =====
cat("\n=== APPLYING MULTIPLE COMPARISONS CORRECTIONS ===\n")
cat("Testing", nrow(interface_results), "interfaces × 2 measures =", nrow(interface_results)*2, "statistical tests\n")

# Tendency results with corrections
tendency_summary <- interface_results %>%
  select(interface, pattern_name, n_total, tendency_p_onetailed, tendency_cohens_d) %>%
  rename(p_onetailed = tendency_p_onetailed) %>%
  mutate(
    p_bonferroni = p.adjust(p_onetailed, method = "bonferroni"),
    p_fdr = p.adjust(p_onetailed, method = "BH"),
    p_holm = p.adjust(p_onetailed, method = "holm"),
    
    # Significance indicators
    sig_uncorrected = p_onetailed < 0.05,
    sig_bonferroni = p_bonferroni < 0.05,
    sig_fdr = p_fdr < 0.05,
    sig_holm = p_holm < 0.05,
    
    # Display symbols
    sig_symbol = case_when(
      sig_bonferroni ~ "***",
      sig_holm ~ "**", 
      sig_fdr ~ "*",
      sig_uncorrected ~ "·",
      TRUE ~ ""
    ),
    
    sig_level = case_when(
      sig_bonferroni ~ "Bonferroni",
      sig_holm ~ "Holm",
      sig_fdr ~ "FDR",
      sig_uncorrected ~ "Uncorrected",
      TRUE ~ "Not Sig"
    )
  )

# Print correction comparison
cat("\n=== MULTIPLE CORRECTION COMPARISON (TENDENCY SCORES) ===\n")
cat("• Uncorrected (p < 0.05):", sum(tendency_summary$sig_uncorrected), "of", nrow(tendency_summary), "\n")
cat("• FDR corrected:", sum(tendency_summary$sig_fdr), "of", nrow(tendency_summary), "\n")
cat("• Holm corrected:", sum(tendency_summary$sig_holm), "of", nrow(tendency_summary), "\n")  
cat("• Bonferroni corrected:", sum(tendency_summary$sig_bonferroni), "of", nrow(tendency_summary), "\n\n")

# Show significant results
if(sum(tendency_summary$sig_fdr) > 0) {
  cat("SIGNIFICANT AFTER FDR CORRECTION:\n")
  sig_fdr <- tendency_summary %>% filter(sig_fdr) %>% arrange(p_fdr)
  for(i in 1:nrow(sig_fdr)) {
    cat("•", sig_fdr$pattern_name[i], "(UI", sig_fdr$interface[i], "): p =", round(sig_fdr$p_fdr[i], 3), 
        ", d =", round(sig_fdr$tendency_cohens_d[i], 3), "\n")
  }
} else {
  cat("NO INTERFACES SIGNIFICANT AFTER FDR CORRECTION\n")
}

# ===== CREATE VISUALIZATION =====
cat("\n=== CREATING VISUALIZATION ===\n")

# Function to create individual interface plots
create_interface_plot <- function(ui_num, correction = "fdr") {
  ui_data <- interface_data %>%
    filter(interface_num == ui_num)
  
  if(nrow(ui_data) < 6) return(NULL)
  
  pattern_name <- ui_mapping$pattern_short[ui_mapping$interface_num == ui_num]
  sig_info <- tendency_summary %>% filter(interface == ui_num)
  
  p_val <- switch(correction,
                  "fdr" = sig_info$p_fdr[1],
                  "holm" = sig_info$p_holm[1], 
                  "bonferroni" = sig_info$p_bonferroni[1],
                  sig_info$p_onetailed[1])
  
  is_sig <- switch(correction,
                   "fdr" = sig_info$sig_fdr[1],
                   "holm" = sig_info$sig_holm[1],
                   "bonferroni" = sig_info$sig_bonferroni[1], 
                   sig_info$sig_uncorrected[1])
  
  sig_symbol <- ifelse(is_sig, "***", "")
  correction_label <- switch(correction,
                            "fdr" = "FDR",
                            "holm" = "Holm",
                            "bonferroni" = "Bonferroni",
                            "Uncorrected")
  
  # Create plot
  p <- ggbetweenstats(
    data = ui_data,
    x = condition,
    y = tendency,
    plot.type = "box",
    type = "parametric",
    centrality.plotting = TRUE,
    bf.message = FALSE,
    results.subtitle = FALSE,
    pairwise.display = "none",
    xlab = "",
    ylab = if(ui_num == 1) "Tendency Score (1-7)" else "",
    title = paste0(pattern_name, " ", sig_symbol),
    subtitle = paste0(correction_label, " p = ", round(p_val, 3), " (one-tailed)")
  ) +
    theme_ggstatsplot() +
    theme(
      plot.title = element_text(size = 11, hjust = 0.5, face = "bold",
                                color = ifelse(is_sig, "red", "black")),
      plot.subtitle = element_text(size = 9),
      axis.text.x = element_text(size = 8),
      legend.position = "none"
    ) +
    ylim(1, 7)
  
  # Add significance line if significant
  if(is_sig) {
    p <- p + 
      annotate("segment", x = 1, xend = 2, y = 6.5, yend = 6.5, color = "red", size = 1) +
      annotate("text", x = 1.5, y = 6.8, label = "***", color = "red", size = 4, fontface = "bold")
  }
  
  return(p)
}

# Create plots with FDR correction (recommended)
cat("Creating plots with FDR correction...\n")

tendency_plots <- list()
for(ui_num in 1:15) {
  plot <- create_interface_plot(ui_num, "fdr")
  if(!is.null(plot)) {
    tendency_plots[[paste0("ui", ui_num)]] <- plot
  }
}

# Combine plots
if(length(tendency_plots) > 0) {
  tendency_grid <- wrap_plots(tendency_plots, ncol = 5, nrow = 3)
  
  tendency_final <- tendency_grid + 
    plot_annotation(
      title = "Dark Pattern Tendency Scores: UEQ vs UEQ+Autonomy (FDR Corrected)",
      subtitle = paste0("One-tailed tests (UEQ+Autonomy < UEQ). *** = p < 0.05 after FDR correction\n",
                       "Clean dataset: N=", length(unique(interface_data$ResponseId)), 
                       " participants (AI/suspicious excluded). Red titles = significant"),
      theme = theme(
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5)
      )
    )
  
  filename <- "plots/dark_patterns_tendency_cleaned_fdr_onetailed.png"
  ggsave(filename, plot = tendency_final, width = 24, height = 14, dpi = 300)
  cat("✓ Saved:", filename, "\n")
}

# ===== SAVE RESULTS =====
write.csv(interface_results, "results/individual_interface_analysis_cleaned_onetailed.csv", row.names = FALSE)
write.csv(tendency_summary, "results/tendency_corrections_summary_cleaned.csv", row.names = FALSE)

cat("\n", paste(rep("=", 60), collapse=""), "\n")
cat("SUMMARY: MULTIPLE COMPARISONS CORRECTION RECOMMENDATIONS\n")
cat(paste(rep("=", 60), collapse=""), "\n")

cat("1. FDR (FALSE DISCOVERY RATE): ** RECOMMENDED **\n")
cat("   - Balances discovery potential with false positive control\n")
cat("   - Significant results:", sum(tendency_summary$sig_fdr), "of", nrow(tendency_summary), "interfaces\n\n")

cat("2. HOLM: More conservative than FDR\n") 
cat("   - Stronger Type I error control\n")
cat("   - Significant results:", sum(tendency_summary$sig_holm), "of", nrow(tendency_summary), "interfaces\n\n")

cat("3. BONFERRONI: Most conservative\n")
cat("   - Strictest family-wise error rate control\n")
cat("   - Significant results:", sum(tendency_summary$sig_bonferroni), "of", nrow(tendency_summary), "interfaces\n\n")

cat("CREATED FILES:\n")
cat("• plots/dark_patterns_tendency_cleaned_fdr_onetailed.png\n")
cat("• results/individual_interface_analysis_cleaned_onetailed.csv\n")
cat("• results/tendency_corrections_summary_cleaned.csv\n")

cat("\n=== INDIVIDUAL INTERFACE ANALYSIS COMPLETE ===\n")
cat("=== INDIVIDUAL INTERFACE ANALYSIS COMPLETE ===
")
