# Updated Publication Plots: UI/UEQ/UEQ-A with Standardized Colors
# Simple approach using summary statistics for clean publication figures

library(ggplot2)
library(dplyr)
library(patchwork)

# Define the standardized color scheme
condition_colors <- c(
  "UI" = rgb(255, 136, 136, maxColorValue = 255),      # Light salmon
  "UEQ" = rgb(171, 226, 171, maxColorValue = 255),     # Light green
  "UEQ-A" = rgb(174, 128, 255, maxColorValue = 255)    # Light purple
)

# Load condition summary data
condition_summary <- read.csv("results/condition_summary.csv")

# Update condition names
condition_summary$condition <- factor(condition_summary$condition, 
                                    levels = c("RAW", "UEQ", "UEQ+Autonomy"),
                                    labels = c("UI", "UEQ", "UEQ-A"))

# Convert rejection rate to percentage
condition_summary$rejection_percentage <- condition_summary$mean_rejection_rate * 100

cat("Creating publication-ready summary plots...\n")

# Create rejection rate plot
rejection_plot <- ggplot(condition_summary, aes(x = condition, y = rejection_percentage, fill = condition)) +
  geom_col(width = 0.7, alpha = 0.8, color = "black", size = 0.8) +
  
  # Add value labels on bars
  geom_text(aes(label = paste0(round(rejection_percentage, 1), "%")), 
            vjust = -0.5, size = 4.5, fontface = "bold") +
  
  # Add sample size labels
  geom_text(aes(label = paste0("n=", participants)), 
            vjust = 1.5, size = 3.5, color = "white", fontface = "bold") +
  
  # Significance brackets
  annotate("segment", x = 1, xend = 2, y = 62, yend = 62, size = 0.8) +
  annotate("text", x = 1.5, y = 64, label = "***", size = 5, fontface = "bold") +
  
  annotate("segment", x = 2, xend = 3, y = 68, yend = 68, size = 0.8) +
  annotate("text", x = 2.5, y = 70, label = "***", size = 5, fontface = "bold") +
  
  annotate("segment", x = 1, xend = 3, y = 74, yend = 74, size = 0.8) +
  annotate("text", x = 2, y = 76, label = "***", size = 5, fontface = "bold") +
  
  scale_fill_manual(values = condition_colors) +
  scale_y_continuous(limits = c(0, 80), expand = c(0, 0)) +
  
  labs(
    x = "Evaluation Condition",
    y = "Rejection Rate (%)",
    title = "Dark Pattern Rejection Rates",
    subtitle = "F(2,138) = 15.97, p < 0.001, η² = 0.19"
  ) +
  
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, fontface = "bold"),
    plot.subtitle = element_text(hjust = 0.5, size = 12),
    axis.title = element_text(size = 14, fontface = "bold"),
    axis.text = element_text(size = 12),
    legend.position = "none",
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "black", fill = NA, size = 0.8),
    plot.margin = margin(20, 20, 20, 20)
  )

# Create release tendency plot
tendency_plot <- ggplot(condition_summary, aes(x = condition, y = mean_tendency, fill = condition)) +
  geom_col(width = 0.7, alpha = 0.8, color = "black", size = 0.8) +
  
  # Add value labels on bars
  geom_text(aes(label = round(mean_tendency, 2)), 
            vjust = -0.5, size = 4.5, fontface = "bold") +
  
  # Add sample size labels
  geom_text(aes(label = paste0("n=", participants)), 
            vjust = 1.5, size = 3.5, color = "white", fontface = "bold") +
  
  # Significance brackets
  annotate("segment", x = 1, xend = 2, y = 5.2, yend = 5.2, size = 0.8) +
  annotate("text", x = 1.5, y = 5.4, label = "***", size = 5, fontface = "bold") +
  
  annotate("segment", x = 2, xend = 3, y = 5.8, yend = 5.8, size = 0.8) +
  annotate("text", x = 2.5, y = 6.0, label = "***", size = 5, fontface = "bold") +
  
  annotate("segment", x = 1, xend = 3, y = 6.4, yend = 6.4, size = 0.8) +
  annotate("text", x = 2, y = 6.6, label = "***", size = 5, fontface = "bold") +
  
  scale_fill_manual(values = condition_colors) +
  scale_y_continuous(limits = c(0, 7), expand = c(0, 0), 
                     breaks = 1:7, 
                     labels = c("1\n(Definitely\nwould not\nrelease)", "2", "3", "4", "5", "6", "7\n(Definitely\nwould\nrelease)")) +
  
  labs(
    x = "Evaluation Condition",
    y = "Release Tendency (1-7 scale)",
    title = "Release Tendency Scores",
    subtitle = "F(2,138) = 16.61, p < 0.001, η² = 0.19"
  ) +
  
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, fontface = "bold"),
    plot.subtitle = element_text(hjust = 0.5, size = 12),
    axis.title = element_text(size = 14, fontface = "bold"),
    axis.text.x = element_text(size = 12),
    axis.text.y = element_text(size = 10),
    legend.position = "none",
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "black", fill = NA, size = 0.8),
    plot.margin = margin(20, 20, 20, 20)
  )

# Save individual plots
ggsave("plots/rejection_rates_UI_UEQ_UEQA_final.png", rejection_plot, 
       width = 8, height = 8, dpi = 300)

ggsave("plots/release_tendency_UI_UEQ_UEQA_final.png", tendency_plot, 
       width = 8, height = 8, dpi = 300)

# Create combined publication plot
combined_plot <- rejection_plot + tendency_plot + 
  plot_layout(ncol = 2) +
  plot_annotation(
    title = "Evaluation Framework Effects on Dark Pattern Acceptance",
    subtitle = "UI: Interface Baseline | UEQ: User Experience Evaluation | UEQ-A: User Experience + Autonomy Evaluation",
    caption = "All pairwise comparisons significant (*** p < 0.001)",
    theme = theme(
      plot.title = element_text(hjust = 0.5, size = 18, fontface = "bold"),
      plot.subtitle = element_text(hjust = 0.5, size = 14),
      plot.caption = element_text(hjust = 0.5, size = 12)
    )
  )

ggsave("plots/combined_effects_UI_UEQ_UEQA_final.png", combined_plot, 
       width = 16, height = 8, dpi = 300)

# Print updated summary with new naming
cat("\n=== UPDATED SUMMARY STATISTICS ===\n")
print(condition_summary)

# Save updated summary
condition_summary_renamed <- condition_summary
write.csv(condition_summary_renamed, "results/condition_summary_UI_UEQ_UEQA.csv", row.names = FALSE)

cat("\n=== PUBLICATION PLOTS COMPLETED ===\n")
cat("✓ Updated naming: UI, UEQ, UEQ-A\n") 
cat("✓ Standardized colors: UI (salmon), UEQ (green), UEQ-A (purple)\n")
cat("✓ Publication-ready significance annotations\n")
cat("✓ Files saved in plots/ directory\n")
cat("✓ Summary statistics updated\n")
