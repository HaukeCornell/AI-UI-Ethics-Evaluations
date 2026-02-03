# Create Three-Condition Omnibus ANOVA Violin Plot with FDR Corrected Results
# Based on the successful violin plot structure, but using omnibus ANOVA results
# Tests: Any differences among UEQ vs UEQ+Autonomy vs RAW (two-tailed)

library(dplyr)
library(ggplot2)
library(patchwork)

cat("=== CREATING THREE-CONDITION OMNIBUS ANOVA VIOLIN PLOT (FDR CORRECTED) ===\n")

# Map interfaces to pattern names (same as original analysis)
interface_patterns <- data.frame(
  interface = paste0("ui", sprintf("%03d", 1:15)),
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
    "Toying with Emotion",   # UI 13 - CORRECTED
    "Trick Wording",         # UI 14 - CORRECTED  
    "Social Pressure"        # UI 15 - CORRECTED
  )
)

# Load the FDR-corrected ANOVA results
results_data <- read.csv("results/three_condition_anova_results.csv")
cat("Loaded ANOVA results for", nrow(results_data), "interfaces\n")

# Add pattern names to results
results_data <- results_data %>%
  left_join(interface_patterns, by = c("interface" = "interface"))

# Load the three-condition interface data for plotting
interface_data <- read.csv("results/three_condition_interface_data.csv")
cat("Loaded interface data:", nrow(interface_data), "evaluations from", 
    length(unique(interface_data$ResponseId)), "participants\n")

# Check which interfaces have significant FDR-corrected omnibus ANOVA results
sig_interfaces <- results_data %>%
  filter(tendency_p_fdr < 0.05) %>%
  pull(interface)

cat("Significant interfaces after FDR correction (Omnibus ANOVA - any difference among 3 groups):", length(sig_interfaces), "\n")
if(length(sig_interfaces) > 0) {
  sig_names <- results_data %>%
    filter(interface %in% sig_interfaces) %>%
    select(interface, pattern_name, tendency_p_fdr, tendency_f)
  print(sig_names)
}

# Create individual interface plot function for omnibus ANOVA
create_interface_plot <- function(ui_num) {
  
  # Get interface data
  ui_data <- interface_data %>%
    filter(interface == paste0("ui", sprintf("%03d", ui_num)), !is.na(tendency))
  
  if(nrow(ui_data) == 0) {
    return(NULL)
  }
  
  # Get results for this interface
  ui_results <- results_data %>%
    filter(interface == paste0("ui", sprintf("%03d", ui_num)))
  
  pattern_name <- ui_results$pattern_name
  p_fdr <- ui_results$tendency_p_fdr      # Using omnibus ANOVA p-value
  f_stat <- ui_results$tendency_f         # F-statistic for omnibus ANOVA
  
  # Determine if significant (FDR corrected omnibus ANOVA)
  is_significant <- p_fdr < 0.05
  
  # Create title with significance indicator
  title_text <- paste0("UI ", ui_num, ": ", pattern_name)
  if(is_significant) {
    title_text <- paste0(title_text, " ***")
  }
  
  # Get sample sizes
  n_ueq <- ui_results$n_ueq
  n_autonomy <- ui_results$n_autonomy
  n_raw <- ui_results$n_raw
  
  # Set condition order and labels
  ui_data$condition_f <- factor(ui_data$condition, 
                               levels = c("RAW", "UEQ", "UEQ+Autonomy"),
                               labels = c("UI", "UEQ", "UEEQ-P"))
  
  # Create the plot with violin plots
  p <- ggplot(ui_data, aes(x = condition_f, y = tendency, fill = condition_f)) +
    geom_violin(alpha = 0.7, trim = FALSE) +
    geom_jitter(width = 0.15, alpha = 0.5, size = 0.8) +
    stat_summary(fun = mean, geom = "point", shape = 18, size = 3, color = "white") +
    scale_fill_manual(values = c("UI" = "#FF8888", "UEQ" = "#ABE2AB", "UEEQ-P" = "#AE80FF")) +
    labs(
      title = title_text,
      x = "",  # Remove x-axis label to reduce repetition
      y = if(ui_num %in% c(1, 6, 11)) "Release Tendency" else "",  # Only show y-label on left column
      subtitle = paste0("N: ", n_ueq, "/", n_autonomy, "/", n_raw, " • p=", sprintf("%.3f", p_fdr), " • F=", sprintf("%.1f", f_stat))
    ) +
    theme_minimal() +
    theme(
      legend.position = "none",
      plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
      axis.title = element_text(size = 11, face = "bold"),
      axis.text = element_text(size = 10),
      axis.text.x = element_text(size = 9, face = "bold"),
      panel.grid.minor = element_blank(),
      plot.margin = margin(t = 10, r = 5, b = 5, l = 5)
    ) +
    scale_y_continuous(limits = c(1, 7), breaks = 1:7) +
    scale_x_discrete()
  
  # Add significance annotation for omnibus ANOVA (spans all three groups)
  if(is_significant) {
    # Add significance line spanning all three conditions
    p <- p + 
      # Significance line across all three groups
      geom_segment(aes(x = 1, xend = 3, y = 6.3, yend = 6.3), 
                   color = "black", linewidth = 0.5, inherit.aes = FALSE) +
      geom_segment(aes(x = 1, xend = 1, y = 6.25, yend = 6.3), 
                   color = "black", linewidth = 0.5, inherit.aes = FALSE) +
      geom_segment(aes(x = 3, xend = 3, y = 6.25, yend = 6.3), 
                   color = "black", linewidth = 0.5, inherit.aes = FALSE) +
      # Significance stars
      annotate("text", x = 2, y = 6.4, label = "***", color = "black", size = 4, fontface = "bold")
  }
  
  return(p)
}

# Create plots for all interfaces
cat("\nCreating individual plots...\n")

tendency_plots <- list()
for(ui_num in 1:15) {
  plot <- create_interface_plot(ui_num)
  if(!is.null(plot)) {
    tendency_plots[[paste0("ui", ui_num)]] <- plot
  }
}

# Combine plots
if(length(tendency_plots) > 0) {
  
  # Create directory if it doesn't exist
  if(!dir.exists("plots")) {
    dir.create("plots")
  }
  
  tendency_grid <- wrap_plots(tendency_plots, ncol = 5, nrow = 3)
  
  # Count significant results
  n_sig_fdr <- sum(results_data$tendency_p_fdr < 0.05, na.rm = TRUE)
  n_total <- nrow(results_data)
  
  tendency_final <- tendency_grid + 
    plot_annotation(
      title = "Dark Pattern Release Tendency: Omnibus ANOVA (Any Differences Among Groups)",
      subtitle = paste0("Three-way comparison: Tests for ANY differences among UEQ, UEQ+Autonomy, and RAW conditions\n",
                       "*** p < 0.05 after FDR correction (", n_sig_fdr, "/", n_total, " significant omnibus tests) • ",
                       "N = ", length(unique(interface_data$ResponseId)), " participants"),
      caption = "White diamonds show mean values • Higher scores = more accepting of dark patterns • Significance spans all three groups",
      theme = theme(
        plot.title = element_text(size = 20, face = "bold", hjust = 0.5, margin = margin(b = 10)),
        plot.subtitle = element_text(size = 14, hjust = 0.5, margin = margin(b = 15)),
        plot.caption = element_text(size = 12, hjust = 0.5, color = "gray50", margin = margin(t = 10))
      )
    )
  
  # Save the plot
  filename <- "plots/three_condition_omnibus_anova_violin_fdr_corrected.png"
  ggsave(filename, plot = tendency_final, width = 24, height = 14, dpi = 300)
  
  cat("✓ Plot saved:", filename, "\n")
  cat("✓ Significant interfaces (FDR corrected omnibus ANOVA):", n_sig_fdr, "out of", n_total, "\n")
  
  # List significant interfaces
  if(n_sig_fdr > 0) {
    cat("\nSignificant interfaces (Omnibus ANOVA - any difference among groups):\n")
    sig_summary <- results_data %>%
      filter(tendency_p_fdr < 0.05) %>%
      select(interface, pattern_name, tendency_p_fdr, tendency_f) %>%
      arrange(tendency_p_fdr)
    
    for(i in seq_len(nrow(sig_summary))) {
      cat(sprintf("• UI %s (%s): p=%.4f, F=%.2f\n", 
                  gsub("ui0*", "", sig_summary$interface[i]), 
                  sig_summary$pattern_name[i],
                  sig_summary$tendency_p_fdr[i],
                  sig_summary$tendency_f[i]))
    }
  }
  
} else {
  cat("❌ No plots created - check data availability\n")
}

cat("\n✓ Three-condition omnibus ANOVA violin plot generation complete!\n")
