# Corrected Interface-Level Analysis: Side-by-Side Conditions with Proper Statistical Tests
# Each interface shows UEQ vs UEQ+Autonomy side-by-side with appropriate statistical tests

# Load required packages
library(dplyr)
library(ggplot2)
library(ggstatsplot)
library(patchwork)

# Load the interface-level data
interface_data <- read.csv("results/interface_plot_data_updated.csv")

cat("=== CORRECTED INTERFACE ANALYSIS ===\n")
cat("Creating side-by-side comparisons for each interface\n")
cat("Statistical tests: Chi-square for rejection rates, t-test for tendency scores\n\n")

# ===== STATISTICAL TEST EXPLANATIONS =====
cat("=== STATISTICAL TEST METHODS ===\n")
cat("1. REJECTION RATES (Binary 0/100%):\n")
cat("   - Chi-square test or Fisher's exact test (for small samples)\n")
cat("   - Tests association between condition and rejection (categorical data)\n")
cat("   - Appropriate for binary outcomes\n\n")

cat("2. TENDENCY SCORES (1-7 Likert):\n") 
cat("   - Independent samples t-test\n")
cat("   - Treats Likert data as continuous (common practice with 7-point scales)\n")
cat("   - Tests difference in means between conditions\n\n")

# ===== PREPARE DATA FOR SIDE-BY-SIDE PLOTTING =====

# Function to create individual interface comparison plots
create_interface_comparison_plot <- function(ui_num, measure = "rejection") {
  ui_data <- interface_data %>%
    filter(interface_num == ui_num)
  
  if(nrow(ui_data) < 6) return(NULL)  # Skip interfaces with too little data
  
  if(measure == "rejection") {
    # For rejection rates: convert to binary for statistical test
    ui_binary <- ui_data %>%
      mutate(rejected_binary = ifelse(rejection_pct > 0, 1, 0))
    
    # Chi-square or Fisher's exact test for binary data
    if(length(unique(ui_binary$condition_f)) == 2) {
      contingency_table <- table(ui_binary$condition_f, ui_binary$rejected_binary)
      
      if(all(contingency_table >= 5)) {
        test_result <- chisq.test(contingency_table)
        p_value <- test_result$p.value
        test_type <- "χ²"
      } else {
        test_result <- fisher.test(contingency_table)
        p_value <- test_result$p.value  
        test_type <- "Fisher"
      }
      
      # Create plot using ggbetweenstats for rejection percentages
      p <- ggbetweenstats(
        data = ui_data,
        x = condition_f,
        y = rejection_pct,
        plot.type = "box",
        type = "nonparametric",  # More appropriate for percentage data
        centrality.plotting = TRUE,
        bf.message = FALSE,
        results.subtitle = FALSE,
        xlab = "",
        ylab = if(ui_num == 1) "Rejection Rate (%)" else "",
        title = paste0("UI", ui_num),
        subtitle = paste0(test_type, " p = ", round(p_value, 3))
      ) +
        theme_ggstatsplot() +
        theme(
          plot.title = element_text(size = 12, hjust = 0.5),
          plot.subtitle = element_text(size = 10),
          axis.text.x = element_text(size = 9),
          legend.position = "none"
        ) +
        ylim(0, 100)
        
    } else {
      return(NULL)
    }
    
  } else if(measure == "tendency") {
    # For tendency scores: use t-test
    if(length(unique(ui_data$condition_f)) == 2) {
      p <- ggbetweenstats(
        data = ui_data,
        x = condition_f, 
        y = tendency,
        plot.type = "box",
        type = "parametric",
        centrality.plotting = TRUE,
        bf.message = FALSE,
        results.subtitle = TRUE,
        xlab = "",
        ylab = if(ui_num == 1) "Tendency Score (1-7)" else "",
        title = paste0("UI", ui_num)
      ) +
        theme_ggstatsplot() +
        theme(
          plot.title = element_text(size = 12, hjust = 0.5),
          plot.subtitle = element_text(size = 10),
          axis.text.x = element_text(size = 9),
          legend.position = "none"
        ) +
        ylim(1, 7)
    } else {
      return(NULL)
    }
  }
  
  return(p)
}

# ===== CREATE REJECTION RATE GRID =====
cat("Creating rejection rate comparison grid...\n")

rejection_plots <- list()
for(i in 1:15) {
  plot <- create_interface_comparison_plot(i, "rejection")
  if(!is.null(plot)) {
    rejection_plots[[paste0("ui", i)]] <- plot
  }
}

# Combine into grid
if(length(rejection_plots) > 0) {
  rejection_grid <- wrap_plots(rejection_plots, ncol = 5, nrow = 3)
  
  # Add overall title
  rejection_final <- rejection_grid + 
    plot_annotation(
      title = "Interface Rejection Rates: UEQ vs UEQ+Autonomy",
      subtitle = "Each panel shows side-by-side comparison for one interface\nStatistical tests: Chi-square (χ²) or Fisher's exact test for binary rejection data",
      theme = theme(
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5)
      )
    )
  
  # Save rejection grid
  ggsave("plots/interface_rejection_sidebyside_corrected.png",
         plot = rejection_final,
         width = 20, height = 12, dpi = 300)
  
  cat("✓ Rejection rate grid saved to plots/interface_rejection_sidebyside_corrected.png\n")
}

# ===== CREATE TENDENCY SCORE GRID =====
cat("Creating tendency score comparison grid...\n")

tendency_plots <- list()
for(i in 1:15) {
  plot <- create_interface_comparison_plot(i, "tendency")
  if(!is.null(plot)) {
    tendency_plots[[paste0("ui", i)]] <- plot
  }
}

# Combine into grid
if(length(tendency_plots) > 0) {
  tendency_grid <- wrap_plots(tendency_plots, ncol = 5, nrow = 3)
  
  # Add overall title
  tendency_final <- tendency_grid + 
    plot_annotation(
      title = "Interface Tendency Scores: UEQ vs UEQ+Autonomy", 
      subtitle = "Each panel shows side-by-side comparison for one interface\nStatistical tests: Independent samples t-test for continuous tendency data",
      theme = theme(
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5)
      )
    )
  
  # Save tendency grid
  ggsave("plots/interface_tendency_sidebyside_corrected.png",
         plot = tendency_final, 
         width = 20, height = 12, dpi = 300)
  
  cat("✓ Tendency score grid saved to plots/interface_tendency_sidebyside_corrected.png\n")
}

# ===== DETAILED STATISTICAL ANALYSIS =====
cat("\n=== DETAILED STATISTICAL RESULTS ===\n")

# Function to perform proper statistical tests
perform_interface_tests <- function(ui_num) {
  ui_data <- interface_data %>%
    filter(interface_num == ui_num)
  
  if(nrow(ui_data) < 6 || length(unique(ui_data$condition_f)) != 2) {
    return(NULL)
  }
  
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
  
  # Calculate effect sizes
  ueu_tend <- ui_data$tendency[ui_data$condition_f == "UEQ"]
  uea_tend <- ui_data$tendency[ui_data$condition_f == "UEQ+Autonomy"]
  
  pooled_sd <- sqrt(((length(ueu_tend)-1)*var(ueu_tend) + (length(uea_tend)-1)*var(uea_tend)) / 
                    (length(ueu_tend) + length(uea_tend) - 2))
  cohens_d <- (mean(uea_tend, na.rm=TRUE) - mean(ueu_tend, na.rm=TRUE)) / pooled_sd
  
  # Calculate rejection rate difference
  ueu_rej <- mean(ui_data$rejection_pct[ui_data$condition_f == "UEQ"], na.rm=TRUE)
  uea_rej <- mean(ui_data$rejection_pct[ui_data$condition_f == "UEQ+Autonomy"], na.rm=TRUE)
  rejection_diff <- uea_rej - ueu_rej
  
  return(data.frame(
    interface = ui_num,
    n_total = nrow(ui_data),
    rejection_method = rejection_method,
    rejection_p = rejection_p,
    rejection_diff_pct = rejection_diff,
    tendency_p = tendency_p,
    tendency_cohens_d = cohens_d,
    rejection_significant = rejection_p < 0.05,
    tendency_significant = tendency_p < 0.05
  ))
}

# Perform tests for all interfaces
all_interface_results <- do.call(rbind, lapply(1:15, perform_interface_tests))
all_interface_results <- all_interface_results[!is.na(all_interface_results$interface), ]

print(all_interface_results)

# Save detailed results
write.csv(all_interface_results, "results/corrected_interface_statistical_tests.csv", row.names = FALSE)

# ===== SUMMARY =====
cat("\n=== CORRECTED ANALYSIS SUMMARY ===\n")
cat("Statistical Methods Used:\n")
cat("• Rejection rates: Chi-square test or Fisher's exact test (appropriate for binary data)\n")
cat("• Tendency scores: Independent samples t-test (appropriate for Likert scale data)\n\n")

significant_rejection <- sum(all_interface_results$rejection_significant, na.rm = TRUE)
significant_tendency <- sum(all_interface_results$tendency_significant, na.rm = TRUE)

cat("Results:\n")
cat("• Interfaces with significant rejection differences:", significant_rejection, "\n")
cat("• Interfaces with significant tendency differences:", significant_tendency, "\n")

if(significant_rejection > 0) {
  sig_rej_interfaces <- all_interface_results$interface[all_interface_results$rejection_significant]
  cat("• Significant rejection interfaces:", paste(sig_rej_interfaces, collapse = ", "), "\n")
}

if(significant_tendency > 0) {
  sig_tend_interfaces <- all_interface_results$interface[all_interface_results$tendency_significant]
  cat("• Significant tendency interfaces:", paste(sig_tend_interfaces, collapse = ", "), "\n")
}

cat("\nFiles created:\n")
cat("• plots/interface_rejection_sidebyside_corrected.png - Side-by-side rejection comparisons\n")
cat("• plots/interface_tendency_sidebyside_corrected.png - Side-by-side tendency comparisons\n") 
cat("• results/corrected_interface_statistical_tests.csv - Proper statistical test results\n")

cat("\n=== ANALYSIS COMPLETE ===\n")
