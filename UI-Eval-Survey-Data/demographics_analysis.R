# Demographics Analysis - UX Et# Extract demographic variables with their exact column names
demographic_vars <- list(
  professional_exp = "Professional Experie",
  experience_level = "Experience Level", 
  ethics_encounter = "UI Ethics Experience",
  dark_pattern_familiarity = "Dark Pattern Exp. ",
  org_ai_support = "Organizational Suppo_1",
  current_role = "Current Role",
  industry = "Industry Experience", 
  company_size = "Company Size",
  decision_authority = "Decision-Making Auth"
)
# Analysis of participant professional background and expertise

library(dplyr)
library(ggplot2)
library(readr)
library(gridExtra)
library(scales)

cat("=== UX ETHICS SURVEY DEMOGRAPHICS ANALYSIS ===\n")

# Load the processed interface data to get clean participant list
interface_data <- read.csv("results/interface_plot_data_aug16_plus_new_filtered.csv")
clean_participant_ids <- unique(interface_data$ResponseId)

cat("Clean participants for analysis: N =", length(clean_participant_ids), "\n")

# Load raw data to extract demographics
raw_data <- read_tsv("aug17_utf8.tsv", show_col_types = FALSE)

# Clean the raw data
clean_raw <- raw_data %>%
  filter(
    !is.na(ResponseId),
    !grepl("Response ID|ImportId|Understanding How User", ResponseId, ignore.case = TRUE),
    !ResponseId %in% c("Response ID", "{\"ImportId\":\"_recordId\"}")
  ) %>%
  filter(ResponseId %in% clean_participant_ids)

cat("Matched demographic data for", nrow(clean_raw), "participants\n")

# Extract demographic variables with their exact column names
demographic_vars <- list(
  professional_exp = "Professional Experie",
  experience_level = "Experience Level", 
  ethics_encounter = "UI Ethics Experience",
  dark_pattern_familiarity = "Dark Pattern Exp. ",
  current_role = "Current Role",
  industry = "Industry Experience", 
  company_size = "Company Size",
  decision_authority = "Decision-Making Auth"
)

# Check which columns actually exist
existing_vars <- list()
for(var_name in names(demographic_vars)) {
  col_name <- demographic_vars[[var_name]]
  if(col_name %in% names(clean_raw)) {
    existing_vars[[var_name]] <- col_name
  } else {
    # Try without trailing space for dark pattern
    if(var_name == "dark_pattern_familiarity") {
      alt_name <- "Dark Pattern Exp."
      if(alt_name %in% names(clean_raw)) {
        existing_vars[[var_name]] <- alt_name
      }
    }
    # Try alternative for organizational support
    if(var_name == "org_ai_support") {
      alt_name <- "Organizational Suppo_1"
      if(alt_name %in% names(clean_raw)) {
        existing_vars[[var_name]] <- alt_name
      }
    }
  }
}

demographic_vars <- existing_vars

# Create demographic summary
demographics <- clean_raw %>%
  select(ResponseId, all_of(unlist(demographic_vars)))

# Rename columns for easier handling
names(demographics) <- c("ResponseId", names(demographic_vars))

cat("\n=== DEMOGRAPHIC SUMMARIES ===\n")

# Function to create summary table
create_summary <- function(data, var_name, title) {
  summary_table <- data %>%
    filter(!is.na(.data[[var_name]]) & .data[[var_name]] != "") %>%
    count(.data[[var_name]], name = "Count") %>%
    mutate(Percentage = round(Count / sum(Count) * 100, 1)) %>%
    arrange(desc(Count))
  
  cat("\n", title, ":\n")
  print(summary_table)
  
  return(summary_table)
}

# Create summaries for each variable
summaries <- list()
summaries$professional_exp <- create_summary(demographics, "professional_exp", "Professional Experience")
summaries$experience_level <- create_summary(demographics, "experience_level", "Experience Level")
summaries$ethics_encounter <- create_summary(demographics, "ethics_encounter", "UI Ethics Encounter Frequency")
summaries$dark_pattern_familiarity <- create_summary(demographics, "dark_pattern_familiarity", "Dark Pattern Familiarity")

# Skip organizational AI support - not needed for analysis

summaries$current_role <- create_summary(demographics, "current_role", "Current Role")
summaries$industry <- create_summary(demographics, "industry", "Industry Experience")
summaries$company_size <- create_summary(demographics, "company_size", "Company Size")

# Add decision authority if it exists - with proper ordering
if("decision_authority" %in% names(demographics)) {
  decision_data <- demographics %>%
    filter(!is.na(decision_authority) & decision_authority != "") %>%
    count(decision_authority, name = "Count") %>%
    mutate(Percentage = round(Count / sum(Count) * 100, 1))
  
  # Create proper ordering for decision authority
  decision_order <- c("Yes, final decision authority", "Yes, significant influence", 
                     "Some input", "Little input", "No decision authority")
  
  # Reorder the data and include missing categories
  decision_summary <- data.frame(
    decision_authority = decision_order,
    stringsAsFactors = FALSE
  ) %>%
    left_join(decision_data, by = "decision_authority") %>%
    mutate(
      Count = ifelse(is.na(Count), 0, Count),
      Percentage = ifelse(is.na(Percentage), 0, Percentage)
    ) %>%
    filter(Count > 0 | decision_authority %in% c("Yes, final decision authority", "Yes, significant influence", 
                                                 "Some input", "Little input"))  # Show relevant categories
  
  cat("\nDECISION-MAKING AUTHORITY:\n")
  print(decision_summary)
  
  summaries$decision_authority <- decision_summary
}

# Create visualizations
if(!dir.exists("plots")) {
  dir.create("plots")
}

# Color palette
colors <- c("#3498db", "#e74c3c", "#2ecc71", "#f39c12", "#9b59b6", "#1abc9c", "#34495e", "#95a5a6")

# Create individual plots
plots <- list()

# Professional Experience
plots$prof_exp <- ggplot(summaries$professional_exp, aes(x = reorder(professional_exp, Count), y = Count, fill = professional_exp)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  scale_fill_manual(values = colors[1:nrow(summaries$professional_exp)]) +
  coord_flip() +
  labs(title = "Professional UX/UI Experience", x = "", y = "Count") +
  theme_minimal() +
  theme(legend.position = "none", plot.title = element_text(face = "bold", size = 12))

# Experience Level
plots$exp_level <- ggplot(summaries$experience_level, aes(x = "", y = Count, fill = experience_level)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar("y", start = 0) +
  scale_fill_manual(values = colors[1:nrow(summaries$experience_level)]) +
  labs(title = "Years of Design Experience", fill = "Experience Level") +
  theme_void() +
  theme(plot.title = element_text(face = "bold", size = 12, hjust = 0.5))

# Ethics Encounter Frequency
plots$ethics <- ggplot(summaries$ethics_encounter, aes(x = reorder(ethics_encounter, Count), y = Count, fill = ethics_encounter)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  scale_fill_manual(values = colors[1:nrow(summaries$ethics_encounter)]) +
  coord_flip() +
  labs(title = "Encounter Ethically Questionable Designs", x = "", y = "Count") +
  theme_minimal() +
  theme(legend.position = "none", plot.title = element_text(face = "bold", size = 12))

# Dark Pattern Familiarity - with proper ordering
dp_order <- c("Very familiar", "Somewhat familiar", "Slightly familiar", "Not familiar")
dp_data <- summaries$dark_pattern_familiarity %>%
  mutate(dark_pattern_familiarity = factor(dark_pattern_familiarity, levels = dp_order)) %>%
  arrange(dark_pattern_familiarity)

plots$dark_patterns <- ggplot(dp_data, aes(x = "", y = Count, fill = dark_pattern_familiarity)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar("y", start = 0) +
  scale_fill_manual(values = colors[1:nrow(dp_data)]) +
  labs(title = "Dark Pattern Familiarity", fill = "Familiarity Level") +
  theme_void() +
  theme(plot.title = element_text(face = "bold", size = 12, hjust = 0.5))

# Skip organizational AI support visualization - not needed

# Current Role
plots$role <- ggplot(summaries$current_role, aes(x = reorder(current_role, Count), y = Count, fill = current_role)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  scale_fill_manual(values = colors[1:nrow(summaries$current_role)]) +
  coord_flip() +
  labs(title = "Current Professional Role", x = "", y = "Count") +
  theme_minimal() +
  theme(legend.position = "none", plot.title = element_text(face = "bold", size = 12))

# Decision Authority (if available) - with proper ordering
if("decision_authority" %in% names(summaries)) {
  auth_data <- summaries$decision_authority %>%
    mutate(decision_authority = factor(decision_authority, 
                                     levels = c("Yes, final decision authority", "Yes, significant influence", 
                                               "Some input", "Little input", "No decision authority")))
  
  plots$authority <- ggplot(auth_data, aes(x = decision_authority, y = Count, fill = decision_authority)) +
    geom_bar(stat = "identity", alpha = 0.8) +
    scale_fill_manual(values = colors[1:nrow(auth_data)]) +
    coord_flip() +
    labs(title = "Design Decision-Making Authority", x = "", y = "Count") +
    theme_minimal() +
    theme(legend.position = "none", plot.title = element_text(face = "bold", size = 12))
} else {
  plots$authority <- NULL
}

# Create combined visualization - clean 2x2 layout
combined_plot <- grid.arrange(
  plots$exp_level, plots$dark_patterns,
  plots$ethics, plots$authority,
  ncol = 2, nrow = 2,
  top = paste("Participant Demographics (N =", length(clean_participant_ids), ")")
)

# Save combined plot
ggsave("plots/demographics_complete_summary.png", combined_plot, 
       width = 16, height = 12, dpi = 300)

# Save individual plots
ggsave("plots/demographics_experience_level.png", plots$exp_level, width = 8, height = 6, dpi = 300)
ggsave("plots/demographics_ethics_encounter.png", plots$ethics, width = 10, height = 6, dpi = 300)
ggsave("plots/demographics_dark_patterns.png", plots$dark_patterns, width = 8, height = 6, dpi = 300)
ggsave("plots/demographics_ai_support.png", plots$ai_support, width = 10, height = 6, dpi = 300)
ggsave("plots/demographics_current_role.png", plots$role, width = 10, height = 6, dpi = 300)
if(!is.null(plots$authority)) {
  ggsave("plots/demographics_decision_authority.png", plots$authority, width = 10, height = 6, dpi = 300)
}

# Generate LaTeX summary paragraphs
cat("\n", paste(rep("=", 60), collapse=""), "\n")
cat("LATEX METHODS SECTION - PARTICIPANT DEMOGRAPHICS\n")
cat(paste(rep("=", 60), collapse=""), "\n")

# Calculate key statistics
n_total <- length(clean_participant_ids)
n_professional <- summaries$professional_exp %>% filter(grepl("Yes", professional_exp)) %>% pull(Count) %>% sum()
n_experienced <- summaries$experience_level %>% filter(!grepl("Less than 1 year|No experience", experience_level)) %>% pull(Count) %>% sum()
n_decision_makers <- summaries$decision_authority %>% 
  filter(grepl("Yes", decision_authority)) %>% 
  pull(Count) %>% sum()

# Most common role
top_role <- summaries$current_role %>% slice(1) %>% pull(current_role)
top_role_pct <- summaries$current_role %>% slice(1) %>% pull(Percentage)

# Dark pattern awareness
aware_dp <- summaries$dark_pattern_familiarity %>% filter(!grepl("Not familiar|Never heard", dark_pattern_familiarity)) %>% pull(Count) %>% sum()

latex_text <- paste0(
"\\textbf{Participants.} We recruited N = ", n_total, " participants through Prolific Academic, focusing on individuals with design-related professional backgrounds. ",
"Of these participants, ", n_professional, " (", round(n_professional/n_total*100, 1), "\\%) reported having professional experience in UI/UX design, product design, or design decision-making roles. ",
"The majority (", n_experienced, ", ", round(n_experienced/n_total*100, 1), "\\%) had more than one year of professional design experience, indicating a sample with substantial domain expertise. ",
"Participants represented diverse professional roles, with ", top_role, " being the most common (", top_role_pct, "\\%).\n\n",

"\\textbf{Professional Context.} Importantly, ", n_decision_makers, " participants (", round(n_decision_makers/n_total*100, 1), "\\%) reported having either full or some authority to make final decisions about interface designs in their current roles, ",
"ensuring our sample included individuals who actively engage in design decision-making processes. ",
"Additionally, ", aware_dp, " participants (", round(aware_dp/n_total*100, 1), "\\%) indicated familiarity with dark patterns, ",
"suggesting appropriate background knowledge for evaluating ethically questionable interface designs. ",
"This professional profile supports the ecological validity of our findings for understanding how UX evaluation metrics influence real-world design decisions."
)

cat(latex_text)

# Save results
write.csv(demographics, "results/participant_demographics.csv", row.names = FALSE)

# Save summary statistics
summary_stats <- data.frame(
  Metric = c("Total Participants", "Professional Experience", "1+ Years Experience", 
            "Decision Authority", "Dark Pattern Awareness"),
  Count = c(n_total, n_professional, n_experienced, n_decision_makers, aware_dp),
  Percentage = c(100, round(c(n_professional, n_experienced, n_decision_makers, aware_dp)/n_total*100, 1))
)

write.csv(summary_stats, "results/demographic_summary_stats.csv", row.names = FALSE)

cat("\n\nFiles created:\n")
cat("• plots/demographics_complete_summary.png - Combined demographic visualization\n")
cat("• plots/demographics_*.png - Individual demographic charts\n")
cat("• results/participant_demographics.csv - Raw demographic data\n")
cat("• results/demographic_summary_stats.csv - Summary statistics\n")

cat("\n✓ Demographics analysis complete!\n")
