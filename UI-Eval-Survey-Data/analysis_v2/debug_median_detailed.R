# Test boxplot median vs calculated median
library(dplyr)
library(ggplot2)

# Load and prepare data exactly as in main script
interface_data <- read.csv("results/three_condition_interface_data.csv")

interface_data$condition_new <- case_when(
  interface_data$condition == "RAW" ~ "UI",
  interface_data$condition == "UEQ" ~ "UEQ", 
  interface_data$condition == "UEQ+Autonomy" ~ "UEQ-A",
  TRUE ~ interface_data$condition
)

interface_data$condition_new <- factor(interface_data$condition_new, levels = c("UI", "UEQ", "UEQ-A"))
interface_data <- interface_data[!is.na(interface_data$tendency), ]

# Calculate stats for verification
stats_for_plot <- interface_data %>%
  group_by(condition_new) %>%
  summarise(
    mean_val = mean(tendency, na.rm = TRUE),
    median_val = median(tendency, na.rm = TRUE),
    .groups = "drop"
  )

cat("=== STATS FOR PLOT ===\n")
print(stats_for_plot)

# Create a simple test plot to see what ggplot thinks the medians are
test_plot <- ggplot(interface_data, aes(x = condition_new, y = tendency)) +
  geom_boxplot() +
  stat_summary(fun = median, geom = "point", shape = 95, size = 10, color = "red") +
  geom_text(data = stats_for_plot, 
            aes(x = condition_new, y = 1, 
                label = paste0("Calc Median: ", median_val)), 
            color = "blue", size = 3, inherit.aes = FALSE) +
  labs(title = "Boxplot vs Calculated Median Comparison",
       subtitle = "Red lines = ggplot boxplot medians, Blue text = calculated medians")

ggsave("debug_median_comparison.png", test_plot, width = 10, height = 6, dpi = 300)

cat("\n=== CHECKING FOR Y-AXIS SCALING ISSUES ===\n")
# Check if the y-axis limits might be affecting the visualization
interface_data_filtered <- interface_data[interface_data$tendency >= 1 & interface_data$tendency <= 7, ]

cat("Original data size:", nrow(interface_data), "\n")
cat("Filtered data size (1-7 range):", nrow(interface_data_filtered), "\n")

filtered_stats <- interface_data_filtered %>%
  group_by(condition_new) %>%
  summarise(
    mean_val = mean(tendency, na.rm = TRUE),
    median_val = median(tendency, na.rm = TRUE),
    .groups = "drop"
  )

cat("\n=== FILTERED STATS (1-7 range only) ===\n")
print(filtered_stats)

cat("\n=== UEQ-A DETAILED COMPARISON ===\n")
ueqa_all <- interface_data$tendency[interface_data$condition_new == "UEQ-A"]
ueqa_filtered <- interface_data_filtered$tendency[interface_data_filtered$condition_new == "UEQ-A"]

cat("UEQ-A median (all data):", median(ueqa_all), "\n")
cat("UEQ-A median (1-7 filtered):", median(ueqa_filtered), "\n")
cat("UEQ-A count (all data):", length(ueqa_all), "\n")
cat("UEQ-A count (1-7 filtered):", length(ueqa_filtered), "\n")

# Check if there are 0 values that might affect things
cat("\n=== ZERO VALUES ANALYSIS ===\n")
zero_counts <- interface_data %>%
  group_by(condition_new) %>%
  summarise(
    total = n(),
    zeros = sum(tendency == 0),
    percent_zeros = (sum(tendency == 0) / n()) * 100
  )
print(zero_counts)
