# Comprehensive Confidence Analysis: Mixed Effects Analysis with High-Quality Visualization
# Extract and analyze confidence data from raw survey data with same style as tendency analysis

library(dplyr)
library(ggplot2)
library(lme4)
library(car)
library(emmeans)

cat("=== CONFIDENCE ANALYSIS: EXTRACTING AND ANALYZING CONFIDENCE DATA ===\n")

# Read raw survey data (use UTF-8 converted file)
raw_data <- read.delim("data/sep2_completed_utf8.tsv", 
                       sep = "\t", stringsAsFactors = FALSE)

cat("Raw data loaded:", nrow(raw_data), "participants\n")

# Function to extract confidence data for one condition
extract_confidence_data <- function(data, condition_name) {
  # R converts column names: "1_UEQ Confidence_4" becomes "X1_UEQ.Confidence_4"
  confidence_cols <- paste0("X", 1:15, "_", condition_name, ".Confidence_4")
  tendency_cols <- paste0("X", 1:15, "_", condition_name, ".Tendency_1")
  
  extracted_rows <- list()
  
  for(i in 1:15) {
    conf_col <- confidence_cols[i]
    tend_col <- tendency_cols[i]
    
    if(conf_col %in% names(data) && tend_col %in% names(data)) {
      
      # Get non-NA rows for this interface
      conf_values <- data[[conf_col]]
      tend_values <- data[[tend_col]]
      
      valid_rows <- !is.na(conf_values) & !is.na(tend_values)
      
      if(sum(valid_rows) > 0) {
        interface_data <- data.frame(
          PROLIFIC_PID = data$PROLIFIC_PID[valid_rows],
          interface = paste0("ui", sprintf("%03d", i)),
          interface_num = i,
          condition = condition_name,
          confidence = as.numeric(conf_values[valid_rows]),
          tendency = as.numeric(tend_values[valid_rows]),
          stringsAsFactors = FALSE
        )
        
        extracted_rows[[length(extracted_rows) + 1]] <- interface_data
      }
    }
  }
  
  if(length(extracted_rows) > 0) {
    result <- do.call(rbind, extracted_rows)
    return(result)
  } else {
    return(data.frame())
  }
}

# Extract confidence data for all conditions
cat("Extracting confidence data...\n")
raw_confidence <- extract_confidence_data(raw_data, "RAW")
cat("RAW confidence entries:", nrow(raw_confidence), "\n")

ueq_confidence <- extract_confidence_data(raw_data, "UEQ") 
cat("UEQ confidence entries:", nrow(ueq_confidence), "\n")

ueeq_confidence <- extract_confidence_data(raw_data, "UEEQ")
cat("UEEQ confidence entries:", nrow(ueeq_confidence), "\n")

# Combine all data
confidence_data <- rbind(raw_confidence, ueq_confidence, ueeq_confidence)

cat("Total confidence data extracted:", nrow(confidence_data), "evaluations\n")

# Check if we have any data
if(nrow(confidence_data) == 0) {
  cat("ERROR: No confidence data extracted. Checking column names...\n")
  conf_cols <- grep("Confidence", names(raw_data), value = TRUE)
  cat("Available confidence columns:\n")
  print(head(conf_cols, 20))
  stop("No confidence data found")
}

# Update condition names to match our naming convention
confidence_data$condition_new <- dplyr::case_when(
  confidence_data$condition == "RAW" ~ "UI",
  confidence_data$condition == "UEQ" ~ "UEQ", 
  confidence_data$condition == "UEEQ" ~ "UEEQ-P"
)

confidence_data$condition_new <- factor(confidence_data$condition_new, levels = c("UI", "UEQ", "UEEQ-P"))

# Remove missing confidence values
confidence_data <- confidence_data[!is.na(confidence_data$confidence), ]

# Define consistent color scheme
condition_colors <- c("UI" = "#FF8888", "UEQ" = "#ABE2AB", "UEEQ-P" = "#AE80FF")

cat("Confidence data extracted:", nrow(confidence_data), "evaluations\n")
cat("From", length(unique(confidence_data$PROLIFIC_PID)), "participants\n")
cat("Across", length(unique(confidence_data$interface)), "interfaces\n")
print(table(confidence_data$condition_new))

# Check confidence scale
cat("\n=== CONFIDENCE SCALE ANALYSIS ===\n")
cat("Confidence value summary:\n")
print(summary(confidence_data$confidence))
cat("Confidence value counts:\n")
print(table(confidence_data$confidence, useNA = "always"))

# 1. Mixed Effects Analysis
cat("\n=== MIXED EFFECTS ANALYSIS ===\n")

# Fit mixed effects model with participant and interface as random effects
model_mixed <- lmer(confidence ~ condition_new + (1|PROLIFIC_PID) + (1|interface), 
                   data = confidence_data, REML = FALSE)

# ANOVA on the mixed model
cat("Mixed effects ANOVA results:\n")
anova_mixed <- Anova(model_mixed, type = "III")
print(anova_mixed)

# Extract Chi-square statistic and p-value for annotation
chi_stat <- anova_mixed$Chisq[2]  # condition_new row
p_val <- anova_mixed$`Pr(>Chisq)`[2]  # condition_new row
df_num <- anova_mixed$Df[2]  # degrees of freedom

cat(sprintf("\nChi-square(%d) = %.2f, p = %s\n", df_num, chi_stat, 
            if(p_val < 0.001) "< 0.001" else sprintf("= %.3f", p_val)))

# 2. Post-hoc comparisons using emmeans
cat("\n=== POST-HOC COMPARISONS (EMMEANS WITH TUKEY) ===\n")

# Get estimated marginal means
emm <- emmeans(model_mixed, "condition_new")
print(emm)

# Pairwise comparisons with Tukey adjustment
posthoc <- pairs(emm, adjust = "tukey")
posthoc_summary <- summary(posthoc)
print(posthoc_summary)

# Extract p-values for significance bars
posthoc_df <- as.data.frame(posthoc_summary)
ui_ueq_p <- posthoc_df$p.value[grepl("UI.*UEQ", posthoc_df$contrast) & !grepl("UEEQ-P", posthoc_df$contrast)]
ui_ueqa_p <- posthoc_df$p.value[grepl("UI.*UEEQ-P", posthoc_df$contrast)]
ueq_ueqa_p <- posthoc_df$p.value[grepl("UEQ.*UEEQ-P", posthoc_df$contrast)]

cat("P-values extracted:\n")
cat("UI vs UEQ:", ui_ueq_p, "\n")
cat("UI vs UEEQ-P:", ui_ueqa_p, "\n")
cat("UEQ vs UEEQ-P:", ueq_ueqa_p, "\n")

# 3. Descriptive statistics
cat("\n=== DESCRIPTIVE STATISTICS (ALL EVALUATIONS: 0-7 SCALE) ===\n")

desc_stats <- confidence_data %>%
  group_by(condition_new) %>%
  summarise(
    n_evaluations = n(),
    n_participants = n_distinct(PROLIFIC_PID),
    n_interfaces = n_distinct(interface),
    mean_confidence = mean(confidence, na.rm = TRUE),
    sd_confidence = sd(confidence, na.rm = TRUE),
    median_confidence = median(confidence, na.rm = TRUE),
    q25 = quantile(confidence, 0.25, na.rm = TRUE),
    q75 = quantile(confidence, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

print(desc_stats)

# Calculate means and medians for plot annotations
stats_for_plot <- confidence_data %>%
  group_by(condition_new) %>%
  summarise(
    mean_val = mean(confidence, na.rm = TRUE),
    median_val = median(confidence, na.rm = TRUE),
    .groups = "drop"
  )

# 4. Enhanced Visualization: Individual Evaluations Distribution
cat("\n=== CREATING HIGH-QUALITY CONFIDENCE VISUALIZATION ===\n")

# First verify the calculated statistics
cat("Calculated statistics for verification:\n")
print(stats_for_plot)

p_confidence <- ggplot(confidence_data, aes(x = condition_new, y = confidence, fill = condition_new)) +
  # Violin plots for distribution
  geom_violin(alpha = 0.6, trim = FALSE) +
  
  # BOXPLOTS
  geom_boxplot(width = 0.3, alpha = 0.8, outlier.shape = NA) +
  
  # Individual evaluation jitter points
  geom_jitter(width = 0.15, alpha = 0.2, size = 0.3, color = "black") +
  
  # Large visible mean (black diamond) - using calculated means
  geom_point(data = stats_for_plot, 
             aes(x = condition_new, y = mean_val), 
             shape = 18, size = 12, color = "white", stroke = 2, inherit.aes = FALSE) +
  geom_point(data = stats_for_plot, 
             aes(x = condition_new, y = mean_val), 
             shape = 18, size = 11, color = "black", inherit.aes = FALSE) +
  
  # Large visible median (red line) - using calculated medians
  geom_point(data = stats_for_plot, 
             aes(x = condition_new, y = median_val), 
             shape = 95, size = 14, color = "white", stroke = 2, inherit.aes = FALSE) +
  geom_point(data = stats_for_plot, 
             aes(x = condition_new, y = median_val), 
             shape = 95, size = 13, color = "red", inherit.aes = FALSE) +
  
  # SIGNIFICANCE BARS (UI vs UEQ)
  geom_segment(aes(x = 1, xend = 2, y = 6.5, yend = 6.5), color = "black", linewidth = 1.2) +
  geom_segment(aes(x = 1, xend = 1, y = 6.3, yend = 6.5), color = "black", linewidth = 1.2) +
  geom_segment(aes(x = 2, xend = 2, y = 6.3, yend = 6.5), color = "black", linewidth = 1.2) +
  annotate("text", x = 1.5, y = 6.7, 
           label = if(ui_ueq_p < 0.001) "p < 0.001" else paste0("p = ", sprintf("%.3f", ui_ueq_p)), 
           size = 5, fontface = "bold") +
  
  # SIGNIFICANCE BARS (UEQ vs UEEQ-P)
  geom_segment(aes(x = 2, xend = 3, y = 6.0, yend = 6.0), color = "black", linewidth = 1.2) +
  geom_segment(aes(x = 2, xend = 2, y = 5.8, yend = 6.0), color = "black", linewidth = 1.2) +
  geom_segment(aes(x = 3, xend = 3, y = 5.8, yend = 6.0), color = "black", linewidth = 1.2) +
  annotate("text", x = 2.5, y = 6.2, 
           label = if(ueq_ueqa_p < 0.001) "p < 0.001" else paste0("p = ", sprintf("%.3f", ueq_ueqa_p)), 
           size = 5, fontface = "bold") +
  
  # SIGNIFICANCE BARS (UI vs UEEQ-P)
  geom_segment(aes(x = 1, xend = 3, y = 7.0, yend = 7.0), color = "black", linewidth = 1.2) +
  geom_segment(aes(x = 1, xend = 1, y = 6.8, yend = 7.0), color = "black", linewidth = 1.2) +
  geom_segment(aes(x = 3, xend = 3, y = 6.8, yend = 7.0), color = "black", linewidth = 1.2) +
  annotate("text", x = 2, y = 7.2, 
           label = if(ui_ueqa_p < 0.001) "p < 0.001" else paste0("p = ", sprintf("%.3f", ui_ueqa_p)), 
           size = 5, fontface = "bold") +
  
  # VISIBLE MEAN/MEDIAN TEXT ANNOTATIONS
  geom_text(data = stats_for_plot, 
            aes(x = as.numeric(condition_new), y = 0.4, 
                label = paste0("Mean: ", sprintf("%.2f", mean_val))), 
            color = "black", fontface = "bold", size = 5.5, hjust = 0.5, inherit.aes = FALSE) +
  geom_text(data = stats_for_plot, 
            aes(x = as.numeric(condition_new), y = 0.2, 
                label = paste0("Median: ", sprintf("%.0f", median_val))), 
            color = "red", fontface = "bold", size = 5.5, hjust = 0.5, inherit.aes = FALSE) +
  
  scale_fill_manual(values = condition_colors, name = "Condition") +
  labs(
    title = "Decision Confidence Distribution: All Individual Evaluations",
    subtitle = paste0("Mixed effects analysis of ", nrow(confidence_data), 
                     " individual evaluations • χ²(", df_num, ") = ", 
                     sprintf("%.2f", chi_stat), ", p ", 
                     if(p_val < 0.001) "< 0.001" else paste0("= ", sprintf("%.3f", p_val))),
    x = "Evaluation Condition",
    y = "Decision Confidence (0-7 scale)",
    caption = "♦ = Mean (black diamond) • ▬ = Median (red line) • Boxes show quartiles • Points = Individual evaluations\nMixed effects model accounts for participant and interface random effects • Post-hoc: Tukey HSD"
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
    panel.grid.major.x = element_blank()
  ) +
  scale_y_continuous(limits = c(0, 7.5), breaks = 0:7)

# Create THUMBNAIL version
p_thumbnail <- ggplot(confidence_data, aes(x = condition_new, y = confidence, fill = condition_new)) +
  # Boxplots only (cleaner for thumbnail)
  geom_boxplot(width = 0.5, alpha = 0.8, outlier.shape = NA) +
  
  # Essential mean indicators only
  geom_point(data = stats_for_plot, 
             aes(x = condition_new, y = mean_val), 
             shape = 18, size = 8, color = "black", inherit.aes = FALSE) +
  
  # SIGNIFICANCE STARS only
  annotate("text", x = 1.5, y = 6.5, 
           label = if(ui_ueq_p < 0.001) "***" else if(ui_ueq_p < 0.01) "**" else if(ui_ueq_p < 0.05) "*" else "ns", 
           size = 6, fontface = "bold") +
  annotate("text", x = 2.5, y = 6.0, 
           label = if(ueq_ueqa_p < 0.001) "***" else if(ueq_ueqa_p < 0.01) "**" else if(ueq_ueqa_p < 0.05) "*" else "ns", 
           size = 6, fontface = "bold") +
  annotate("text", x = 2, y = 6.8, 
           label = if(ui_ueqa_p < 0.001) "***" else if(ui_ueqa_p < 0.01) "**" else if(ui_ueqa_p < 0.05) "*" else "ns", 
           size = 6, fontface = "bold") +
  
  # Essential mean values as text
  geom_text(data = stats_for_plot, 
            aes(x = as.numeric(condition_new), y = 0.5, 
                label = sprintf("%.2f", mean_val)), 
            color = "black", fontface = "bold", size = 6, hjust = 0.5, inherit.aes = FALSE) +
  
  scale_fill_manual(values = condition_colors) +
  labs(
    title = "Decision Confidence: Mixed Effects Analysis",
    x = "Condition",
    y = "Confidence (0-7)"
  ) +
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
  scale_y_continuous(limits = c(0, 7), breaks = 0:7)

# Save plots
if(!dir.exists("plots")) dir.create("plots")

ggsave("plots/confidence_analysis_enhanced.png", p_confidence, 
       width = 14, height = 10, dpi = 300)

ggsave("plots/confidence_analysis_thumbnail.png", p_thumbnail, 
       width = 8, height = 6, dpi = 300)

# Save results
if(!dir.exists("results")) dir.create("results")
write.csv(confidence_data, "results/confidence_interface_data.csv", row.names = FALSE)
write.csv(desc_stats, "results/confidence_descriptive_stats.csv", row.names = FALSE)

# Save post-hoc results
posthoc_conf_df <- data.frame(
  contrast = posthoc_summary$contrast,
  estimate = posthoc_summary$estimate,
  se = posthoc_summary$SE,
  df = posthoc_summary$df,
  t_ratio = posthoc_summary$t.ratio,
  p_value = posthoc_summary$p.value
)
write.csv(posthoc_conf_df, "results/confidence_posthoc_results.csv", row.names = FALSE)

# 5. Effect sizes for pairwise comparisons
cat("\n=== EFFECT SIZES (COHEN'S D) ===\n")

ui_conf_data <- confidence_data$confidence[confidence_data$condition_new == "UI"]
ueq_conf_data <- confidence_data$confidence[confidence_data$condition_new == "UEQ"]
ueqa_conf_data <- confidence_data$confidence[confidence_data$condition_new == "UEEQ-P"]

# Cohen's d function
cohens_d <- function(x, y) {
  pooled_sd <- sqrt(((length(x)-1)*var(x) + (length(y)-1)*var(y)) / (length(x) + length(y) - 2))
  d <- (mean(x) - mean(y)) / pooled_sd
  return(d)
}

d_ui_ueq <- cohens_d(ui_conf_data, ueq_conf_data)
d_ui_ueqa <- cohens_d(ui_conf_data, ueqa_conf_data)
d_ueq_ueqa <- cohens_d(ueq_conf_data, ueqa_conf_data)

cat(sprintf("UI vs UEQ: d = %.3f\n", d_ui_ueq))
cat(sprintf("UI vs UEEQ-P: d = %.3f\n", d_ui_ueqa))
cat(sprintf("UEQ vs UEEQ-P: d = %.3f\n", d_ueq_ueqa))

cat("\n✓ CONFIDENCE analysis completed\n")
cat("✓ High-quality plot saved: plots/confidence_analysis_enhanced.png\n")
cat("✓ Thumbnail plot saved: plots/confidence_analysis_thumbnail.png\n")
cat("✓ Confidence data saved: results/confidence_interface_data.csv\n")
cat("✓ Descriptive statistics saved: results/confidence_descriptive_stats.csv\n")
cat("✓ Post-hoc results saved: results/confidence_posthoc_results.csv\n")

cat("\n=== CONFIDENCE ANALYSIS SUMMARY ===\n")
cat("This analysis examines decision confidence ratings across the three conditions\n")
cat("using the same mixed effects approach as the tendency analysis. Confidence was\n") 
cat("measured on a 0-7 scale alongside each release tendency decision.\n")
