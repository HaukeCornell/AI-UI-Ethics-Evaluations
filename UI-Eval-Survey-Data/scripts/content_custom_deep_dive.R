# Deep dive analysis of the one surviving effect: Content Customization
# N=94, FDR-corrected significant tendency difference

library(dplyr)
library(ggplot2)
library(ggstatsplot)

cat("=== DEEP DIVE: CONTENT CUSTOMIZATION EFFECT ===\n")
cat("The only interface-level effect surviving FDR correction\n\n")

# Load data
interface_data <- read.csv("results/interface_plot_data_aug17_final.csv")

# Focus on Content Customization (interface 2)
content_custom_data <- interface_data %>%
  filter(interface_num == 2)

cat("1. CONTENT CUSTOMIZATION SAMPLE:\n")
print(content_custom_data %>% 
  count(condition_f) %>%
  mutate(percentage = round(n/sum(n)*100, 1)))

cat("\n2. DETAILED STATISTICS:\n")

# Tendency score analysis
tendency_summary <- content_custom_data %>%
  group_by(condition_f) %>%
  summarise(
    n = n(),
    mean_tendency = round(mean(tendency), 3),
    sd_tendency = round(sd(tendency), 3),
    median_tendency = median(tendency),
    min_tendency = min(tendency),
    max_tendency = max(tendency)
  )
print(tendency_summary)

# Statistical test
t_test_result <- t.test(tendency ~ condition_f, data = content_custom_data)
cat("\nt-test results:\n")
cat("t =", round(t_test_result$statistic, 3), "\n")
cat("df =", round(t_test_result$parameter, 1), "\n")
cat("p-value =", format(t_test_result$p.value, scientific = TRUE), "\n")
cat("95% CI:", round(t_test_result$conf.int, 3), "\n")

# Effect size (Cohen's d)
pooled_sd <- sqrt(((tendency_summary$n[1]-1)*tendency_summary$sd_tendency[1]^2 + 
                   (tendency_summary$n[2]-1)*tendency_summary$sd_tendency[2]^2) / 
                  (sum(tendency_summary$n)-2))
cohens_d <- abs(diff(tendency_summary$mean_tendency)) / pooled_sd
cat("Cohen's d =", round(cohens_d, 3), "(", 
    ifelse(cohens_d < 0.2, "negligible", 
           ifelse(cohens_d < 0.5, "small",
                  ifelse(cohens_d < 0.8, "medium", "large"))), "effect )\n")

cat("\n3. REJECTION RATE ANALYSIS:\n")
rejection_summary <- content_custom_data %>%
  group_by(condition_f) %>%
  summarise(
    n = n(),
    rejection_rate = round(mean(rejection_pct), 1),
    rejected_any = sum(rejection_pct > 0),
    rejection_pct_participants = round(rejected_any/n*100, 1)
  )
print(rejection_summary)

# Chi-square test for rejection rates
content_binary <- content_custom_data %>%
  mutate(rejected_binary = ifelse(rejection_pct > 0, 1, 0))
contingency_table <- table(content_binary$condition_f, content_binary$rejected_binary)
cat("\nContingency table (condition vs any rejection):\n")
print(contingency_table)

chisq_result <- chisq.test(contingency_table)
cat("Chi-square test: X² =", round(chisq_result$statistic, 3), 
    ", p =", format(chisq_result$p.value, scientific = TRUE), "\n")

cat("\n4. INTERPRETATION:\n")
ueeq_mean <- tendency_summary$mean_tendency[tendency_summary$condition_f == "UEQ+Autonomy"]
ueq_mean <- tendency_summary$mean_tendency[tendency_summary$condition_f == "UEQ"]

if(ueeq_mean > ueq_mean) {
  cat("• UEQ+Autonomy participants rate Content Customization as MORE ethically problematic\n")
  cat("• Effect size:", round(cohens_d, 3), "- suggests autonomy concerns increase ethical sensitivity\n")
} else {
  cat("• UEQ participants rate Content Customization as MORE ethically problematic\n")
  cat("• Effect size:", round(cohens_d, 3), "- suggests standard UEQ detects more concerns\n")
}

cat("• This is the ONLY interface showing robust differences after multiple comparisons\n")
cat("• Content customization involves algorithmic personalization - relevant to autonomy\n")

# Create visualization
p1 <- ggplot(content_custom_data, aes(x = condition_f, y = tendency, fill = condition_f)) +
  geom_boxplot(alpha = 0.7) +
  geom_jitter(width = 0.2, alpha = 0.6) +
  scale_fill_manual(values = c("UEQ" = "#FF6B6B", "UEQ+Autonomy" = "#4ECDC4")) +
  labs(
    title = "Content Customization: The Only Surviving Effect",
    subtitle = paste0("t(", round(t_test_result$parameter, 1), ") = ", 
                     round(t_test_result$statistic, 3), 
                     ", p = ", format(t_test_result$p.value, digits = 3),
                     ", Cohen's d = ", round(cohens_d, 3)),
    x = "Condition",
    y = "Ethical Concern (1-7 scale)",
    caption = "N=94 participants, FDR-corrected significant difference"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave("results/content_customization_effect.png", p1, width = 8, height = 6, dpi = 300)

cat("\n5. SUMMARY:\n")
cat("After rigorous multiple comparisons correction with N=94:\n")
cat("• 14 of 15 interfaces show NO difference between conditions\n")
cat("• Content Customization shows robust difference (FDR p =", 
    format(0.007238259, digits = 3), ")\n")
cat("• This suggests autonomy considerations specifically matter for algorithmic personalization\n")
cat("• Overall conclusion: UEQ and UEQ+Autonomy perform equivalently except for this one pattern\n")

cat("\nVisualization saved: results/content_customization_effect.png\n")
