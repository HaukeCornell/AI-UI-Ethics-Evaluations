# UEQ vs UEEQ Analysis Results Summary

## Research Question
Do UEEQ (ethics-enhanced) metrics lead to significantly different interface rejection rates and tendency scores compared to UEQ (standard) metrics?

## Key Findings

### Rejection Rates
- **UEQ (standard metrics)**: 46.2% rejection rate  
- **UEEQ (enhanced metrics)**: 51.7% rejection rate
- **Difference**: 5.5 percentage points higher with UEEQ
- **Statistical significance**: Not significant (p = 0.202, OR = 1.25)

### Tendency Scores
- **UEQ mean**: 3.67 (SD: 2.42)
- **UEEQ mean**: 3.31 (SD: 2.21)  
- **Difference**: -0.36 points (UEQ higher)
- **Effect size**: Cohen's d = -0.155 (negligible)
- **Statistical significance**: Not significant (p = 0.197)

## Statistical Approach

### Design
- **Unit of analysis**: Response-level (610 total responses)
- **Study design**: Within-subjects (each participant evaluated both UEQ and UEEQ)
- **Participants**: 61 unique participants
- **Interfaces**: 15 different interfaces

### Methods
- **Rejection rates**: Logistic mixed-effects model with participant as random effect
- **Tendency scores**: Linear mixed-effects model with participant as random effect
- **Assumption checks**: Mixed-effects models account for clustering within participants

## Interpretation

### No Significant Difference
The analysis reveals **no statistically significant differences** between UEQ and UEEQ metrics for either:
1. Interface rejection rates (p = 0.202)
2. Tendency scores (p = 0.197)

### Effect Sizes
- The observed differences are small and practically negligible
- Cohen's d of -0.155 for tendency scores is well below the threshold for even a "small" effect (0.2)

### Confidence Intervals
- **Rejection rate difference**: The 95% CI for the odds ratio (1.25) includes 1.0, indicating no significant difference
- **Tendency difference**: The 95% CI includes 0, confirming no significant difference

## Interface-Level Patterns

Some interfaces showed larger differences between UEQ and UEEQ:
- **Interface 2**: 16.7% UEQ vs 43.8% UEEQ rejection (27.1 pp difference)
- **Interface 8**: 26.1% UEQ vs 63.6% UEEQ rejection (37.5 pp difference)  
- **Interface 15**: 13.0% UEQ vs 42.1% UEEQ rejection (29.1 pp difference)

However, others showed the opposite pattern:
- **Interface 4**: 66.7% UEQ vs 41.2% UEEQ rejection (25.5 pp difference)
- **Interface 10**: 72.7% UEQ vs 93.8% UEEQ rejection (21.1 pp difference)

## Implications

### For Research Design
1. **Metric type effect**: No evidence that ethics-enhanced metrics systematically change evaluation outcomes
2. **Individual interfaces**: Some interfaces may be more sensitive to metric type than others
3. **Power considerations**: The current sample may not be large enough to detect small but meaningful differences

### For Practice
1. **Evaluation equivalence**: UEQ and UEEQ appear to produce similar overall evaluation patterns
2. **Interface specificity**: The type of interface may moderate the effect of metric type
3. **Decision-making**: The choice between standard and ethics-enhanced metrics may not dramatically alter aggregate decision outcomes

## Next Steps

### Recommended Analyses
1. **AI vs Human comparison**: Analyze whether evaluation source (AI vs human data) shows different patterns
2. **Interface characteristics**: Examine which interface features predict larger UEQ-UEEQ differences
3. **Individual differences**: Explore participant characteristics that moderate metric type effects

### Methodological Considerations
1. **Power analysis**: Calculate required sample size for detecting meaningful effects
2. **Interface selection**: Consider whether the current interface set represents adequate variability
3. **Metric validation**: Examine whether UEEQ metrics actually capture ethical concerns as intended

## Data Quality Notes
- **Response rate**: Good coverage across participants and interfaces
- **Missing data**: Minimal missing responses after cleaning
- **Encoding issues**: Original file required UTF-16 to UTF-8 conversion
- **Statistical assumptions**: Mixed-effects models appropriately handle clustered data structure
