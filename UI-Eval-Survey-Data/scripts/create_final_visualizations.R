library(readr)
library(dplyr)
library(ggplot2)

# Quick visualization script based on our findings
# UEQ: 46.3% rejection, UEEQ: 51.7% rejection (p=0.214)
# UEQ: 3.67 tendency, UEEQ: 3.31 tendency (p=0.198)

# Create summary data
results_data <- data.frame(
  condition = c("UEQ", "UEEQ"),
  rejection_rate = c(0.463, 0.517),
  rejection_se = c(0.031, 0.031),
  tendency_mean = c(3.67, 3.31),
  tendency_se = c(0.13, 0.12)
)

# Rejection rates plot
p1 <- ggplot(results_data, aes(x = condition, y = rejection_rate, fill = condition)) +
  geom_col(alpha = 0.7, width = 0.6) +
  geom_errorbar(aes(ymin = rejection_rate - 1.96 * rejection_se,
                    ymax = rejection_rate + 1.96 * rejection_se),
                width = 0.1) +
  scale_y_continuous(labels = scales::percent_format(), limits = c(0, 0.7)) +
  scale_fill_manual(values = c("UEQ" = "#3498db", "UEEQ" = "#e74c3c")) +
  labs(title = "Interface Rejection Rates by Condition (Between-Subjects)",
       subtitle = "UEQ: 46.3%, UEEQ: 51.7% (p = 0.214, not significant)",
       x = "Condition",
       y = "Mean Rejection Rate",
       caption = "Error bars: 95% CI, Cohen's d = 0.321 (small effect)") +
  theme_minimal() +
  theme(legend.position = "none",
        plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 11, color = "gray40"))

# Tendency scores plot  
p2 <- ggplot(results_data, aes(x = condition, y = tendency_mean, fill = condition)) +
  geom_col(alpha = 0.7, width = 0.6) +
  geom_errorbar(aes(ymin = tendency_mean - 1.96 * tendency_se,
                    ymax = tendency_mean + 1.96 * tendency_se),
                width = 0.1) +
  scale_fill_manual(values = c("UEQ" = "#3498db", "UEEQ" = "#e74c3c")) +
  labs(title = "Mean Tendency Scores by Condition (Between-Subjects)",
       subtitle = "UEQ: 3.67, UEEQ: 3.31 (p = 0.198, not significant)",
       x = "Condition", 
       y = "Mean Tendency Score",
       caption = "Error bars: 95% CI, Cohen's d = -0.331 (small effect)") +
  theme_minimal() +
  theme(legend.position = "none",
        plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 11, color = "gray40"))

# Save plots
ggsave("final_rejection_rates.png", p1, width = 8, height = 6, dpi = 300)
ggsave("final_tendency_scores.png", p2, width = 8, height = 6, dpi = 300)

cat("Final visualizations created:\n")
cat("1. final_rejection_rates.png\n")
cat("2. final_tendency_scores.png\n")

# Print the key statistics
cat("\nKEY FINDINGS SUMMARY:\n")
cat("=====================\n")
cat("Sample: 32 UEQ participants, 29 UEEQ participants\n")
cat("Design: Between-subjects (different participants per condition)\n\n")

cat("REJECTION RATES:\n")
cat("UEQ: 46.3% (SE: 3.1%)\n")
cat("UEEQ: 51.7% (SE: 3.1%)\n") 
cat("Difference: +5.5 percentage points (UEEQ higher)\n")
cat("p-value: 0.214 (not significant)\n")
cat("Effect size: Cohen's d = 0.321 (small)\n\n")

cat("TENDENCY SCORES:\n")
cat("UEQ: 3.67 (SE: 0.13)\n")
cat("UEEQ: 3.31 (SE: 0.12)\n")
cat("Difference: -0.36 points (UEQ higher)\n") 
cat("p-value: 0.198 (not significant)\n")
cat("Effect size: Cohen's d = -0.331 (small)\n\n")

cat("INTERPRETATION:\n")
cat("No statistically significant differences between UEQ and UEEQ conditions.\n")
cat("Small effect sizes suggest subtle, not dramatic, differences.\n")
cat("Ethics-enhanced metrics do not substantially alter evaluation outcomes.\n")
