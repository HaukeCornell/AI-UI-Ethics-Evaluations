# Comparison: Planned Contrast vs Omnibus ANOVA Violin Plots

## Two Different Statistical Questions, Same Beautiful Visualization Style

### Plot 1: Planned Contrast (UEQ vs UEQ+Autonomy)
**File**: `three_condition_tendency_violin_fdr_corrected.png`
- **Statistical test**: One-tailed t-test between UEQ and UEQ+Autonomy specifically  
- **Question**: "Are UEQ+Autonomy participants more critical than UEQ participants?" (directional hypothesis)
- **Significance bars**: Between UEQ and UEQ+A only
- **Results**: **6 significant interfaces**
- **Interpretation**: Tests our specific theory about autonomy-focused evaluation

### Plot 2: Omnibus ANOVA (All Three Groups)  
**File**: `three_condition_omnibus_anova_violin_fdr_corrected.png`
- **Statistical test**: Two-tailed F-test comparing all three groups simultaneously
- **Question**: "Are there ANY differences among UEQ, UEQ+Autonomy, and RAW?" (non-directional)
- **Significance bars**: Spanning all three groups  
- **Results**: **9 significant interfaces**
- **Interpretation**: Shows which interfaces have group differences, but doesn't specify which groups differ

## Key Differences in Results

### Significant Interfaces Comparison:

#### Planned Contrast Only (6 interfaces):
- Content Customization ✓
- Endlessness ✓ 
- Trick Wording ✓
- Hindering Account Deletion ✓
- Pull to Refresh ✓
- Social Pressure ✓

#### Omnibus ANOVA Only (9 interfaces):
All 6 above **PLUS**:
- **Forced Access** (strongest effect, F=20.56)
- **False Hierarchy** (F=15.70)  
- **Expectation Result Mismatch** (F=13.23)
- **Nagging** (F=8.48)
- **Toying with Emotion** (F=7.89)

#### Why the Difference?
The omnibus ANOVA detects **3 additional interfaces** because:

1. **It captures all types of differences**, not just UEQ vs UEQ+Autonomy
2. **RAW vs others comparisons** may be significant even when UEQ vs UEQ+Autonomy isn't
3. **More sensitive to complex patterns** where all three groups differ

## What This Tells Us

### Pattern Analysis:
Looking at the **3 interfaces significant in omnibus but not planned contrast**:
- **Forced Access**, **False Hierarchy**, **Expectation Result Mismatch**: These likely show strong RAW vs evaluation-condition differences
- The evaluation framework (any framework) makes people more critical of these patterns
- But UEQ vs UEQ+Autonomy specifically might not differ much

### Complementary Insights:
1. **Planned contrast**: Tests our specific autonomy hypothesis (theory-driven)
2. **Omnibus ANOVA**: Reveals broader patterns we might have missed (exploratory)

## Visual Design Differences

### Planned Contrast Plot:
- Significance bars between UEQ and UEQ+A only
- Title emphasizes "Focus on UEQ vs UEQ+Autonomy Contrast"  
- Subtitle clarifies "Primary test" and "RAW shown for context"

### Omnibus ANOVA Plot:
- Significance bars span all three groups
- Title emphasizes "Any Differences Among Groups"
- Subtitle clarifies "Three-way comparison"

## When to Use Which?

### Use Planned Contrast When:
- You have specific directional hypotheses
- Testing theory-driven predictions
- Want to maximize power for specific comparisons

### Use Omnibus ANOVA When:
- Exploring general group differences
- Don't want to miss unexpected patterns  
- Need to establish overall significance before post-hoc tests

Both approaches are valuable and tell complementary parts of the story!
