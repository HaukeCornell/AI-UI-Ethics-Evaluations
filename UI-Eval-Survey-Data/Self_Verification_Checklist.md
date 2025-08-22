# Self-Verification Checklist for Statistical Analysis
## JAMOVI/JASP Replication Steps

### Data Preparation
1. **Export clean dataset**
   - Use: `results/clean_data_for_analysis.csv`
   - Variables needed: `PROLIFIC_PID`, `condition`, `avg_tendency`, `rejection_rate`
   - Sample sizes: UEQ (n=46), UEQ+Autonomy (n=37)

### Step 1: Descriptive Statistics
- [X] Calculate means and SDs by condition for both variables
- [X] Verify: UEQ tendency M=3.872, SD=1.253
- [X] Verify: UEQ+Autonomy tendency M=3.151, SD=0.967  
- [X] Verify: UEQ rejection M=43.3%, SD=20.3%
- [X] Verify: UEQ+Autonomy rejection M=53.5%, SD=18.9%

### Step 2: Assumption Testing
#### Normality Tests
- [X] Shapiro-Wilk test for UEQ tendency scores (expect p > 0.05)
- [ ] Shapiro-Wilk test for UEQ+Autonomy tendency scores (expect p > 0.05)
- [X] Shapiro-Wilk test for UEQ rejection rates (expect p > 0.05)
- [ ] Shapiro-Wilk test for UEQ+Autonomy rejection rates (expect p > 0.05)
- [X] Create Q-Q plots to visually inspect normality

#### Homogeneity of Variance
- [X] Levene's test for tendency scores (expect p > 0.05)
- [X] Levene's test for rejection rates (expect p > 0.05)

### Step 3: Primary Hypothesis Tests
#### H1: Release Tendency (UEQ+Autonomy < UEQ)
- [X] Independent samples t-test (one-tailed, UEQ > UEQ+Autonomy)
- [X] Expected results: t ≈ 2.87, df ≈ 81, p ≈ 0.003
- [X] Calculate Cohen's d (expect d ≈ 0.635)
- [ ] Verify 95% CI does not include 0

#### H2: Rejection Rate (UEQ+Autonomy > UEQ)  
- [X] Independent samples t-test (one-tailed, UEQ+Autonomy > UEQ)
- [X] Expected results: t ≈ 2.36, df ≈ 81, p ≈ 0.010
- [X] Calculate Cohen's d (expect d ≈ 0.52)
- [ ] Verify 95% CI does not include 0

### Step 4: Effect Size Interpretation
- [X] Tendency difference: d=0.635 (medium-large effect)
- [X] Rejection difference: d=0.52 (medium effect)
- [X] Both effects exceed Cohen's medium threshold (d ≥ 0.5)

### Step 5: Supplementary Analyses
- [X] Create boxplots/violin plots by condition
- [X] Check for outliers using boxplot method
- **No significant outliers detected, confirmed using scatter plots. Two participants with extreme rejection rate (0% and 100%) were retained as it reflects valid data.**
- [ ] ~~Consider Mann-Whitney U tests as non-parametric alternatives~~
- [ ] ~~Calculate exact p-values and confidence intervals~~

### Expected Discrepancies to Investigate
- Small differences in t-statistics due to rounding
- Slight variations in p-values (should be within 0.001)
- Software-specific handling of tied values
- Different default settings for one-tailed vs two-tailed tests

### Files to Use
- **Data**: `results/clean_data_for_analysis.csv`
- **Reference**: `results/statistical_analysis_results.csv`
- **R Script**: `scripts/statistical_analysis.R`

### Key Variables for JAMOVI/JASP
```
DV1: avg_tendency (continuous, 1-7 scale)
DV2: rejection_rate (continuous, 0-100 percentage)  
IV: condition (categorical: "UEQ" vs "UEQ+Autonomy")
```

### Quality Checks
- [X] Sample sizes match (total n=83)
- [X] No missing data in key variables
- [ ] Condition coding is correct
- [ ] Results replicate within acceptable margins
- [X] Effect directions match hypotheses (UEQ+Autonomy shows more conservative decisions)
