# Three-Condition Visualization Script
# Individual Interface Analysis + Key Comparisons
# September 2025

library(dplyr)
library(readr)
library(ggplot2)
library(gridExtra)

cat("=== THREE-CONDITION VISUALIZATION ===\n")

# ===== LOAD DATA =====
cat("1. LOADING DATA...\n")
data <- read.csv("results/three_condition_interface_data.csv")
results <- read.csv("results/three_condition_anova_results.csv")

# ===== INDIVIDUAL INTERFACE VIOLIN PLOTS (like previous FDR plot) =====
cat("\n2. CREATING INDIVIDUAL INTERFACE PLOTS...\n")

# Get significant interfaces for highlighting
sig_tendency <- results %>%
  filter(ueq_autonomy_tend_p_fdr < 0.05) %>%
  pull(interface)

sig_rejection <- results %>%
  filter(ueq_autonomy_rej_p_fdr < 0.05) %>%
  pull(interface)

# All significant interfaces (union)
sig_interfaces <- unique(c(sig_tendency, sig_rejection))

cat("Significant interfaces for highlighting:", length(sig_interfaces), "\n")
print(sig_interfaces)

# Create interface-level summaries for plotting
interface_summary <- data %>%
  group_by(interface, condition) %>%
  summarise(
    mean_tendency = mean(tendency_numeric),
    se_tendency = sd(tendency_numeric) / sqrt(n()),
    mean_rejection = mean(1 - release_binary),
    se_rejection = sd(1 - release_binary) / sqrt(n()),
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(
    interface_num = as.numeric(gsub("ui0*", "", interface)),
    is_significant = interface %in% sig_interfaces
  )

# === TENDENCY PLOT ===
p_tendency <- ggplot(interface_summary, aes(x = reorder(interface, interface_num), y = mean_tendency, fill = condition)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), alpha = 0.8) +
  geom_errorbar(aes(ymin = mean_tendency - se_tendency, ymax = mean_tendency + se_tendency),
                position = position_dodge(width = 0.8), width = 0.2) +
  scale_fill_manual(values = c("UEQ" = "#3498db", "UEQ+Autonomy" = "#e74c3c", "RAW" = "#2ecc71"),
                    name = "Condition") +
  scale_y_continuous(limits = c(1, 7), breaks = 1:7) +
  labs(
    title = "Release Tendency by Interface and Condition",
    subtitle = paste("Significant interfaces (FDR < 0.05):", paste(sig_interfaces, collapse = ", ")),
    x = "Interface",
    y = "Mean Release Tendency (1-7 scale)"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 12),
    legend.position = "bottom"
  ) +
  # Highlight significant interfaces
  geom_rect(data = interface_summary %>% filter(is_significant) %>% select(interface) %>% distinct(),
            aes(xmin = as.numeric(factor(interface, levels = levels(reorder(interface_summary$interface, interface_summary$interface_num)))) - 0.4,
                xmax = as.numeric(factor(interface, levels = levels(reorder(interface_summary$interface, interface_summary$interface_num)))) + 0.4,
                ymin = -Inf, ymax = Inf),
            fill = "yellow", alpha = 0.2, inherit.aes = FALSE)

# === REJECTION RATE PLOT ===
p_rejection <- ggplot(interface_summary, aes(x = reorder(interface, interface_num), y = mean_rejection, fill = condition)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), alpha = 0.8) +
  geom_errorbar(aes(ymin = mean_rejection - se_rejection, ymax = mean_rejection + se_rejection),
                position = position_dodge(width = 0.8), width = 0.2) +
  scale_fill_manual(values = c("UEQ" = "#3498db", "UEQ+Autonomy" = "#e74c3c", "RAW" = "#2ecc71"),
                    name = "Condition") +
  scale_y_continuous(limits = c(0, 1), labels = scales::percent) +
  labs(
    title = "Rejection Rate by Interface and Condition",
    subtitle = paste("Significant interfaces (FDR < 0.05):", paste(sig_rejection, collapse = ", ")),
    x = "Interface",
    y = "Mean Rejection Rate (%)"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 12),
    legend.position = "bottom"
  )

# Save individual plots
ggsave("plots/three_condition_tendency_comparison.png", p_tendency, 
       width = 16, height = 10, dpi = 300)
ggsave("plots/three_condition_rejection_comparison.png", p_rejection, 
       width = 16, height = 10, dpi = 300)

# === OVERALL CONDITION COMPARISON ===
cat("\n3. CREATING OVERALL CONDITION COMPARISONS...\n")

# Overall tendency comparison
overall_tendency <- data %>%
  group_by(condition) %>%
  summarise(
    mean_tendency = mean(tendency_numeric),
    se_tendency = sd(tendency_numeric) / sqrt(n()),
    n = n(),
    .groups = "drop"
  )

p_overall_tendency <- ggplot(overall_tendency, aes(x = condition, y = mean_tendency, fill = condition)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  geom_errorbar(aes(ymin = mean_tendency - se_tendency, ymax = mean_tendency + se_tendency), width = 0.2) +
  scale_fill_manual(values = c("UEQ" = "#3498db", "UEQ+Autonomy" = "#e74c3c", "RAW" = "#2ecc71")) +
  scale_y_continuous(limits = c(1, 7), breaks = 1:7) +
  labs(
    title = "Overall Release Tendency by Condition",
    subtitle = paste("Sample sizes - UEQ:", overall_tendency$n[overall_tendency$condition == "UEQ"],
                     "UEQ+Autonomy:", overall_tendency$n[overall_tendency$condition == "UEQ+Autonomy"],
                     "RAW:", overall_tendency$n[overall_tendency$condition == "RAW"]),
    x = "Condition",
    y = "Mean Release Tendency (1-7 scale)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "none"
  )

# Overall rejection rate comparison
overall_rejection <- data %>%
  mutate(rejection = 1 - release_binary) %>%
  group_by(condition) %>%
  summarise(
    mean_rejection = mean(rejection),
    se_rejection = sd(rejection) / sqrt(n()),
    n = n(),
    .groups = "drop"
  )

p_overall_rejection <- ggplot(overall_rejection, aes(x = condition, y = mean_rejection, fill = condition)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  geom_errorbar(aes(ymin = mean_rejection - se_rejection, ymax = mean_rejection + se_rejection), width = 0.2) +
  scale_fill_manual(values = c("UEQ" = "#3498db", "UEQ+Autonomy" = "#e74c3c", "RAW" = "#2ecc71")) +
  scale_y_continuous(limits = c(0, 1), labels = scales::percent) +
  labs(
    title = "Overall Rejection Rate by Condition",
    subtitle = paste("Sample sizes - UEQ:", overall_rejection$n[overall_rejection$condition == "UEQ"],
                     "UEQ+Autonomy:", overall_rejection$n[overall_rejection$condition == "UEQ+Autonomy"],
                     "RAW:", overall_rejection$n[overall_rejection$condition == "RAW"]),
    x = "Condition",
    y = "Mean Rejection Rate (%)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "none"
  )

# Save overall comparison plots
ggsave("plots/overall_tendency_comparison.png", p_overall_tendency, 
       width = 10, height = 8, dpi = 300)
ggsave("plots/overall_rejection_comparison.png", p_overall_rejection, 
       width = 10, height = 8, dpi = 300)

# === COMBINED SUMMARY PLOT ===
combined_summary <- grid.arrange(p_overall_tendency, p_overall_rejection, ncol = 2,
                                top = "Three-Condition Experiment: Key Findings")

ggsave("plots/three_condition_summary.png", combined_summary, 
       width = 16, height = 8, dpi = 300)

cat("\n4. FILES CREATED:\n")
cat("• plots/three_condition_tendency_comparison.png - Individual interface tendency\n")
cat("• plots/three_condition_rejection_comparison.png - Individual interface rejection\n")
cat("• plots/overall_tendency_comparison.png - Overall tendency comparison\n")
cat("• plots/overall_rejection_comparison.png - Overall rejection comparison\n")
cat("• plots/three_condition_summary.png - Combined summary plot\n")

cat("\n✓ Visualization complete!\n")
