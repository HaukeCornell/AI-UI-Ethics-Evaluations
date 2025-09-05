# Create Three-Condition Dark Pattern Tendency Violin Plot with FDR Corrected Results
# Based on the successful create_fdr_corrected_plot.R structure
# Three conditions: UI vs UEQ vs UEQ-A
# UPDATED: UI/UEQ/UEQ-A naming with consistent colors

library(dplyr)
library(ggplot2)
library(patchwork)

cat("=== CREATING THREE-CONDITION DARK PATTERN TENDENCY VIOLIN PLOT (FDR CORRECTED) ===\n")

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
    "Social Pressure",       # UI 13
    "Toying with Emotion",   # UI 14
    "Trick Wording"          # UI 15
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

# Update condition names
interface_data$condition_new <- case_when(
  interface_data$condition == "RAW" ~ "UI",
  interface_data$condition == "UEQ" ~ "UEQ", 
  interface_data$condition == "UEQ+Autonomy" ~ "UEQ-A",
  TRUE ~ interface_data$condition
)

# Check which interfaces have significant FDR-corrected planned contrast results (UEQ vs UEQ-A)
sig_interfaces <- results_data %>%
  filter(ueq_autonomy_tend_p_fdr < 0.05) %>%
  pull(interface)

cat("Significant interfaces after FDR correction (UEQ vs UEQ-A planned contrast):", length(sig_interfaces), "\n")
if(length(sig_interfaces) > 0) {
  sig_names <- results_data %>%
    filter(interface %in% sig_interfaces) %>%
    select(interface, pattern_name, ueq_autonomy_tend_p_fdr, ueq_autonomy_tend_d)
  print(sig_names)
}

# Create individual interface plot function for three conditions
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
  p_fdr <- ui_results$ueq_autonomy_tend_p_fdr  # Using planned contrast p-value
  cohens_d <- ui_results$ueq_autonomy_tend_d   # Effect size for UEQ vs UEQ-A
  
  # Determine if significant (FDR corrected planned contrast)
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
  
  # Set condition order and labels with new naming
  ui_data$condition_f <- factor(ui_data$condition_new, 
                               levels = c("UEQ", "UEQ-A", "UI"),
                               labels = c("UEQ", "UEQ-A", "UI"))
  
  # Create the plot with violin plots and updated colors
  p <- ggplot(ui_data, aes(x = condition_f, y = tendency, fill = condition_f)) +
    geom_violin(alpha = 0.7, trim = FALSE) +
    geom_jitter(width = 0.15, alpha = 0.5, size = 0.8) +
    stat_summary(fun = mean, geom = "point", shape = 18, size = 3, color = "white") +
    scale_fill_manual(values = c("UI" = "#FF8888", "UEQ" = "#ABE2AB", "UEQ-A" = "#AE80FF")) +
    labs(
      title = title_text,
      x = "",  # Remove x-axis label to reduce repetition
      y = if(ui_num %in% c(1, 6, 11)) "Release Tendency" else "",  # Only show y-label on left column
      subtitle = paste0("N: ", n_raw, "/", n_ueq, "/", n_autonomy, " • p=", sprintf("%.3f", p_fdr), " • d=", sprintf("%.2f", cohens_d))
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
  
  # Add significance annotation for planned contrast (UEQ vs UEQ-A)
  if(is_significant) {
    # Add significance line between UEQ and UEQ-A
    p <- p + 
      # Significance line
      geom_segment(aes(x = 1, xend = 2, y = 6.3, yend = 6.3), 
                   color = "black", linewidth = 0.5, inherit.aes = FALSE) +
      geom_segment(aes(x = 1, xend = 1, y = 6.25, yend = 6.3), 
                   color = "black", linewidth = 0.5, inherit.aes = FALSE) +
      geom_segment(aes(x = 2, xend = 2, y = 6.25, yend = 6.3), 
                   color = "black", linewidth = 0.5, inherit.aes = FALSE) +
      # Significance stars
      annotate("text", x = 1.5, y = 6.4, label = "***", color = "black", size = 4, fontface = "bold")
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
  n_sig_fdr <- sum(results_data$ueq_autonomy_tend_p_fdr < 0.05, na.rm = TRUE)
  n_total <- nrow(results_data)
  
  tendency_final <- tendency_grid + 
    plot_annotation(
      title = "Dark Pattern Release Tendency: Focus on UEQ vs UEQ-A Contrast",
      subtitle = paste0("Primary test: UEQ vs UEQ-A planned contrast (UEQ-A participants rate dark patterns more critically)\n",
                       "*** p < 0.05 after FDR correction (", n_sig_fdr, "/", n_total, " significant contrasts) • ",
                       "UI condition shown for context • N = ", length(unique(interface_data$ResponseId)), " participants"),
      caption = "White diamonds show mean values • Higher scores = more accepting of dark patterns • Significance bars show UEQ vs UEQ-A contrast only",
      theme = theme(
        plot.title = element_text(size = 20, face = "bold", hjust = 0.5, margin = margin(b = 10)),
        plot.subtitle = element_text(size = 14, hjust = 0.5, margin = margin(b = 15)),
        plot.caption = element_text(size = 12, hjust = 0.5, color = "gray50", margin = margin(t = 10))
      )
    )
  
  # Save the plot
  filename <- "plots/three_condition_tendency_violin_fdr_corrected.png"
  ggsave(filename, plot = tendency_final, width = 24, height = 14, dpi = 300)
  
  cat("✓ Plot saved:", filename, "\n")
  cat("✓ Significant interfaces (FDR corrected planned contrasts):", n_sig_fdr, "out of", n_total, "\n")
  
  # List significant interfaces
  if(n_sig_fdr > 0) {
    cat("\nSignificant interfaces (UEQ vs UEQ-A planned contrast):\n")
    sig_summary <- results_data %>%
      filter(ueq_autonomy_tend_p_fdr < 0.05) %>%
      select(interface, pattern_name, ueq_autonomy_tend_p_fdr, ueq_autonomy_tend_d) %>%
      arrange(ueq_autonomy_tend_p_fdr)
    
    for(i in 1:nrow(sig_summary)) {
      cat(sprintf("• UI %s (%s): p=%.4f, d=%.2f\n", 
                  gsub("ui0*", "", sig_summary$interface[i]), 
                  sig_summary$pattern_name[i],
                  sig_summary$ueq_autonomy_tend_p_fdr[i],
                  sig_summary$ueq_autonomy_tend_d[i]))
    }
  }
  
} else {
  cat("✗ No plots created - no valid data found\n")
}
