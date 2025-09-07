# HIGH-QUALITY Participant-Level Analysis Plots with UI/UEQ/UEQ-A naming
# RESTORED: Boxplots, significance lines, visible mean/median labels, jitter points
# Based on original 10_publication_ready_plots.R structure

library(dplyr)
library(ggplot2)

cat("=== CREATING HIGH-QUALITY PARTICIPANT-LEVEL PLOTS ===\n")

# Load and prepare interface data, then create participant aggregations
interface_data <- read.csv("results/three_condition_interface_data.csv")

# Update condition names
interface_data$condition_new <- case_when(
  interface_data$condition == "RAW" ~ "UI",
  interface_data$condition == "UEQ" ~ "UEQ", 
  interface_data$condition == "UEQ+Autonomy" ~ "UEQ-A",
  TRUE ~ interface_data$condition
)

# Create participant-level aggregations
participant_data <- interface_data %>%
  group_by(PROLIFIC_PID, condition_new) %>%
  summarise(
    mean_tendency = mean(tendency, na.rm = TRUE),
    mean_rejection_rate = mean(1 - release_binary, na.rm = TRUE),
    n_evaluations = n(),
    .groups = "drop"
  ) %>%
  filter(!is.na(mean_tendency)) # Remove participants with missing data

# Set factor levels
participant_data$condition_new <- factor(participant_data$condition_new, levels = c("UI", "UEQ", "UEQ-A"))

# Define consistent color scheme
condition_colors <- c("UI" = "#FF8888", "UEQ" = "#ABE2AB", "UEQ-A" = "#AE80FF")

cat("Participant data loaded:", nrow(participant_data), "participants\n")
print(table(participant_data$condition_new))

# === STATISTICAL TESTS ===
cat("\nSTATISTICAL TESTS:\n")

# ANOVA
rejection_aov <- aov(mean_rejection_rate ~ condition_new, data = participant_data)
tendency_aov <- aov(mean_tendency ~ condition_new, data = participant_data)

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
rej_tukey_results <- as.data.frame(rejection_tukey$condition_new)
tend_tukey_results <- as.data.frame(tendency_tukey$condition_new)

cat("\nPost-hoc comparisons (Tukey HSD):\n")
cat("REJECTION:\n")
print(rej_tukey_results)
cat("\nTENDENCY:\n")
print(tend_tukey_results)

# Function to format p-values consistently
format_p_value <- function(p_value) {
  if (p_value < 0.001) return("p < 0.001")
  return(paste0("p = ", sprintf("%.3f", p_value)))
}

# Calculate descriptive statistics for annotations
descriptive_stats <- participant_data %>%
  group_by(condition_new) %>%
  summarise(
    n = n(),
    mean_rejection = mean(mean_rejection_rate),
    median_rejection = median(mean_rejection_rate),
    mean_tendency = mean(mean_tendency),
    median_tendency = median(mean_tendency),
    .groups = "drop"
  )

# === HIGH-QUALITY TENDENCY PLOT ===
cat("Creating high-quality participant tendency plot...\n")

p_tendency <- ggplot(participant_data, aes(x = condition_new, y = mean_tendency, fill = condition_new)) +
  # Violin plots (background)
  geom_violin(alpha = 0.6, trim = FALSE, scale = "width") +
  # Box plots (quartiles and outliers)
  geom_boxplot(width = 0.3, alpha = 0.8, outlier.shape = NA) +
  # Individual points (jitter)
  geom_jitter(width = 0.15, alpha = 0.7, size = 1.2, color = "black") +
  # Mean points (large, visible)
  stat_summary(fun = mean, geom = "point", shape = 18, size = 5, color = "white", stroke = 1) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 4, color = "black") +
  # Median lines (visible)
  stat_summary(fun = median, geom = "point", shape = 95, size = 8, color = "red", stroke = 1) +
  
  scale_fill_manual(values = condition_colors, name = "Condition") +
  scale_y_continuous(limits = c(0.5, 7.5), breaks = 1:7) +
  labs(
    title = "Release Tendency by Evaluation Condition",
    subtitle = "Participant-level means across all interface evaluations",
    x = "Evaluation Condition",
    y = "Mean Release Tendency (1-7 scale)",
    caption = "White/black diamonds = Mean • Red lines = Median • Points = Individual participants"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 20, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 16, hjust = 0.5, color = "gray50"),
    plot.caption = element_text(size = 14, hjust = 0.5, color = "gray50"),
    axis.title = element_text(size = 17, face = "bold"),
    axis.text = element_text(size = 16),
    axis.text.x = element_text(size = 17, face = "bold"),
    legend.position = "none",
    panel.grid.minor.y = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.line = element_line(color = "black", linewidth = 0.5),
    axis.ticks = element_line(color = "black", linewidth = 0.5)
  ) +
  
  # === SIGNIFICANCE BRACKETS ===
  # UI vs UEQ
  geom_segment(aes(x = 1, xend = 2, y = 6.8, yend = 6.8), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 1, xend = 1, y = 6.65, yend = 6.8), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 2, xend = 2, y = 6.65, yend = 6.8), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  annotate("text", x = 1.5, y = 6.95, 
           label = format_p_value(tend_tukey_results["UEQ-UI", "p adj"]), 
           color = "black", size = 5, fontface = "bold") +
  
  # UEQ vs UEQ-A
  geom_segment(aes(x = 2, xend = 3, y = 6.3, yend = 6.3), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 2, xend = 2, y = 6.15, yend = 6.3), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 3, xend = 3, y = 6.15, yend = 6.3), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  annotate("text", x = 2.5, y = 6.45, 
           label = format_p_value(tend_tukey_results["UEQ-A-UEQ", "p adj"]), 
           color = "black", size = 5, fontface = "bold") +
  
  # UI vs UEQ-A
  geom_segment(aes(x = 1, xend = 3, y = 7.3, yend = 7.3), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 1, xend = 1, y = 7.15, yend = 7.3), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 3, xend = 3, y = 7.15, yend = 7.3), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  annotate("text", x = 2, y = 7.45, 
           label = format_p_value(tend_tukey_results["UEQ-A-UI", "p adj"]), 
           color = "black", size = 5, fontface = "bold") +
  
  # Add visible mean and median text annotations
  annotate("text", x = 1, y = 0.7, 
           label = paste0("Mean = ", round(descriptive_stats$mean_tendency[1], 2)), 
           color = "black", size = 3.5, fontface = "bold") +
  annotate("text", x = 1, y = 0.9, 
           label = paste0("Median = ", round(descriptive_stats$median_tendency[1], 2)), 
           color = "red", size = 3.5, fontface = "bold") +
  
  annotate("text", x = 2, y = 0.7, 
           label = paste0("Mean = ", round(descriptive_stats$mean_tendency[2], 2)), 
           color = "black", size = 3.5, fontface = "bold") +
  annotate("text", x = 2, y = 0.9, 
           label = paste0("Median = ", round(descriptive_stats$median_tendency[2], 2)), 
           color = "red", size = 3.5, fontface = "bold") +
  
  annotate("text", x = 3, y = 0.7, 
           label = paste0("Mean = ", round(descriptive_stats$mean_tendency[3], 2)), 
           color = "black", size = 3.5, fontface = "bold") +
  annotate("text", x = 3, y = 0.9, 
           label = paste0("Median = ", round(descriptive_stats$median_tendency[3], 2)), 
           color = "red", size = 3.5, fontface = "bold")

# === HIGH-QUALITY REJECTION PLOT ===
cat("Creating high-quality participant rejection plot...\n")

p_rejection <- ggplot(participant_data, aes(x = condition_new, y = mean_rejection_rate * 100, fill = condition_new)) +
  # Violin plots (background)
  geom_violin(alpha = 0.6, trim = FALSE, scale = "width") +
  # Box plots (quartiles and outliers)
  geom_boxplot(width = 0.3, alpha = 0.8, outlier.shape = NA) +
  # Individual points (jitter)
  geom_jitter(width = 0.15, alpha = 0.7, size = 1.2, color = "black") +
  # Mean points (large, visible)
  stat_summary(fun = mean, geom = "point", shape = 18, size = 5, color = "white", stroke = 1) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 4, color = "black") +
  # Median lines (visible)
  stat_summary(fun = median, geom = "point", shape = 95, size = 8, color = "red", stroke = 1) +
  
  scale_fill_manual(values = condition_colors, name = "Condition") +
  scale_y_continuous(limits = c(-8, 108), breaks = seq(0, 100, 20)) +
  labs(
    title = "Rejection Rate by Evaluation Condition", 
    subtitle = "Participant-level rejection rates across all interface evaluations",
    x = "Evaluation Condition",
    y = "Mean Rejection Rate (%)",
    caption = "White/black diamonds = Mean • Red lines = Median • Points = Individual participants"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 20, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 16, hjust = 0.5, color = "gray50"), 
    plot.caption = element_text(size = 14, hjust = 0.5, color = "gray50"),
    axis.title = element_text(size = 17, face = "bold"),
    axis.text = element_text(size = 16),
    axis.text.x = element_text(size = 17, face = "bold"),
    legend.position = "none",
    panel.grid.minor.y = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.line = element_line(color = "black", linewidth = 0.5),
    axis.ticks = element_line(color = "black", linewidth = 0.5)
  ) +
  
  # === SIGNIFICANCE BRACKETS ===
  # UI vs UEQ
  geom_segment(aes(x = 1, xend = 2, y = 85, yend = 85), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 1, xend = 1, y = 82, yend = 85), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 2, xend = 2, y = 82, yend = 85), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  annotate("text", x = 1.5, y = 88, 
           label = format_p_value(rej_tukey_results["UEQ-UI", "p adj"]), 
           color = "black", size = 5, fontface = "bold") +
  
  # UEQ vs UEQ-A
  geom_segment(aes(x = 2, xend = 3, y = 75, yend = 75), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 2, xend = 2, y = 72, yend = 75), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 3, xend = 3, y = 72, yend = 75), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  annotate("text", x = 2.5, y = 78, 
           label = format_p_value(rej_tukey_results["UEQ-A-UEQ", "p adj"]), 
           color = "black", size = 5, fontface = "bold") +
  
  # UI vs UEQ-A
  geom_segment(aes(x = 1, xend = 3, y = 95, yend = 95), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 1, xend = 1, y = 92, yend = 95), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  geom_segment(aes(x = 3, xend = 3, y = 92, yend = 95), 
               color = "black", linewidth = 0.5, inherit.aes = FALSE) +
  annotate("text", x = 2, y = 98, 
           label = format_p_value(rej_tukey_results["UEQ-A-UI", "p adj"]), 
           color = "black", size = 5, fontface = "bold") +
  
  # Add visible mean and median text annotations
  annotate("text", x = 1, y = -3, 
           label = paste0("Mean = ", round(descriptive_stats$mean_rejection[1] * 100, 1), "%"), 
           color = "black", size = 3.5, fontface = "bold") +
  annotate("text", x = 1, y = -6, 
           label = paste0("Median = ", round(descriptive_stats$median_rejection[1] * 100, 1), "%"), 
           color = "red", size = 3.5, fontface = "bold") +
  
  annotate("text", x = 2, y = -3, 
           label = paste0("Mean = ", round(descriptive_stats$mean_rejection[2] * 100, 1), "%"), 
           color = "black", size = 3.5, fontface = "bold") +
  annotate("text", x = 2, y = -6, 
           label = paste0("Median = ", round(descriptive_stats$median_rejection[2] * 100, 1), "%"), 
           color = "red", size = 3.5, fontface = "bold") +
  
  annotate("text", x = 3, y = -3, 
           label = paste0("Mean = ", round(descriptive_stats$mean_rejection[3] * 100, 1), "%"), 
           color = "black", size = 3.5, fontface = "bold") +
  annotate("text", x = 3, y = -6, 
           label = paste0("Median = ", round(descriptive_stats$median_rejection[3] * 100, 1), "%"), 
           color = "red", size = 3.5, fontface = "bold")

# Save high-quality plots
if(!dir.exists("plots")) dir.create("plots")

ggsave("plots/participant_tendency_publication_ready.png", p_tendency, 
       width = 12, height = 8, dpi = 300)

ggsave("plots/participant_rejection_publication_ready.png", p_rejection, 
       width = 12, height = 8, dpi = 300)

# === CREATE THUMBNAIL VERSIONS ===
cat("Creating thumbnail versions...\n")

# Function to get significance stars for thumbnails
get_sig_stars <- function(p_value) {
  if (p_value < 0.001) return("***")
  if (p_value < 0.01) return("**")
  if (p_value < 0.05) return("*")
  return("ns")
}

# Tendency thumbnail
p_tendency_thumb <- ggplot(participant_data, aes(x = condition_new, y = mean_tendency, fill = condition_new)) +
  geom_boxplot(width = 0.6, alpha = 0.8, outlier.shape = NA) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 6, color = "black") +
  
  # Essential significance stars only
  annotate("text", x = 1.5, y = 6.8, 
           label = get_sig_stars(tend_tukey_results["UEQ-UI", "p adj"]), 
           size = 8, fontface = "bold") +
  annotate("text", x = 2.5, y = 6.3, 
           label = get_sig_stars(tend_tukey_results["UEQ-A-UEQ", "p adj"]), 
           size = 8, fontface = "bold") +
  annotate("text", x = 2, y = 7.2, 
           label = get_sig_stars(tend_tukey_results["UEQ-A-UI", "p adj"]), 
           size = 8, fontface = "bold") +
  
  # Essential mean values
  annotate("text", x = 1, y = 1.2, 
           label = sprintf("%.2f", descriptive_stats$mean_tendency[1]), 
           color = "black", size = 6, fontface = "bold") +
  annotate("text", x = 2, y = 1.2, 
           label = sprintf("%.2f", descriptive_stats$mean_tendency[2]), 
           color = "black", size = 6, fontface = "bold") +
  annotate("text", x = 3, y = 1.2, 
           label = sprintf("%.2f", descriptive_stats$mean_tendency[3]), 
           color = "black", size = 6, fontface = "bold") +
  
  scale_fill_manual(values = condition_colors) +
  labs(title = "Release Tendency", x = "Condition", y = "Tendency (1-7)") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 11),
    axis.text.x = element_text(size = 12, face = "bold"),
    legend.position = "none",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  ) +
  scale_y_continuous(limits = c(1, 7.5), breaks = 1:7)

# Rejection thumbnail  
p_rejection_thumb <- ggplot(participant_data, aes(x = condition_new, y = mean_rejection_rate * 100, fill = condition_new)) +
  geom_boxplot(width = 0.6, alpha = 0.8, outlier.shape = NA) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 6, color = "black") +
  
  # Essential significance stars only
  annotate("text", x = 1.5, y = 82, 
           label = get_sig_stars(rej_tukey_results["UEQ-UI", "p adj"]), 
           size = 8, fontface = "bold") +
  annotate("text", x = 2.5, y = 72, 
           label = get_sig_stars(rej_tukey_results["UEQ-A-UEQ", "p adj"]), 
           size = 8, fontface = "bold") +
  annotate("text", x = 2, y = 92, 
           label = get_sig_stars(rej_tukey_results["UEQ-A-UI", "p adj"]), 
           size = 8, fontface = "bold") +
  
  # Essential mean values
  annotate("text", x = 1, y = 5, 
           label = paste0(sprintf("%.1f", descriptive_stats$mean_rejection[1] * 100), "%"), 
           color = "black", size = 6, fontface = "bold") +
  annotate("text", x = 2, y = 5, 
           label = paste0(sprintf("%.1f", descriptive_stats$mean_rejection[2] * 100), "%"), 
           color = "black", size = 6, fontface = "bold") +
  annotate("text", x = 3, y = 5, 
           label = paste0(sprintf("%.1f", descriptive_stats$mean_rejection[3] * 100), "%"), 
           color = "black", size = 6, fontface = "bold") +
  
  scale_fill_manual(values = condition_colors) +
  labs(title = "Rejection Rate", x = "Condition", y = "Rejection (%)") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 11),
    axis.text.x = element_text(size = 12, face = "bold"),
    legend.position = "none",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  ) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20))

ggsave("plots/participant_tendency_thumbnail.png", p_tendency_thumb, 
       width = 8, height = 6, dpi = 300)

ggsave("plots/participant_rejection_thumbnail.png", p_rejection_thumb, 
       width = 8, height = 6, dpi = 300)

cat("✓ HIGH-QUALITY participant plots saved with:\n")
cat("  • Boxplots showing quartiles\n")
cat("  • Significance brackets and p-values\n")
cat("  • Large, visible mean (black diamonds) and median (red lines) indicators\n")
cat("  • Jitter points showing individual participants\n")
cat("  • Visible mean/median text annotations\n")
cat("✓ Plot saved: plots/participant_tendency_publication_ready.png\n")
cat("✓ Plot saved: plots/participant_rejection_publication_ready.png\n")
cat("✓ Thumbnail saved: plots/participant_tendency_thumbnail.png\n")
cat("✓ Thumbnail saved: plots/participant_rejection_thumbnail.png\n")
