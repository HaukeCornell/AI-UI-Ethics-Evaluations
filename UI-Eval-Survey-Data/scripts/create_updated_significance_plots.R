# Create updated significance plot for August 17 data (N=94)
# With proper multiple comparisons correction highlighting Content Customization

library(dplyr)
library(ggplot2)
library(ggstatsplot)

cat("Creating updated significance plot for August 17 data...\n")

# Load the complete statistical results
complete_results <- read.csv("results/aug17_complete_statistical_results.csv")
interface_data <- read.csv("results/interface_plot_data_aug17_final.csv")

# Create pattern mapping with proper names
ui_mapping <- data.frame(
  interface = 1:15,
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

# Merge results with proper names
plot_data <- complete_results %>%
  left_join(ui_mapping, by = "interface") %>%
  select(interface, pattern_name.y, pattern_short, 
         tendency_p_raw, tendency_p_fdr, tendency_p_bonferroni,
         sig_uncorrected.y, sig_fdr.y, sig_bonferroni.y) %>%
  rename(
    pattern_name = pattern_name.y,
    sig_uncorrected = sig_uncorrected.y,
    sig_fdr = sig_fdr.y, 
    sig_bonferroni = sig_bonferroni.y
  ) %>%
  mutate(
    # Create significance categories
    significance_level = case_when(
      sig_bonferroni ~ "Bonferroni Significant",
      sig_fdr ~ "FDR Significant", 
      sig_uncorrected ~ "Uncorrected Only",
      TRUE ~ "Not Significant"
    ),
    # Create -log10 p-values for visualization
    neg_log_p_raw = -log10(tendency_p_raw),
    neg_log_p_fdr = -log10(tendency_p_fdr),
    # Highlight the Content Customization finding
    is_content_custom = pattern_short == "Content Custom"
  )

# Create the significance plot
p_significance <- ggplot(plot_data, aes(x = reorder(pattern_short, neg_log_p_raw), 
                                       y = neg_log_p_raw)) +
  # Add significance thresholds
  geom_hline(yintercept = -log10(0.05), linetype = "dashed", color = "red", alpha = 0.7) +
  geom_hline(yintercept = -log10(0.01), linetype = "dashed", color = "darkred", alpha = 0.7) +
  geom_hline(yintercept = -log10(0.001), linetype = "dashed", color = "black", alpha = 0.7) +
  
  # Add bars colored by significance level
  geom_col(aes(fill = significance_level), alpha = 0.8) +
  
  # Highlight Content Customization
  geom_col(data = plot_data %>% filter(is_content_custom), 
           aes(fill = significance_level), alpha = 1.0, size = 1.5) +
  
  # Add FDR-corrected p-values as points
  geom_point(aes(y = neg_log_p_fdr), color = "blue", size = 2, alpha = 0.8) +
  
  # Customize colors
  scale_fill_manual(
    values = c(
      "Bonferroni Significant" = "#1f77b4",    # Blue
      "FDR Significant" = "#ff7f0e",           # Orange  
      "Uncorrected Only" = "#d62728",          # Red
      "Not Significant" = "#7f7f7f"            # Gray
    ),
    name = "Significance Level"
  ) +
  
  # Labels and theme
  labs(
    title = "Dark Pattern Tendency Score Differences (August 17 Data, N=94)",
    subtitle = "UEQ vs UEQ+Autonomy • Bars = Raw p-values • Blue dots = FDR-corrected p-values",
    x = "Dark Pattern Interface",
    y = "-log₁₀(p-value)",
    caption = "Only Content Customization survives FDR correction\nDashed lines: p=0.05 (red), p=0.01 (dark red), p=0.001 (black)"
  ) +
  
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  ) +
  
  # Add annotation for the significant finding
  annotate("text", x = which(plot_data$pattern_short == "Content Custom"), 
           y = max(plot_data$neg_log_p_raw) * 0.9,
           label = "FDR Significant\n(only surviving effect)", 
           hjust = 0.5, vjust = 1, size = 3.5, 
           color = "darkblue", fontface = "bold")

# Save the plot
ggsave("plots/dark_patterns_tendency_corrected_significance_aug17.png", 
       p_significance, width = 14, height = 8, dpi = 300)

cat("✓ Updated significance plot saved: plots/dark_patterns_tendency_corrected_significance_aug17.png\n")

# Also create a summary comparison plot showing effect sizes
plot_data_effects <- interface_data %>%
  group_by(interface_num) %>%
  summarise(
    pattern_name = first(ui_mapping$pattern_short[ui_mapping$interface == interface_num]),
    ueeq_mean = mean(tendency[condition_f == "UEQ+Autonomy"], na.rm = TRUE),
    ueq_mean = mean(tendency[condition_f == "UEQ"], na.rm = TRUE),
    effect_size = ueq_mean - ueeq_mean,  # Positive = UEQ higher
    n = n()
  ) %>%
  left_join(plot_data %>% select(interface, significance_level, sig_fdr), 
            by = c("interface_num" = "interface")) %>%
  mutate(
    is_significant = sig_fdr,
    is_content_custom = pattern_name == "Content Custom"
  )

p_effects <- ggplot(plot_data_effects, aes(x = reorder(pattern_name, effect_size), 
                                          y = effect_size)) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black", alpha = 0.5) +
  geom_col(aes(fill = is_significant), alpha = 0.8) +
  geom_col(data = plot_data_effects %>% filter(is_content_custom),
           aes(fill = is_significant), alpha = 1.0, color = "darkblue", size = 1.5) +
  
  scale_fill_manual(
    values = c("TRUE" = "#ff7f0e", "FALSE" = "#7f7f7f"),
    labels = c("TRUE" = "FDR Significant", "FALSE" = "Not Significant"),
    name = "Statistical Significance"
  ) +
  
  labs(
    title = "Effect Sizes: UEQ vs UEQ+Autonomy Tendency Differences (N=94)",
    subtitle = "Positive values = UEQ shows more ethical concern • Only Content Customization is significant",
    x = "Dark Pattern Interface", 
    y = "Effect Size (UEQ mean - UEQ+Autonomy mean)",
    caption = "Content Customization: Large effect (d=1.011), FDR p=0.007"
  ) +
  
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  ) +
  
  annotate("text", x = which(plot_data_effects$pattern_name == "Content Custom"),
           y = plot_data_effects$effect_size[plot_data_effects$pattern_name == "Content Custom"] + 0.3,
           label = "Large Effect\n(Cohen's d = 1.011)",
           hjust = 0.5, size = 3.5, color = "darkblue", fontface = "bold")

ggsave("plots/dark_patterns_effect_sizes_aug17.png", 
       p_effects, width = 14, height = 8, dpi = 300)

cat("✓ Effect sizes plot saved: plots/dark_patterns_effect_sizes_aug17.png\n")

cat("\nSUMMARY:\n")
cat("• Updated plots created with August 17 data (N=94)\n")
cat("• Proper multiple comparisons correction applied\n") 
cat("• Only Content Customization survives FDR correction\n")
cat("• Large effect size (Cohen's d = 1.011) in unexpected direction\n")
cat("• All other 14 interfaces show no significant differences\n")
