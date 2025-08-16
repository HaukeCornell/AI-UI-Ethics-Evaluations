# Enhanced AI vs Human Analysis
# More detailed examination of evaluation sources

library(readr)
library(dplyr)
library(ggplot2)
library(emmeans)
library(lme4)
library(tidyr)

# Read the UTF-8 converted data
data <- read_tsv("survey_data_utf8.tsv", show_col_types = FALSE)

cat("=== Enhanced AI vs Human Analysis ===\n")

# Filter to completed responses only
completed_data <- data %>% 
  filter(Progress == 100) %>%
  filter(!is.na(`1_UEQ Tendency_1`) | !is.na(`1_UEEQ Tendency_1`))

cat("Completed responses:", nrow(completed_data), "\n\n")

# Understand the structure of "Evaluation Data" responses
eval_data_responses <- completed_data %>%
  filter(!is.na(`Evaluation Data`)) %>%
  count(`Evaluation Data`, sort = TRUE)

cat("Evaluation Data responses (counts):\n")
print(eval_data_responses)
cat("\n")

# Create indicator for AI evaluation exposure
# Based on "Combined AI-human evaluation" appearing in Evaluation Data responses
completed_data <- completed_data %>%
  mutate(
    has_ai_evaluation = case_when(
      is.na(`Evaluation Data`) ~ NA,
      grepl("Combined AI-human evaluation", `Evaluation Data`, ignore.case = TRUE) ~ TRUE,
      TRUE ~ FALSE
    )
  )

cat("AI evaluation exposure distribution:\n")
print(table(completed_data$has_ai_evaluation, useNA = "always"))
cat("\n")

# Determine UEQ vs UEEQ condition assignment (same logic as before)
completed_data <- completed_data %>%
  mutate(
    has_ueq = !is.na(`1_UEQ Tendency_1`),
    has_ueeq = !is.na(`1_UEEQ Tendency_1`),
    condition = case_when(
      has_ueq & !has_ueeq ~ "UEQ",
      !has_ueq & has_ueeq ~ "UEEQ", 
      has_ueq & has_ueeq ~ "Mixed", # Should not happen
      TRUE ~ "Neither"
    )
  )

# Cross-tabulate condition by AI evaluation exposure
cat("Cross-tabulation: Condition x AI Evaluation Exposure\n")
crosstab <- table(completed_data$condition, completed_data$has_ai_evaluation, useNA = "always")
print(crosstab)
cat("\n")

# Check if we have sufficient data for within-subjects AI vs Human analysis
ai_exposed <- completed_data %>% filter(has_ai_evaluation == TRUE, condition %in% c("UEQ", "UEEQ"))
no_ai_exposed <- completed_data %>% filter(has_ai_evaluation == FALSE, condition %in% c("UEQ", "UEEQ"))

cat("Sample sizes for AI analysis:\n")
cat("Participants with AI-Human combined evaluations:", nrow(ai_exposed), "\n")
cat("Participants with non-AI evaluations only:", nrow(no_ai_exposed), "\n")
cat("AI-exposed by condition: UEQ =", sum(ai_exposed$condition == "UEQ"), 
    ", UEEQ =", sum(ai_exposed$condition == "UEEQ"), "\n")
cat("Non-AI-exposed by condition: UEQ =", sum(no_ai_exposed$condition == "UEQ"), 
    ", UEEQ =", sum(no_ai_exposed$condition == "UEEQ"), "\n\n")

# The issue here is that this appears to be between-subjects for AI exposure too
# Let me check if the experiment design has interfaces with both AI and non-AI evaluations
# for the same participant

# Check the range of interfaces evaluated per participant
interface_pattern <- "^(\\d+)_U?E?E?Q"

# Count interfaces per participant
interface_counts <- completed_data %>%
  select(ResponseId, matches(interface_pattern)) %>%
  pivot_longer(cols = -ResponseId, names_to = "variable", values_to = "value") %>%
  filter(!is.na(value)) %>%
  extract(variable, c("interface_num", "condition_type"), "(\\d+)_U?(E?E?)Q") %>%
  count(ResponseId, interface_num) %>%
  count(ResponseId, name = "interfaces_completed")

cat("Interfaces completed per participant:\n")
print(table(interface_counts$interfaces_completed))
cat("\n")

# This suggests that the current experimental design does not have within-participant
# AI vs Human comparisons for individual interfaces. Instead, participants were
# exposed to either AI-enhanced evaluation data or traditional evaluation data
# across all their interfaces.

cat("CONCLUSION:\n")
cat("Based on the data structure, it appears that AI vs Human evaluation is also\n")
cat("a BETWEEN-SUBJECTS factor, not within-subjects. Participants were assigned to\n")
cat("receive either 'Combined AI-human evaluation' data or other types of evaluation\n")
cat("data for all their interface evaluations.\n\n")

cat("This means we should analyze AI vs Human differences using independent samples\n")
cat("methods, similar to the UEQ vs UEEQ analysis.\n\n")

# Prepare data for between-subjects AI vs Human analysis
if(nrow(ai_exposed) > 0 && nrow(no_ai_exposed) > 0) {
  cat("Proceeding with between-subjects AI vs Human analysis...\n")
  
  # Would need to restructure data for this analysis
  # Similar to the UEQ/UEEQ analysis but comparing AI-exposed vs non-AI-exposed participants
  
} else {
  cat("Insufficient data for AI vs Human comparison.\n")
  cat("Need participants in both AI-exposed and non-AI-exposed groups.\n")
}
