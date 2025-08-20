# Create side-by-side violin plots for tendency scores with August 17 data (N=94)
# Highlighting the Content Customization significant effect

library(dplyr)
library(ggplot2)
library(ggstatsplot)
library(patchwork)

cat("Creating updated violin plots for August 17 data...\n")

# Load data
interface_data <- read.csv("results/interface_plot_data_aug17_final.csv")
complete_results <- read.csv("results/aug17_complete_statistical_results.csv")

# Create pattern mapping
ui_mapping <- data.frame(
  interface_num = 1:15,
  pattern_name = c(
    "Bad Defaults", "Content Customization", "Endlessness", "Expectation Mismatch",
    "False Hierarchy", "Forced Access", "Gamification", "Hinder Deletion",
    "Nagging", "Overcomplicated Process", "Pull to Refresh", "Social Connector",
    "Toying with Emotion", "Trick Wording", "Social Pressure"
  ),
  pattern_short = c(
    "Bad Defaults", "Content Custom", "Endlessness", "Expect. Mismatch",
    "False Hierarchy", "Forced Access", "Gamification", "Hinder Deletion",
    "Nagging", "Overcomplex", "Pull to Refresh", "Social Connect",
    "Toy w/ Emotion", "Trick Wording", "Social Pressure"
  )
)

# Add pattern names to interface data
interface_data <- interface_data %>%
  left_join(ui_mapping, by = "interface_num") %>%
  mutate(
    # Mark significant interfaces
    is_significant = interface_num == 2,  # Content Customization
    pattern_label = ifelse(is_significant, 
                          paste0(pattern_short, "*"), 
                          pattern_short)
  )

# Get significance info for annotations
sig_info <- complete_results %>%
  mutate(
    sig_label = case_when(
      sig_fdr.y ~ paste0("FDR p = ", format(tendency_p_fdr, digits = 3)),
      sig_uncorrected.y ~ paste0("p = ", format(tendency_p_raw, digits = 3), " (uncorrected)"),
      TRUE ~ "n.s."
    )
  )

# Create violin plots for all interfaces
create_violin_plot <- function(ui_num, pattern_name, sig_label) {
  ui_data <- interface_data %>% filter(interface_num == ui_num)
  
  # Check if this is the significant interface
  is_sig <- ui_num == 2
  
  p <- ggplot(ui_data, aes(x = condition_f, y = tendency, fill = condition_f)) +
    geom_violin(alpha = 0.7, trim = FALSE) +
    geom_boxplot(width = 0.1, alpha = 0.8, outlier.shape = NA) +
    geom_jitter(width = 0.15, alpha = 0.6, size = 1) +
    
    scale_fill_manual(values = c("UEQ" = "#FF6B6B", "UEQ+Autonomy" = "#4ECDC4")) +
    scale_y_continuous(limits = c(0, 7), breaks = 0:7) +
    
    labs(
      title = pattern_name,
      subtitle = sig_label,
      x = "",
      y = if(ui_num %in% c(1, 6, 11)) "Ethical Concern (1-7)" else ""
    ) +
    
    theme_minimal() +
    theme(
      legend.position = "none",
      plot.title = element_text(size = 10, face = if(is_sig) "bold" else "plain"),
      plot.subtitle = element_text(size = 8, 
                                  color = if(is_sig) "darkblue" else "gray50",
                                  face = if(is_sig) "bold" else "plain"),
      axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
      axis.text.y = element_text(size = 8),
      axis.title.y = element_text(size = 9),
      panel.border = if(is_sig) element_rect(color = "darkblue", fill = NA, size = 2) else element_blank()
    )
  
  return(p)
}

# Create all 15 plots
plots <- list()
for(i in 1:15) {
  pattern_name <- ui_mapping$pattern_short[i]
  sig_label <- sig_info$sig_label[i]
  plots[[i]] <- create_violin_plot(i, pattern_name, sig_label)
}

# Arrange plots in a 3x5 grid
combined_plot <- wrap_plots(plots, ncol = 5, nrow = 3)

# Add overall title
final_plot <- combined_plot + 
  plot_annotation(
    title = "Dark Pattern Tendency Scores: UEQ vs UEQ+Autonomy (August 17 Data, N=94)",
    subtitle = "Violin plots with box plots and individual points • * = FDR-significant after multiple comparisons correction",
    caption = "Only Content Customization shows significant difference after FDR correction\nBlue border = significant effect",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold"),
      plot.subtitle = element_text(size = 12),
      plot.caption = element_text(size = 10)
    )
  )

# Save the plot
ggsave("plots/dark_patterns_tendency_violin_aug17.png", 
       final_plot, width = 20, height = 12, dpi = 300)

cat("✓ Updated violin plots saved: plots/dark_patterns_tendency_violin_aug17.png\n")

# Also create a focused plot just for the significant effect
content_data <- interface_data %>% filter(interface_num == 2)

p_content_focus <- ggplot(content_data, aes(x = condition_f, y = tendency, fill = condition_f)) +
  geom_violin(alpha = 0.7, trim = FALSE, scale = "width") +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.shape = NA) +
  geom_jitter(width = 0.1, alpha = 0.7, size = 2) +
  
  scale_fill_manual(values = c("UEQ" = "#FF6B6B", "UEQ+Autonomy" = "#4ECDC4")) +
  scale_y_continuous(limits = c(0, 7), breaks = 0:7) +
  
  labs(
    title = "Content Customization: The Only Significant Difference",
    subtitle = "FDR-corrected p = 0.007, Cohen's d = 1.011 (large effect)",
    x = "Condition",
    y = "Ethical Concern (1-7 scale)",
    caption = paste0("N=94 participants (UEQ: n=29, UEQ+Autonomy: n=27)\n",
                    "UEQ participants show MORE ethical concern than UEQ+Autonomy")
  ) +
  
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12, color = "darkblue"),
    axis.text = element_text(size = 11),
    axis.title = element_text(size = 12),
    plot.caption = element_text(size = 10)
  )

ggsave("plots/content_customization_violin_focus.png", 
       p_content_focus, width = 10, height = 8, dpi = 300)

cat("✓ Focused violin plot saved: plots/content_customization_violin_focus.png\n")

cat("\nSUMMARY:\n")
cat("• Created side-by-side violin plots for all 15 interfaces\n")
cat("• Highlighted Content Customization with blue border and bold formatting\n")
cat("• Shows distributions, box plots, and individual data points\n")
cat("• Includes FDR-corrected significance annotations\n")
cat("• Created focused plot for the one significant effect\n")
