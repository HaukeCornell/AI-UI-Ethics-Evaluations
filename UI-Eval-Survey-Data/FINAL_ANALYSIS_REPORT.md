# FINAL ANALYSIS REPORT: UEQ vs UEQ+Autonomy with August 17 Data
## N=94 Participants, Rigorous Multiple Comparisons Correction

### EXECUTIVE SUMMARY

After comprehensive data validation and reprocessing with 44.6% larger sample size (N=94 vs N=65), we find **minimal differences** between UEQ and UEQ+Autonomy conditions, with **one notable exception**: Content Customization pattern.

### KEY FINDINGS

1. **Sample Improvement**: Successfully processed 94 of 104 valid participants (vs 65 previously)
   - Balanced conditions: UEQ (n=49), UEQ+Autonomy (n=45)
   - Fixed UTF-16 encoding issues and participant filtering problems

2. **Statistical Rigor**: Applied proper multiple comparisons correction
   - 15 interfaces × 2 measures = 30 statistical tests
   - FDR (False Discovery Rate) correction for multiple comparisons
   - Conservative Bonferroni correction as additional check

3. **Overall Result**: **UEQ and UEQ+Autonomy perform equivalently**
   - 14 of 15 interfaces show NO significant differences after correction
   - Previous "significant" findings in smaller sample were likely false positives
   - Confirms participant-level analysis showing minimal differences

4. **One Surviving Effect**: **Content Customization Pattern**
   - **Large effect size**: Cohen's d = 1.011
   - **Robust significance**: FDR-corrected p = 0.007
   - **Direction**: UEQ participants rate it as MORE ethically problematic (M=5.52) than UEQ+Autonomy (M=3.78)
   - **Interpretation**: Counter-intuitive finding suggests standard UEQ detects more ethical concerns

### DETAILED CONTENT CUSTOMIZATION FINDINGS

**Statistical Details:**
- t(48.4) = 3.743, p < 0.001, Cohen's d = 1.011 (large effect)
- UEQ: Mean = 5.52 (SD = 1.48), Rejection rate = 13.8%
- UEQ+Autonomy: Mean = 3.78 (SD = 1.95), Rejection rate = 40.7%

**Interpretation Considerations:**
1. **Counter-intuitive Direction**: Expected UEQ+Autonomy to show MORE concern for algorithmic personalization
2. **Possible Explanations**:
   - UEQ participants may interpret "content customization" as manipulation
   - UEQ+Autonomy participants may view personalization as autonomy-supporting
   - Autonomy framing may change how algorithmic customization is perceived

### IMPLICATIONS

1. **Measurement Equivalence**: UEQ and UEQ+Autonomy are largely equivalent for dark pattern assessment
2. **Specific Sensitivity**: Autonomy considerations specifically affect perception of algorithmic personalization
3. **Research Validity**: Both measures detect the same patterns except for this one interface
4. **Practical Recommendation**: Either measure is suitable for dark pattern research

### STATISTICAL POWER ANALYSIS

With N=94:
- **Improved Power**: 44.6% larger sample provides better statistical power
- **Conservative Testing**: Multiple comparisons correction prevents false positives
- **Robust Finding**: The surviving effect has large effect size and low p-value

### FILES GENERATED

1. `aug17_complete_statistical_results.csv` - All statistical test results with corrections
2. `interface_plot_data_aug17_final.csv` - Complete interface-level dataset (N=94)
3. `content_customization_effect.png` - Visualization of the significant effect
4. `participant_plot_data_aug17_final.csv` - Participant-level dataset

### CONCLUSION

**Primary Finding**: UEQ and UEQ+Autonomy are equivalent measures for dark pattern assessment, with one important exception for algorithmic personalization patterns.

**Methodological Note**: The larger sample size (N=94) with proper multiple comparisons correction provides more reliable results than the initial N=65 analysis.

**Future Research**: The Content Customization finding warrants replication and deeper investigation into how autonomy framing affects perception of algorithmic personalization.

---
*Analysis completed with R statistical software*  
*Multiple comparisons corrected using Benjamini-Hochberg FDR method*  
*Effect sizes calculated using Cohen's d*
