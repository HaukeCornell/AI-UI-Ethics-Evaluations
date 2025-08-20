# Dark Pattern Analysis Summary - WITH PATTERN NAMES

## ✅ **UPDATED CHARTS WITH DARK PATTERN NAMES**

### **New Files Created:**
- `plots/dark_patterns_rejection_named.png` - **15 panels**, each showing **actual dark pattern names** instead of "UI1", "UI2", etc.
- `plots/dark_patterns_tendency_named.png` - Same structure with **dark pattern names**
- `results/dark_patterns_statistical_results_named.csv` - Complete results with pattern names

## 🎯 **SIGNIFICANT DARK PATTERNS (p < 0.05)**

### **REJECTION RATE DIFFERENCES:**
- **Hindering Account Deletion** (χ² p = 0.046) - UEQ+Autonomy +35.9% higher rejection
- **Social Pressure** (Fisher p = 0.011) - UEQ+Autonomy +37.2% higher rejection

### **TENDENCY SCORE DIFFERENCES:**
- **Content Customization** (t-test p = 0.023, d = -0.835)
- **Hindering Account Deletion** (t-test p = 0.015, d = -0.777) 
- **Pull to Refresh** (t-test p = 0.038, d = -0.683)
- **Social Pressure** (t-test p = 0.043, d = -0.629)

## 🔍 **PATTERN INSIGHTS**

### **Most Sensitive Patterns (Both measures significant):**
1. **Hindering Account Deletion** - Both rejection AND tendency significant
2. **Social Pressure** - Both rejection AND tendency significant

### **UEQ+Autonomy Effect Pattern:**
When significant differences occur, UEQ+Autonomy consistently leads to:
- **More critical evaluation** (higher rejection rates)
- **Lower willingness to release** (lower tendency scores)
- **More conservative decisions** about problematic interfaces

### **Ethics-Sensitive Dark Patterns:**
The patterns showing significant differences are among the most **ethically problematic**:
- **Account deletion hindering** - Directly prevents user autonomy
- **Social pressure tactics** - Manipulates user psychology
- **Content customization** - Can create filter bubbles/echo chambers
- **Pull to refresh** - Addictive design patterns

## 📊 **CHART IMPROVEMENTS**

### **Before:**
- Generic labels: "UI1", "UI2", "UI3"...
- Hard to interpret which patterns are problematic

### **Now:**
- **Descriptive names**: "Bad Defaults", "Hindering Account Deletion", "Social Pressure"
- **Immediate recognition** of which dark patterns are sensitive to ethics evaluation
- **Better scientific communication** and interpretation

## 🎯 **KEY FINDING**

UEQ+Autonomy is particularly effective at detecting the **most ethically problematic** dark patterns:
- Patterns that **directly violate user autonomy** (account deletion, social pressure)
- Patterns that **manipulate user behavior** (content customization, addictive refresh)

This validates that ethics-enhanced evaluation frameworks can successfully identify interfaces that pose the greatest ethical risks to users.
