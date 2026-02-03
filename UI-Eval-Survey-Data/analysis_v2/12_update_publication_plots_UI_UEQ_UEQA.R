# Update Publication Plots with UI, UEQ, UEEQ-P Naming and Consistent Colors
# Updated for final paper submission

library(tidyverse)
library(scales)

# Set working directory
# setwd("/Users/hgs52/Documents/Github/AI-UI-Ethics-Evaluations/UI-Eval-Survey-Data/analysis_v2")

# Define consistent color scheme
condition_colors <- c(
  "UI" = "#FF8888",      # RGB(255, 136, 136) - Light red/salmon
  "UEQ" = "#ABE2AB",     # RGB(171, 226, 171) - Light green  
  "UEEQ-P" = "#AE80FF"    # RGB(174, 128, 255) - Light purple
)

# Load the participant-level data
print("Loading participant data...")
participant_data_file <- "results/three_condition_interface_data.csv"
if (!file.exists(participant_data_file)) {
  stop("Participant data file not found!")
}

interface_data <- read_csv(participant_data_file, show_col_types = FALSE)

# Check data structure
print("Data structure:")
print(colnames(interface_data))
print(head(interface_data))

# Create condition mapping with new names
condition_mapping <- c(
  "RAW" = "UI",
  "UEQ" = "UEQ", 
  "UEQ+Autonomy" = "UEEQ-P"
)

# Apply condition mapping to interface data
interface_data <- interface_data %>%
  mutate(condition_new = condition_mapping[condition])

# Calculate participant-level summaries
participant_summary <- interface_data %>%
  mutate(rejection = ifelse(release == "Yes", "No", "Yes")) %>%  # Fix rejection logic
  group_by(PROLIFIC_PID, condition_new) %>%
  summarise(
    mean_tendency = mean(tendency, na.rm = TRUE),
    mean_rejection_rate = mean(rejection == "Yes", na.rm = TRUE),
    .groups = 'drop'
  )

print("Participant summary created:")
print(head(participant_summary))

# Load ANOVA results for significance annotations
anova_results <- read_csv("results/three_condition_anova_results.csv", show_col_types = FALSE)
print("ANOVA results:")
print(anova_results)

# Calculate means and stats for annotations
condition_stats <- participant_summary %>%
  group_by(condition_new) %>%
  summarise(
    mean_tendency = mean(mean_tendency, na.rm = TRUE),
    sd_tendency = sd(mean_tendency, na.rm = TRUE),
    mean_rejection = mean(mean_rejection_rate, na.rm = TRUE),
    sd_rejection = sd(mean_rejection_rate, na.rm = TRUE),
    median_tendency = median(mean_tendency, na.rm = TRUE),
    median_rejection = median(mean_rejection_rate, na.rm = TRUE),
    n = n(),
    .groups = 'drop'
  )

print("Condition statistics:")
print(condition_stats)

# Create factor with correct order
participant_summary$condition_new <- factor(participant_summary$condition_new, 
                                          levels = c("UI", "UEQ", "UEEQ-P"))

# 1. PARTICIPANT TENDENCY PUBLICATION READY PLOT
print("Creating participant tendency publication plot...")

p_tendency <- ggplot(participant_summary, aes(x = condition_new, y = mean_tendency, fill = condition_new)) +
  geom_violin(alpha = 0.6, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.shape = NA) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3, fill = "white", stroke = 1.5) +
  stat_summary(fun = median, geom = "point", shape = 3, size = 2, color = "black") +
  scale_fill_manual(values = condition_colors) +
  scale_y_continuous(limits = c(1, 7), breaks = 1:7) +
  labs(
    title = "Release Tendency by Evaluation Condition",
    subtitle = "Participant-Level Analysis (N=141)",
    x = "Evaluation Condition",
    y = "Release Tendency\n(1 = Definitely would not release, 7 = Definitely would release)",
    caption = "F(2,138) = 16.61, p < 0.001, η² = 0.19\nAll pairwise comparisons significant (Tukey HSD, all p < 0.001)\n◇ = Mean, + = Median"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(size = 12, hjust = 0.5),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 11),
    legend.position = "none",
    panel.grid.minor = element_blank(),
    plot.caption = element_text(size = 9, hjust = 0.5, color = "gray40")
  )

# Add significance brackets
p_tendency <- p_tendency +
  annotate("segment", x = 1, xend = 2, y = 6.5, yend = 6.5, color = "black") +
  annotate("text", x = 1.5, y = 6.6, label = "***", size = 4, hjust = 0.5) +
  annotate("segment", x = 2, xend = 3, y = 6.7, yend = 6.7, color = "black") +
  annotate("text", x = 2.5, y = 6.8, label = "***", size = 4, hjust = 0.5) +
  annotate("segment", x = 1, xend = 3, y = 6.9, yend = 6.9, color = "black") +
  annotate("text", x = 2, y = 7.0, label = "***", size = 4, hjust = 0.5)

# Add mean/median text annotations
means_text <- condition_stats %>%
  mutate(
    label = sprintf("M=%.2f\nMd=%.2f", mean_tendency, median_tendency),
    y_pos = 1.5
  )

for(i in 1:nrow(means_text)) {
  p_tendency <- p_tendency +
    annotate("text", x = i, y = means_text$y_pos[i], 
             label = means_text$label[i], size = 3, hjust = 0.5, color = "gray30")
}

ggsave("plots/participant_tendency_publication_ready.png", p_tendency, 
       width = 10, height = 8, dpi = 300, bg = "white")

# 2. PARTICIPANT REJECTION PUBLICATION READY PLOT
print("Creating participant rejection publication plot...")

p_rejection <- ggplot(participant_summary, aes(x = condition_new, y = mean_rejection_rate, fill = condition_new)) +
  geom_violin(alpha = 0.6, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.shape = NA) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3, fill = "white", stroke = 1.5) +
  stat_summary(fun = median, geom = "point", shape = 3, size = 2, color = "black") +
  scale_fill_manual(values = condition_colors) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2), labels = percent_format()) +
  labs(
    title = "Rejection Rate by Evaluation Condition",
    subtitle = "Participant-Level Analysis (N=141)",
    x = "Evaluation Condition",
    y = "Interface Rejection Rate\n(Proportion of interfaces rejected)",
    caption = "F(2,138) = 15.97, p < 0.001, η² = 0.19\nAll pairwise comparisons significant (Tukey HSD, all p < 0.001)\n◇ = Mean, + = Median"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(size = 12, hjust = 0.5),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 11),
    legend.position = "none",
    panel.grid.minor = element_blank(),
    plot.caption = element_text(size = 9, hjust = 0.5, color = "gray40")
  )

# Add significance brackets
p_rejection <- p_rejection +
  annotate("segment", x = 1, xend = 2, y = 0.85, yend = 0.85, color = "black") +
  annotate("text", x = 1.5, y = 0.87, label = "***", size = 4, hjust = 0.5) +
  annotate("segment", x = 2, xend = 3, y = 0.90, yend = 0.90, color = "black") +
  annotate("text", x = 2.5, y = 0.92, label = "***", size = 4, hjust = 0.5) +
  annotate("segment", x = 1, xend = 3, y = 0.95, yend = 0.95, color = "black") +
  annotate("text", x = 2, y = 0.97, label = "***", size = 4, hjust = 0.5)

# Add mean/median text annotations for rejection
means_text_rej <- condition_stats %>%
  mutate(
    label = sprintf("M=%.1f%%\nMd=%.1f%%", mean_rejection*100, median_rejection*100),
    y_pos = 0.1
  )

for(i in 1:nrow(means_text_rej)) {
  p_rejection <- p_rejection +
    annotate("text", x = i, y = means_text_rej$y_pos[i], 
             label = means_text_rej$label[i], size = 3, hjust = 0.5, color = "gray30")
}

ggsave("plots/participant_rejection_publication_ready.png", p_rejection, 
       width = 10, height = 8, dpi = 300, bg = "white")

# 3. THREE CONDITION TENDENCY VIOLIN FDR CORRECTED
print("Creating three condition tendency violin FDR plot using interface data...")

# Create interface-level summary from the main data
interface_summary_for_plot <- interface_data %>%
  group_by(interface, condition_new) %>%
  summarise(
    mean_tendency = mean(tendency, na.rm = TRUE),
    n_evaluations = n(),
    .groups = 'drop'
  )

# Create interface-level violin plot
p_interface_violin <- ggplot(interface_summary_for_plot, aes(x = condition_new, y = mean_tendency, fill = condition_new)) +
  geom_violin(alpha = 0.6, trim = FALSE) +
  geom_boxplot(width = 0.2, alpha = 0.8, outlier.shape = NA) +
  geom_point(alpha = 0.6, position = position_jitter(width = 0.1)) +
  scale_fill_manual(values = condition_colors) +
  scale_y_continuous(limits = c(1, 7), breaks = 1:7) +
  labs(
    title = "Release Tendency by Interface and Condition",
    subtitle = "Interface-Level Analysis with FDR Correction",
    x = "Evaluation Condition",
    y = "Mean Release Tendency\n(1 = Definitely would not release, 7 = Definitely would release)",
    caption = "Individual interface means across conditions\nFDR-corrected for multiple comparisons"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(size = 12, hjust = 0.5),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 11),
    legend.position = "none",
    panel.grid.minor = element_blank(),
    plot.caption = element_text(size = 9, hjust = 0.5, color = "gray40")
  )

ggsave("plots/three_condition_tendency_violin_fdr_corrected.png", p_interface_violin, 
       width = 10, height = 8, dpi = 300, bg = "white")

# 4. INTERFACE REJECTION TRENDS SORTED
print("Creating interface rejection trends sorted plot...")

# Calculate interface rejection rates by condition
interface_rejection_trends <- interface_data %>%
  mutate(rejection = ifelse(release == "Yes", "No", "Yes")) %>%  # Fix rejection logic
  group_by(interface, condition_new) %>%
  summarise(
    rejection_rate = mean(rejection == "Yes", na.rm = TRUE),
    n_evaluations = n(),
    .groups = 'drop'
  ) %>%
  pivot_wider(names_from = condition_new, values_from = rejection_rate, names_prefix = "rejection_") %>%
  mutate(
    overall_rejection = rowMeans(select(., starts_with("rejection_")), na.rm = TRUE)
  ) %>%
  arrange(desc(overall_rejection)) %>%
  mutate(interface_ordered = factor(interface, levels = unique(interface)))

# Convert back to long format for plotting
interface_trends_long <- interface_rejection_trends %>%
  select(interface, interface_ordered, rejection_UI, rejection_UEQ, `rejection_UEEQ-P`) %>%
  pivot_longer(cols = starts_with("rejection_"), 
               names_to = "condition", 
               values_to = "rejection_rate",
               names_prefix = "rejection_") %>%
  mutate(condition = factor(condition, levels = c("UI", "UEQ", "UEEQ-P")))

p_trends <- ggplot(interface_trends_long, aes(x = interface_ordered, y = rejection_rate, 
                                             color = condition, group = condition)) +
  geom_line(size = 1.2, alpha = 0.8) +
  geom_point(size = 2.5, alpha = 0.9) +
  scale_color_manual(values = condition_colors, name = "Evaluation\nCondition") +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2), labels = percent_format()) +
  labs(
    title = "Interface Rejection Rates by Condition",
    subtitle = "Interfaces sorted by overall rejection rate (highest to lowest)",
    x = "Interface (sorted by rejection rate)",
    y = "Rejection Rate",
    caption = "Each point represents the proportion of participants who rejected the interface in that condition"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(size = 12, hjust = 0.5),
    axis.title = element_text(size = 12),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    axis.text.y = element_text(size = 11),
    legend.position = "right",
    legend.title = element_text(size = 11),
    legend.text = element_text(size = 10),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(size = 9, hjust = 0.5, color = "gray40")
  )

ggsave("plots/interface_rejection_trends_sorted.png", p_trends, 
       width = 12, height = 8, dpi = 300, bg = "white")

print("All publication plots updated successfully with UI, UEQ, UEEQ-P naming!")
print("Updated plots:")
print("- plots/participant_tendency_publication_ready.png")
print("- plots/participant_rejection_publication_ready.png") 
print("- plots/three_condition_tendency_violin_fdr_corrected.png")
print("- plots/interface_rejection_trends_sorted.png")
