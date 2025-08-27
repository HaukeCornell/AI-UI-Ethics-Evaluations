# Fixed Demographics Analysis - UX Ethics Survey

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
               "Current Role", "Industry Experience", "Company Size", "Decision-Making Auth")

# Extract available demographics
demographics <- clean_raw %>%
  select(ResponseId, all_of(demo_cols))

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

for(col in demo_cols) {
  cat("\n", toupper(col), ":\n")
  summary_table <- create_summary(demographics, col)
  print(summary_table)
}

# Create key visualizations
if(!dir.exists("plots")) {
  dir.create("plots")
}

# Professional Experience (already 100% yes, skip)

# Experience Level
exp_data <- create_summary(demographics, "Experience Level")
p1 <- ggplot(exp_data, aes(x = "", y = Count, fill = `Experience Level`)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar("y", start = 0) +
  labs(title = "Years of Design Experience", fill = "Experience Level") +
  theme_void() +
  theme(plot.title = element_text(face = "bold", size = 14, hjust = 0.5))

# Ethics Encounter
ethics_data <- create_summary(demographics, "UI Ethics Experience")
p2 <- ggplot(ethics_data, aes(x = reorder(`UI Ethics Experience`, Count), y = Count, fill = `UI Ethics Experience`)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  coord_flip() +
  labs(title = "Encounter Ethically Questionable Designs", x = "", y = "Count") +
  theme_minimal() +
  theme(legend.position = "none", plot.title = element_text(face = "bold", size = 14))

# Current Role
role_data <- create_summary(demographics, "Current Role")
p3 <- ggplot(role_data, aes(x = reorder(`Current Role`, Count), y = Count, fill = `Current Role`)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  coord_flip() +
  labs(title = "Current Professional Role", x = "", y = "Count") +
  theme_minimal() +
  theme(legend.position = "none", plot.title = element_text(face = "bold", size = 14))

# Company Size
size_data <- create_summary(demographics, "Company Size")
p4 <- ggplot(size_data, aes(x = "", y = Count, fill = `Company Size`)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar("y", start = 0) +
  labs(title = "Company Size", fill = "Company Size") +
  theme_void() +
  theme(plot.title = element_text(face = "bold", size = 14, hjust = 0.5))

# Decision Authority
auth_data <- create_summary(demographics, "Decision-Making Auth")
p5 <- ggplot(auth_data, aes(x = reorder(`Decision-Making Auth`, Count), y = Count, fill = `Decision-Making Auth`)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  coord_flip() +
  labs(title = "Design Decision-Making Authority", x = "", y = "Count") +
  theme_minimal() +
  theme(legend.position = "none", plot.title = element_text(face = "bold", size = 14))

# Industry breakdown (top 10)
industry_data <- create_summary(demographics, "Industry Experience") %>%
  slice_head(n = 10)
p6 <- ggplot(industry_data, aes(x = reorder(`Industry Experience`, Count), y = Count, fill = `Industry Experience`)) +
  geom_bar(stat = "identity", alpha = 0.8) +
  coord_flip() +
  labs(title = "Industry Experience (Top 10)", x = "", y = "Count") +
  theme_minimal() +
  theme(legend.position = "none", plot.title = element_text(face = "bold", size = 14))

# Create combined plot
combined_plot <- grid.arrange(p1, p2, p3, p4, p5, p6, ncol = 2, nrow = 3,
                              top = paste("Participant Demographics (N =", length(clean_participant_ids), ")"))

# Save combined plot
ggsave("plots/demographics_complete_summary.png", combined_plot, 
       width = 16, height = 12, dpi = 300)

# Generate LaTeX summary
cat("\n", paste(rep("=", 60), collapse=""), "\n")
cat("LATEX METHODS SECTION - PARTICIPANT DEMOGRAPHICS\n")
cat(paste(rep("=", 60), collapse=""), "\n")

# Calculate key statistics
n_total <- length(clean_participant_ids)

# Experience level
exp_seasoned <- exp_data %>% 
  filter(!grepl("Less than 1 year", `Experience Level`)) %>% 
  pull(Count) %>% sum()

# Ethics encounter
ethics_frequent <- ethics_data %>% 
  filter(grepl("Often|Very often|Sometimes", `UI Ethics Experience`)) %>% 
  pull(Count) %>% sum()

# Decision authority
has_authority <- auth_data %>% 
  filter(grepl("Yes", `Decision-Making Auth`)) %>% 
  pull(Count) %>% sum()

# Company size distribution
startup_small <- size_data %>% 
  filter(grepl("Startup|Small", `Company Size`)) %>% 
  pull(Count) %>% sum()

latex_text <- sprintf(
"\\textbf{Participants.} We recruited N = %d participants through Prolific Academic, all with professional experience in UI/UX design, product design, or design decision-making roles. The majority had substantial professional experience: %.1f%% with 3-5 years and %.1f%% with 1-2 years of design experience, indicating a sample with relevant domain expertise for interface evaluation.

\\textbf{Professional Context and Expertise.} Importantly, %d participants (%.1f%%) reported having decision-making authority in their current roles (final decision authority or significant influence), ensuring our sample included individuals who actively engage in design decision-making processes. Additionally, %d participants (%.1f%%) regularly encounter ethically questionable designs in their professional work (sometimes, often, or very often), supporting the ecological validity of our findings. Participants were primarily UX/UI Designers (%.1f%%) working across diverse company sizes, with %.1f%% in startups or small companies and %.1f%% in medium to large organizations, representing typical industry contexts where design decisions are made.",
n_total,
exp_data$Percentage[exp_data$`Experience Level` == "3-5 years"],
exp_data$Percentage[exp_data$`Experience Level` == "1-2 years"],
has_authority, has_authority/n_total*100,
ethics_frequent, ethics_frequent/n_total*100,
role_data$Percentage[role_data$`Current Role` == "UX/UI Designer"],
startup_small/n_total*100,
100 - startup_small/n_total*100
)

cat(latex_text)

# Save results
write.csv(demographics, "results/participant_demographics.csv", row.names = FALSE)

cat("\n\nFiles created:\n")
cat("• plots/demographics_complete_summary.png - Combined demographic visualization\n")
cat("• results/participant_demographics.csv - Raw demographic data\n")

cat("\n✓ Demographics analysis complete!\n")
