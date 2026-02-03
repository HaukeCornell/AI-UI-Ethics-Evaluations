# Create Publication-Ready Participant-Level Plots with Statistical Annotations
# APA-compliant visualizations with significance testing and proper formatting

library(dplyr)
library(ggplot2)
library(patchwork)

cat("=== CREATING PUBLICATION-READY PARTICIPANT-LEVEL PLOTS ===\n")

# Load data
data <- read.csv("results/three_condition_interface_data.csv")
data$rejection <- 1 - data$release_binary

# Calculate participant-level means
participant_means <- data %>%
  # Mapping: Ensure we handle any previous renaming attempts
  mutate(condition = case_when(
    condition %in% c("RAW", "UI") ~ "UI",
    condition %in% c("UEQ") ~ "UEQ",
    condition %in% c("UEQ+Autonomy", "UEQ-A", "UEEQ-P") ~ "UEEQ-P",
    TRUE ~ condition
  )) %>%
  group_by(ResponseId, condition) %>%
  summarise(
    participant_mean_rejection = mean(rejection, na.rm = TRUE),
    participant_mean_tendency = mean(tendency_numeric, na.rm = TRUE),
    n_interfaces = n(),
    .groups = "drop"
  ) %>%
  mutate(condition_f = factor(condition, 
                             levels = c("UI", "UEQ", "UEEQ-P")))

# Calculate descriptive statistics
descriptive_stats <- participant_means %>%
  group_by(condition_f) %>%
  summarise(
    n = n(),
    mean_rejection = mean(participant_mean_rejection),
    median_rejection = median(participant_mean_rejection),
    sd_rejection = sd(participant_mean_rejection),
    se_rejection = sd_rejection / sqrt(n),
    mean_tendency = mean(participant_mean_tendency),
    median_tendency = median(participant_mean_tendency),
    sd_tendency = sd(participant_mean_tendency),
    se_tendency = sd_tendency / sqrt(n),
    .groups = "drop"
  )

cat("DESCRIPTIVE STATISTICS:\n")
print(descriptive_stats)

# === STATISTICAL TESTS ===
cat("\nSTATISTICAL TESTS:\n")

# ANOVA
rejection_aov <- aov(participant_mean_rejection ~ condition_f, data = participant_means)
tendency_aov <- aov(participant_mean_tendency ~ condition_f, data = participant_means)

rejection_summary <- summary(rejection_aov)
tendency_summary <- summary(tendency_aov)

# Post-hoc tests (Tukey HSD)
rejection_tukey <- TukeyHSD(rejection_aov)
tendency_tukey <- TukeyHSD(tendency_aov)

cat("Rejection ANOVA: F(2,138) =", round(rejection_summary[[1]][["F value"]][1], 2), 
    ", p =", format(rejection_summary[[1]][["Pr(>F)"]][1], scientific = TRUE), "\n")
cat("Tendency ANOVA: F(2,138) =", round(tendency_summary[[1]][["F value"]][1], 2), 
    ", p =", format(tendency_summary[[1]][["Pr(>F)"]][1], scientific = TRUE), "\n")

# Extract significance levels for annotations
rej_tukey_results <- as.data.frame(rejection_tukey$condition_f)
tend_tukey_results <- as.data.frame(tendency_tukey$condition_f)

cat("\nPost-hoc comparisons (Tukey HSD):\n")
cat("REJECTION:\n")
print(rej_tukey_results)
cat("\nTENDENCY:\n")
print(tend_tukey_results)

# Function to get significance stars
get_sig_stars <- function(p_value) {
  if (p_value < 0.001) return("***")
  if (p_value < 0.01) return("**")
  if (p_value < 0.05) return("*")
  return("ns")
}

# === PUBLICATION-READY REJECTION PLOT ===
p_rejection_pub <- ggplot(participant_means, aes(x = condition_f, y = participant_mean_rejection * 100, fill = condition_f)) +
  # Violin plots
  geom_violin(alpha = 0.6, trim = FALSE, scale = "width") +
  # Box plots
  geom_boxplot(width = 0.3, alpha = 0.8, outlier.shape = NA) +
  # Individual points
  geom_jitter(width = 0.15, alpha = 0.7, size = 1.2) +
  # Mean points
  stat_summary(fun = mean, geom = "point", shape = 18, size = 4, color = "white", stroke = 0.5) +
  # Color scheme
  scale_fill_manual(values = c("UI" = "#FF8888", "UEQ" = "#ABE2AB", "UEEQ-P" = "#AE80FF")) +
  scale_y_continuous(limits = c(-5, 105), breaks = seq(0, 100, 20)) +
  labs(
    title = "Dark Pattern Rejection Rates by Evaluation Condition",
    x = "Evaluation Condition",
    y = "Rejection Rate (%)",
    caption = paste("Error bars represent ±1 SEM. N =", nrow(participant_means), "participants.",
                   "White diamonds indicate means.")
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5, margin = margin(b = 20)),
    plot.caption = element_text(size = 10, hjust = 0.5, color = "gray50", margin = margin(t = 15)),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 11),
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "black", size = 0.5),
    axis.ticks = element_line(color = "black", size = 0.5)
  ) +
  # Add significance brackets and annotations
  # RAW vs UEQ
  geom_segment(aes(x = 1, xend = 2, y = 85, yend = 85), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 1, xend = 1, y = 82, yend = 85), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 2, xend = 2, y = 82, yend = 85), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  annotate("text", x = 1.5, y = 88, 
           label = get_sig_stars(rej_tukey_results["UEQ-UI", "p adj"]), 
           color = "black", size = 4, fontface = "bold") +
  
  # UEQ vs UEEQ-P
  geom_segment(aes(x = 2, xend = 3, y = 75, yend = 75), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 2, xend = 2, y = 72, yend = 75), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 3, xend = 3, y = 72, yend = 75), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  annotate("text", x = 2.5, y = 78, 
           label = get_sig_stars(rej_tukey_results["UEEQ-P-UEQ", "p adj"]), 
           color = "black", size = 4, fontface = "bold") +
  
  # UI vs UEEQ-P
  geom_segment(aes(x = 1, xend = 3, y = 95, yend = 95), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 1, xend = 1, y = 92, yend = 95), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 3, xend = 3, y = 92, yend = 95), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  annotate("text", x = 2, y = 98, 
           label = get_sig_stars(rej_tukey_results["UEEQ-P-UI", "p adj"]), 
           color = "black", size = 4, fontface = "bold") +
  
  # Add descriptive statistics text
  annotate("text", x = 1, y = -2, 
           label = paste0("M = ", round(descriptive_stats$mean_rejection[1] * 100, 1), 
                         "%\nMdn = ", round(descriptive_stats$median_rejection[1] * 100, 1), "%"), 
           size = 3, hjust = 0.5, color = "gray40") +
  annotate("text", x = 2, y = -2, 
           label = paste0("M = ", round(descriptive_stats$mean_rejection[2] * 100, 1), 
                         "%\nMdn = ", round(descriptive_stats$median_rejection[2] * 100, 1), "%"), 
           size = 3, hjust = 0.5, color = "gray40") +
  annotate("text", x = 3, y = -2, 
           label = paste0("M = ", round(descriptive_stats$mean_rejection[3] * 100, 1), 
                         "%\nMdn = ", round(descriptive_stats$median_rejection[3] * 100, 1), "%"), 
           size = 3, hjust = 0.5, color = "gray40")

# === PUBLICATION-READY TENDENCY PLOT ===
p_tendency_pub <- ggplot(participant_means, aes(x = condition_f, y = participant_mean_tendency, fill = condition_f)) +
  # Violin plots
  geom_violin(alpha = 0.6, trim = FALSE, scale = "width") +
  # Box plots
  geom_boxplot(width = 0.3, alpha = 0.8, outlier.shape = NA) +
  # Individual points
  geom_jitter(width = 0.15, alpha = 0.7, size = 1.2) +
  # Mean points
  stat_summary(fun = mean, geom = "point", shape = 18, size = 4, color = "white", stroke = 0.5) +
  # Color scheme
  scale_fill_manual(values = c("UI" = "#FF8888", "UEQ" = "#ABE2AB", "UEEQ-P" = "#AE80FF")) +
  scale_y_continuous(limits = c(0.5, 7.5), breaks = 1:7) +
  labs(
    title = "Dark Pattern Release Tendency by Evaluation Condition",
    x = "Evaluation Condition",
    y = "Release Tendency (1-7 scale)",
    caption = paste("Error bars represent ±1 SEM. N =", nrow(participant_means), "participants.",
                   "White diamonds indicate means.")
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5, margin = margin(b = 20)),
    plot.caption = element_text(size = 10, hjust = 0.5, color = "gray50", margin = margin(t = 15)),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 11),
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "black", size = 0.5),
    axis.ticks = element_line(color = "black", size = 0.5)
  ) +
  # Add significance brackets and annotations
  # RAW vs UEQ
  geom_segment(aes(x = 1, xend = 2, y = 6.8, yend = 6.8), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 1, xend = 1, y = 6.7, yend = 6.8), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 2, xend = 2, y = 6.7, yend = 6.8), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  annotate("text", x = 1.5, y = 6.95, 
           label = get_sig_stars(tend_tukey_results["UEQ-UI", "p adj"]), 
           color = "black", size = 4, fontface = "bold") +
  
  # UEQ vs UEEQ-P
  geom_segment(aes(x = 2, xend = 3, y = 6.4, yend = 6.4), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 2, xend = 2, y = 6.3, yend = 6.4), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 3, xend = 3, y = 6.3, yend = 6.4), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  annotate("text", x = 2.5, y = 6.55, 
           label = get_sig_stars(tend_tukey_results["UEEQ-P-UEQ", "p adj"]), 
           color = "black", size = 4, fontface = "bold") +
  
  # UI vs UEEQ-P
  geom_segment(aes(x = 1, xend = 3, y = 7.2, yend = 7.2), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 1, xend = 1, y = 7.1, yend = 7.2), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 3, xend = 3, y = 7.1, yend = 7.2), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  annotate("text", x = 2, y = 7.35, 
           label = get_sig_stars(tend_tukey_results["UEEQ-P-UI", "p adj"]), 
           color = "black", size = 4, fontface = "bold") +
  
  # Add descriptive statistics text
  annotate("text", x = 1, y = 0.8, 
           label = paste0("M = ", round(descriptive_stats$mean_tendency[1], 2), 
                         "\nMdn = ", round(descriptive_stats$median_tendency[1], 2)), 
           size = 3, hjust = 0.5, color = "gray40") +
  annotate("text", x = 2, y = 0.8, 
           label = paste0("M = ", round(descriptive_stats$mean_tendency[2], 2), 
                         "\nMdn = ", round(descriptive_stats$median_tendency[2], 2)), 
           size = 3, hjust = 0.5, color = "gray40") +
  annotate("text", x = 3, y = 0.8, 
           label = paste0("M = ", round(descriptive_stats$mean_tendency[3], 2), 
                         "\nMdn = ", round(descriptive_stats$median_tendency[3], 2)), 
           size = 3, hjust = 0.5, color = "gray40")

# === SAVE PUBLICATION-READY PLOTS ===
if(!dir.exists("plots")) {
  dir.create("plots")
}

ggsave("plots/participant_rejection_publication_ready.png", p_rejection_pub, 
       width = 8, height = 6, dpi = 300)
ggsave("plots/participant_tendency_publication_ready.png", p_tendency_pub, 
       width = 8, height = 6, dpi = 300)

# Combined publication plot
combined_pub <- p_tendency_pub / p_rejection_pub +
  plot_annotation(
    title = "Evaluation Framework Effects on Dark Pattern Assessment",
    subtitle = "Participant-level analysis (N = 141 participants)",
    caption = "Note: *** p < .001, ** p < .01, * p < .05. Error bars represent ±1 SEM.",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 10)),
      plot.subtitle = element_text(size = 12, hjust = 0.5, margin = margin(b = 15)),
      plot.caption = element_text(size = 10, hjust = 0.5, color = "gray50", margin = margin(t = 15))
    )
  )

ggsave("plots/participant_combined_publication_ready.png", combined_pub, 
       width = 8, height = 10, dpi = 300)

cat("✓ PUBLICATION-READY PLOTS CREATED!\n")
cat("✓ Plots saved:\n")
cat("• plots/participant_rejection_publication_ready.png\n")
cat("• plots/participant_tendency_publication_ready.png\n")
cat("• plots/participant_combined_publication_ready.png\n\n")

# === STATISTICAL SUMMARY FOR PAPER ===
cat("STATISTICAL SUMMARY FOR PAPER:\n")
cat("=============================\n")
cat("REJECTION RATES:\n")
for(i in 1:3) {
  cond <- descriptive_stats$condition_f[i]
  cat(sprintf("%s: M = %.1f%%, SD = %.1f%%, Mdn = %.1f%%\n", 
              cond, 
              descriptive_stats$mean_rejection[i] * 100,
              descriptive_stats$sd_rejection[i] * 100,
              descriptive_stats$median_rejection[i] * 100))
}

cat("\nTENDENCY SCORES:\n")
for(i in 1:3) {
  cond <- descriptive_stats$condition_f[i]
  cat(sprintf("%s: M = %.2f, SD = %.2f, Mdn = %.2f\n", 
              cond, 
              descriptive_stats$mean_tendency[i],
              descriptive_stats$sd_tendency[i],
              descriptive_stats$median_tendency[i]))
}

cat("\nANOVA RESULTS:\n")
cat(sprintf("Rejection: F(2,138) = %.2f, p = %.2e\n", 
            rejection_summary[[1]][["F value"]][1], 
            rejection_summary[[1]][["Pr(>F)"]][1]))
cat(sprintf("Tendency: F(2,138) = %.2f, p = %.2e\n", 
            tendency_summary[[1]][["F value"]][1], 
            tendency_summary[[1]][["Pr(>F)"]][1]))

cat("\n✓ Publication-ready analysis complete!\n")
