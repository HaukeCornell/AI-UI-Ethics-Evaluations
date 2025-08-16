# UEQ vs UEEQ Interface Rejection Analysis - Simplified Version
# Statistical analysis comparing rejection rates and tendencies
# between UEQ (standard metrics) and UEEQ (ethics-enhanced metrics)

# Set CRAN mirror and load required libraries
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Install and load required packages
required_packages <- c("readr", "dplyr", "ggplot2", "tidyr", "lme4", "emmeans")

for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  }
}

# ==============================================================================
# 1. DATA LOADING AND PREPROCESSING
# ==============================================================================

cat("Loading data...\n")
data_raw <- read_tsv("survey_data_utf8.tsv", 
                     show_col_types = FALSE)

# Check data dimensions
cat("Data dimensions:", dim(data_raw), "\n")

# Remove header rows (first 2 rows are metadata)
data_clean <- data_raw[-c(1:2), ]
cat("Clean data dimensions:", dim(data_clean), "\n")

# ==============================================================================
# 2. DATA RESTRUCTURING  
# ==============================================================================

cat("\n=== DATA RESTRUCTURING ===\n")
cat("Converting wide format to long format for analysis...\n")

# Extract UEQ and UEEQ columns for all interfaces (1-15)
interfaces <- 1:15

# Create long format data for analysis
data_long <- data.frame()

for (i in interfaces) {
  # Extract UEQ data for interface i
  ueq_tendency_col <- paste0(i, "_UEQ Tendency_1")
  ueq_release_col <- paste0(i, "_UEQ Release")
  ueq_confidence_col <- paste0(i, "_UEQ Confidence_4")
  ueq_explanation_col <- paste0(i, "_UEQ Explanation")
  
  # Extract UEEQ data for interface i  
  ueeq_tendency_col <- paste0(i, "_UEEQ Tendency_1")
  ueeq_release_col <- paste0(i, "_UEEQ Release")
  ueeq_confidence_col <- paste0(i, "_UEEQ Confidence_4")
  ueeq_explanation_col <- paste0(i, "_UEEQ Explanation")
  
  # Check if columns exist
  if (all(c(ueq_tendency_col, ueq_release_col) %in% names(data_clean))) {
    # UEQ data
    ueq_data <- data.frame(
      participant_id = data_clean$ResponseId,
      interface = i,
      metric_type = "UEQ",
      tendency = as.numeric(data_clean[[ueq_tendency_col]]),
      release = data_clean[[ueq_release_col]],
      confidence = as.numeric(data_clean[[ueq_confidence_col]]),
      explanation = if(ueq_explanation_col %in% names(data_clean)) data_clean[[ueq_explanation_col]] else NA,
      stringsAsFactors = FALSE
    )
    
    # UEEQ data
    ueeq_data <- data.frame(
      participant_id = data_clean$ResponseId,
      interface = i,
      metric_type = "UEEQ",
      tendency = as.numeric(data_clean[[ueeq_tendency_col]]),
      release = data_clean[[ueeq_release_col]],
      confidence = as.numeric(data_clean[[ueeq_confidence_col]]),
      explanation = if(ueeq_explanation_col %in% names(data_clean)) data_clean[[ueeq_explanation_col]] else NA,
      stringsAsFactors = FALSE
    )
    
    # Combine for this interface
    interface_data <- rbind(ueq_data, ueeq_data)
    data_long <- rbind(data_long, interface_data)
  }
}

# Clean and prepare data
data_long <- data_long %>%
  mutate(
    release_binary = case_when(
      release == "Yes" ~ 1,
      release == "No" ~ 0,
      TRUE ~ NA_real_
    ),
    rejection = 1 - release_binary,  # 1 = rejected, 0 = accepted
    interface = as.factor(interface),
    metric_type = as.factor(metric_type),
    participant_id = as.factor(participant_id)
  ) %>%
  filter(!is.na(tendency), !is.na(release_binary))  # Remove missing responses

cat("Long format data created with", nrow(data_long), "observations\n")
cat("Participants:", n_distinct(data_long$participant_id), "\n")
cat("Interfaces:", n_distinct(data_long$interface), "\n")

# ==============================================================================
# 3. DESCRIPTIVE STATISTICS
# ==============================================================================

cat("\n=== DESCRIPTIVE STATISTICS ===\n")

# Overall summary by metric type
overall_summary <- data_long %>%
  group_by(metric_type) %>%
  summarise(
    n_responses = n(),
    n_participants = n_distinct(participant_id),
    n_interfaces = n_distinct(interface),
    
    # Rejection rates 
    rejection_rate = mean(rejection, na.rm = TRUE),
    rejection_se = sqrt(rejection_rate * (1 - rejection_rate) / n()),
    
    # Tendency scores
    tendency_mean = mean(tendency, na.rm = TRUE),
    tendency_sd = sd(tendency, na.rm = TRUE),
    tendency_median = median(tendency, na.rm = TRUE),
    tendency_q25 = quantile(tendency, 0.25, na.rm = TRUE),
    tendency_q75 = quantile(tendency, 0.75, na.rm = TRUE),
    
    # Confidence
    confidence_mean = mean(confidence, na.rm = TRUE),
    confidence_sd = sd(confidence, na.rm = TRUE),
    .groups = 'drop'
  )

cat("\nOVERALL SUMMARY BY METRIC TYPE:\n")
print(overall_summary)

# Interface-level summary for pattern analysis
interface_summary <- data_long %>%
  group_by(interface, metric_type) %>%
  summarise(
    n_responses = n(),
    rejection_rate = mean(rejection, na.rm = TRUE),
    tendency_mean = mean(tendency, na.rm = TRUE),
    tendency_sd = sd(tendency, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  pivot_wider(names_from = metric_type, 
              values_from = c(rejection_rate, tendency_mean, tendency_sd, n_responses),
              names_sep = "_")

cat("\nINTERFACE-LEVEL COMPARISON:\n")
print(interface_summary)

# ==============================================================================
# 4. STATISTICAL TESTS - REJECTION RATES
# ==============================================================================

cat("\n=== STATISTICAL ANALYSIS: REJECTION RATES ===\n")

# Test using mixed-effects logistic regression
cat("Fitting logistic mixed-effects model for rejection rates...\n")

# Simple model with metric type as fixed effect, participant as random effect
rejection_model <- glmer(rejection ~ metric_type + (1|participant_id), 
                        data = data_long,
                        family = binomial(link = "logit"))

cat("\nModel summary:\n")
print(summary(rejection_model))

# Extract coefficients and significance
coef_summary <- summary(rejection_model)$coefficients
cat("\nCoefficient table:\n")
print(coef_summary)

# Calculate marginal means
rejection_emmeans <- emmeans(rejection_model, ~ metric_type, type = "response")
cat("\nEstimated marginal means (probabilities):\n")
print(rejection_emmeans)

# Pairwise comparison
rejection_contrast <- contrast(rejection_emmeans, method = "pairwise")
cat("\nPairwise contrast:\n")
print(rejection_contrast)

# ==============================================================================
# 5. STATISTICAL TESTS - TENDENCY SCORES
# ==============================================================================

cat("\n=== STATISTICAL ANALYSIS: TENDENCY SCORES ===\n")

# Test using mixed-effects linear regression
cat("Fitting linear mixed-effects model for tendency scores...\n")

tendency_model <- lmer(tendency ~ metric_type + (1|participant_id), 
                      data = data_long)

cat("\nModel summary:\n")
print(summary(tendency_model))

# Marginal means for tendency
tendency_emmeans <- emmeans(tendency_model, ~ metric_type)
cat("\nEstimated marginal means for tendency:\n")
print(tendency_emmeans)

# Pairwise comparison
tendency_contrast <- contrast(tendency_emmeans, method = "pairwise")
cat("\nPairwise contrast for tendency:\n")
print(tendency_contrast)

# ==============================================================================
# 6. EFFECT SIZES AND PRACTICAL SIGNIFICANCE
# ==============================================================================

cat("\n=== EFFECT SIZES ===\n")

# Manual Cohen's d calculation for tendency
ueq_tendency <- data_long$tendency[data_long$metric_type == "UEQ"]
ueeq_tendency <- data_long$tendency[data_long$metric_type == "UEEQ"]

cohens_d <- (mean(ueeq_tendency, na.rm = TRUE) - mean(ueq_tendency, na.rm = TRUE)) / 
            sqrt((var(ueq_tendency, na.rm = TRUE) + var(ueeq_tendency, na.rm = TRUE)) / 2)

cat("Cohen's d for tendency scores:", round(cohens_d, 3), "\n")

# Interpretation
if (abs(cohens_d) < 0.2) {
  effect_interpretation <- "negligible"
} else if (abs(cohens_d) < 0.5) {
  effect_interpretation <- "small"
} else if (abs(cohens_d) < 0.8) {
  effect_interpretation <- "medium"
} else {
  effect_interpretation <- "large"
}
cat("Effect size interpretation:", effect_interpretation, "\n")

# ==============================================================================
# 7. KEY FINDINGS SUMMARY
# ==============================================================================

cat("\n" %>% rep(3) %>% paste(collapse=""))
cat("=== KEY FINDINGS SUMMARY ===\n")
cat("============================\n")

ueq_rejection <- overall_summary$rejection_rate[overall_summary$metric_type == "UEQ"]
ueeq_rejection <- overall_summary$rejection_rate[overall_summary$metric_type == "UEEQ"]
rejection_diff <- ueeq_rejection - ueq_rejection

ueq_tendency_mean <- overall_summary$tendency_mean[overall_summary$metric_type == "UEQ"]
ueeq_tendency_mean <- overall_summary$tendency_mean[overall_summary$metric_type == "UEEQ"]
tendency_diff <- ueeq_tendency_mean - ueq_tendency_mean

cat("REJECTION RATES:\n")
cat("----------------\n")
cat(sprintf("UEQ (standard metrics):   %.1f%% rejection rate\n", ueq_rejection * 100))
cat(sprintf("UEEQ (enhanced metrics):  %.1f%% rejection rate\n", ueeq_rejection * 100))
cat(sprintf("Difference:               %.1f percentage points", rejection_diff * 100))
if (rejection_diff > 0) {
  cat(" (UEEQ higher)\n")
} else if (rejection_diff < 0) {
  cat(" (UEQ higher)\n")
} else {
  cat(" (no difference)\n")
}

cat("\nTENDENCY SCORES:\n")
cat("----------------\n")
cat(sprintf("UEQ mean tendency:   %.2f (SD: %.2f)\n", 
            ueq_tendency_mean, 
            overall_summary$tendency_sd[overall_summary$metric_type == "UEQ"]))
cat(sprintf("UEEQ mean tendency:  %.2f (SD: %.2f)\n", 
            ueeq_tendency_mean,
            overall_summary$tendency_sd[overall_summary$metric_type == "UEEQ"]))
cat(sprintf("Difference:          %.2f points", tendency_diff))
if (tendency_diff > 0) {
  cat(" (UEEQ higher)\n")
} else if (tendency_diff < 0) {
  cat(" (UEQ higher)\n") 
} else {
  cat(" (no difference)\n")
}

cat(sprintf("Effect size (Cohen's d): %.3f (%s effect)\n", cohens_d, effect_interpretation))

cat("\nSTATISTICAL SIGNIFICANCE:\n")
cat("-------------------------\n")
cat("Statistical tests used mixed-effects models accounting for participant clustering.\n")
cat("Check model outputs above for p-values and confidence intervals.\n")

cat("\nDATA SUMMARY:\n")
cat("-------------\n")
cat(sprintf("Total responses analyzed: %d\n", nrow(data_long)))
cat(sprintf("Unique participants: %d\n", n_distinct(data_long$participant_id)))
cat(sprintf("Interfaces evaluated: %d\n", n_distinct(data_long$interface)))
cat(sprintf("Study design: Within-subjects (each participant evaluated both UEQ and UEEQ)\n"))

cat("\nAnalysis complete!\n")
