# Enhanced Dark Pattern Analysis with Significance Indicators and Multiple Comparisons Correction
# Adding asterisks for significance and correcting for multiple testing

# Load required packages
library(dplyr)
library(ggplot2)
library(ggstatsplot)
library(patchwork)

# Create the UI pattern name mapping
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

# Load the interface-level data
interface_data <- read.csv("results/interface_plot_data_updated.csv")

cat("=== MULTIPLE COMPARISONS CORRECTION ANALYSIS ===\n")
cat("Testing 15 interfaces × 2 measures = 30 statistical tests\n")
cat("Applying Benjamini-Hochberg (FDR) and Bonferroni corrections\n\n")

# ===== COMPREHENSIVE STATISTICAL TESTING WITH CORRECTIONS =====

# Function to perform all statistical tests
perform_all_interface_tests <- function() {
  results_list <- list()
  
  for(ui_num in 1:15) {
    ui_data <- interface_data %>%
      filter(interface_num == ui_num)
    
    if(nrow(ui_data) < 6 || length(unique(ui_data$condition_f)) != 2) {
      next
    }
    
    pattern_name <- ui_mapping$pattern_short[ui_mapping$interface_num == ui_num]
    
    # Test 1: Rejection rates (binary)
    ui_binary <- ui_data %>%
      mutate(rejected_binary = ifelse(rejection_pct > 0, 1, 0))
    
    contingency_table <- table(ui_binary$condition_f, ui_binary$rejected_binary)
    
    if(all(contingency_table >= 5)) {
      rejection_test <- chisq.test(contingency_table)
      rejection_p <- rejection_test$p.value
      rejection_method <- "Chi-square"
    } else {
      rejection_test <- fisher.test(contingency_table)
      rejection_p <- rejection_test$p.value
      rejection_method <- "Fisher's exact"
    }
    
    # Test 2: Tendency scores (continuous)
    tendency_test <- t.test(tendency ~ condition_f, data = ui_data)
    tendency_p <- tendency_test$p.value
    
    # Calculate effect sizes and means
    ueu_tend <- ui_data$tendency[ui_data$condition_f == "UEQ"]
    uea_tend <- ui_data$tendency[ui_data$condition_f == "UEQ+Autonomy"]
    
    pooled_sd <- sqrt(((length(ueu_tend)-1)*var(ueu_tend) + (length(uea_tend)-1)*var(uea_tend)) / 
                      (length(ueu_tend) + length(uea_tend) - 2))
    cohens_d <- (mean(uea_tend, na.rm=TRUE) - mean(ueu_tend, na.rm=TRUE)) / pooled_sd
    
    # Calculate rejection rate difference
    ueu_rej <- mean(ui_data$rejection_pct[ui_data$condition_f == "UEQ"], na.rm=TRUE)
    uea_rej <- mean(ui_data$rejection_pct[ui_data$condition_f == "UEQ+Autonomy"], na.rm=TRUE)
    rejection_diff <- uea_rej - ueu_rej
    
    # Store results
    results_list[[length(results_list) + 1]] <- data.frame(
      interface = ui_num,
      pattern_name = pattern_name,
      n_total = nrow(ui_data),
      rejection_method = rejection_method,
      rejection_p_raw = rejection_p,
      rejection_diff_pct = rejection_diff,
      tendency_p_raw = tendency_p,
      tendency_cohens_d = cohens_d,
      test_type = c("rejection", "tendency"),
      p_value_raw = c(rejection_p, tendency_p)
    )
  }
  
  return(do.call(rbind, results_list))
}

# Get all test results
all_results <- perform_all_interface_tests()

# Create separate dataframes for each test type
rejection_results <- all_results %>%
  filter(test_type == "rejection") %>%
  select(interface, pattern_name, rejection_p_raw, rejection_diff_pct, rejection_method) %>%
  distinct()

tendency_results <- all_results %>%
  filter(test_type == "tendency") %>%
  select(interface, pattern_name, tendency_p_raw, tendency_cohens_d) %>%
  distinct()

# ===== MULTIPLE COMPARISONS CORRECTIONS =====

# Apply corrections for rejection tests (15 tests)
rejection_results$rejection_p_bonferroni <- p.adjust(rejection_results$rejection_p_raw, method = "bonferroni")
rejection_results$rejection_p_fdr <- p.adjust(rejection_results$rejection_p_raw, method = "BH")

# Apply corrections for tendency tests (15 tests) 
tendency_results$tendency_p_bonferroni <- p.adjust(tendency_results$tendency_p_raw, method = "bonferroni")
tendency_results$tendency_p_fdr <- p.adjust(tendency_results$tendency_p_raw, method = "BH")

# Determine significance levels with corrections
rejection_results <- rejection_results %>%
  mutate(
    sig_uncorrected = rejection_p_raw < 0.05,
    sig_bonferroni = rejection_p_bonferroni < 0.05,
    sig_fdr = rejection_p_fdr < 0.05,
    sig_symbol = ifelse(sig_fdr, "***", ifelse(sig_uncorrected, "*", "")),
    sig_level = case_when(
      sig_bonferroni ~ "Bonferroni",
      sig_fdr ~ "FDR",
      sig_uncorrected ~ "Uncorrected",
      TRUE ~ "Not Sig"
    )
  )

tendency_results <- tendency_results %>%
  mutate(
    sig_uncorrected = tendency_p_raw < 0.05,
    sig_bonferroni = tendency_p_bonferroni < 0.05,
    sig_fdr = tendency_p_fdr < 0.05,
    sig_symbol = ifelse(sig_fdr, "***", ifelse(sig_uncorrected, "*", "")),
    sig_level = case_when(
      sig_bonferroni ~ "Bonferroni",
      sig_fdr ~ "FDR",
      sig_uncorrected ~ "Uncorrected",
      TRUE ~ "Not Sig"
    )
  )

# Print correction results
cat("=== MULTIPLE COMPARISONS CORRECTION RESULTS ===\n")
cat("REJECTION TESTS (15 comparisons):\n")
print(rejection_results %>% select(interface, pattern_name, rejection_p_raw, rejection_p_fdr, rejection_p_bonferroni, sig_level))

cat("\nTENDENCY TESTS (15 comparisons):\n")
print(tendency_results %>% select(interface, pattern_name, tendency_p_raw, tendency_p_fdr, tendency_p_bonferroni, sig_level))

# ===== CREATE CHARTS WITH SIGNIFICANCE INDICATORS =====

# Function to create plots with significance indicators
create_significance_plot <- function(ui_num, measure = "rejection") {
  ui_data <- interface_data %>%
    filter(interface_num == ui_num)
  
  if(nrow(ui_data) < 6) return(NULL)
  
  pattern_name <- ui_mapping$pattern_short[ui_mapping$interface_num == ui_num]
  
  if(measure == "rejection") {
    # Get significance info
    sig_info <- rejection_results %>% filter(interface == ui_num)
    p_val <- sig_info$rejection_p_fdr[1]
    sig_symbol <- sig_info$sig_symbol[1]
    sig_level <- sig_info$sig_level[1]
    
    # Create plot
    p <- ggbetweenstats(
      data = ui_data,
      x = condition_f,
      y = rejection_pct,
      plot.type = "box",
      type = "nonparametric",
      centrality.plotting = TRUE,
      bf.message = FALSE,
      results.subtitle = FALSE,
      pairwise.display = "none",  # We'll add our own significance
      xlab = "",
      ylab = if(ui_num == 1) "Rejection Rate (%)" else "",
      title = paste0(pattern_name, " ", sig_symbol),
      subtitle = paste0("FDR p = ", round(p_val, 3), " (", sig_level, ")")
    ) +
      theme_ggstatsplot() +
      theme(
        plot.title = element_text(size = 11, hjust = 0.5, face = "bold", 
                                  color = ifelse(sig_info$sig_fdr[1], "red", "black")),
        plot.subtitle = element_text(size = 9),
        axis.text.x = element_text(size = 8),
        legend.position = "none"
      ) +
      ylim(0, 100)
    
    # Add significance line if significant after FDR correction
    if(sig_info$sig_fdr[1]) {
      p <- p + 
        annotate("segment", x = 1, xend = 2, y = 95, yend = 95, color = "red", size = 1) +
        annotate("text", x = 1.5, y = 98, label = "***", color = "red", size = 4, fontface = "bold")
    }
    
  } else if(measure == "tendency") {
    # Get significance info
    sig_info <- tendency_results %>% filter(interface == ui_num)
    p_val <- sig_info$tendency_p_fdr[1]
    sig_symbol <- sig_info$sig_symbol[1]
    sig_level <- sig_info$sig_level[1]
    
    # Create plot
    p <- ggbetweenstats(
      data = ui_data,
      x = condition_f,
      y = tendency,
      plot.type = "box",
      type = "parametric",
      centrality.plotting = TRUE,
      bf.message = FALSE,
      results.subtitle = FALSE,
      pairwise.display = "none",  # We'll add our own significance
      xlab = "",
      ylab = if(ui_num == 1) "Tendency Score (1-7)" else "",
      title = paste0(pattern_name, " ", sig_symbol),
      subtitle = paste0("FDR p = ", round(p_val, 3), " (", sig_level, ")")
    ) +
      theme_ggstatsplot() +
      theme(
        plot.title = element_text(size = 11, hjust = 0.5, face = "bold",
                                  color = ifelse(sig_info$sig_fdr[1], "red", "black")),
        plot.subtitle = element_text(size = 9),
        axis.text.x = element_text(size = 8),
        legend.position = "none"
      ) +
      ylim(1, 7)
    
    # Add significance line if significant after FDR correction
    if(sig_info$sig_fdr[1]) {
      p <- p + 
        annotate("segment", x = 1, xend = 2, y = 6.5, yend = 6.5, color = "red", size = 1) +
        annotate("text", x = 1.5, y = 6.8, label = "***", color = "red", size = 4, fontface = "bold")
    }
  }
  
  return(p)
}

# ===== CREATE CORRECTED CHARTS =====
cat("\n=== CREATING CHARTS WITH SIGNIFICANCE INDICATORS AND CORRECTIONS ===\n")

# Create rejection plots
rejection_plots_corrected <- list()
for(i in 1:15) {
  plot <- create_significance_plot(i, "rejection")
  if(!is.null(plot)) {
    rejection_plots_corrected[[paste0("ui", i)]] <- plot
  }
}

# Combine rejection grid
if(length(rejection_plots_corrected) > 0) {
  rejection_grid_corrected <- wrap_plots(rejection_plots_corrected, ncol = 5, nrow = 3)
  
  rejection_final_corrected <- rejection_grid_corrected + 
    plot_annotation(
      title = "Dark Pattern Rejection Rates: UEQ vs UEQ+Autonomy (FDR Corrected)",
      subtitle = "*** = Significant after FDR correction for multiple testing (15 comparisons)\n* = Significant uncorrected. Red titles = FDR significant",
      theme = theme(
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5)
      )
    )
  
  ggsave("plots/dark_patterns_rejection_corrected_significance.png",
         plot = rejection_final_corrected,
         width = 24, height = 14, dpi = 300)
  
  cat("✓ Corrected rejection plot saved to plots/dark_patterns_rejection_corrected_significance.png\n")
}

# Create tendency plots
tendency_plots_corrected <- list()
for(i in 1:15) {
  plot <- create_significance_plot(i, "tendency")
  if(!is.null(plot)) {
    tendency_plots_corrected[[paste0("ui", i)]] <- plot
  }
}

# Combine tendency grid
if(length(tendency_plots_corrected) > 0) {
  tendency_grid_corrected <- wrap_plots(tendency_plots_corrected, ncol = 5, nrow = 3)
  
  tendency_final_corrected <- tendency_grid_corrected + 
    plot_annotation(
      title = "Dark Pattern Tendency Scores: UEQ vs UEQ+Autonomy (FDR Corrected)",
      subtitle = "*** = Significant after FDR correction for multiple testing (15 comparisons)\n* = Significant uncorrected. Red titles = FDR significant",
      theme = theme(
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5)
      )
    )
  
  ggsave("plots/dark_patterns_tendency_corrected_significance.png",
         plot = tendency_final_corrected,
         width = 24, height = 14, dpi = 300)
  
  cat("✓ Corrected tendency plot saved to plots/dark_patterns_tendency_corrected_significance.png\n")
}

# ===== SAVE CORRECTED RESULTS =====
corrected_results <- rejection_results %>%
  full_join(tendency_results, by = c("interface", "pattern_name"))

write.csv(corrected_results, "results/dark_patterns_multiple_comparisons_corrected.csv", row.names = FALSE)

# ===== FINAL SUMMARY =====
cat("\n=== FINAL CORRECTED RESULTS SUMMARY ===\n")

# Count significances at different levels
cat("UNCORRECTED (α = 0.05):\n")
cat("• Rejection differences:", sum(rejection_results$sig_uncorrected), "of 15\n")
cat("• Tendency differences:", sum(tendency_results$sig_uncorrected), "of 15\n")

cat("\nFDR CORRECTED (α = 0.05):\n")
cat("• Rejection differences:", sum(rejection_results$sig_fdr), "of 15\n")
cat("• Tendency differences:", sum(tendency_results$sig_fdr), "of 15\n")

cat("\nBONFERRONI CORRECTED (α = 0.05):\n")
cat("• Rejection differences:", sum(rejection_results$sig_bonferroni), "of 15\n")
cat("• Tendency differences:", sum(tendency_results$sig_bonferroni), "of 15\n")

# List patterns that survive FDR correction
fdr_sig_rejection <- rejection_results %>% filter(sig_fdr) %>% pull(pattern_name)
fdr_sig_tendency <- tendency_results %>% filter(sig_fdr) %>% pull(pattern_name)

if(length(fdr_sig_rejection) > 0) {
  cat("\nPatterns with FDR-significant REJECTION differences:\n")
  for(pattern in fdr_sig_rejection) cat("• ", pattern, "\n")
}

if(length(fdr_sig_tendency) > 0) {
  cat("\nPatterns with FDR-significant TENDENCY differences:\n")
  for(pattern in fdr_sig_tendency) cat("• ", pattern, "\n")
}

cat("\nFiles created:\n")
cat("• plots/dark_patterns_rejection_corrected_significance.png - With FDR corrections and *** markers\n")
cat("• plots/dark_patterns_tendency_corrected_significance.png - With FDR corrections and *** markers\n")
cat("• results/dark_patterns_multiple_comparisons_corrected.csv - All correction methods\n")

cat("\n=== MULTIPLE COMPARISONS CORRECTED ANALYSIS COMPLETE ===\n")
