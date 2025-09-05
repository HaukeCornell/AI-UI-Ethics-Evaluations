# Interface Rejection Trends by Condition (Sorted by Overall Rejection Rate)
# Line plot with error bars, pattern names as x-axis labels
# UPDATED: UI/UEQ/UEQ-A naming with consistent colors

library(dplyr)
library(ggplot2)
library(tidyr)

cat("=== CREATING INTERFACE REJECTION TRENDS LINE PLOT (SORTED) ===\n")

# Pattern names for each interface
pattern_names <- c(
  "Bad Defaults", "Content Customization", "Endlessness", "Expectation Result Mismatch",
  "False Hierarchy", "Forced Access", "Gamification", "Hindering Account Deletion",
  "Nagging", "Overcomplicated Process", "Pull to Refresh", "Social Connector",
  "Social Pressure", "Toying with Emotion", "Trick Wording"
)

# Load data
data <- read.csv("results/three_condition_interface_data.csv")
data$rejection <- 1 - data$release_binary

# Update condition names
data$condition_new <- case_when(
  data$condition == "RAW" ~ "UI",
  data$condition == "UEQ" ~ "UEQ", 
  data$condition == "UEQ+Autonomy" ~ "UEQ-A",
  TRUE ~ data$condition
)

# Calculate mean rejection rate and SE per interface × condition
summary_df <- data %>%
  group_by(interface, condition_new) %>%
  summarise(
    mean_rejection = mean(rejection),
    se_rejection = sd(rejection) / sqrt(n()),
    .groups = "drop"
  )

# Add pattern names
summary_df$pattern_name <- pattern_names[as.integer(gsub("ui", "", summary_df$interface))]

# Calculate overall mean rejection per interface (across all conditions)
overall_order <- summary_df %>%
  group_by(interface, pattern_name) %>%
  summarise(overall_mean = mean(mean_rejection), .groups = "drop") %>%
  arrange(overall_mean)

# Set factor levels for ordered plotting
summary_df$pattern_name <- factor(summary_df$pattern_name, levels = overall_order$pattern_name)
summary_df$condition_new <- factor(summary_df$condition_new, levels = c("UI", "UEQ", "UEQ-A"))

# Plot with new color scheme
p <- ggplot(summary_df, aes(x = pattern_name, y = mean_rejection * 100, group = condition_new, color = condition_new)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  geom_errorbar(aes(ymin = (mean_rejection - se_rejection) * 100, ymax = (mean_rejection + se_rejection) * 100),
                width = 0.2, linewidth = 0.7) +
  scale_color_manual(values = c("UI" = "#FF8888", "UEQ" = "#ABE2AB", "UEQ-A" = "#AE80FF"),
                     name = "Condition") +
  labs(
    title = "Rejection Rates by Interface and Condition (Sorted)",
    subtitle = "Ordered by overall mean rejection rate (lowest to highest)",
    x = "Pattern Name",
    y = "Rejection Rate (%)"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 40, hjust = 1, size = 10, face = "bold"),
    axis.title.x = element_text(size = 12, face = "bold"),
    axis.title.y = element_text(size = 12, face = "bold"),
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5),
    legend.position = "top"
  )

# Save
if(!dir.exists("plots")) dir.create("plots")
ggsave("plots/interface_rejection_trends_sorted.png", p, width = 14, height = 7, dpi = 300)

cat("✓ Plot saved: plots/interface_rejection_trends_sorted.png\n")
