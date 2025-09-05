# Enhanced Participant-Level Analysis Plots with UI/UEQ/UEQ-A naming
# Improved readability for means/medians and added jitter points

library(dplyr)
library(ggplot2)
library(scales)

cat("=== CREATING ENHANCED PARTICIPANT-LEVEL PLOTS ===\n")

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

# Enhanced Tendency Plot
cat("Creating enhanced participant tendency plot...\n")

p_tendency <- ggplot(participant_data, aes(x = condition_new, y = mean_tendency, fill = condition_new)) +
  geom_violin(alpha = 0.6, trim = FALSE, width = 0.8) +
  geom_jitter(width = 0.2, alpha = 0.6, size = 1.5, color = "black") +
  # Larger, more visible mean
  stat_summary(fun = mean, geom = "point", shape = 18, size = 6, color = "white", stroke = 1.5) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 5, color = "black") +
  # Larger, more visible median  
  stat_summary(fun = median, geom = "point", shape = 95, size = 8, color = "white", stroke = 2) +
  stat_summary(fun = median, geom = "point", shape = 95, size = 7, color = "red") +
  scale_fill_manual(values = condition_colors, name = "Condition") +
  labs(
    title = "Release Tendency by Evaluation Condition",
    subtitle = "Participant-level means across all interface evaluations",
    x = "Evaluation Condition",
    y = "Mean Release Tendency (1-7 scale)",
    caption = "♦ = Mean (black diamond) • ▬ = Median (red line) • Points = Individual participants"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray50"),
    plot.caption = element_text(size = 11, hjust = 0.5, color = "gray50"),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text = element_text(size = 12),
    axis.text.x = element_text(size = 13, face = "bold"),
    legend.position = "none",
    panel.grid.minor.y = element_blank(),
    panel.grid.major.x = element_blank()
  ) +
  scale_y_continuous(limits = c(1, 7), breaks = 1:7)

# Enhanced Rejection Plot  
cat("Creating enhanced participant rejection plot...\n")

p_rejection <- ggplot(participant_data, aes(x = condition_new, y = mean_rejection_rate * 100, fill = condition_new)) +
  geom_violin(alpha = 0.6, trim = FALSE, width = 0.8) +
  geom_jitter(width = 0.2, alpha = 0.6, size = 1.5, color = "black") +
  # Larger, more visible mean
  stat_summary(fun = mean, geom = "point", shape = 18, size = 6, color = "white", stroke = 1.5) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 5, color = "black") +
  # Larger, more visible median
  stat_summary(fun = median, geom = "point", shape = 95, size = 8, color = "white", stroke = 2) +
  stat_summary(fun = median, geom = "point", shape = 95, size = 7, color = "red") +
  scale_fill_manual(values = condition_colors, name = "Condition") +
  labs(
    title = "Rejection Rate by Evaluation Condition", 
    subtitle = "Participant-level rejection rates across all interface evaluations",
    x = "Evaluation Condition",
    y = "Mean Rejection Rate (%)",
    caption = "♦ = Mean (black diamond) • ▬ = Median (red line) • Points = Individual participants"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray50"), 
    plot.caption = element_text(size = 11, hjust = 0.5, color = "gray50"),
    axis.title = element_text(size = 13, face = "bold"),
    axis.text = element_text(size = 12),
    axis.text.x = element_text(size = 13, face = "bold"),
    legend.position = "none",
    panel.grid.minor.y = element_blank(),
    panel.grid.major.x = element_blank()
  ) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 20))

# Save enhanced plots
if(!dir.exists("plots")) dir.create("plots")

ggsave("plots/participant_tendency_publication_ready.png", p_tendency, 
       width = 10, height = 8, dpi = 300)

ggsave("plots/participant_rejection_publication_ready.png", p_rejection, 
       width = 10, height = 8, dpi = 300)

cat("✓ Enhanced participant plots saved with larger, more readable mean/median indicators\n")
cat("✓ Plot saved: plots/participant_tendency_publication_ready.png\n")
cat("✓ Plot saved: plots/participant_rejection_publication_ready.png\n")
