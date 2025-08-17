# Interface-Level Comparison Analysis with Statistical Testing
# Using specialized functions from r_functionality.R

# Load required packages
library(dplyr)
library(ggplot2)
library(ggstatsplot)

# Source the specialized functions
source("scripts/r_functionality.R")

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

# Create interface labels for plotting
interface_labels <- paste0("UI", 1:15)
names(interface_labels) <- as.character(1:15)

# ===== REJECTION RATES BY INTERFACE =====

# Create comprehensive interface rejection comparison
cat("\n=== CREATING INTERFACE REJECTION COMPARISON WITH SIGNIFICANCE TESTING ===\n")

# Prepare data for between-stats comparison (UEQ vs UEQ+Autonomy for each interface)
interface_rejection_data <- interface_data %>%
  select(interface_num, condition_f, rejection_pct) %>%
  mutate(interface_f = factor(interface_num, levels = 1:15, labels = paste0("UI", 1:15)))

# Create comprehensive interface rejection trends plot
p_interface_rejection <- ggbetweenstatsWithPriorNormalityCheckAsterisk(
  data = interface_rejection_data,
  x = "interface_f", 
  y = "rejection_pct",
  ylab = "Rejection Rate (%)",
  xlabels = interface_labels,
  plotType = "boxviolin"
)

# Save the interface rejection trends plot
ggsave("plots/interface_rejection_trends_updated.png", 
       plot = p_interface_rejection, 
       width = 16, height = 10, dpi = 300)

cat("✓ Interface rejection trends saved to plots/interface_rejection_trends_updated.png\n")

# ===== TENDENCY SCORES BY INTERFACE =====

# Create interface tendency comparison
cat("\n=== CREATING INTERFACE TENDENCY COMPARISON WITH SIGNIFICANCE TESTING ===\n")

interface_tendency_data <- interface_data %>%
  select(interface_num, condition_f, tendency) %>%
  mutate(interface_f = factor(interface_num, levels = 1:15, labels = paste0("UI", 1:15)))

p_interface_tendency <- ggbetweenstatsWithPriorNormalityCheckAsterisk(
  data = interface_tendency_data,
  x = "interface_f", 
  y = "tendency",
  ylab = "Release Tendency Score (1-7)",
  xlabels = interface_labels,
  plotType = "boxviolin"
)

# Save the interface tendency trends plot
ggsave("plots/interface_tendency_trends_updated.png", 
       plot = p_interface_tendency, 
       width = 16, height = 10, dpi = 300)

cat("✓ Interface tendency trends saved to plots/interface_tendency_trends_updated.png\n")

# ===== CONDITION COMPARISON BY INTERFACE =====

# Create separate plots for each interface comparing UEQ vs UEQ+Autonomy
cat("\n=== CREATING INDIVIDUAL INTERFACE COMPARISONS ===\n")

# Function to create individual interface comparison
create_interface_comparison <- function(ui_num) {
  ui_data <- interface_data %>%
    filter(interface_num == ui_num) %>%
    select(condition_f, rejection_pct, tendency)
  
  if(nrow(ui_data) > 0) {
    # Rejection comparison for this interface
    p_rej <- ggbetweenstatsWithPriorNormalityCheckAsterisk(
      data = ui_data,
      x = "condition_f",
      y = "rejection_pct", 
      ylab = paste0("UI", ui_num, " Rejection Rate (%)"),
      xlabels = c("UEQ" = "UEQ", "UEQ+Autonomy" = "UEQ+Autonomy"),
      plotType = "boxviolin"
    )
    
    # Tendency comparison for this interface  
    p_tend <- ggbetweenstatsWithPriorNormalityCheckAsterisk(
      data = ui_data,
      x = "condition_f",
      y = "tendency",
      ylab = paste0("UI", ui_num, " Release Tendency (1-7)"),
      xlabels = c("UEQ" = "UEQ", "UEQ+Autonomy" = "UEQ+Autonomy"),
      plotType = "boxviolin"
    )
    
    # Save individual interface plots
    ggsave(paste0("plots/ui", sprintf("%02d", ui_num), "_rejection_comparison.png"), 
           plot = p_rej, width = 10, height = 8, dpi = 300)
    ggsave(paste0("plots/ui", sprintf("%02d", ui_num), "_tendency_comparison.png"), 
           plot = p_tend, width = 10, height = 8, dpi = 300)
    
    cat("✓ UI", ui_num, "comparisons saved\n")
  }
}

# Create comparisons for interfaces with sufficient data
interfaces_to_analyze <- interface_summary %>%
  group_by(interface_num) %>%
  summarise(total_n = sum(n_evaluations)) %>%
  filter(total_n >= 10) %>%  # Only analyze interfaces with sufficient data
  pull(interface_num)

cat("Analyzing interfaces with sufficient data:", paste(interfaces_to_analyze, collapse = ", "), "\n")

# Create individual interface comparisons
for(ui in interfaces_to_analyze) {
  create_interface_comparison(ui)
}

# ===== SUMMARY STATISTICS =====

# Calculate interface-level effect sizes
cat("\n=== INTERFACE-LEVEL EFFECT SIZES ===\n")

interface_effects <- interface_data %>%
  group_by(interface_num) %>%
  do({
    ui_data <- .
    if(length(unique(ui_data$condition_f)) == 2 && nrow(ui_data) >= 10) {
      ueu_rej <- ui_data$rejection_pct[ui_data$condition_f == "UEQ"]
      uea_rej <- ui_data$rejection_pct[ui_data$condition_f == "UEQ+Autonomy"]
      
      ueu_tend <- ui_data$tendency[ui_data$condition_f == "UEQ"]
      uea_tend <- ui_data$tendency[ui_data$condition_f == "UEQ+Autonomy"]
      
      # Calculate effect sizes (Cohen's d)
      if(length(ueu_rej) > 1 && length(uea_rej) > 1) {
        pooled_sd_rej <- sqrt(((length(ueu_rej)-1)*var(ueu_rej) + (length(uea_rej)-1)*var(uea_rej)) / 
                              (length(ueu_rej) + length(uea_rej) - 2))
        cohens_d_rej <- (mean(uea_rej) - mean(ueu_rej)) / pooled_sd_rej
        
        pooled_sd_tend <- sqrt(((length(ueu_tend)-1)*var(ueu_tend) + (length(uea_tend)-1)*var(uea_tend)) / 
                               (length(ueu_tend) + length(uea_tend) - 2))
        cohens_d_tend <- (mean(uea_tend) - mean(ueu_tend)) / pooled_sd_tend
        
        data.frame(
          cohens_d_rejection = cohens_d_rej,
          cohens_d_tendency = cohens_d_tend,
          n_ueu = length(ueu_rej),
          n_uea = length(uea_rej)
        )
      } else {
        data.frame(
          cohens_d_rejection = NA,
          cohens_d_tendency = NA,
          n_ueu = length(ueu_rej),
          n_uea = length(uea_rej)
        )
      }
    } else {
      data.frame(
        cohens_d_rejection = NA,
        cohens_d_tendency = NA,
        n_ueu = 0,
        n_uea = 0
      )
    }
  }) %>%
  ungroup() %>%
  filter(!is.na(cohens_d_rejection))

print(interface_effects)

# Create summary table
interface_analysis_summary <- interface_summary %>%
  left_join(interface_effects, by = "interface_num") %>%
  arrange(interface_num)

# Save summary table
write.csv(interface_analysis_summary, "results/interface_analysis_summary.csv", row.names = FALSE)

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Files created:\n")
cat("• plots/interface_rejection_trends_updated.png - Main interface comparison with significance\n")
cat("• plots/interface_tendency_trends_updated.png - Interface tendency comparison\n")
cat("• plots/ui##_rejection_comparison.png - Individual interface rejection comparisons\n") 
cat("• plots/ui##_tendency_comparison.png - Individual interface tendency comparisons\n")
cat("• results/interface_analysis_summary.csv - Complete interface summary with effect sizes\n")
