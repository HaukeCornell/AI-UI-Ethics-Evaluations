library(dplyr)
data <- read.csv('results/participant_screening_with_text_and_variance.csv')
complete_data <- data %>% filter(interfaces_evaluated > 0)

cat('=== POTENTIALLY CONCERNING RESPONSE PATTERNS ===\n\n')

cat('Participants with very short explanations (avg < 20 chars):\n')
short_responses <- complete_data %>% 
  filter(avg_char_count < 20) %>%
  select(PROLIFIC_PID, condition, avg_char_count, total_characters, rejection_rate) %>%
  arrange(avg_char_count)
print(short_responses)

cat('\nParticipants with very long explanations (avg > 300 chars):\n')
long_responses <- complete_data %>% 
  filter(avg_char_count > 300) %>%
  select(PROLIFIC_PID, condition, avg_char_count, total_characters, rejection_rate) %>%
  arrange(desc(avg_char_count))
print(long_responses)

cat('\nParticipants with very low variance (< 100 - potentially repetitive):\n')
low_variance <- complete_data %>% 
  filter(var_char_count < 100, !is.na(var_char_count)) %>%
  select(PROLIFIC_PID, condition, avg_char_count, var_char_count, rejection_rate) %>%
  arrange(var_char_count)
print(low_variance)

cat('\nParticipants with very high variance (> 10000 - potentially inconsistent):\n')
high_variance <- complete_data %>% 
  filter(var_char_count > 10000, !is.na(var_char_count)) %>%
  select(PROLIFIC_PID, condition, avg_char_count, var_char_count, rejection_rate) %>%
  arrange(desc(var_char_count))
print(high_variance)
