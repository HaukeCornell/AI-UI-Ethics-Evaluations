# Create visualizations for UEQ vs UEEQ analysis
library(ggplot2)
library(dplyr)
library(readr)
library(tidyr)

# Load the processed data
data_raw <- read_tsv("survey_data_utf8.tsv", show_col_types = FALSE)
data_clean <- data_raw[-c(1:2), ]

# Recreate the long format data (simplified version)
interfaces <- 1:15
data_long <- data.frame()

for (i in interfaces) {
  ueq_tendency_col <- paste0(i, "_UEQ Tendency_1")
  ueq_release_col <- paste0(i, "_UEQ Release")
  ueeq_tendency_col <- paste0(i, "_UEEQ Tendency_1")
  ueeq_release_col <- paste0(i, "_UEEQ Release")
  
  if (all(c(ueq_tendency_col, ueq_release_col) %in% names(data_clean))) {
    ueq_data <- data.frame(
      participant_id = data_clean$ResponseId,
      interface = i,
      metric_type = "UEQ",
      tendency = as.numeric(data_clean[[ueq_tendency_col]]),
      release = data_clean[[ueq_release_col]],
      stringsAsFactors = FALSE
    )
    
    ueeq_data <- data.frame(
      participant_id = data_clean$ResponseId,
      interface = i,
      metric_type = "UEEQ",
      tendency = as.numeric(data_clean[[ueeq_tendency_col]]),
      release = data_clean[[ueeq_release_col]],
      stringsAsFactors = FALSE
    )
    
    interface_data <- rbind(ueq_data, ueeq_data)
    data_long <- rbind(data_long, interface_data)
  }
}

data_long <- data_long %>%
  mutate(
    release_binary = case_when(
      release == "Yes" ~ 1,
      release == "No" ~ 0,
      TRUE ~ NA_real_
    ),
    rejection = 1 - release_binary,
    interface = as.factor(interface),
    metric_type = as.factor(metric_type),
    participant_id = as.factor(participant_id)
  ) %>%
  filter(!is.na(tendency), !is.na(release_binary))

# Visualization 1: Overall rejection rates
p1 <- data_long %>%
  group_by(metric_type) %>%
  summarise(
    rejection_rate = mean(rejection, na.rm = TRUE),
    se = sqrt(rejection_rate * (1 - rejection_rate) / n()),
    .groups = 'drop'
  ) %>%
  ggplot(aes(x = metric_type, y = rejection_rate, fill = metric_type)) +
  geom_col(alpha = 0.7, width = 0.6) +
  geom_errorbar(aes(ymin = rejection_rate - 1.96*se, 
                    ymax = rejection_rate + 1.96*se), 
                width = 0.1) +
  scale_y_continuous(labels = scales::percent_format(), limits = c(0, 0.7)) +
  scale_fill_manual(values = c("UEQ" = "#3498db", "UEEQ" = "#e74c3c")) +
  labs(title = "Interface Rejection Rates by Metric Type",
       subtitle = "Error bars show 95% confidence intervals\nNo significant difference (p = 0.202)",
       x = "Metric Type",
       y = "Rejection Rate",
       caption = "UEQ: Standard metrics, UEEQ: Ethics-enhanced metrics") +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 11)
  )

# Visualization 2: Tendency scores distribution
p2 <- ggplot(data_long, aes(x = metric_type, y = tendency, fill = metric_type)) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.3) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 3, 
               fill = "white", color = "black") +
  scale_fill_manual(values = c("UEQ" = "#3498db", "UEEQ" = "#e74c3c")) +
  labs(title = "Distribution of Tendency Scores by Metric Type",
       subtitle = "Diamond shows mean, no significant difference (p = 0.197)",
       x = "Metric Type",
       y = "Tendency Score",
       caption = "Higher scores indicate more positive evaluation tendency") +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 11)
  )

# Visualization 3: Interface-level comparison
interface_summary <- data_long %>%
  group_by(interface, metric_type) %>%
  summarise(
    n_responses = n(),
    rejection_rate = mean(rejection, na.rm = TRUE),
    tendency_mean = mean(tendency, na.rm = TRUE),
    .groups = 'drop'
  )

p3 <- interface_summary %>%
  ggplot(aes(x = interface, y = rejection_rate, color = metric_type, group = metric_type)) +
  geom_line(linewidth = 1.2, alpha = 0.8) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = scales::percent_format()) +
  scale_color_manual(values = c("UEQ" = "#3498db", "UEEQ" = "#e74c3c")) +
  labs(title = "Rejection Rates by Interface and Metric Type",
       subtitle = "Each point represents one interface evaluated with different metrics",
       x = "Interface Number",
       y = "Rejection Rate",
       color = "Metric Type") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 11),
    legend.position = "bottom"
  )

# Visualization 4: Difference plot (UEEQ - UEQ) by interface
difference_data <- interface_summary %>%
  select(interface, metric_type, rejection_rate, tendency_mean) %>%
  pivot_wider(names_from = metric_type, values_from = c(rejection_rate, tendency_mean)) %>%
  mutate(
    rejection_diff = rejection_rate_UEEQ - rejection_rate_UEQ,
    tendency_diff = tendency_mean_UEEQ - tendency_mean_UEQ
  )

p4 <- difference_data %>%
  ggplot(aes(x = interface, y = rejection_diff)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_col(aes(fill = rejection_diff > 0), alpha = 0.7) +
  scale_fill_manual(values = c("TRUE" = "#e74c3c", "FALSE" = "#3498db"),
                    labels = c("UEQ Higher", "UEEQ Higher")) +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(title = "Rejection Rate Differences by Interface (UEEQ - UEQ)",
       subtitle = "Positive values = UEEQ had higher rejection rate",
       x = "Interface Number",
       y = "Difference in Rejection Rate",
       fill = "Direction") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 11),
    legend.position = "bottom"
  )

# Save all plots
ggsave("rejection_rates_comparison.png", p1, width = 8, height = 6, dpi = 300)
ggsave("tendency_distribution.png", p2, width = 8, height = 6, dpi = 300)
ggsave("interface_rejection_trends.png", p3, width = 10, height = 6, dpi = 300)
ggsave("rejection_differences_by_interface.png", p4, width = 10, height = 6, dpi = 300)

cat("Visualizations saved:\n")
cat("1. rejection_rates_comparison.png - Overall comparison\n")
cat("2. tendency_distribution.png - Distribution comparison\n") 
cat("3. interface_rejection_trends.png - Interface-level trends\n")
cat("4. rejection_differences_by_interface.png - Differences by interface\n")

# Print some key statistics for the summary
cat("\nKey statistics:\n")
cat("Overall rejection rates:\n")
print(data_long %>% 
  group_by(metric_type) %>% 
  summarise(rejection_rate = mean(rejection, na.rm = TRUE), .groups = 'drop'))

cat("\nLargest differences by interface:\n")
print(difference_data %>% 
  arrange(desc(abs(rejection_diff))) %>% 
  select(interface, rejection_diff) %>% 
  head(5))
