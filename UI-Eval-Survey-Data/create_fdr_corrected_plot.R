# Create Dark Pattern Tendency Plot with FDR Corrected Results
# Using: individual_interface_analysis_final_clean_N65.csv

library(dplyr)
library(ggplot2)
library(patchwork)

cat("=== CREATING DARK PATTERN TENDENCY PLOT (FDR CORRECTED) ===\n")

# Load the FDR-corrected results
results_data <- read.csv("results/individual_interface_analysis_final_clean_N65.csv")
cat("Loaded results for", nrow(results_data), "interfaces\n")

# Load the interface data for plotting
interface_data <- read.csv("results/interface_plot_data_aug16_plus_new_filtered.csv")
cat("Loaded interface data:", nrow(interface_data), "evaluations from", 
    length(unique(interface_data$ResponseId)), "participants\n")

# Check which interfaces have significant FDR-corrected results
sig_interfaces <- results_data %>%
  filter(tendency_p_fdr < 0.05) %>%
  pull(interface)

cat("Significant interfaces after FDR correction:", length(sig_interfaces), "\n")
if(length(sig_interfaces) > 0) {
  sig_names <- results_data %>%
    filter(interface %in% sig_interfaces) %>%
    select(interface, pattern_name, tendency_p_fdr, tendency_cohens_d)
  print(sig_names)
}

# Create individual interface plot function
create_interface_plot <- function(ui_num) {
  
  # Get interface data
  ui_data <- interface_data %>%
    filter(interface == ui_num, !is.na(tendency))
  
  if(nrow(ui_data) == 0) {
    return(NULL)
  }
  
  # Get results for this interface
  ui_results <- results_data %>%
    filter(interface == ui_num)
  
  pattern_name <- ui_results$pattern_name
  p_fdr <- ui_results$tendency_p_fdr
  cohens_d <- ui_results$tendency_cohens_d
  
  # Determine if significant (FDR corrected)
  is_significant <- p_fdr < 0.05
  
  # Create title with significance indicator (but not red)
  title_text <- paste0("UI ", ui_num, ": ", pattern_name)
  if(is_significant) {
    title_text <- paste0(title_text, " ***")
  }
  
  # Get sample sizes
  n_ueq <- sum(ui_data$condition_f == "UEQ")
  n_ueeq <- sum(ui_data$condition_f == "UEQ+Autonomy")
  
  # Create the plot with violin plots
  p <- ggplot(ui_data, aes(x = condition_f, y = tendency, fill = condition_f)) +
    geom_violin(alpha = 0.7, trim = FALSE) +
    geom_jitter(width = 0.15, alpha = 0.5, size = 0.8) +
    stat_summary(fun = mean, geom = "point", shape = 18, size = 3, color = "white") +
    scale_fill_manual(values = c("UEQ" = "#3498db", "UEQ+Autonomy" = "#e74c3c")) +
    labs(
      title = title_text,
      x = "",  # Remove x-axis label to reduce repetition
      y = if(ui_num %in% c(1, 6, 11)) "Release Tendency" else "",  # Only show y-label on left column
      subtitle = paste0("N: ", n_ueq, "/", n_ueeq, " • p=", sprintf("%.3f", p_fdr), " • d=", sprintf("%.2f", cohens_d))
    ) +
    theme_minimal() +
    theme(
      legend.position = "none",
      plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
      axis.title = element_text(size = 11, face = "bold"),
      axis.text = element_text(size = 10),
      axis.text.x = element_text(size = 10, face = "bold"),
      panel.grid.minor = element_blank(),
      plot.margin = margin(t = 10, r = 5, b = 5, l = 5)
    ) +
    scale_y_continuous(limits = c(1, 7), breaks = 1:7) +
    scale_x_discrete(labels = c("UEQ" = "UEQ", "UEQ+Autonomy" = "UEQ+A"))  # Shorter labels
  
  # Add significance annotation (but not in red)
  if(is_significant) {
    p <- p + 
      annotate("text", x = 1.5, y = 6.5, label = "***", color = "black", size = 5, fontface = "bold")
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
      title = "Dark Pattern Release Tendency: UEQ vs UEQ+Autonomy (FDR Corrected)",
      subtitle = paste0("One-tailed tests: UEQ+Autonomy participants rate dark patterns more critically (lower scores)\n",
                       "*** p < 0.05 after FDR correction (", n_sig_fdr, "/", n_total, " significant) • ",
                       "N = ", length(unique(interface_data$ResponseId)), " participants"),
      caption = "White diamonds show mean values • Higher scores = more accepting of dark patterns",
      theme = theme(
        plot.title = element_text(size = 20, face = "bold", hjust = 0.5, margin = margin(b = 10)),
        plot.subtitle = element_text(size = 14, hjust = 0.5, margin = margin(b = 15)),
        plot.caption = element_text(size = 12, hjust = 0.5, color = "gray50", margin = margin(t = 10))
      )
    )
  
  # Save the plot
  filename <- "plots/dark_patterns_tendency_cleaned_fdr_onetailed.png"
  ggsave(filename, plot = tendency_final, width = 24, height = 14, dpi = 300)
  
  cat("✓ Plot saved:", filename, "\n")
  cat("✓ Significant interfaces (FDR corrected):", n_sig_fdr, "out of", n_total, "\n")
  
  # List significant interfaces
  if(n_sig_fdr > 0) {
    cat("\nSignificant interfaces:\n")
    sig_summary <- results_data %>%
      filter(tendency_p_fdr < 0.05) %>%
      select(interface, pattern_name, tendency_p_fdr, tendency_cohens_d) %>%
      arrange(tendency_p_fdr)
    
    for(i in 1:nrow(sig_summary)) {
      cat(sprintf("• UI %d (%s): p=%.4f, d=%.2f\n", 
                  sig_summary$interface[i], 
                  sig_summary$pattern_name[i],
                  sig_summary$tendency_p_fdr[i],
                  sig_summary$tendency_cohens_d[i]))
    }
  }
  
} else {
  cat("❌ No plots created - check data availability\n")
}

cat("\n✓ Plot generation complete!\n")
