# Qualtrics Setup Guide

## Quick Setup Process

### 1. Create Survey Structure
- Create 5 blocks in Qualtrics matching your sections
- Set up randomization groups (Standard vs Enhanced Ethics)
- Configure qualification logic for eligibility screening

### 2. Block Organization

**Block 1: Consent & Eligibility**
**Block 2: Demographics** 
**Block 3: Interface Evaluation Task**
**Block 4: Decision-Making Process**
**Block 5: Debrief**

---

## Block 1: Consent & Eligibility

### Q1: Consent Form (Single Answer - Multiple Choice)
**Question Type:** Multiple Choice (Single Answer)
**Question Text:** [Paste entire consent form content here]
**Choices:**
- I consent to participate
- I do not consent to participate

**Logic:** If "I do not consent" → End Survey

### Q2: Professional Experience (Single Answer)
**Question Type:** Multiple Choice (Single Answer)
**Question Text:** Do you have professional experience in UI/UX design, product design, or design decision-making roles?
**Choices:**
- Yes
- No

**Logic:** If "No" → End Survey

### Q3: Experience Level (Single Answer)
**Question Type:** Multiple Choice (Single Answer)
**Question Text:** How many years of professional design experience do you have?
**Choices:**
- Less than 1 year
- 1-2 years
- 3-5 years
- 6-10 years
- More than 10 years

**Logic:** If "Less than 1 year" → End Survey

### Q4: Age Verification (Single Answer)
**Question Type:** Multiple Choice (Single Answer)
**Question Text:** Are you 18 years of age or older?
**Choices:**
- Yes
- No

**Logic:** If "No" → End Survey

---

## Block 2: Demographics

### Q5: Current Role (Single Answer)
**Question Type:** Multiple Choice (Single Answer)
**Choices:** UX Designer / UX Researcher / UI Designer / Product Designer / Design Manager / Product Manager / Design Director / Other (Text Entry)

### Q6: Industry Experience (Multiple Answer)
**Question Type:** Multiple Choice (Multiple Answer)
**Choices:** Technology/Software / E-commerce / Healthcare / Financial Services / Gaming / Media/Entertainment / Consulting / Other (Text Entry)

### Q7: Company Size (Single Answer)
**Question Type:** Multiple Choice (Single Answer)
**Choices:** Startup (<50 employees) / Small (50-200) / Medium (200-1000) / Large (1000-5000) / Enterprise (5000+) / Freelance/Consultant

### Q8: Decision-Making Authority (Single Answer)
**Question Type:** Multiple Choice (Single Answer)
**Choices:** Yes, final decision authority / Yes, significant influence / Some input / Little input / No decision authority

---

## Block 3: Interface Evaluation Task

### Setup Instructions for Qualtrics:

1. **Create Random Assignment:**
   - Survey Flow → Add Randomizer
   - Create 2 groups: "Standard_UX" and "Enhanced_Ethics"
   - Set to evenly distribute participants

2. **Create Interface Loop:**
   - Add Loop & Merge for 10-12 interfaces
   - Upload interface images to Qualtrics library
   - Create embedded data fields for each interface

3. **For Each Interface Question Block:**

#### Instructions (Display Logic: Show once at beginning)
**Question Type:** Text/Graphic
**Text:** [Paste full instructions from survey instrument]

#### Q9-X: Interface Presentation (Repeated for each interface)

**Business Context (Text/Graphic):**
✓ Business team approved | ✓ Marketing approved | ✓ Supervisor approved | **Awaiting your final design approval**

**Interface Image:**
[Insert interface mockup image]

**Evaluation Data:**
- **Standard Condition:** Show UX metrics table only
- **Enhanced Condition:** Show UX + Ethics metrics tables
- **Data Source:** Randomly assign "Human evaluation" vs "AI evaluation" text per interface

#### Q-A: Release Likelihood (Slider/Scale)
**Question Type:** Slider or Matrix (Single Answer)
**Scale:** 1 (Definitely would not release) to 7 (Definitely would release)

#### Q-B: Release Decision (Single Answer)
**Question Type:** Multiple Choice (Single Answer)
**Choices:** Yes / No

#### Q-C: Decision Reasoning (Text Entry)
**Question Type:** Text Entry (Single Line)
**Character Limit:** 300

#### Q-D: Decision Confidence (Scale)
**Question Type:** Matrix (Single Answer) or Slider
**Scale:** 1 (Not at all confident) to 7 (Extremely confident)

---

## Block 4: Decision-Making Process

### Copy-Paste Ready Questions:

**Q20: Evaluation Source Usefulness**
Question Type: Multiple Choice (Single Answer)
Overall, which type of evaluation data did you find more useful for decision-making?
- Human evaluation data
- AI evaluation data  
- Both were equally useful
- Neither was particularly useful

**Q21: Evaluation Source Trust**
Question Type: Multiple Choice (Single Answer)
Which type of evaluation data did you trust more?
- Human evaluation data
- AI evaluation data
- Both equally
- Neither

**Q22: Metric Importance Ranking**
Question Type: Rank Order
Which factors were most important in your decision-making? (Rank top 3)
- User satisfaction
- Ease of use
- Business impact
- Ethical considerations
- Legal compliance
- User safety
- Innovation
- Evaluation source (human vs AI)
- Other (Text Entry)

**Q23: AI Accuracy Perception**
Question Type: Matrix (Single Answer) or Slider
How accurate do you believe AI evaluation of interfaces is compared to human evaluation?
Scale: 1 (Much less accurate) to 7 (Much more accurate), with 4 being "About the same"

**Q24: AI Reliability Perception**
Question Type: Matrix (Single Answer) or Slider  
How reliable do you believe AI evaluation of interfaces is compared to human evaluation?
Scale: 1 (Much less reliable) to 7 (Much more reliable), with 4 being "About the same"

**Q25: Ethical Design Frequency**
Question Type: Multiple Choice (Single Answer)
In your professional work, how often do you encounter designs that you consider ethically questionable?
- Never
- Rarely
- Sometimes
- Often
- Very often

**Q26: Dark Patterns Familiarity**
Question Type: Multiple Choice (Single Answer)
How familiar are you with the concept of 'dark patterns' in interface design?
- Very familiar
- Somewhat familiar
- Slightly familiar
- Not familiar

**Q27: Organizational AI Support**
Question Type: Matrix (Single Answer) or Slider
How supportive is your organization of using AI tools for design evaluation?
Scale: 1 (Not at all supportive) to 7 (Extremely supportive) + "Not applicable"

**Q28: Organizational Ethics Support**
Question Type: Matrix (Single Answer) or Slider
How supportive is your organization of rejecting designs based on ethical concerns?
Scale: 1 (Not at all supportive) to 7 (Extremely supportive) + "Not applicable"

**Q29: Future Tool Preferences**
Question Type: Multiple Choice (Multiple Answer)
What additional information would be most helpful when evaluating interface designs?
- Long-term user behavior data
- Accessibility metrics
- Privacy impact assessments
- Psychological impact measures
- Regulatory compliance scores
- Combined AI-human evaluation
- Other (Text Entry)

**Q30: AI Tool Experience**
Question Type: Multiple Choice (Single Answer)
Have you previously used AI tools to evaluate or analyze user interfaces?
- Yes, frequently
- Yes, occasionally
- Yes, but rarely
- No, never

**Q31: Open Feedback**
Question Type: Text Entry (Essay Box)
Any additional thoughts about comparing AI vs human evaluation data, or this study in general?
Character Limit: 500 (Optional)

---

## Block 5: Debrief

**Study Purpose Text:**
Question Type: Text/Graphic
[Paste debrief text from survey instrument]

**Q32: Awareness Check 1**
Question Type: Multiple Choice (Single Answer)
Did you notice differences in how the user evaluation data was presented across different interfaces?
- Yes
- No  
- Unsure

**Q33: Awareness Check 2**
Question Type: Multiple Choice (Single Answer)
Did you notice patterns in differences between AI and human evaluation data?
- Yes
- No
- Unsure

**Q34: Study Feedback**
Question Type: Text Entry (Essay Box)
Do you have any feedback about this study or questions about the research? (Optional)

**Completion Text:**
Question Type: Text/Graphic
- Display completion code
- Show researcher contact information
- Thank participant

---

## Technical Setup in Qualtrics

### 1. Survey Flow Configuration:
```
Randomizer (Even Distribution)
├── Group: Standard_UX
│   └── Set Embedded Data: condition = "standard"
└── Group: Enhanced_Ethics
    └── Set Embedded Data: condition = "enhanced"

Block: Consent & Eligibility
└── Branch Logic: If consent = "No" → End Survey

Block: Demographics

Block: Interface Evaluation
└── Loop: interface_loop (10-12 iterations)
    └── Randomizer: data_source ("human" vs "ai")

Block: Decision Process

Block: Debrief
```

### 2. Embedded Data Fields to Create:
- condition (standard/enhanced)
- interface_1_source through interface_12_source
- interface_order (for randomization tracking)
- completion_code

### 3. Piped Text Setup:
Use ${e://Field/condition} and ${e://Field/interface_X_source} to display appropriate content

---

## Time-Saving Tips:

1. **Batch Upload Images:** Upload all interface mockups to Qualtrics library first
2. **Copy Question Templates:** Create first interface evaluation block, then duplicate
3. **Use Piped Text:** Set up condition and source variables once, reference throughout
4. **Test Logic:** Preview survey in both conditions before launch
5. **Export QSF:** Save survey file as backup after setup complete
