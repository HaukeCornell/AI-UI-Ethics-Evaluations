# jamovi Individual Interface Analysis - Results Template

## Testing Protocol
1. For each interface (1-15):
   - Run independent t-test for tendency (one-tailed: UEQ+Autonomy < UEQ)
   - Run chi-square test for rejection (one-tailed: UEQ+Autonomy > UEQ)
   - Record sample sizes, means, effect sizes, and p-values

## Results Table Template

| Interface | Pattern Name | N_UEQ | N_UEEQ | UEQ_Mean | UEEQ_Mean | t | p_onetailed | Cohen_d | UEQ_Reject% | UEEQ_Reject% | Chi2 | p_reject | Effect_Size |
|-----------|--------------|-------|--------|----------|-----------|---|-------------|---------|-------------|--------------|------|----------|-------------|
| 1 | Bad Defaults | | | | | | | | | | | | |
| 2 | Content Customization | | | | | | | | | | | | |
| 3 | Endlessness | | | | | | | | | | | | |
| 4 | Expectation Result Mismatch | | | | | | | | | | | | |
| 5 | False Hierarchy | | | | | | | | | | | | |
| 6 | Forced Access | | | | | | | | | | | | |
| 7 | Gamification | | | | | | | | | | | | |
| 8 | Hindering Account Deletion | | | | | | | | | | | | |
| 9 | Nagging | | | | | | | | | | | | |
| 10 | Overcomplicated Process | | | | | | | | | | | | |
| 11 | Pull to Refresh | | | | | | | | | | | | |
| 12 | Social Connector | | | | | | | | | | | | |
| 13 | Social Pressure | | | | | | | | | | | | |
| 14 | Toying with Emotion | | | | | | | | | | | | |
| 15 | Trick Wording | | | | | | | | | | | | |

## Multiple Comparison Corrections
After collecting all p-values:
1. Apply FDR correction (Benjamini-Hochberg)
2. Apply Holm correction  
3. Apply Bonferroni correction
4. Identify significant results at α = .05

## Expected Results (from R analysis)
Significant tendency effects (FDR corrected):
- Content Customization (UI 2): d = -1.21, p = 0.002
- Endlessness (UI 3): d = -0.71, p = 0.019
- Trick Wording (UI 15): d = -0.75, p = 0.019
- Social Pressure (UI 13): d = -0.74, p = 0.023
- Hindering Account Deletion (UI 8): d = -0.63, p = 0.027
- Pull to Refresh (UI 11): d = -0.61, p = 0.046

Significant rejection effects (FDR corrected):
- Content Customization (UI 2): h = 0.88, p = 0.041
- Trick Wording (UI 15): h = 0.77, p = 0.041
