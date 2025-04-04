# UI Assessment Analysis Summary

Analysis generated on 2025-04-04 10:32:56

## Overview

- Total assessments analyzed: 59
- AI services: Anthropic, Nan, Ollama, Openai
- Models: claude-3-opus-20240229, gemma3, gpt-4-turbo, nan
- Pattern types: Content Customization, Endlessness, Expectation Result Mismatch, False Hierarchy, Forced Access, Gamification, Hindering Account Deletion, Nagging, Overcomplicated Process, Pull to Refresh, Sneaking Bad Default, Social Connector, Social Pressure, Toying With Emotion, Trick Wording, nan

## Key Findings

### Inter-Annotator Agreement

Agreement within models (Krippendorff's Alpha, averaged across metrics):

| Service/Model | Agreement |
|---------------|----------|

### Most Reliable Models

Models with the most consistent assessments across runs:

| Service | Model | Reliability Score |
|---------|-------|------------------|
| Anthropic | claude-3-opus-20240229 | nan |
| Nan | nan | nan |
| Ollama | gemma3 | nan |
| Openai | gpt-4-turbo | nan |

### Models Most Similar to Human Assessment

| Service | Model | Human Concordance |
|---------|-------|-------------------|
| Anthropic | claude-3-opus-20240229 | nan |
| Ollama | gemma3 | nan |
| Openai | gpt-4-turbo | nan |


## UX KPI Analysis

The UX KPI (User Experience Key Performance Indicator) is calculated as the mean of the following UEQ-S items:
- boring
- not interesting
- complicated
- confusing
- inefficient
- cluttered
- unpredictable
- obstructive

Higher UX KPI values indicate more problematic UX patterns, while lower values indicate better user experience.

### Patterns Ranked by UX KPI (Worst to Best)

| Pattern Type | UX KPI |
|-------------|-------|
| Forced Access | 4.38 |
| Overcomplicated Process | 4.38 |
| Expectation Result Mismatch | 4.33 |
| Nagging | 4.04 |
| Pull to Refresh | 4.00 |

### Models with Best UX KPI Scores

| Service | Model | UX KPI |
|---------|-------|-------|
| Ollama | gemma3 | 3.70 |
| Anthropic | claude-3-opus-20240229 | 3.79 |
| Openai | gpt-4-turbo | 3.95 |
| Nan | nan | nan |

For each pattern type, a gauge visualization has been generated showing the worst UX aspect and the overall UX KPI value. These visualizations can be found in the 'gauges' subdirectory.

## Visualizations

The following visualizations have been generated:

1. Model comparison heatmap
2. Pattern type heatmaps by model
3. Model reliability comparison
4. Inter-annotator agreement comparison
5. Human concordance comparison
6. Reliability vs. human concordance
7. AI-Human agreement heatmap
8. Score distributions by model
9. UX KPI visualizations
   - UX KPI boxplot by model
   - UX KPI heatmap by pattern type
   - Gauge visualizations for each pattern type
10. Temperature effect plots

## Detailed Results

Detailed results are available in the CSV files in this directory.
