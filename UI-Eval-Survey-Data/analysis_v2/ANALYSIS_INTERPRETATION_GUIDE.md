# Three-Condition Analysis Summary: Understanding the Different Statistical Tests

## Overview
We have **three types of participants** and **two main statistical approaches**:

### Participant Groups:
1. **UEQ**: Participants who evaluated interfaces using standard UEQ (usability questionnaire)
2. **UEQ+Autonomy**: Participants who evaluated using UEQ + autonomy-specific questions  
3. **RAW**: Participants who saw interfaces without any evaluation framework (raw ratings)

## Statistical Approaches Used

### 1. Omnibus ANOVA (Three-way comparison)
- **What it tests**: Whether there are ANY differences among the three groups
- **File**: `plots/three_condition_rejection_comparison.png`, `plots/three_condition_tendency_comparison.png`
- **Statistical approach**: F-test comparing all three groups simultaneously
- **Interpretation**: Two-tailed test asking "Are these three groups different in some way?"
- **Results**: 9 interfaces significant for tendency differences

### 2. Planned Contrast (UEQ vs UEQ+Autonomy)
- **What it tests**: Specific directional hypothesis that UEQ+Autonomy < UEQ
- **File**: `plots/three_condition_tendency_violin_fdr_corrected.png`
- **Statistical approach**: Focused t-test between just UEQ and UEQ+Autonomy
- **Interpretation**: One-tailed test asking "Do UEQ+Autonomy participants rate dark patterns more critically?"
- **Results**: 6 interfaces significant for UEQ > UEQ+Autonomy

## Key Findings & Interpretation

### Pattern in the Data:
Looking at mean tendency scores, we consistently see:
**UEQ+Autonomy < RAW ≤ UEQ**

### What This Means:

1. **UEQ+Autonomy participants are most critical**: They consistently give the lowest acceptance scores to dark patterns
   - This supports the hypothesis that autonomy-focused evaluation makes people more aware of manipulative design

2. **UEQ participants are most accepting**: They give the highest scores
   - Standard usability evaluation may not sensitize people to ethical issues

3. **RAW participants are in the middle**: They often score between the two evaluation conditions
   - Without any evaluation framework, people have moderate sensitivity to dark patterns
   - This suggests that evaluation frameworks do influence perception

### Significant Interfaces (UEQ > UEQ+Autonomy):
1. **Content Customization** (d=1.02) - Large effect
2. **Endlessness** (d=0.73) - Medium-large effect  
3. **Trick Wording** (d=0.70) - Medium-large effect
4. **Hindering Account Deletion** (d=0.64) - Medium effect
5. **Pull to Refresh** (d=0.55) - Medium effect
6. **Social Pressure** (d=0.61) - Medium effect

## Methodological Notes

### Why Use Planned Contrasts?
- We had a specific directional hypothesis about UEQ vs UEQ+Autonomy
- More powerful than omnibus ANOVA for testing specific predictions
- Appropriate for one-tailed testing given theoretical justification

### Role of RAW Condition:
- **Not the primary comparison** - serves as important context
- Shows that evaluation frameworks matter (both UEQ conditions differ from RAW)
- Helps establish that effects aren't just due to any evaluation vs no evaluation

### Effect Sizes:
- Medium to large Cohen's d values (0.55-1.02) indicate practically meaningful differences
- These aren't just statistical artifacts but represent substantial differences in perception

## Implications:
1. **Autonomy-focused evaluation** makes people more sensitive to dark patterns
2. **Standard usability evaluation** may inadvertently increase tolerance for dark patterns
3. **Evaluation frameworks shape perception** - the act of evaluation itself influences how people see interfaces
4. **Six specific dark patterns** show this effect most strongly, suggesting some manipulative designs are more influenced by evaluation mindset than others
