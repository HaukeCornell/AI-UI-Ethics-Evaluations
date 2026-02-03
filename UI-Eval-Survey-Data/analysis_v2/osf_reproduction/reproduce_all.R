# Master script to reproduce all figures in the paper

# 0. Check and install dependencies
packages <- c("dplyr", "readr", "tidyr", "ggplot2", "patchwork", "scales", "lme4", "car", "emmeans", "gridExtra", "effsize")
new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages, repos = "https://cloud.r-project.org")

cat("\n=== REPRODUCING ALL FIGURES FOR OSF DATA TRANSPARENCY ===\n")

# 1. Process data
source("scripts/01_process_data.R")

# 1b. Statistical Analysis (for ANOVA results used in later plots)
source("scripts/01b_statistical_analysis.R")

# 2. Generate Figure 7 (Participant Rejection)
source("scripts/04_fig_participant_rejection.R")

# 3. Generate Figure 8 (Release Tendency Line Plot)
source("scripts/05_fig_interface_trends.R")

# 4. Generate Enhanced Tendency Plot
source("scripts/02_fig_tendency_enhanced.R")

# 5. Generate Confidence Plot
source("scripts/03_fig_confidence.R")

# 6. Generate Appendix Grid (15 subplots)
source("scripts/06_fig_appendix_grid.R")

cat("\n✓ All figures successfully reproduced in the 'plots/' folder.\n")
