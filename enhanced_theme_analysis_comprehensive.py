#!/usr/bin/env python3
"""
Enhanced Comprehensive Theme Analysis
Incorporating all discovered keywords from semantic search and domain expertise

Key enhancements:
1. Manipulation awareness keywords found in RAW condition
2. Aesthetic-focused language across conditions  
3. Business-focused reasoning patterns
4. Changed terminology from "patterns" to "themes"
5. Comprehensive keyword lists based on actual text analysis
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
from scipy import stats
import warnings
warnings.filterwarnings('ignore')

class EnhancedThemeAnalyzer:
    def __init__(self, data_dir="explanation_analysis_output"):
        self.data_dir = Path(data_dir)
        self.explanations_df = None
        self.output_dir = self.data_dir / "enhanced_theme_analysis"
        self.output_dir.mkdir(exist_ok=True)
        
    def load_data(self):
        """Load the explanation data."""
        csv_file = self.data_dir / "all_explanations_raw.csv"
        self.explanations_df = pd.read_csv(csv_file)
        self.explanations_df['pattern'] = self.explanations_df['pattern'].astype(int)
        return self.explanations_df
    
    def analyze_comprehensive_themes(self):
        """
        Analyze comprehensive themes with enhanced keyword lists discovered through semantic search.
        """
        print("Performing comprehensive theme analysis with enhanced keywords...")
        
        # Define themes with comprehensive keywords including newly discovered ones
        themes = {
            'manipulation_awareness': {
                'keywords': [
                    # Core manipulation terms
                    'manipulative', 'manipulation', 'manipulate', 'manipulating',
                    'coercion', 'coercive', 'coerce', 'pressuring', 'pressure',
                    'deception', 'deceptive', 'deceive', 'misleading', 'dishonest',
                    
                    # Newly discovered manipulation awareness in RAW
                    'seems pushing', 'feels off', 'warning tone', 'user-hostile',
                    'emotionally coercive language', 'emotionally manipulative',
                    'heavy-handed', 'poor taste', 'backfire', 'forced',
                    
                    # Emotional manipulation recognition
                    'guilt trip', 'guilt tripping', 'exploiting user behavior',
                    'fear of loss', 'unacceptable copy', 'violating user autonomy',
                    'undermining autonomy', 'forced to use', 'pressuring users',
                    
                    # Strong negative responses to manipulation
                    'hate the language', 'disrespectful', 'hateful', 'awful', 'terrible',
                    'disgusting', 'I HATE', 'unacceptable', 'negative backlash',
                    'highly unsuitable', 'severely negative'
                ],
                'hypothesis': 'Manipulation awareness present across conditions, highest in UEEQ',
                'expected_condition': 'UEEQ > UEQ > RAW'
            },
            'responsibility_avoidance': {
                'keywords': [
                    # Direct organizational responsibility transfer
                    'supervisor', 'business team', 'marketing department', 'marketing team',
                    'already approved', 'all approved', 'stakeholders approved', 'supervisor approved',
                    'business approved', 'marketing approved', 'team approved', 'unanimous approval',
                    
                    # Professional risk avoidance
                    'professional risk', 'business risk', 'professional and business risk',
                    'withholding my final approval', 'not a responsible action',
                    'halt progress', 'waste resources', 'undermine the team',
                    
                    # Market pressure justifications
                    'competitive market', 'limited runway', 'pivotal for success',
                    'momentum', 'strategic decision', 'growth priorities',
                    'funding opportunities', 'development team has already',
                    
                    # Trust in authority
                    'trust his decision', 'trust their decision', 'supervisor signing off',
                    'strategic perspective', 'already a positive from me',
                    'my role at this stage', 'final sign-off'
                ],
                'hypothesis': 'Most common in RAW condition - promotes responsibility diffusion',
                'expected_condition': 'RAW'
            },
            'ethics_focused_reasoning': {
                'keywords': [
                    # Direct ethical language
                    'ethical', 'ethics', 'unethical', 'moral', 'immoral', 'wrong', 'right',
                    'ethical design', 'ethical standards', 'ethical principles', 'ethical concerns',
                    'ethical risks', 'ethical violation', 'ethical UX', 'ethical considerations',
                    
                    # User welfare and autonomy
                    'autonomy', 'consent', 'privacy', 'trust', 'transparent', 'transparency',
                    'honest', 'fair', 'unfair', 'user well-being', 'user safety',
                    'respectful user experience', 'safe and respectful', 'user welfare',
                    
                    # Professional ethical stance
                    'user well-being and safety outweigh business', 'values I stand for',
                    'priority is to ensure', 'violating fundamental principles',
                    'protect users', 'user protection', 'harmful to user trust',
                    'undermines trust', 'destroy user trust', 'user trust and safety'
                ],
                'hypothesis': 'Most common in UEEQ condition - ethical framework promotes moral reasoning',
                'expected_condition': 'UEEQ'
            },
            'aesthetic_focused_reasoning': {
                'keywords': [
                    # Visual aesthetics - positive
                    'beautiful', 'attractive', 'appealing', 'visually appealing', 'sleek',
                    'elegant', 'polished', 'aesthetic appeal', 'clean', 'modern',
                    'nice clean', 'design is clean', 'visually', 'layout',
                    
                    # Visual aesthetics - negative  
                    'plain', 'flat', 'lazy', 'ugly', 'outdated', 'boring',
                    'rough and lacks quality', 'scrambled mess', 'needs cleaning up',
                    'lacks quality', 'could use polishing', 'a bit boring',
                    
                    # Design simplicity
                    'simple', 'basic', 'simple enough', 'simple and basic',
                    'simple notification', 'simple language', 'familiar',
                    
                    # Visual hierarchy and organization
                    'visual hierarchy', 'spacing', 'alignment', 'sectional division',
                    'laid out better', 'icon consistency', 'distracting visual elements'
                ],
                'hypothesis': 'Present across conditions but may vary in emphasis',
                'expected_condition': 'Similar across conditions'
            },
            'business_focused_reasoning': {
                'keywords': [
                    # Business strategy
                    'business', 'commercial', 'company', 'strategic', 'strategy',
                    'business goals', 'business team', 'business risk', 'strategic perspective',
                    'strategic decision', 'strategic goals', 'strategic leadership',
                    
                    # Market and competition
                    'market', 'competitive', 'competition', 'competitive market',
                    'competitive environment', 'limited runway', 'momentum',
                    
                    # Financial metrics
                    'revenue', 'revenue potential', 'profit', 'engagement', 'retention',
                    'metrics', 'funding', 'financing', 'monetization', 'growth',
                    'user engagement', 'financial gains',
                    
                    # Corporate structure
                    'corporate', 'industry', 'stakeholders', 'departments',
                    'marketing department', 'development team', 'organizational',
                    'organization-wide alignment'
                ],
                'hypothesis': 'Most common in RAW condition - business context emphasizes commercial reasoning',
                'expected_condition': 'RAW'
            },
            'emotional_intensity': {
                'keywords': [
                    # Strong positive emotions
                    'love', 'amazing', 'fantastic', 'excellent', 'brilliant', 'wonderful',
                    'perfect', 'outstanding', 'impressive', 'exciting',
                    
                    # Strong negative emotions  
                    'hate', 'disgusting', 'awful', 'terrible', 'horrible', 'outrageous',
                    'unacceptable', 'I HATE', 'severely negative', 'highly unsuitable',
                    'appalled', 'shocked', 'disturbed', 'concerned', 'worried',
                    
                    # Emotional language intensifiers
                    'extremely', 'very', 'highly', 'severely', 'completely', 'totally',
                    'absolutely', 'definitely', 'certainly', 'really', 'truly'
                ],
                'hypothesis': 'Higher emotional intensity in UEEQ condition due to ethical framework',
                'expected_condition': 'UEEQ'
            },
            'conformity_justification': {
                'keywords': [
                    # Industry standards
                    'industry standard', 'common practice', 'standard approach',
                    'widely accepted', 'conventional design', 'standard UX pattern',
                    'typical for this type', 'normal for social media',
                    
                    # Platform conformity
                    'other social media', 'social media giants', 'follows similarly',
                    'similar to existing', 'already in place', 'platform-level',
                    'OS-level UX conventions', 'regulatory norms',
                    
                    # User expectations
                    'users expect', 'user expectations', 'users are familiar',
                    'aligns with expectations', 'recognition and ease of use',
                    'likelihood of recognition', 'familiar pattern',
                    'expected behavior', 'conventional'
                ],
                'hypothesis': 'Present across conditions but may be emphasized differently',
                'expected_condition': 'RAW > UEQ > UEEQ'
            }
        }
        
        # Count theme occurrences by condition
        theme_counts = {}
        theme_explanations = {}
        
        for theme_name, theme_info in themes.items():
            print(f"\nAnalyzing {theme_name}...")
            keywords = theme_info['keywords']
            
            # Count occurrences by condition
            condition_counts = {'UEQ': 0, 'UEEQ': 0, 'RAW': 0}
            condition_explanations = {'UEQ': [], 'UEEQ': [], 'RAW': []}
            
            for condition in ['UEQ', 'UEEQ', 'RAW']:
                condition_df = self.explanations_df[self.explanations_df['condition'] == condition]
                
                for _, row in condition_df.iterrows():
                    explanation = str(row['explanation']).lower()
                    
                    # Check if any keywords are present
                    found_keywords = []
                    for keyword in keywords:
                        if keyword.lower() in explanation:
                            found_keywords.append(keyword)
                    
                    if found_keywords:
                        condition_counts[condition] += 1
                        condition_explanations[condition].append({
                            'explanation': row['explanation'],
                            'keywords_found': found_keywords,
                            'pattern': row['pattern'],
                            'release_decision': row['release_decision']
                        })
            
            theme_counts[theme_name] = condition_counts
            theme_explanations[theme_name] = condition_explanations
            
            # Print summary for this theme
            total = sum(condition_counts.values())
            print(f"Total occurrences: {total}")
            for condition, count in condition_counts.items():
                percentage = (count/total)*100 if total > 0 else 0
                print(f"  {condition}: {count} ({percentage:.1f}%)")
        
        # Statistical analysis
        self.perform_enhanced_statistical_analysis(theme_counts, themes)
        
        # Save detailed results
        self.save_enhanced_theme_results(theme_counts, theme_explanations, themes)
        
        return theme_counts, theme_explanations
    
    def perform_enhanced_statistical_analysis(self, theme_counts, themes):
        """Perform chi-square tests for each theme."""
        print("\n" + "="*60)
        print("STATISTICAL ANALYSIS RESULTS")
        print("="*60)
        
        results = []
        
        for theme_name, counts in theme_counts.items():
            # Create contingency table
            observed = np.array([[counts['UEQ']], [counts['UEEQ']], [counts['RAW']]])
            
            # Calculate totals for each condition
            condition_totals = {}
            for condition in ['UEQ', 'UEEQ', 'RAW']:
                condition_df = self.explanations_df[self.explanations_df['condition'] == condition]
                condition_totals[condition] = len(condition_df)
            
            # Create full contingency table (present vs not present)
            contingency_table = np.array([
                [counts['UEQ'], condition_totals['UEQ'] - counts['UEQ']],
                [counts['UEEQ'], condition_totals['UEEQ'] - counts['UEEQ']],
                [counts['RAW'], condition_totals['RAW'] - counts['RAW']]
            ])
            
            # Chi-square test
            chi2_stat, p_value, dof, expected = stats.chi2_contingency(contingency_table)
            
            # Cramér's V (effect size)
            n = contingency_table.sum()
            cramers_v = np.sqrt(chi2_stat / (n * (min(contingency_table.shape) - 1)))
            
            # Determine significance
            alpha = 0.05
            alpha_bonferroni = alpha / len(theme_counts)  # Bonferroni correction
            is_significant = p_value < alpha_bonferroni
            
            results.append({
                'theme': theme_name,
                'chi2_stat': chi2_stat,
                'p_value': p_value,
                'p_bonferroni': alpha_bonferroni,
                'is_significant': is_significant,
                'cramers_v': cramers_v,
                'total_count': sum(counts.values()),
                'ueg_count': counts['UEQ'],
                'ueeq_count': counts['UEEQ'],
                'raw_count': counts['RAW'],
                'hypothesis': themes[theme_name]['hypothesis']
            })
            
            print(f"\n{theme_name.upper().replace('_', ' ')}")
            print(f"  Chi-square: {chi2_stat:.3f}")
            print(f"  p-value: {p_value:.6f}")
            print(f"  Bonferroni-corrected α: {alpha_bonferroni:.6f}")
            print(f"  Significant: {'YES' if is_significant else 'NO'}")
            print(f"  Cramér's V: {cramers_v:.3f}")
            print(f"  Effect size: {self.interpret_cramers_v(cramers_v)}")
            print(f"  Counts - UEQ: {counts['UEQ']}, UEEQ: {counts['UEEQ']}, RAW: {counts['RAW']}")
            print(f"  Hypothesis: {themes[theme_name]['hypothesis']}")
        
        # Create and save results DataFrame
        results_df = pd.DataFrame(results)
        results_df.to_csv(self.output_dir / "enhanced_theme_statistics.csv", index=False)
        
        # Summary of significant themes
        significant_themes = results_df[results_df['is_significant']]
        print(f"\n{'='*60}")
        print(f"SUMMARY: {len(significant_themes)} out of {len(results)} themes are statistically significant")
        print("="*60)
        
        return results_df
    
    def interpret_cramers_v(self, v):
        """Interpret Cramér's V effect size."""
        if v < 0.1:
            return "Negligible"
        elif v < 0.3:
            return "Small"
        elif v < 0.5:
            return "Medium"
        else:
            return "Large"
    
    def save_enhanced_theme_results(self, theme_counts, theme_explanations, themes):
        """Save detailed theme analysis results."""
        
        # Save theme counts
        counts_df = pd.DataFrame(theme_counts).T
        counts_df.to_csv(self.output_dir / "enhanced_theme_counts.csv")
        
        # Save detailed explanations for each theme
        for theme_name, explanations in theme_explanations.items():
            theme_data = []
            for condition, exp_list in explanations.items():
                for exp_info in exp_list:
                    theme_data.append({
                        'condition': condition,
                        'explanation': exp_info['explanation'],
                        'keywords_found': ', '.join(exp_info['keywords_found']),
                        'pattern': exp_info['pattern'],
                        'release_decision': exp_info['release_decision']
                    })
            
            if theme_data:
                theme_df = pd.DataFrame(theme_data)
                theme_df.to_csv(self.output_dir / f"{theme_name}_examples.csv", index=False)
        
        print(f"\nResults saved to {self.output_dir}")

# Run the enhanced analysis
if __name__ == "__main__":
    analyzer = EnhancedThemeAnalyzer()
    analyzer.load_data()
    theme_counts, theme_explanations = analyzer.analyze_comprehensive_themes()
