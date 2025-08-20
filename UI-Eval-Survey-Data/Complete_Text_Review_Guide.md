## Complete Text Review Guide

### File Overview
- **File**: `results/all_participants_text_review.txt`
- **Size**: 225KB, 5,132 lines
- **Content**: All 94 participants with complete data
- **Format**: Structured text format for easy manual review

### Review Structure for Each Participant

```
================================================================================
PARTICIPANT: [PROLIFIC_PID]
CONDITION: [UEQ or UEQ+Autonomy]
INTERFACES EVALUATED: [Number]
AVG TENDENCY: [Score] | VAR TENDENCY: [Variance]
REJECTION RATE: [Percentage] %
AVG CHAR COUNT: [Characters] | VAR CHAR COUNT: [Variance]
FLAGS: [Any automated flags or "None"]
AI_SUSPICIOUS: [  ]  (Mark TRUE/FALSE after review)
QUALITY_NOTES: _________________________________________________
================================================================================

--- INTERFACE EXPLANATIONS ---
[1] Interface_Name:
[Explanation text]

[2] Interface_Name:
[Explanation text]
...

--- FEEDBACK ---
Open Feedback:
[Feedback text if provided]

Feedback:
[Additional feedback if provided]

--------------------------------------------------------------------------------
```

### Key Metrics to Look For

**AI Indicators:**
- Very consistent response lengths (low var_char_count < 100)
- Extremely long responses (avg_char_count > 300)
- Generic, template-like language patterns
- Overly sophisticated vocabulary/structure inconsistent with other responses

**Quality Issues:**
- Very short responses (avg_char_count < 20)
- Straightlining in tendency scores (var_tendency < 0.5)
- Random clicking patterns (var_tendency > 8)
- Inconsistent engagement (high var_char_count > 10,000)

### Review Process
1. **Search for specific participants**: Use Ctrl+F (or Cmd+F) with PROLIFIC_PID
2. **Mark AI_SUSPICIOUS**: Replace `[  ]` with `[X]` for suspicious cases
3. **Add notes**: Fill in QUALITY_NOTES with specific observations
4. **Flag patterns**: Look for repetitive language, unusual sophistication, or inconsistent styles

### Navigation Tips
- Each participant section starts with "PARTICIPANT:"
- Use "PARTICIPANT:" as search term to jump between participants
- Flagged participants from automated screening are noted in the FLAGS field
- Focus extra attention on participants with existing flags

### Priority Review Cases
**Highest Priority:**
- Participants with LONG_RESPONSES flag (potential AI)
- Participants with LOW_TEXT_VAR + SHORT_RESPONSES (potential copy-paste)
- Participants with HIGH_CHAR_VAR (inconsistent engagement)

**Already Pre-flagged:** 28 participants have automated flags and should be reviewed first

### Output
After manual review, you can use the annotations to:
- Create exclusion criteria
- Identify patterns in AI usage
- Assess overall data quality
- Inform future study design improvements
