# Interface-Level Comparison Analysis with Statistical Testing
# Using ggstatsplot directly for significance testing

# Load required packages
library(dplyr)
library(ggplot2)
library(ggstatsplot)

# Load the interface-level data
interface_data <- read.csv("results/interface_plot_data_updated.csv")

# Create interface summaries
interface_summary <- interface_data %>%
  group_by(interface_num, condition_f) %>%
  summarise(
    n_evaluations = n(),
    mean_rejection = mean(rejection_pct),
    sd_rejection = sd(rejection_pct),
    mean_tendency = mean(tendency),
    sd_tendency = sd(tendency),
    .groups = 'drop'
  ) %>%
  arrange(interface_num)

# Print interface summary
cat("=== INTERFACE-LEVEL SUMMARY ===\n")
print(interface_summary)

# ===== MAIN INTERFACE REJECTION TRENDS PLOT =====
cat("\n=== CREATING INTERFACE REJECTION TRENDS WITH SIGNIFICANCE TESTING ===\n")

# Prepare data for plotting
interface_rejection_data <- interface_data %>%
  select(interface_num, condition_f, rejection_pct) %>%
  mutate(
    interface_f = factor(interface_num, levels = 1:15, labels = paste0("UI", 1:15))
  )

# Create the main interface rejection trends plot with statistical testing
p_interface_rejection <- ggbetweenstats(
  data = interface_rejection_data,
  x = interface_f,
  y = rejection_pct,
  plot.type = "box",
  type = "parametric",
  var.equal = FALSE,
  pairwise.display = "significant",
  p.adjust.method = "holm",
  centrality.plotting = TRUE,
  bf.message = FALSE,
  results.subtitle = TRUE,
  xlab = "Interface",
  ylab = "Rejection Rate (%)",
  title = "Interface Rejection Rates: UEQ vs UEQ+Autonomy",
  subtitle = "Statistical significance testing between evaluation frameworks",
  caption = "Asterisks (*) indicate significant differences between UEQ and UEQ+Autonomy conditions"
) +
  theme_ggstatsplot() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12),
    legend.position = "bottom"
  )

# Save the interface rejection trends plot
ggsave("plots/interface_rejection_trends_updated_with_stats.png", 
       plot = p_interface_rejection, 
       width = 18, height = 12, dpi = 300)

cat("✓ Interface rejection trends with statistics saved to plots/interface_rejection_trends_updated_with_stats.png\n")

# ===== INTERFACE TENDENCY TRENDS PLOT =====
cat("\n=== CREATING INTERFACE TENDENCY TRENDS WITH SIGNIFICANCE TESTING ===\n")

interface_tendency_data <- interface_data %>%
  select(interface_num, condition_f, tendency) %>%
  mutate(
    interface_f = factor(interface_num, levels = 1:15, labels = paste0("UI", 1:15))
  )

p_interface_tendency <- ggbetweenstats(
  data = interface_tendency_data,
  x = interface_f,
  y = tendency,
  plot.type = "box",
  type = "parametric",
  var.equal = FALSE,
  pairwise.display = "significant",
  p.adjust.method = "holm",
  centrality.plotting = TRUE,
  bf.message = FALSE,
  results.subtitle = TRUE,
  xlab = "Interface",
  ylab = "Release Tendency Score (1-7)",
  title = "Interface Tendency Scores: UEQ vs UEQ+Autonomy",
  subtitle = "Statistical significance testing between evaluation frameworks",
  caption = "Asterisks (*) indicate significant differences between UEQ and UEQ+Autonomy conditions"
) +
  theme_ggstatsplot() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12),
    legend.position = "bottom"
  )

# Save the interface tendency trends plot
ggsave("plots/interface_tendency_trends_updated_with_stats.png", 
       plot = p_interface_tendency, 
       width = 18, height = 12, dpi = 300)

cat("✓ Interface tendency trends with statistics saved to plots/interface_tendency_trends_updated_with_stats.png\n")

# ===== INDIVIDUAL INTERFACE ANALYSIS =====
cat("\n=== ANALYZING INDIVIDUAL INTERFACES ===\n")

# Calculate which interfaces have sufficient data for analysis
interfaces_with_data <- interface_data %>%
  group_by(interface_num) %>%
  summarise(
    total_n = n(),
    n_conditions = length(unique(condition_f)),
    .groups = 'drop'
  ) %>%
  filter(total_n >= 8 & n_conditions == 2) %>%
  arrange(interface_num)

cat("Interfaces with sufficient data for comparison (n >= 8, both conditions):\n")
print(interfaces_with_data)

# Create summary statistics for significant interfaces
significant_interfaces <- c()

# Function to test individual interface significance
test_interface_significance <- function(ui_num) {
  ui_data <- interface_data %>%
    filter(interface_num == ui_num)
  
  if(nrow(ui_data) >= 8 && length(unique(ui_data$condition_f)) == 2) {
    # Test rejection rates
    t_test_rej <- t.test(rejection_pct ~ condition_f, data = ui_data)
    # Test tendency scores  
    t_test_tend <- t.test(tendency ~ condition_f, data = ui_data)
    
    # Calculate effect sizes (Cohen's d)
    ueu_rej <- ui_data$rejection_pct[ui_data$condition_f == "UEQ"]
    uea_rej <- ui_data$rejection_pct[ui_data$condition_f == "UEQ+Autonomy"]
    
    pooled_sd_rej <- sqrt(((length(ueu_rej)-1)*var(ueu_rej) + (length(uea_rej)-1)*var(uea_rej)) / 
                          (length(ueu_rej) + length(uea_rej) - 2))
    cohens_d_rej <- (mean(uea_rej) - mean(ueu_rej)) / pooled_sd_rej
    
    ueu_tend <- ui_data$tendency[ui_data$condition_f == "UEQ"]
    uea_tend <- ui_data$tendency[ui_data$condition_f == "UEQ+Autonomy"]
    
    pooled_sd_tend <- sqrt(((length(ueu_tend)-1)*var(ueu_tend) + (length(uea_tend)-1)*var(uea_tend)) / 
                           (length(ueu_tend) + length(uea_tend) - 2))
    cohens_d_tend <- (mean(uea_tend) - mean(ueu_tend)) / pooled_sd_tend
    
    return(data.frame(
      interface = ui_num,
      n_total = nrow(ui_data),
      rejection_p = t_test_rej$p.value,
      rejection_d = cohens_d_rej,
      tendency_p = t_test_tend$p.value,
      tendency_d = cohens_d_tend,
      significant_rejection = t_test_rej$p.value < 0.05,
      significant_tendency = t_test_tend$p.value < 0.05
    ))
  } else {
    return(NULL)
  }
}

# Test all interfaces with sufficient data
interface_test_results <- do.call(rbind, lapply(interfaces_with_data$interface_num, test_interface_significance))

cat("\n=== INDIVIDUAL INTERFACE STATISTICAL RESULTS ===\n")
print(interface_test_results)

# Identify significant interfaces
significant_interfaces <- interface_test_results %>%
  filter(significant_rejection | significant_tendency) %>%
  pull(interface)

if(length(significant_interfaces) > 0) {
  cat("\nInterfaces with significant differences:", paste(significant_interfaces, collapse = ", "), "\n")
} else {
  cat("\nNo individual interfaces show significant differences between UEQ and UEQ+Autonomy\n")
}

# Save detailed results
write.csv(interface_test_results, "results/interface_statistical_tests.csv", row.names = FALSE)

# ===== SUMMARY REPORT =====
cat("\n=== INTERFACE ANALYSIS SUMMARY ===\n")
cat("Total interfaces analyzed:", nrow(interfaces_with_data), "\n")
cat("Interfaces with significant rejection differences:", sum(interface_test_results$significant_rejection, na.rm = TRUE), "\n")
cat("Interfaces with significant tendency differences:", sum(interface_test_results$significant_tendency, na.rm = TRUE), "\n")

# Calculate overall interface-level effect
overall_interface_effect <- interface_data %>%
  group_by(interface_num) %>%
  summarise(
    mean_rejection_diff = mean(rejection_pct[condition_f == "UEQ+Autonomy"]) - mean(rejection_pct[condition_f == "UEQ"]),
    mean_tendency_diff = mean(tendency[condition_f == "UEQ+Autonomy"]) - mean(tendency[condition_f == "UEQ"]),
    .groups = 'drop'
  )

cat("\nOverall interface-level effects:\n")
cat("Mean rejection difference (UEQ+Autonomy - UEQ):", round(mean(overall_interface_effect$mean_rejection_diff, na.rm = TRUE), 2), "%\n")
cat("Mean tendency difference (UEQ+Autonomy - UEQ):", round(mean(overall_interface_effect$mean_tendency_diff, na.rm = TRUE), 2), "points\n")

cat("\n=== FILES CREATED ===\n")
cat("• plots/interface_rejection_trends_updated_with_stats.png - Main rejection trends with significance\n")
cat("• plots/interface_tendency_trends_updated_with_stats.png - Main tendency trends with significance\n")
cat("• results/interface_statistical_tests.csv - Individual interface test results\n")
cat("\n=== ANALYSIS COMPLETE ===\n")
