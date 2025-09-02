# Three-Condition Analysis Guide
**For AI Assistant Reference - September 2025**

## 📁 **File Structure**
```
analysis_v2/
├── 01_process_three_condition_data.R     # Data processing pipeline
├── 02_three_condition_statistical_analysis.R  # ANOVA + planned comparisons  
├── 03_demographics_analysis.R           # Demographics (copied from original)
├── 04_three_condition_visualizations.R  # Main visualizations
├── results/                             # All output files
└── plots/                              # All visualization files
```

## 🎯 **Study Design**
- **Between-subjects**: UEQ vs UEQ+Autonomy vs RAW (no evaluation data)
- **Participants**: N=141 (UEQ: 49, UEQ+Autonomy: 47, RAW: 45) 
- **Interfaces**: All 15 interfaces included (ui001-ui015)
- **DVs**: Release tendency (1-7), Release decision (binary)

## 📊 **Key Results Summary**

### **Overall Condition Effects:**
- **RAW**: Higher tendency (4.66), lower rejection (30%)
- **UEQ**: Medium tendency (3.80), medium rejection (44%)  
- **UEQ+Autonomy**: Lower tendency (3.14), higher rejection (56%)

### **Significant Interface-Level Effects (FDR < 0.05):**
**Tendency (UEQ > UEQ+Autonomy)**: ui002, ui003, ui015, ui008, ui011, ui013
**Rejection (UEQ < UEQ+Autonomy)**: ui015, ui002, ui008

### **Demographics (N=141):**
- **100% professional UX/design experience**
- **75.2% have decision authority**
- **93.6% familiar with dark patterns**
- **85.8% encounter ethical issues regularly**

## 🔧 **Scripts Usage**

### **01_process_three_condition_data.R**
- **Input**: `../sep2_completed_utf8.tsv`, `../results/correct_exclusion_list.csv`
- **Output**: `results/three_condition_interface_data.csv` (main dataset)
- **Purpose**: Extract + clean data for all 3 conditions

### **02_three_condition_statistical_analysis.R**  
- **Input**: `results/three_condition_interface_data.csv`
- **Output**: `results/three_condition_anova_results.csv`
- **Purpose**: ANOVA + planned contrasts with FDR correction

### **03_demographics_analysis.R**
- **Input**: `../sep2_completed_utf8.tsv`
- **Output**: `plots/demographics_complete_summary.png`
- **Purpose**: Replicate 2x2 demographics visualization

### **04_three_condition_visualizations.R**
- **Input**: `results/three_condition_interface_data.csv`, `results/three_condition_anova_results.csv`
- **Output**: All comparison plots
- **Purpose**: Individual interface + overall condition plots

## 📈 **Key Visualizations**
- `plots/three_condition_tendency_comparison.png` - Individual interfaces (like old FDR plot)
- `plots/three_condition_rejection_comparison.png` - Individual interfaces rejection
- `plots/overall_tendency_comparison.png` - Main condition effect
- `plots/overall_rejection_comparison.png` - Main condition effect
- `plots/demographics_complete_summary.png` - Clean 2x2 demographics

## 🔬 **Statistical Approach**
- **Primary**: Planned contrasts (UEQ vs UEQ+Autonomy) - original hypothesis
- **Secondary**: RAW comparisons (exploratory)
- **Correction**: FDR for multiple interfaces
- **Effect sizes**: Cohen's d for significant differences

## ⚠️ **Important Notes**
- Used **UEEQ** column naming (not UEQ+Autonomy) in raw data
- **No interface exclusions** (all ui001-ui015 included)
- **Correct exclusion list**: 10 participants only
- **Completed responses only**: Better quality than original dataset

## 🎯 **Hypotheses Confirmed**
✅ **UEQ+Autonomy < UEQ tendency** (6 interfaces significant)  
✅ **UEQ+Autonomy > UEQ rejection** (3 interfaces significant)  
✅ **Strong sample demographics** (N=141, professional expertise)  
🔍 **RAW condition** performed as expected (closest to UEQ+Autonomy)
