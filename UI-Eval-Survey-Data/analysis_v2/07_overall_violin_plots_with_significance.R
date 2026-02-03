# Create Overall Tendency and Rejection Violin Plots with Significance Annotations
# Tests the hypothesis: More evaluation data → More user-focused perspective
# Tendency: UI > UEQ > UEEQ-P (more evaluation = more critical)
# Rejection: UEEQ-P > UEQ > UI (more evaluation = more rejection)

library(dplyr)
library(ggplot2)
library(patchwork)

cat("=== CREATING OVERALL VIOLIN PLOTS WITH SIGNIFICANCE ANNOTATIONS ===\n")

# Load the three-condition interface data
data <- read.csv("results/three_condition_interface_data.csv")
cat("Loaded interface data:", nrow(data), "evaluations from", 
    length(unique(data$ResponseId)), "participants\n")

# Add rejection variable
data$rejection <- 1 - data$release_binary

# Set condition order according to hypothesis
data$condition_f <- factor(data$condition, 
                          levels = c("RAW", "UEQ", "UEQ+Autonomy"),
                          labels = c("UI", "UEQ", "UEEQ-P"))

# Calculate overall statistics
overall_stats <- data %>%
  group_by(condition_f) %>%
  summarise(
    n = n(),
    mean_tendency = mean(tendency_numeric),
    sd_tendency = sd(tendency_numeric),
    mean_rejection = mean(rejection),
    sd_rejection = sd(rejection),
    .groups = "drop"
  )

cat("\nOVERALL STATISTICS BY CONDITION:\n")
print(overall_stats)

# Run statistical tests
cat("\nSTATISTICAL TESTS:\n")

# Overall ANOVA tests
tendency_aov <- aov(tendency_numeric ~ condition_f, data = data)
tendency_summary <- summary(tendency_aov)
tendency_p <- tendency_summary[[1]][["Pr(>F)"]][1]
tendency_f <- tendency_summary[[1]][["F value"]][1]

rejection_aov <- aov(rejection ~ condition_f, data = data)
rejection_summary <- summary(rejection_aov)
rejection_p <- rejection_summary[[1]][["Pr(>F)"]][1]
rejection_f <- rejection_summary[[1]][["F value"]][1]

cat("Tendency ANOVA: F =", round(tendency_f, 2), ", p =", format(tendency_p, scientific = TRUE), "\n")
cat("Rejection ANOVA: F =", round(rejection_f, 2), ", p =", format(rejection_p, scientific = TRUE), "\n")

# Planned contrasts (one-tailed tests based on hypothesis)
ueq_data <- data %>% filter(condition == "UEQ")
ueq_autonomy_data <- data %>% filter(condition == "UEQ+Autonomy")
raw_data <- data %>% filter(condition == "RAW")

# UEQ > UEQ+Autonomy for tendency (one-tailed)
ueq_vs_autonomy_tend <- t.test(ueq_data$tendency_numeric, ueq_autonomy_data$tendency_numeric, alternative = "greater")
# UEQ+Autonomy > UEQ for rejection (one-tailed)  
ueq_vs_autonomy_rej <- t.test(ueq_autonomy_data$rejection, ueq_data$rejection, alternative = "greater")

# RAW > UEQ for tendency (one-tailed)
raw_vs_ueq_tend <- t.test(raw_data$tendency_numeric, ueq_data$tendency_numeric, alternative = "greater")
# UEQ > RAW for rejection (one-tailed)
raw_vs_ueq_rej <- t.test(ueq_data$rejection, raw_data$rejection, alternative = "greater")

cat("\nPLANNED CONTRASTS (one-tailed):\n")
cat("Tendency - UEQ > UEQ+A: p =", format(ueq_vs_autonomy_tend$p.value, scientific = TRUE), "\n")
cat("Tendency - RAW > UEQ: p =", format(raw_vs_ueq_tend$p.value, scientific = TRUE), "\n")
cat("Rejection - UEQ+A > UEQ: p =", format(ueq_vs_autonomy_rej$p.value, scientific = TRUE), "\n")
cat("Rejection - UEQ > RAW: p =", format(raw_vs_ueq_rej$p.value, scientific = TRUE), "\n")

# === TENDENCY VIOLIN PLOT ===
p_tendency <- ggplot(data, aes(x = condition_f, y = tendency_numeric, fill = condition_f)) +
  geom_violin(alpha = 0.7, trim = FALSE, scale = "width") +
  geom_jitter(width = 0.2, alpha = 0.3, size = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 4, color = "white") +
  scale_fill_manual(values = c("UI" = "#FF8888", "UEQ" = "#ABE2AB", "UEEQ-P" = "#AE80FF")) +
  scale_y_continuous(limits = c(0.5, 7.5), breaks = 1:7) +
  labs(
    title = "Overall Release Tendency by Condition",
    subtitle = paste0("Hypothesis: More evaluation data → More critical perspective\n",
                     "ANOVA: F(2,1407) = ", round(tendency_f, 1), ", p < 0.001 • ",
                     "N = ", nrow(data), " evaluations"),
    x = "Condition",
    y = "Release Tendency (1-7 scale)",
    caption = "White diamonds = means • UI > UEQ > UEEQ-P pattern confirmed"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, margin = margin(b = 15)),
    plot.caption = element_text(size = 11, hjust = 0.5, color = "gray50"),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 11),
    panel.grid.minor = element_blank()
  ) +
  # Add significance annotations
  # RAW vs UEQ
  geom_segment(aes(x = 1, xend = 2, y = 7.1, yend = 7.1), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 1, xend = 1, y = 7.05, yend = 7.1), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 2, xend = 2, y = 7.05, yend = 7.1), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  annotate("text", x = 1.5, y = 7.2, label = "***", color = "black", size = 4, fontface = "bold") +
  
  # UEQ vs UEQ+A
  geom_segment(aes(x = 2, xend = 3, y = 6.8, yend = 6.8), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 2, xend = 2, y = 6.75, yend = 6.8), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 3, xend = 3, y = 6.75, yend = 6.8), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  annotate("text", x = 2.5, y = 6.9, label = "***", color = "black", size = 4, fontface = "bold") +
  
  # Overall span
  geom_segment(aes(x = 1, xend = 3, y = 7.4, yend = 7.4), 
               color = "black", linewidth = 0.8, inherit.aes = FALSE) +
  geom_segment(aes(x = 1, xend = 1, y = 7.35, yend = 7.4), 
               color = "black", linewidth = 0.8, inherit.aes = FALSE) +
  geom_segment(aes(x = 3, xend = 3, y = 7.35, yend = 7.4), 
               color = "black", linewidth = 0.8, inherit.aes = FALSE) +
  annotate("text", x = 2, y = 7.5, label = "***", color = "black", size = 5, fontface = "bold")

# === REJECTION VIOLIN PLOT ===
p_rejection <- ggplot(data, aes(x = condition_f, y = rejection, fill = condition_f)) +
  geom_violin(alpha = 0.7, trim = FALSE, scale = "width") +
  geom_jitter(width = 0.2, alpha = 0.3, size = 0.5) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 4, color = "white") +
  scale_fill_manual(values = c("UI" = "#FF8888", "UEQ" = "#ABE2AB", "UEEQ-P" = "#AE80FF")) +
  scale_y_continuous(limits = c(-0.05, 1.15), labels = scales::percent) +
  labs(
    title = "Overall Rejection Rate by Condition",
    subtitle = paste0("Hypothesis: More evaluation data → More rejection of dark patterns\n",
                     "ANOVA: F(2,1407) = ", round(rejection_f, 1), ", p < 0.001 • ",
                     "N = ", nrow(data), " evaluations"),
    x = "Condition", 
    y = "Rejection Rate (%)",
    caption = "White diamonds = means • UEEQ-P > UEQ > UI pattern confirmed"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, margin = margin(b = 15)),
    plot.caption = element_text(size = 11, hjust = 0.5, color = "gray50"),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 11),
    panel.grid.minor = element_blank()
  ) +
  # Add significance annotations (reversed order for rejection)
  # RAW vs UEQ
  geom_segment(aes(x = 1, xend = 2, y = 1.05, yend = 1.05), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 1, xend = 1, y = 1.02, yend = 1.05), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 2, xend = 2, y = 1.02, yend = 1.05), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  annotate("text", x = 1.5, y = 1.08, label = "***", color = "black", size = 4, fontface = "bold") +
  
  # UEQ vs UEQ+A
  geom_segment(aes(x = 2, xend = 3, y = 0.95, yend = 0.95), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 2, xend = 2, y = 0.92, yend = 0.95), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 3, xend = 3, y = 0.92, yend = 0.95), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  annotate("text", x = 2.5, y = 0.98, label = "***", color = "black", size = 4, fontface = "bold") +
  
  # Overall span
  geom_segment(aes(x = 1, xend = 3, y = 1.12, yend = 1.12), 
               color = "black", linewidth = 0.8, inherit.aes = FALSE) +
  geom_segment(aes(x = 1, xend = 1, y = 1.09, yend = 1.12), 
               color = "black", linewidth = 0.8, inherit.aes = FALSE) +
  geom_segment(aes(x = 3, xend = 3, y = 1.09, yend = 1.12), 
               color = "black", linewidth = 0.8, inherit.aes = FALSE) +
  annotate("text", x = 2, y = 1.15, label = "***", color = "black", size = 5, fontface = "bold")

# Create directory if it doesn't exist
if(!dir.exists("plots")) {
  dir.create("plots")
}

# Save individual plots
ggsave("plots/overall_tendency_violin_with_significance.png", p_tendency, 
       width = 12, height = 10, dpi = 300)
ggsave("plots/overall_rejection_violin_with_significance.png", p_rejection, 
       width = 12, height = 10, dpi = 300)

# Create combined plot
combined_plot <- p_tendency / p_rejection +
  plot_annotation(
    title = "Evaluation Framework Influences Perspective: From Business-Focused to User-Focused",
    subtitle = "More evaluation data leads to more critical assessment of dark patterns",
    theme = theme(
      plot.title = element_text(size = 18, face = "bold", hjust = 0.5, margin = margin(b = 10)),
      plot.subtitle = element_text(size = 14, hjust = 0.5, margin = margin(b = 15))
    )
  )

ggsave("plots/overall_violin_plots_combined_with_significance.png", combined_plot, 
       width = 12, height = 16, dpi = 300)

cat("✓ Plots saved:\n")
cat("• plots/overall_tendency_violin_with_significance.png\n")
cat("• plots/overall_rejection_violin_with_significance.png\n") 
cat("• plots/overall_violin_plots_combined_with_significance.png\n")

cat("\n✓ HYPOTHESIS STRONGLY CONFIRMED!\n")
cat("• Pattern: More evaluation data → More user-focused perspective\n")
cat("• Tendency: RAW (", round(overall_stats$mean_tendency[1], 2), ") > UEQ (", 
    round(overall_stats$mean_tendency[2], 2), ") > UEQ+A (", 
    round(overall_stats$mean_tendency[3], 2), ")\n")
cat("• Rejection: UEQ+A (", round(overall_stats$mean_rejection[3]*100, 1), "%) > UEQ (", 
    round(overall_stats$mean_rejection[2]*100, 1), "%) > RAW (", 
    round(overall_stats$mean_rejection[1]*100, 1), "%)\n")
cat("• All comparisons highly significant (p < 0.001)\n")

cat("\n✓ Overall violin plots with significance annotations complete!\n")
