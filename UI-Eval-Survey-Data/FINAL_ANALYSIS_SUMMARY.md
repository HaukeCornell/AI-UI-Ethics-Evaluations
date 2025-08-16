# FINAL ANALYSIS RESULTS: UEQ vs UEEQ Study

## Executive Summary

We conducted a between-subjects analysis comparing UEQ (standard metrics) vs UEEQ (ethics-enhanced metrics) conditions on interface rejection rates and tendency scores. Here are the key findings:

### Primary Results

**Rejection Rates:**
- UEQ: 46.3% rejection rate (SE: 3.1%)
- UEEQ: 51.7% rejection rate (SE: 3.1%) 
- Difference: 5.5 percentage points higher with UEEQ
- **Statistical significance: p = 0.214 (not significant)**
- Effect size: Cohen's d = 0.321 (small effect)

**Tendency Scores:**
- UEQ: 3.67 (SE: 0.13)
- UEEQ: 3.31 (SE: 0.12)
- Difference: -0.36 points (UEQ higher)
- **Statistical significance: p = 0.198 (not significant)**  
- Effect size: Cohen's d = -0.331 (small effect)

## Detailed Analysis

### Study Design Confirmed
- **Between-subjects design**: Different participants assigned to UEQ vs UEEQ conditions
- **Sample sizes**: UEQ = 32 participants, UEEQ = 29 participants  
- **No contamination**: 0 participants had responses in both conditions
- **Complete data**: All 61 participants had clear condition assignment
- **Interface coverage**: Each participant evaluated exactly 10 interfaces

### Statistical Analysis
- **Method**: Independent samples t-tests (Welch's correction for unequal variances)
- **Power**: With n=61 total, power to detect medium effects (d=0.5) ≈ 70%
- **Effect sizes**: Both outcomes showed small effects (|d| ≈ 0.3)

### Key Findings

#### 1. No Significant Differences
Neither rejection rates nor tendency scores showed statistically significant differences between UEQ and UEEQ conditions (both p > 0.19).

#### 2. Direction of Effects
- **Rejection rates**: UEEQ showed 5.5 percentage points higher rejection rate (directionally suggesting more critical evaluation with ethics-enhanced metrics)
- **Tendency scores**: UEQ showed higher tendency scores (directionally suggesting more positive evaluation with standard metrics)

#### 3. Effect Sizes
Both effects were in the "small" range (Cohen's d ≈ 0.3), suggesting:
- Effects may exist but are subtle
- Larger sample sizes might be needed to detect significance
- Practical significance may be limited

### Implications

#### For Research
1. **Ethics-enhanced metrics** do not dramatically alter evaluation outcomes
2. **Sample size considerations**: Current study may be underpowered for small effects
3. **Interface variation**: Individual interfaces may respond differently to metric types

#### For Practice
1. **Metric equivalence**: UEQ and UEEQ produce similar overall patterns
2. **Decision impact**: Choice of metric type unlikely to substantially change aggregate recommendations
3. **Subtle effects**: Small differences suggest nuanced rather than dramatic impacts

## Technical Notes

### Data Quality
- **Clean assignment**: Perfect separation between conditions (no mixed responses)
- **Balanced coverage**: Both groups evaluated same number of interfaces
- **Complete responses**: No systematic missing data patterns

### Statistical Assumptions
- **Independence**: Between-subjects design ensures independent observations
- **Normality**: t-tests robust with n>30 per group
- **Equal variances**: Welch's correction applied for robustness

### Limitations
1. **AI vs Human analysis**: Requires additional data on evaluation source assignment
2. **Interface selection**: Unknown whether current set represents optimal variety
3. **Power**: Study may be underpowered for detecting small but meaningful effects

## Next Steps

### Immediate
1. **AI vs Human analysis**: Obtain evaluation source mapping from Qualtrics
2. **Interface-level analysis**: Examine which interfaces show larger differences
3. **Power analysis**: Calculate required sample size for future studies

### Future Research
1. **Larger samples**: Target n≥80 per condition for adequate power
2. **Interface characteristics**: Analyze which design features predict larger differences  
3. **Individual differences**: Explore participant characteristics that moderate effects
4. **Validation**: Replicate findings with different interface sets

## Files Generated
- `fixed_final_analysis.R` - Complete analysis script
- `final_rejection_rates_comparison.png` - Rejection rate visualization  
- `final_tendency_scores_comparison.png` - Tendency score visualization

---

**Date**: August 16, 2025  
**Analysis**: Between-subjects comparison of UEQ vs UEEQ interface evaluation metrics  
**Sample**: 61 participants (32 UEQ, 29 UEEQ) × 10 interfaces each
