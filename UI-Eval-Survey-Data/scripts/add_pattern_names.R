# Extract UI Pattern Names and Update Charts
# Using the qualtrics_loop_merge_copy.tsv mapping

# Load required packages
library(dplyr)
library(ggplot2)
library(ggstatsplot)
library(patchwork)

# Create the UI pattern name mapping
ui_mapping <- data.frame(
  interface_num = 1:15,
  pattern_name = c(
    "bad defaults",
    "content customization", 
    "endlessness",
    "expectation result mismatch",
    "false hierarchy",
    "forced access",
    "gamification",
    "hindering account deletion",
    "nagging",
    "overcomplicated process",
    "pull to refresh",
    "social connector",
    "toying with emotion",
    "trick wording",
    "social pressure"
  ),
  pattern_short = c(
    "Bad Defaults",
    "Content Custom",
    "Endlessness", 
    "Expect. Mismatch",
    "False Hierarchy",
    "Forced Access",
    "Gamification",
    "Hinder Deletion",
    "Nagging",
    "Overcomplex",
    "Pull to Refresh",
    "Social Connect",
    "Toy w/ Emotion",
    "Trick Wording",
    "Social Pressure"
  )
)

cat("=== UI PATTERN MAPPING ===\n")
print(ui_mapping)

# Load the interface-level data
interface_data <- read.csv("results/interface_plot_data_updated.csv")

# Add pattern names to the data
interface_data_named <- interface_data %>%
  left_join(ui_mapping, by = "interface_num") %>%
  mutate(
    interface_label = paste0(interface_num, ": ", pattern_short)
  )

cat("\n=== CREATING CHARTS WITH PATTERN NAMES ===\n")

# Function to create individual interface comparison plots with pattern names
create_named_interface_plot <- function(ui_num, measure = "rejection") {
  ui_data <- interface_data_named %>%
    filter(interface_num == ui_num)
  
  if(nrow(ui_data) < 6) return(NULL)  # Skip interfaces with too little data
  
  pattern_name <- ui_mapping$pattern_short[ui_mapping$interface_num == ui_num]
  
  if(measure == "rejection") {
    # For rejection rates: convert to binary for statistical test
    ui_binary <- ui_data %>%
      mutate(rejected_binary = ifelse(rejection_pct > 0, 1, 0))
    
    # Chi-square or Fisher's exact test for binary data
    if(length(unique(ui_binary$condition_f)) == 2) {
      contingency_table <- table(ui_binary$condition_f, ui_binary$rejected_binary)
      
      if(all(contingency_table >= 5)) {
        test_result <- chisq.test(contingency_table)
        p_value <- test_result$p.value
        test_type <- "χ²"
      } else {
        test_result <- fisher.test(contingency_table)
        p_value <- test_result$p.value  
        test_type <- "Fisher"
      }
      
      # Create plot with pattern name
      p <- ggbetweenstats(
        data = ui_data,
        x = condition_f,
        y = rejection_pct,
        plot.type = "box",
        type = "nonparametric",
        centrality.plotting = TRUE,
        bf.message = FALSE,
        results.subtitle = FALSE,
        xlab = "",
        ylab = if(ui_num == 1) "Rejection Rate (%)" else "",
        title = pattern_name,
        subtitle = paste0(test_type, " p = ", round(p_value, 3))
      ) +
        theme_ggstatsplot() +
        theme(
          plot.title = element_text(size = 11, hjust = 0.5, face = "bold"),
          plot.subtitle = element_text(size = 9),
          axis.text.x = element_text(size = 8),
          legend.position = "none"
        ) +
        ylim(0, 100)
        
    } else {
      return(NULL)
    }
    
  } else if(measure == "tendency") {
    # For tendency scores: use t-test
    if(length(unique(ui_data$condition_f)) == 2) {
      p <- ggbetweenstats(
        data = ui_data,
        x = condition_f, 
        y = tendency,
        plot.type = "box",
        type = "parametric",
        centrality.plotting = TRUE,
        bf.message = FALSE,
        results.subtitle = TRUE,
        xlab = "",
        ylab = if(ui_num == 1) "Tendency Score (1-7)" else "",
        title = pattern_name
      ) +
        theme_ggstatsplot() +
        theme(
          plot.title = element_text(size = 11, hjust = 0.5, face = "bold"),
          plot.subtitle = element_text(size = 9),
          axis.text.x = element_text(size = 8),
          legend.position = "none"
        ) +
        ylim(1, 7)
    } else {
      return(NULL)
    }
  }
  
  return(p)
}

# ===== CREATE REJECTION RATE GRID WITH PATTERN NAMES =====
cat("Creating rejection rate comparison grid with pattern names...\n")

rejection_plots_named <- list()
for(i in 1:15) {
  plot <- create_named_interface_plot(i, "rejection")
  if(!is.null(plot)) {
    rejection_plots_named[[paste0("ui", i)]] <- plot
  }
}

# Combine into grid
if(length(rejection_plots_named) > 0) {
  rejection_grid_named <- wrap_plots(rejection_plots_named, ncol = 5, nrow = 3)
  
  # Add overall title
  rejection_final_named <- rejection_grid_named + 
    plot_annotation(
      title = "Dark Pattern Rejection Rates: UEQ vs UEQ+Autonomy",
      subtitle = "Each panel shows side-by-side comparison for one dark pattern type\nStatistical tests: Chi-square (χ²) or Fisher's exact test for binary rejection data",
      theme = theme(
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5)
      )
    )
  
  # Save rejection grid with pattern names
  ggsave("plots/dark_patterns_rejection_named.png",
         plot = rejection_final_named,
         width = 22, height = 14, dpi = 300)
  
  cat("✓ Named rejection rate grid saved to plots/dark_patterns_rejection_named.png\n")
}

# ===== CREATE TENDENCY SCORE GRID WITH PATTERN NAMES =====
cat("Creating tendency score comparison grid with pattern names...\n")

tendency_plots_named <- list()
for(i in 1:15) {
  plot <- create_named_interface_plot(i, "tendency")
  if(!is.null(plot)) {
    tendency_plots_named[[paste0("ui", i)]] <- plot
  }
}

# Combine into grid
if(length(tendency_plots_named) > 0) {
  tendency_grid_named <- wrap_plots(tendency_plots_named, ncol = 5, nrow = 3)
  
  # Add overall title
  tendency_final_named <- tendency_grid_named + 
    plot_annotation(
      title = "Dark Pattern Tendency Scores: UEQ vs UEQ+Autonomy", 
      subtitle = "Each panel shows side-by-side comparison for one dark pattern type\nStatistical tests: Independent samples t-test for continuous tendency data",
      theme = theme(
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5)
      )
    )
  
  # Save tendency grid with pattern names
  ggsave("plots/dark_patterns_tendency_named.png",
         plot = tendency_final_named, 
         width = 22, height = 14, dpi = 300)
  
  cat("✓ Named tendency score grid saved to plots/dark_patterns_tendency_named.png\n")
}

# ===== UPDATE SUMMARY WITH PATTERN NAMES =====
cat("\n=== UPDATING SUMMARY WITH PATTERN NAMES ===\n")

# Load the statistical results
stats_results <- read.csv("results/corrected_interface_statistical_tests.csv")

# Add pattern names to results
stats_results_named <- stats_results %>%
  left_join(ui_mapping, by = c("interface" = "interface_num"))

cat("Significant interfaces with pattern names:\n")

# Show significant results with pattern names
significant_results <- stats_results_named %>%
  filter(rejection_significant | tendency_significant) %>%
  select(interface, pattern_name, rejection_p, rejection_significant, tendency_p, tendency_significant)

print(significant_results)

# Save updated results with pattern names
write.csv(stats_results_named, "results/dark_patterns_statistical_results_named.csv", row.names = FALSE)

cat("\n=== SUMMARY WITH PATTERN NAMES ===\n")
cat("Dark patterns with significant rejection differences:\n")
rejection_sig <- stats_results_named %>% filter(rejection_significant)
if(nrow(rejection_sig) > 0) {
  for(i in 1:nrow(rejection_sig)) {
    cat("• ", rejection_sig$pattern_name[i], " (p = ", round(rejection_sig$rejection_p[i], 3), ")\n", sep="")
  }
}

cat("\nDark patterns with significant tendency differences:\n")
tendency_sig <- stats_results_named %>% filter(tendency_significant)
if(nrow(tendency_sig) > 0) {
  for(i in 1:nrow(tendency_sig)) {
    cat("• ", tendency_sig$pattern_name[i], " (p = ", round(tendency_sig$tendency_p[i], 3), ")\n", sep="")
  }
}

cat("\nFiles created:\n")
cat("• plots/dark_patterns_rejection_named.png - Rejection rates with dark pattern names\n")
cat("• plots/dark_patterns_tendency_named.png - Tendency scores with dark pattern names\n") 
cat("• results/dark_patterns_statistical_results_named.csv - Results with pattern names\n")

cat("\n=== ANALYSIS COMPLETE WITH PATTERN NAMES ===\n")
