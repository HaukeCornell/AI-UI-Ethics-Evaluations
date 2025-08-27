# Simplified Demographics Analysis - UX Ethics Survey

library(dplyr)
library(ggplot2)
library(readr)
library(gridExtra)

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

# Get the actual demographic columns that exist
demo_cols <- c("Professional Experie", "Experience Level", "UI Ethics Experience", 
               "Dark Pattern Exp.", "Current Role", "Industry Experience", 
               "Company Size", "Decision-Making Auth")

# Check which columns exist
existing_cols <- demo_cols[demo_cols %in% names(clean_raw)]
cat("Found columns:", paste(existing_cols, collapse = ", "), "\n")

# Extract available demographics
demographics <- clean_raw %>%
  select(ResponseId, all_of(existing_cols))

# Create summary function
create_summary <- function(data, col_name) {
  data %>%
    filter(!is.na(.data[[col_name]]) & .data[[col_name]] != "") %>%
    count(.data[[col_name]], name = "Count") %>%
    mutate(Percentage = round(Count / sum(Count) * 100, 1)) %>%
    arrange(desc(Count))
}

# Generate summaries
cat("\n=== DEMOGRAPHIC SUMMARIES ===\n")

for(col in existing_cols) {
  cat("\n", toupper(col), ":\n")
  summary_table <- create_summary(demographics, col)
  print(summary_table)
}

# Create key visualizations
if(!dir.exists("plots")) {
  dir.create("plots")
}

colors <- c("#3498db", "#e74c3c", "#2ecc71", "#f39c12", "#9b59b6", "#1abc9c", "#34495e", "#95a5a6")

# Professional Experience
if("Professional Experie" %in% existing_cols) {
  prof_data <- create_summary(demographics, "Professional Experie")
  p1 <- ggplot(prof_data, aes(x = reorder(`Professional Experie`, Count), y = Count, fill = `Professional Experie`)) +
    geom_bar(stat = "identity", alpha = 0.8) +
    coord_flip() +
    labs(title = "Professional UX/UI Experience", x = "", y = "Count") +
    theme_minimal() +
    theme(legend.position = "none", plot.title = element_text(face = "bold", size = 14))
}

# Experience Level
if("Experience Level" %in% existing_cols) {
  exp_data <- create_summary(demographics, "Experience Level")
  p2 <- ggplot(exp_data, aes(x = "", y = Count, fill = `Experience Level`)) +
    geom_bar(stat = "identity", width = 1) +
    coord_polar("y", start = 0) +
    labs(title = "Years of Design Experience", fill = "Experience Level") +
    theme_void() +
    theme(plot.title = element_text(face = "bold", size = 14, hjust = 0.5))
}

# Ethics Encounter
if("UI Ethics Experience" %in% existing_cols) {
  ethics_data <- create_summary(demographics, "UI Ethics Experience")
  p3 <- ggplot(ethics_data, aes(x = reorder(`UI Ethics Experience`, Count), y = Count, fill = `UI Ethics Experience`)) +
    geom_bar(stat = "identity", alpha = 0.8) +
    coord_flip() +
    labs(title = "Encounter Ethically Questionable Designs", x = "", y = "Count") +
    theme_minimal() +
    theme(legend.position = "none", plot.title = element_text(face = "bold", size = 14))
}

# Dark Pattern Familiarity
if("Dark Pattern Exp." %in% existing_cols) {
  dp_data <- create_summary(demographics, "Dark Pattern Exp.")
  p4 <- ggplot(dp_data, aes(x = "", y = Count, fill = `Dark Pattern Exp.`)) +
    geom_bar(stat = "identity", width = 1) +
    coord_polar("y", start = 0) +
    labs(title = "Dark Pattern Familiarity", fill = "Familiarity Level") +
    theme_void() +
    theme(plot.title = element_text(face = "bold", size = 14, hjust = 0.5))
}

# Current Role
if("Current Role" %in% existing_cols) {
  role_data <- create_summary(demographics, "Current Role")
  p5 <- ggplot(role_data, aes(x = reorder(`Current Role`, Count), y = Count, fill = `Current Role`)) +
    geom_bar(stat = "identity", alpha = 0.8) +
    coord_flip() +
    labs(title = "Current Professional Role", x = "", y = "Count") +
    theme_minimal() +
    theme(legend.position = "none", plot.title = element_text(face = "bold", size = 14))
}

# Decision Authority
if("Decision-Making Auth" %in% existing_cols) {
  auth_data <- create_summary(demographics, "Decision-Making Auth")
  p6 <- ggplot(auth_data, aes(x = reorder(`Decision-Making Auth`, Count), y = Count, fill = `Decision-Making Auth`)) +
    geom_bar(stat = "identity", alpha = 0.8) +
    coord_flip() +
    labs(title = "Design Decision-Making Authority", x = "", y = "Count") +
    theme_minimal() +
    theme(legend.position = "none", plot.title = element_text(face = "bold", size = 14))
}

# Create combined plot
plots_list <- list()
if(exists("p1")) plots_list <- append(plots_list, list(p1))
if(exists("p2")) plots_list <- append(plots_list, list(p2))
if(exists("p3")) plots_list <- append(plots_list, list(p3))
if(exists("p4")) plots_list <- append(plots_list, list(p4))
if(exists("p5")) plots_list <- append(plots_list, list(p5))
if(exists("p6")) plots_list <- append(plots_list, list(p6))

if(length(plots_list) >= 6) {
  combined_plot <- grid.arrange(grobs = plots_list[1:6], ncol = 2, nrow = 3,
                               top = paste("Participant Demographics (N =", length(clean_participant_ids), ")"))
} else {
  combined_plot <- grid.arrange(grobs = plots_list, ncol = 2,
                               top = paste("Participant Demographics (N =", length(clean_participant_ids), ")"))
}

# Save combined plot
ggsave("plots/demographics_complete_summary.png", combined_plot, 
       width = 16, height = 12, dpi = 300)

# Generate LaTeX summary
cat("\n", paste(rep("=", 60), collapse=""), "\n")
cat("LATEX METHODS SECTION - PARTICIPANT DEMOGRAPHICS\n")
cat(paste(rep("=", 60), collapse=""), "\n")

# Calculate key statistics
n_total <- length(clean_participant_ids)

# Professional experience
prof_yes <- demographics %>% 
  filter(!is.na(`Professional Experie`) & `Professional Experie` == "Yes") %>% 
  nrow()

# Experience level
exp_data <- create_summary(demographics, "Experience Level")
exp_seasoned <- exp_data %>% 
  filter(!grepl("Less than 1 year", `Experience Level`)) %>% 
  pull(Count) %>% sum()

# Ethics encounter
ethics_data <- create_summary(demographics, "UI Ethics Experience")
ethics_frequent <- ethics_data %>% 
  filter(grepl("Often|Very often|Sometimes", `UI Ethics Experience`)) %>% 
  pull(Count) %>% sum()

# Dark pattern awareness
dp_data <- create_summary(demographics, "Dark Pattern Exp.")
dp_aware <- dp_data %>% 
  filter(!grepl("Not familiar|Never heard", `Dark Pattern Exp.`)) %>% 
  pull(Count) %>% sum()

# Decision authority
auth_data <- create_summary(demographics, "Decision-Making Auth")
has_authority <- auth_data %>% 
  filter(grepl("Full|Some", `Decision-Making Auth`)) %>% 
  pull(Count) %>% sum()

latex_text <- sprintf(
"\\textbf{Participants.} We recruited N = %d participants through Prolific Academic, all with professional experience in UI/UX design, product design, or design decision-making roles. The majority (%d participants, %.1f%%) had more than one year of professional design experience, with %.1f%% having 3-5 years and %.1f%% having 1-2 years of experience. This indicates a sample with substantial domain expertise relevant to interface design evaluation.

\\textbf{Professional Context and Expertise.} Importantly, %d participants (%.1f%%) reported having either full or some authority to make final decisions about interface designs in their current roles, ensuring our sample included individuals who actively engage in design decision-making processes. Additionally, %d participants (%.1f%%) regularly encounter ethically questionable designs in their professional work (sometimes, often, or very often), and %d participants (%.1f%%) indicated familiarity with dark patterns. This professional profile supports the ecological validity of our findings for understanding how UX evaluation metrics influence real-world design decisions among practicing designers.",
n_total, exp_seasoned, exp_seasoned/n_total*100,
exp_data$Percentage[exp_data$`Experience Level` == "3-5 years"],
exp_data$Percentage[exp_data$`Experience Level` == "1-2 years"],
has_authority, has_authority/n_total*100,
ethics_frequent, ethics_frequent/n_total*100,
dp_aware, dp_aware/n_total*100
)

cat(latex_text)

# Save results
write.csv(demographics, "results/participant_demographics.csv", row.names = FALSE)

cat("\n\nFiles created:\n")
cat("• plots/demographics_complete_summary.png - Combined demographic visualization\n")
cat("• results/participant_demographics.csv - Raw demographic data\n")

cat("\n✓ Demographics analysis complete!\n")
