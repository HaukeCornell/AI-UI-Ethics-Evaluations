# OSF Reproduction Package: AI UI Ethics Evaluations

This folder contains the data and scripts necessary to replicate the figures in the paper "How Evaluation Metrics Shape Designer Sensitivity to Dark Patterns".

## Folder Structure
- `data/`: Raw survey data (tsv) and participant exclusion list (csv).
- `scripts/`: R scripts for each figure (01-06).
- `results/`: Processed data files (populated by running scripts).
- `plots/`: Generated figures (populated by running scripts).
- `reproduce_all.R`: Master script to run the entire pipeline.

## Prerequisites
- R (tested on version 4.2+)
- Required R packages: `dplyr`, `readr`, `tidyr`, `ggplot2`, `patchwork`, `scales`, `lme4`, `car`, `emmeans`

## How to Reproduce
Simply open R or RStudio in this folder and run:
```r
source("reproduce_all.R")
```
This will:
1. Install any missing packages.
2. Clean and process the raw data.
3. Generate all figures in the `plots/` folder.

## Key Figures Mapping
- **Figure 7**: `plots/participant_rejection_publication_ready.png`
- **Figure 8**: `plots/interface_rejection_trends_sorted.png`
- **Enhanced Tendency**: `plots/per_evaluation_tendency_analysis_enhanced.png`
- **Confidence**: `plots/confidence_analysis_enhanced.png` (from scripts/03)
- **Appendix Grid**: `plots/three_condition_tendency_violin_fdr_corrected.png`
