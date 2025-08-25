# Individual Interface Analysis with Cleaned Data (AI/Suspicious Participants Excluded)
# Using One-Tailed Tests and Multiple Comparison Options

# Load required packages
library(dplyr)
library(ggplot2)
library(ggstatsplot)
library(patchwork)

# Create directories
dir.create("plots", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)

cat("=== INDIVIDUAL INTERFACE ANALYSIS WITH CLEANED DATA ===\n")
cat("Using cleaned dataset with AI/suspicious participants excluded\n")
cat("N = 83 participants (UEQ: 46, UEQ+Autonomy: 37)\n\n")

# ===== LOAD CLEANED DATA =====

# Load cleaned participant data
clean_data <- read.csv("results/clean_data_for_analysis.csv")
cat("Clean data loaded: N =", nrow(clean_data), "participants\n")
cat("UEQ condition:", sum(clean_data$condition == "UEQ"), "participants\n")
cat("UEQ+Autonomy condition:", sum(clean_data$condition == "UEQ+Autonomy"), "participants\n\n")

# ===== LOAD AND FILTER INTERFACE DATA =====

# Load original interface data and filter to only include clean participants
if(file.exists("results/interface_plot_data_updated.csv")) {
  interface_data_all <- read.csv("results/interface_plot_data_updated.csv")
} else {
  # If the interface data doesn't exist, we need to recreate it from clean data
  cat("Interface data not found. Creating from clean participant data...\n")
  
  # Load raw data and filter
  raw_data <- read.delim("aug17_utf8.tsv", sep = "\t", header = TRUE, 
                         stringsAsFactors = FALSE, encoding = "UTF-8")
  
  # Filter to only clean participants
  clean_ids <- clean_data$PROLIFIC_PID
  
  # Extract interface-level responses for clean participants only
  interface_data_list <- list()
  
  for(pid in clean_ids) {
    participant_rows <- raw_data[raw_data$PROLIFIC_PID == pid, ]
    if(nrow(participant_rows) == 0) next
    
    condition <- clean_data$condition[clean_data$PROLIFIC_PID == pid][1]
    
    # Extract interface responses
    for(ui_num in 1:15) {
      tendency_col <- paste0("ui", sprintf("%03d", ui_num), "_tendency")
      release_col <- paste0("ui", sprintf("%03d", ui_num), "_release")
      
      if(tendency_col %in% names(participant_rows) && release_col %in% names(participant_rows)) {
        tendency_val <- participant_rows[[tendency_col]][1]
        release_val <- participant_rows[[release_col]][1]
        
        if(!is.na(tendency_val) && !is.na(release_val) && 
           tendency_val != "" && release_val != "") {
          
          interface_data_list[[length(interface_data_list) + 1]] <- data.frame(
            PROLIFIC_PID = pid,
            condition = condition,
            condition_f = factor(condition, levels = c("UEQ", "UEQ+Autonomy")),
            interface_num = ui_num,
            tendency = as.numeric(tendency_val),
            release = release_val,
            rejection_pct = ifelse(release_val == "No", 100, 0)
          )
        }
      }
    }
  }
  
  interface_data <- do.call(rbind, interface_data_list)
  
  # Save the filtered interface data
  write.csv(interface_data, "results/interface_plot_data_cleaned.csv", row.names = FALSE)
  cat("✓ Clean interface data created and saved\n")
} 

# Use the clean interface data
if(exists("interface_data")) {
  # Already created above
} else {
  interface_data <- read.csv("results/interface_plot_data_cleaned.csv")
  interface_data$condition_f <- factor(interface_data$condition, levels = c("UEQ", "UEQ+Autonomy"))
}

cat("Interface data loaded: N =", nrow(interface_data), "interface evaluations\n")
cat("Unique participants:", length(unique(interface_data$PROLIFIC_PID)), "\n\n")

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

# ===== STATISTICAL TESTING WITH ONE-TAILED TESTS =====

cat("=== PERFORMING ONE-TAILED STATISTICAL TESTS ===\n")
cat("H1: UEQ+Autonomy will show LOWER tendency to release (more conservative)\n")
cat("H2: UEQ+Autonomy will show HIGHER rejection rates (more conservative)\n\n")

# Function to perform one-tailed tests for each interface
perform_interface_tests_onetailed <- function() {
  results_list <- list()
  
  for(ui_num in 1:15) {
    ui_data <- interface_data %>%
      filter(interface_num == ui_num)
    
    if(nrow(ui_data) < 6 || length(unique(ui_data$condition_f)) != 2) {
      cat("Skipping UI", ui_num, "- insufficient data\n")
      next
    }
    
    pattern_name <- ui_mapping$pattern_short[ui_mapping$interface_num == ui_num]
    
    # Sample sizes per condition
    n_ueq <- sum(ui_data$condition_f == "UEQ")
    n_uea <- sum(ui_data$condition_f == "UEQ+Autonomy")
    
    cat("UI", ui_num, "(", pattern_name, "): n_UEQ =", n_ueq, ", n_UEQ+Autonomy =", n_uea, "\n")
    
    # Test 1: Rejection rates (binary) - One-tailed
    ui_binary <- ui_data %>%
      mutate(rejected_binary = ifelse(rejection_pct > 0, 1, 0))
    
    contingency_table <- table(ui_binary$condition_f, ui_binary$rejected_binary)
    
    # Check if we can use chi-square
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
    ueq_rejection_rate <- mean(ui_data$rejection_pct[ui_data$condition_f == "UEQ"], na.rm = TRUE)
    uea_rejection_rate <- mean(ui_data$rejection_pct[ui_data$condition_f == "UEQ+Autonomy"], na.rm = TRUE)
    
    if(uea_rejection_rate > ueq_rejection_rate) {
      rejection_p_onetailed <- rejection_p_twotailed / 2  # Correct direction
    } else {
      rejection_p_onetailed <- 1 - (rejection_p_twotailed / 2)  # Wrong direction
    }
    
    # Test 2: Tendency scores (continuous) - One-tailed
    # H1: UEQ+Autonomy < UEQ (lower tendency to release)
    ueq_tendency <- ui_data$tendency[ui_data$condition_f == "UEQ"]
    uea_tendency <- ui_data$tendency[ui_data$condition_f == "UEQ+Autonomy"]
    
    # Perform two-tailed t-test first
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
    
    # Calculate means and differences
    rejection_diff <- uea_rejection_rate - ueq_rejection_rate
    tendency_diff <- mean(uea_tendency, na.rm=TRUE) - mean(ueq_tendency, na.rm=TRUE)
    
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
      rejection_diff = rejection_diff,
      rejection_p_twotailed = rejection_p_twotailed,
      rejection_p_onetailed = rejection_p_onetailed,
      
      # Tendency results
      ueq_tendency_mean = mean(ueq_tendency, na.rm=TRUE),
      uea_tendency_mean = mean(uea_tendency, na.rm=TRUE),
      tendency_diff = tendency_diff,
      tendency_cohens_d = cohens_d,
      tendency_p_twotailed = tendency_p_twotailed,
      tendency_p_onetailed = tendency_p_onetailed
    )
  }
  
  return(do.call(rbind, results_list))
}

# Get all test results
interface_results <- perform_interface_tests_onetailed()

cat("\n=== ONE-TAILED TEST RESULTS ===\n")
print(interface_results %>% 
      select(interface, pattern_name, n_total, rejection_p_onetailed, tendency_p_onetailed) %>%
      arrange(tendency_p_onetailed))

# ===== MULTIPLE COMPARISONS CORRECTIONS =====

cat("\n=== APPLYING MULTIPLE COMPARISONS CORRECTIONS ===\n")
cat("Testing 15 interfaces × 2 measures = 30 statistical tests\n")

# Separate results for different measures
rejection_summary <- interface_results %>%
  select(interface, pattern_name, n_total, rejection_p_onetailed, rejection_diff) %>%
  rename(p_onetailed = rejection_p_onetailed)

tendency_summary <- interface_results %>%
  select(interface, pattern_name, n_total, tendency_p_onetailed, tendency_cohens_d) %>%
  rename(p_onetailed = tendency_p_onetailed)

# Apply different correction methods for rejection tests
rejection_summary$p_bonferroni <- p.adjust(rejection_summary$p_onetailed, method = "bonferroni")
rejection_summary$p_fdr <- p.adjust(rejection_summary$p_onetailed, method = "BH")
rejection_summary$p_holm <- p.adjust(rejection_summary$p_onetailed, method = "holm")

# Apply different correction methods for tendency tests
tendency_summary$p_bonferroni <- p.adjust(tendency_summary$p_onetailed, method = "bonferroni")
tendency_summary$p_fdr <- p.adjust(tendency_summary$p_onetailed, method = "BH")
tendency_summary$p_holm <- p.adjust(tendency_summary$p_onetailed, method = "holm")

# Add significance indicators
add_significance_indicators <- function(df) {
  df %>%
    mutate(
      sig_uncorrected = p_onetailed < 0.05,
      sig_bonferroni = p_bonferroni < 0.05,
      sig_fdr = p_fdr < 0.05,
      sig_holm = p_holm < 0.05,
      
      # Choose most lenient significant correction for display
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
}

rejection_summary <- add_significance_indicators(rejection_summary)
tendency_summary <- add_significance_indicators(tendency_summary)

# Print correction comparison
cat("\n=== MULTIPLE CORRECTION COMPARISON ===\n")
cat("REJECTION RATES (15 tests):\n")
cat("• Uncorrected (p < 0.05):", sum(rejection_summary$sig_uncorrected), "of 15\n")
cat("• FDR corrected:", sum(rejection_summary$sig_fdr), "of 15\n")
cat("• Holm corrected:", sum(rejection_summary$sig_holm), "of 15\n")  
cat("• Bonferroni corrected:", sum(rejection_summary$sig_bonferroni), "of 15\n\n")

cat("TENDENCY SCORES (15 tests):\n")
cat("• Uncorrected (p < 0.05):", sum(tendency_summary$sig_uncorrected), "of 15\n")
cat("• FDR corrected:", sum(tendency_summary$sig_fdr), "of 15\n")
cat("• Holm corrected:", sum(tendency_summary$sig_holm), "of 15\n")
cat("• Bonferroni corrected:", sum(tendency_summary$sig_bonferroni), "of 15\n\n")

# ===== CREATE UPDATED PLOTS =====

# Function to create plots with one-tailed significance indicators
create_onetailed_plot <- function(ui_num, measure = "tendency", correction = "fdr") {
  ui_data <- interface_data %>%
    filter(interface_num == ui_num)
  
  if(nrow(ui_data) < 6) return(NULL)
  
  pattern_name <- ui_mapping$pattern_short[ui_mapping$interface_num == ui_num]
  
  if(measure == "tendency") {
    # Get significance info
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
      x = condition_f,
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
  }
  
  return(p)
}

# Create plots with different correction methods
corrections <- c("uncorrected", "fdr", "holm", "bonferroni")
correction_labels <- c("Uncorrected", "FDR (Recommended)", "Holm", "Bonferroni (Most Conservative)")

for(i in 1:length(corrections)) {
  correction <- corrections[i]
  label <- correction_labels[i]
  
  cat("Creating plots with", label, "correction...\n")
  
  # Create tendency plots
  tendency_plots <- list()
  for(ui_num in 1:15) {
    plot <- create_onetailed_plot(ui_num, "tendency", correction)
    if(!is.null(plot)) {
      tendency_plots[[paste0("ui", ui_num)]] <- plot
    }
  }
  
  # Combine tendency grid
  if(length(tendency_plots) > 0) {
    tendency_grid <- wrap_plots(tendency_plots, ncol = 5, nrow = 3)
    
    tendency_final <- tendency_grid + 
      plot_annotation(
        title = paste0("Dark Pattern Tendency Scores: UEQ vs UEQ+Autonomy (", label, ")"),
        subtitle = paste0("One-tailed tests (UEQ+Autonomy < UEQ). *** = p < 0.05 after ", tolower(label), " correction\n",
                         "Clean dataset: N=83 (AI/suspicious participants excluded). Red titles = significant"),
        theme = theme(
          plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
          plot.subtitle = element_text(size = 12, hjust = 0.5)
        )
      )
    
    filename <- paste0("plots/dark_patterns_tendency_cleaned_", correction, "_onetailed.png")
    ggsave(filename, plot = tendency_final, width = 24, height = 14, dpi = 300)
    cat("✓ Saved:", filename, "\n")
  }
}

# ===== SAVE RESULTS =====
complete_results <- interface_results %>%
  left_join(
    tendency_summary %>% select(interface, sig_fdr, sig_holm, sig_bonferroni, p_fdr, p_holm, p_bonferroni),
    by = "interface",
    suffix = c("", "_tendency")
  )

write.csv(complete_results, "results/individual_interface_analysis_cleaned_onetailed.csv", row.names = FALSE)
write.csv(tendency_summary, "results/tendency_corrections_summary.csv", row.names = FALSE)
write.csv(rejection_summary, "results/rejection_corrections_summary.csv", row.names = FALSE)

# ===== RECOMMENDATIONS SUMMARY =====
cat("\n" + paste(rep("=", 60), collapse="") + "\n")
cat("RECOMMENDATIONS FOR MULTIPLE COMPARISONS CORRECTION\n")
cat(paste(rep("=", 60), collapse="") + "\n")

cat("1. BONFERRONI: Most conservative, controls family-wise error rate\n")
cat("   - Use when: Type I error must be minimized at all costs\n")
cat("   - Significant results:", sum(tendency_summary$sig_bonferroni), "of 15 interfaces\n\n")

cat("2. HOLM: Slightly less conservative than Bonferroni, more powerful\n") 
cat("   - Use when: Good balance of Type I error control and power\n")
cat("   - Significant results:", sum(tendency_summary$sig_holm), "of 15 interfaces\n\n")

cat("3. FDR (FALSE DISCOVERY RATE): Recommended for exploratory research\n")
cat("   - Use when: Some false positives acceptable, want to find effects\n")
cat("   - Significant results:", sum(tendency_summary$sig_fdr), "of 15 interfaces\n\n")

cat("4. UNCORRECTED: Only if you have strong a priori hypotheses\n")
cat("   - Use when: Pre-registered specific interface predictions\n")
cat("   - Significant results:", sum(tendency_summary$sig_uncorrected), "of 15 interfaces\n\n")

cat("RECOMMENDATION: Use FDR correction as it balances discovery and false positive control\n")
cat("File created: plots/dark_patterns_tendency_cleaned_fdr_onetailed.png\n\n")

cat("FILES CREATED:\n")
for(correction in corrections) {
  filename <- paste0("plots/dark_patterns_tendency_cleaned_", correction, "_onetailed.png")
  cat("•", filename, "\n")
}
cat("• results/individual_interface_analysis_cleaned_onetailed.csv\n")
cat("• results/tendency_corrections_summary.csv\n")
cat("• results/rejection_corrections_summary.csv\n")

cat("\n=== INDIVIDUAL INTERFACE ANALYSIS COMPLETE ===\n")
