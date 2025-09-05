# Visual Paper Summary Description: Multi-Stage Dark Pattern Ethics Evaluation Study

## Overview
This study investigated how ethical information in user experience evaluation data influences UX designers' decisions to release interfaces containing dark patterns. The research employed a multi-stage approach combining social media user evaluation, taxonomy development, and designer decision-making assessment.

## Stage 1: Social Media User Evaluation (Foundation Study)
**Participants**: N = 126 social media users  
**Task**: Evaluated 5 randomized dark patterns using adapted UEQ+Autonomy scale  
**Pattern Source**: 15 social media dark patterns derived from literature-based taxonomy  
**Evaluation Framework**: Extended User Experience Questionnaire (UEQ) with embedded autonomy items  

### Methodology Details:
- **Pattern Generation**: Dark pattern experts reviewed academic taxonomies to develop 15 social media-specific dark patterns across 6 strategic categories
- **Autonomy Integration**: Four new autonomy-focused evaluation items added to standard UEQ (pressuring/suggesting, addictive/non-addictive, covert/transparent, deceptive/benevolent)
- **Randomization**: Each participant evaluated 5 randomly selected patterns from the full set of 15
- **Scale**: 7-point semantic differential scales (-3 to +3) for all evaluation dimensions
- **Recruitment**: Convenience sampling through social media platforms and survey exchanges

### Key Findings from Stage 1:
- Dark patterns perceived as pressuring, annoying, and unfriendly and deceptive. Additionally, three social engineering patterns were rated as addictive.
- "Forced Access" rated worst among all pattern types

## Stage 2: Designer Decision-Making Evaluation (Main Study)
**Participants**: N = 141 UX design professionals  
**Conditions**: Three between-subjects experimental conditions  
**Task**: Evaluate 10 randomized dark pattern interfaces for release decisions

### Experimental Design:
**Condition 1 - UI** (n = 45): Interface baseline - No evaluation data provided (baseline control)  
**Condition 2 - UEQ** (n = 49): User experience evaluation - Standard UEQ evaluation, Gauge with average and table with per item evaluation data  
**Condition 3 - UEQ-A** (n = 47): User experience + autonomy evaluation - UEQ plus autonomy-focused evaluation data, represented as a risk indicator gauge and detailed table

### Interface Presentation:
- **Business Context**: "✓ Business approved | ✓ Marketing approved | ✓ Supervisor approved | **Awaiting your final design approval**"
- **Visual Mockups**: 10 dark pattern interfaces randomly selected from 15-interface pool
- **Evaluation Data**: Presented as results from [N] human participant evaluations"
- **Gauges & Metrics**: Visual dashboard showing UEQ scores and (when applicable) autonomy risk indicators

### Dependent Measures:
1. **Binary Release Decision**: "Would you release this interface design?"
   - Options: Yes / No

2. **Release Tendency**: "How likely would you be to release this interface design?"
   - Scale: 1 (Definitely would not release) to 7 (Definitely would release)

3. **Open Reasoning**: Explanation for decision (Required text response)

### Pattern Categories Evaluated:
- **Dark Pattern Examples**: All from a merge of three social media taxonomies
  - Sneaking, Obstruction, Interface Interference, Forced Action, Social Engineering, Nagging

## Key Statistical Results:
### Primary Outcome - Rejection Rates:
- **UI condition**: 30.0% rejection rate
- **UEQ condition**: 43.9% rejection rate  
- **UEQ-A condition**: 56.2% rejection rate
- **Statistical Significance**: F(2,138) = 15.97, p < 0.001, η² = 0.19 (large effect)

### Secondary Outcome - Release Tendency:
- **UI condition**: M = 4.66 (moderate willingness to release)
- **UEQ condition**: M = 4.13 (reduced willingness)
- **UEQ-A condition**: M = 3.57 (lowest willingness to release)  
- **Statistical Significance**: F(2,138) = 16.61, p < 0.001, η² = 0.19 (large effect)

### Post-hoc Comparisons:
All pairwise comparisons significant (Tukey HSD, all p < 0.001):
- UI vs UEQ: Large effect size (Cohen's d = 1.20)
- UEQ vs UEQ-A: Large effect size (Cohen's d = 1.13)  
- UI vs UEQ-A: Very large effect size (Cohen's d = 1.68)

## Visual Figure Elements for Publication:

### Panel A: Foundation Study Flow
- **126 social media users** → **5 random dark patterns each** → **UEQ+Autonomy evaluation** → **Pattern perception database**

### Panel B: Taxonomy Development  
- **Literature review** → **Expert consensus** → **15 social media dark patterns** → **6 strategic categories** → **Mockup creation**

### Panel C: Main Study Design
- **141 UX designers** → **Random assignment to 3 conditions** → **10 pattern evaluations each** → **Binary + tendency decisions**

### Panel D: Condition Comparison
- **Evaluation Data Presentation**:
  - UI: Business context only
  - UEQ: + Standard UX metrics (Hedonic and Pragmatic Quality)
  - UEQ-A: + UEQ + Autonomy risk indicators

### Panel E: Results Visualization
- **Stepwise Effect**: Clear progression UI → UEQ → UEQ-A
- **Effect Sizes**: Large to very large effects across all comparisons
- **Statistical Power**: Strong significance despite modest sample sizes

### Color Scheme for All Visualizations:
- **UI condition**: RGB(255, 136, 136) - Light salmon
- **UEQ condition**: RGB(171, 226, 171) - Light green  
- **UEQ-A condition**: RGB(174, 128, 255) - Light purple

## Methodological Strengths:
1. **Ecological Validity**: Realistic business approval context
2. **Participant Expertise**: Professional UX/design practitioners only
3. **Statistical Rigor**: Participant-level analysis accounting for nested data
4. **Incremental Testing**: Stepwise addition of ethical information
5. **Practical Significance**: Large effect sizes with clear practical implications

## Implications:
The study demonstrates that providing autonomy-focused evaluation data alongside standard UX metrics significantly increases designers' rejection of dark patterns, suggesting that enhanced ethical evaluation frameworks can serve as effective intervention tools in design decision-making processes.
