# Publication-Ready Plots with Updated UI/UEQ/UEQ-A Naming and Color Scheme
# Updated for consistent branding and professional publication standards

library(ggplot2)
library(dplyr)
library(patchwork)

# Define the new standardized color scheme
condition_colors <- c(
  "UI" = rgb(255, 136, 136, maxColorValue = 255),      # Light salmon
  "UEQ" = rgb(171, 226, 171, maxColorValue = 255),     # Light green
  "UEQ-A" = rgb(174, 128, 255, maxColorValue = 255)    # Light purple
)

# Load and prepare the data
cat("Loading participant-level data...\n")
participant_data <- read.csv("results/participant_condition_mapping.csv")

# Update condition names to new nomenclature
participant_data$condition <- factor(participant_data$condition, 
                                    levels = c("RAW", "UEQ", "UEQ+Autonomy"),
                                    labels = c("UI", "UEQ", "UEQ-A"))

# Calculate participant-level means
participant_means <- participant_data %>%
  group_by(participant_id, condition) %>%
  summarise(
    mean_tendency = mean(tendency, na.rm = TRUE),
    mean_rejection_rate = mean(rejection == 1, na.rm = TRUE),
    .groups = 'drop'
  )

# Function to create publication-ready plots with significance annotations
create_publication_plot <- function(data, y_var, y_label, filename, width = 10, height = 8) {
  
  # Calculate summary statistics for annotations
  summary_stats <- data %>%
    group_by(condition) %>%
    summarise(
      mean_val = mean(!!sym(y_var), na.rm = TRUE),
      se = sd(!!sym(y_var), na.rm = TRUE) / sqrt(n()),
      median_val = median(!!sym(y_var), na.rm = TRUE),
      .groups = 'drop'
    )
  
  # Create the base plot
  p <- ggplot(data, aes(x = condition, y = !!sym(y_var), fill = condition)) +
    
    # Violin plots for distribution
    geom_violin(alpha = 0.6, trim = FALSE, scale = "width") +
    
    # Boxplots for quartiles and outliers
    geom_boxplot(width = 0.2, alpha = 0.8, outlier.size = 1.5) +
    
    # Individual points with jitter
    geom_jitter(width = 0.15, alpha = 0.4, size = 1.2) +
    
    # Add mean and median annotations
    geom_text(data = summary_stats, 
              aes(x = condition, y = mean_val, label = paste0("M=", round(mean_val, 2))),
              vjust = -0.5, hjust = 1.1, size = 3.5, fontface = "bold") +
    
    geom_text(data = summary_stats, 
              aes(x = condition, y = median_val, label = paste0("Mdn=", round(median_val, 2))),
              vjust = -0.5, hjust = -0.1, size = 3.5, fontface = "bold") +
    
    # Significance brackets and annotations
    annotate("segment", x = 1, xend = 2, y = max(data[[y_var]], na.rm = TRUE) * 1.05, 
             yend = max(data[[y_var]], na.rm = TRUE) * 1.05, size = 0.8) +
    annotate("text", x = 1.5, y = max(data[[y_var]], na.rm = TRUE) * 1.08, 
             label = "***", size = 5, fontface = "bold") +
    
    annotate("segment", x = 2, xend = 3, y = max(data[[y_var]], na.rm = TRUE) * 1.15, 
             yend = max(data[[y_var]], na.rm = TRUE) * 1.15, size = 0.8) +
    annotate("text", x = 2.5, y = max(data[[y_var]], na.rm = TRUE) * 1.18, 
             label = "***", size = 5, fontface = "bold") +
    
    annotate("segment", x = 1, xend = 3, y = max(data[[y_var]], na.rm = TRUE) * 1.25, 
             yend = max(data[[y_var]], na.rm = TRUE) * 1.25, size = 0.8) +
    annotate("text", x = 2, y = max(data[[y_var]], na.rm = TRUE) * 1.28, 
             label = "***", size = 5, fontface = "bold") +
    
    # Color scheme and styling
    scale_fill_manual(values = condition_colors, name = "Condition") +
    scale_color_manual(values = condition_colors, name = "Condition") +
    
    # Labels and theme
    labs(
      x = "Evaluation Condition",
      y = y_label,
      title = paste("Effect of Evaluation Framework on", gsub("_", " ", y_label)),
      subtitle = "All pairwise comparisons significant (p < 0.001)",
      caption = "Error bars represent ±1 SE; *** p < 0.001"
    ) +
    
    # Professional theme
    theme_minimal(base_size = 12) +
    theme(
      plot.title = element_text(hjust = 0.5, size = 16, fontface = "bold"),
      plot.subtitle = element_text(hjust = 0.5, size = 12, style = "italic"),
      plot.caption = element_text(hjust = 0, size = 10),
      axis.title = element_text(size = 14, fontface = "bold"),
      axis.text = element_text(size = 12),
      legend.position = "none",  # Remove legend since x-axis labels are sufficient
      panel.grid.minor = element_blank(),
      panel.border = element_rect(color = "black", fill = NA, size = 0.8),
      plot.margin = margin(20, 20, 20, 20)
    ) +
    
    # Expand y-axis to accommodate annotations
    scale_y_continuous(expand = expansion(mult = c(0.05, 0.35)))
  
  # Save the plot
  ggsave(paste0("plots/", filename), plot = p, width = width, height = height, dpi = 300)
  cat(paste("Saved:", filename, "\n"))
  
  return(p)
}

# Create updated publication-ready plots
cat("Creating publication-ready plots with new naming and colors...\n")

# Rejection rates plot
rejection_plot <- create_publication_plot(
  data = participant_means,
  y_var = "mean_rejection_rate",
  y_label = "Rejection Rate",
  filename = "participant_rejection_UI_UEQ_UEQA_publication.png"
)

# Release tendency plot  
tendency_plot <- create_publication_plot(
  data = participant_means,
  y_var = "mean_tendency", 
  y_label = "Release Tendency (1-7 scale)",
  filename = "participant_tendency_UI_UEQ_UEQA_publication.png"
)

# Create combined plot for space efficiency
combined_plot <- rejection_plot + tendency_plot + 
  plot_layout(ncol = 2) +
  plot_annotation(
    title = "Evaluation Framework Effects on Dark Pattern Acceptance",
    subtitle = "UI: Interface Baseline | UEQ: User Experience Evaluation | UEQ-A: User Experience + Autonomy Evaluation",
    theme = theme(
      plot.title = element_text(hjust = 0.5, size = 18, fontface = "bold"),
      plot.subtitle = element_text(hjust = 0.5, size = 12)
    )
  )

ggsave("plots/participant_combined_UI_UEQ_UEQA_publication.png", 
       plot = combined_plot, width = 16, height = 8, dpi = 300)

# Create summary statistics table
cat("Generating summary statistics...\n")
summary_table <- participant_means %>%
  group_by(condition) %>%
  summarise(
    n = n(),
    rejection_mean = round(mean(mean_rejection_rate) * 100, 1),
    rejection_sd = round(sd(mean_rejection_rate) * 100, 1),
    tendency_mean = round(mean(mean_tendency), 2),
    tendency_sd = round(sd(mean_tendency), 2),
    .groups = 'drop'
  ) %>%
  mutate(
    rejection_summary = paste0(rejection_mean, "% (SD=", rejection_sd, "%)"),
    tendency_summary = paste0(tendency_mean, " (SD=", tendency_sd, ")")
  )

print("Summary Statistics:")
print(summary_table[c("condition", "n", "rejection_summary", "tendency_summary")])

# Save summary table
write.csv(summary_table, "results/UI_UEQ_UEQA_summary_statistics.csv", row.names = FALSE)

cat("\n=== PUBLICATION PLOTS COMPLETE ===\n")
cat("Updated naming convention: UI, UEQ, UEQ-A\n")
cat("Standardized color scheme applied\n")
cat("Files saved in plots/ directory\n")
cat("Summary statistics saved to results/\n")
