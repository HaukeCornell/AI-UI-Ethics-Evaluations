#!/usr/bin/env python3
"""
Improved Hypothesis-Driven Statistical Analysis
Based on observed patterns with comprehensive keyword lists derived from actual data

Key Clarifications:
1. Statistical significance tests CONDITION DIFFERENCES (UEQ vs UEEQ vs RAW)
2. Keywords are comprehensively derived from manual examination of explanations
3. Patterns are hypothesis-driven based on observed phenomena in the data

Research Questions:
1. Does the RAW condition promote responsibility avoidance/diffusion?
2. Does the UEEQ condition increase manipulation awareness?
3. Does the UEEQ condition promote more ethical reasoning?
4. Does the RAW condition increase conformity justifications?
5. Do conditions differ in aesthetic vs ethical focus?
6. Does the UEEQ condition produce stronger emotional reactions?
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
from scipy import stats
import warnings
warnings.filterwarnings('ignore')

class ImprovedHypothesisDrivenAnalyzer:
    def __init__(self, data_dir="explanation_analysis_output"):
        self.data_dir = Path(data_dir)
        self.explanations_df = None
        self.output_dir = self.data_dir / "hypothesis_driven_analysis"
        self.output_dir.mkdir(exist_ok=True)
        
    def load_data(self):
        """Load the explanation data."""
        csv_file = self.data_dir / "all_explanations_raw.csv"
        self.explanations_df = pd.read_csv(csv_file)
        self.explanations_df['pattern'] = self.explanations_df['pattern'].astype(int)
        return self.explanations_df
    
    def analyze_hypothesis_driven_patterns(self):
        """
        Analyze hypothesis-driven patterns with comprehensive keyword lists.
        
        Note: Statistical tests examine CONDITION DIFFERENCES (UEQ vs UEEQ vs RAW),
        not release decision differences.
        """
        print("Performing hypothesis-driven statistical analysis...")
        
        # Define patterns with comprehensive keywords derived from data examination
        patterns = {
            'responsibility_avoidance': {
                'keywords': [
                    # Direct organizational responsibility transfer
                    'supervisor', 'business team', 'marketing department', 'marketing team',
                    'already approved', 'all approved', 'stakeholders approved', 'supervisor approved',
                    'business approved', 'marketing approved', 'team approved',
                    
                    # Professional risk avoidance
                    'professional risk', 'business risk', 'professional and business risk',
                    'withholding my final approval would be', 'not a responsible action',
                    'halt progress', 'waste resources', 'undermine the team',
                    
                    # Organizational alignment rhetoric  
                    'all prior evaluations', 'already confirmed', 'alignment with business goals',
                    'organization-wide alignment', 'key stakeholders', 'final sign-off',
                    'my role at this stage', 'provide a final sign-off',
                    
                    # Market pressure justifications
                    'competitive market', 'limited runway', 'pivotal for success',
                    'signed off by all departments', 'development team has already',
                    'developers are busy', 'momentum might be put at risk',
                    
                    # Trust in authority
                    'trust his decision', 'trust their decision', 'supervisor signing off',
                    'strategic perspective', 'already a positive from me'
                ],
                'hypothesis': 'More common in RAW condition - promotes responsibility diffusion',
                'expected_condition': 'RAW'
            },
            'manipulation_awareness': {
                'keywords': [
                    # Direct manipulation identification
                    'manipulative', 'manipulation', 'manipulate', 'manipulating',
                    'coercion', 'coercive', 'coerce', 'pressuring', 'pressure',
                    'deception', 'deceptive', 'deceive', 'misleading', 'dishonest',
                    
                    # Emotional manipulation recognition
                    'guilt trip', 'guilt tripping', 'emotionally manipulative',
                    'emotionally coercive', 'heavy-handed guilt', 'coercive language',
                    'fear of loss', 'exploiting user behavior', 'unacceptable copy',
                    
                    # Autonomy violation awareness
                    'violating user autonomy', 'undermining autonomy', 'forced to use',
                    'pressuring users', 'violates ethical design', 'harmful to user trust',
                    'exploiting users', 'undermines user trust', 'violating ethical',
                    
                    # Strong negative emotional responses to manipulation
                    'hate the language', 'disrespectful', 'hateful', 'awful', 'terrible',
                    'disgusting', 'I HATE', 'unacceptable', 'poor taste', 'backfire',
                    'negative backlash', 'highly unsuitable', 'severely negative',
                    
                    # Specific UEQ-E references to manipulation metrics
                    'coercion score', 'deception score', 'highly pressuring',
                    'pressuring and manipulative', 'manipulation and harmful'
                ],
                'hypothesis': 'More common in UEEQ condition - ethical framework raises awareness',
                'expected_condition': 'UEEQ'
            },
            'ethics_focused_reasoning': {
                'keywords': [
                    # Direct ethical language
                    'ethical', 'ethics', 'unethical', 'moral', 'immoral', 'wrong', 'right',
                    'ethical design', 'ethical standards', 'ethical principles', 'ethical concerns',
                    'ethical risks', 'ethical violation', 'ethical UX', 'ethical considerations',
                    
                    # User welfare and autonomy
                    'autonomy', 'consent', 'privacy', 'trust', 'transparent', 'transparency',
                    'honest', 'dishonest', 'fair', 'unfair', 'user well-being', 'user safety',
                    'respectful user experience', 'safe and respectful', 'user welfare',
                    
                    # Professional ethical stance
                    'user well-being and safety outweigh business', 'values I stand for',
                    'believes in honesty and personal responsibility', 'priority is to ensure',
                    'safe and respectful user experience', 'violating fundamental principles',
                    
                    # Harm prevention
                    'harmful to users', 'potentially harming', 'poses a risk', 'user harm',
                    'protect users', 'user protection', 'harmful to user trust',
                    'undermines trust', 'destroy user trust', 'user trust and safety'
                ],
                'hypothesis': 'More common in UEEQ condition - ethical framework promotes moral reasoning',
                'expected_condition': 'UEEQ'
            },
            'industry_conformity': {
                'keywords': [
                    # Direct conformity references
                    'common interface', 'standard for social platforms', 'industry standard',
                    'aligns with user expectations', 'follows similarly', 'other social media',
                    'social media giants', 'similar process already in place',
                    
                    # Platform comparisons
                    'already in place by apple', 'OS-level UX conventions', 'platform-level',
                    'regulatory norms', 'recognition and ease of use', 'likelihood of recognition',
                    'users are familiar', 'similar to existing', 'follows existing patterns',
                    
                    # Normalization language
                    'common practice', 'widely accepted', 'standard approach',
                    'typical for this type', 'normal for social media', 'expected behavior',
                    'users expect this', 'conventional design', 'standard UX pattern'
                ],
                'hypothesis': 'More common in RAW condition - absence of ethical framework promotes conformity',
                'expected_condition': 'RAW'
            },
            'aesthetic_focus': {
                'keywords': [
                    # Visual design elements
                    'layout is clean', 'imagery is appealing', 'visual hierarchy',
                    'spacing', 'typography', 'lacks colors', 'visual elements',
                    'attractiveness', 'appealing', 'polished', 'professional looking',
                    
                    # Design quality assessments
                    'looks good', 'looks great', 'well designed', 'clean design',
                    'simple and clean', 'visually appealing', 'nice layout',
                    'good visual design', 'aesthetically pleasing', 'attractive design',
                    
                    # Superficial design comments
                    'eye catching', 'impressive', 'beautiful', 'ugly', 'boring',
                    'basic enough', 'simple enough', 'nothing special here',
                    'doesn\'t need to be designed to an extent', 'basic but functional'
                ],
                'hypothesis': 'Distributed across conditions - aesthetic focus vs ethical focus',
                'expected_condition': 'DISTRIBUTED'
            },
            'emotional_reaction': {
                'keywords': [
                    # Strong positive emotions
                    'love', 'brilliant', 'amazing', 'fantastic', 'excellent', 'perfect',
                    'wonderful', 'outstanding', 'impressive', 'great',
                    
                    # Strong negative emotions
                    'hate', 'awful', 'terrible', 'disgusting', 'horrible', 'appalling',
                    'extremely', 'severely', 'highly', 'strongly', 'absolutely',
                    'completely', 'totally', 'utterly', 'I HATE', 'very bad',
                    
                    # Intensity modifiers
                    'extremely negative', 'severely negative', 'highly unsuitable',
                    'absolutely unacceptable', 'completely inappropriate', 'totally wrong',
                    'very concerning', 'deeply problematic', 'seriously flawed'
                ],
                'hypothesis': 'More intense in UEEQ condition - metrics amplify emotional responses',
                'expected_condition': 'UEEQ'
            },
            'data_driven_reasoning': {
                'keywords': [
                    # Metric references
                    'score', 'scores', 'data', 'metrics', 'numbers', 'results',
                    'evidence', 'measurement', 'evaluation data', 'user data',
                    'assessment shows', 'ratings', 'feedback', 'statistics',
                    
                    # Specific UEQ/UEEQ metric language
                    'overall ux quality', 'ux quality score', 'overall score',
                    'attractiveness score', 'efficiency score', 'clarity score',
                    'stimulation score', 'predictability score', 'dependability score',
                    'ux kpi', 'composite score', 'overall rating',
                    
                    # Data interpretation
                    'data shows', 'numbers indicate', 'scores reveal', 'evidence suggests',
                    'metrics demonstrate', 'assessment confirms', 'evaluation indicates',
                    'ratings show', 'results suggest', 'data confirms'
                ],
                'hypothesis': 'More common in UEQ/UEEQ conditions - metric-based evaluation',
                'expected_condition': 'UEQ_UEEQ'
            }
        }
        
        results = {}
        
        for pattern_name, pattern_info in patterns.items():
            results[pattern_name] = self._analyze_pattern_by_condition_comprehensive(
                pattern_name, pattern_info['keywords'], pattern_info['hypothesis'], 
                pattern_info['expected_condition']
            )
        
        # Perform statistical tests
        self._perform_comprehensive_statistical_tests(results)
        
        # Create visualizations
        self._create_comprehensive_visualizations(results)
        
        return results
    
    def _analyze_pattern_by_condition_comprehensive(self, pattern_name, keywords, hypothesis, expected_condition):
        """Analyze a specific pattern across conditions with comprehensive keyword matching."""
        results = {
            'hypothesis': hypothesis,
            'expected_condition': expected_condition,
            'keywords': keywords,
            'keyword_count': len(keywords),
            'by_condition': {},
            'examples': {},
            'statistical_data': {}
        }
        
        # Analyze by condition
        for condition in ['UEQ', 'UEEQ', 'RAW']:
            condition_data = self.explanations_df[self.explanations_df['condition'] == condition]
            
            matches = []
            examples = []
            matched_keywords = []
            
            for _, row in condition_data.iterrows():
                explanation = str(row['explanation']).lower()
                
                # Check for pattern match with any keyword
                matched_kw = []
                for keyword in keywords:
                    if keyword.lower() in explanation:
                        matched_kw.append(keyword)
                
                if matched_kw:  # If any keywords matched
                    matches.append(row)
                    matched_keywords.extend(matched_kw)
                    
                    if len(examples) < 5:  # Keep top 5 examples per condition
                        examples.append({
                            'pattern': row['pattern'],
                            'decision': row['release_decision'],
                            'matched_keywords': matched_kw[:3],  # Show first 3 matched keywords
                            'text': row['explanation'][:400] + '...' if len(row['explanation']) > 400 else row['explanation']
                        })
            
            # Count unique matched keywords
            unique_matched_keywords = list(set(matched_keywords))
            
            results['by_condition'][condition] = {
                'count': len(matches),
                'total': len(condition_data),
                'percentage': (len(matches) / len(condition_data)) * 100 if len(condition_data) > 0 else 0,
                'examples': examples,
                'matched_keywords': unique_matched_keywords[:10],  # Top 10 most relevant
                'keyword_coverage': len(unique_matched_keywords) / len(keywords) * 100
            }
            
            # Store raw data for statistical tests
            results['statistical_data'][condition] = [
                1 if any(keyword.lower() in str(row['explanation']).lower() for keyword in keywords) else 0 
                for _, row in condition_data.iterrows()
            ]
        
        return results
    
    def _perform_comprehensive_statistical_tests(self, results):
        """Perform comprehensive statistical tests with interpretation."""
        print("Performing comprehensive statistical significance tests...")
        
        for pattern_name, pattern_data in results.items():
            # Prepare contingency table
            conditions = ['UEQ', 'UEEQ', 'RAW']
            
            # Count matches and non-matches for each condition
            matches = [pattern_data['by_condition'][cond]['count'] for cond in conditions]
            totals = [pattern_data['by_condition'][cond]['total'] for cond in conditions]
            non_matches = [total - match for total, match in zip(totals, matches)]
            
            # Create contingency table
            contingency_table = np.array([matches, non_matches])
            
            # Perform chi-square test
            chi2, p_value, dof, expected = stats.chi2_contingency(contingency_table)
            
            # Calculate effect size (Cramér's V)
            n = np.sum(contingency_table)
            cramers_v = np.sqrt(chi2 / (n * (min(contingency_table.shape) - 1)))
            
            # Determine if hypothesis is supported
            expected_cond = pattern_data['expected_condition']
            percentages = {cond: pattern_data['by_condition'][cond]['percentage'] for cond in conditions}
            
            hypothesis_supported = False
            if expected_cond == 'RAW':
                hypothesis_supported = percentages['RAW'] > max(percentages['UEQ'], percentages['UEEQ'])
            elif expected_cond == 'UEEQ':
                hypothesis_supported = percentages['UEEQ'] > max(percentages['UEQ'], percentages['RAW'])
            elif expected_cond == 'UEQ':
                hypothesis_supported = percentages['UEQ'] > max(percentages['UEEQ'], percentages['RAW'])
            elif expected_cond == 'UEQ_UEEQ':
                hypothesis_supported = (percentages['UEQ'] + percentages['UEEQ']) / 2 > percentages['RAW']
            elif expected_cond == 'DISTRIBUTED':
                # For distributed patterns, check if differences are minimal
                max_diff = max(percentages.values()) - min(percentages.values())
                hypothesis_supported = max_diff < 5.0  # Less than 5% difference
            
            pattern_data['statistical_test'] = {
                'chi2': chi2,
                'p_value': p_value,
                'cramers_v': cramers_v,
                'significant': p_value < 0.05,
                'highly_significant': p_value < 0.01,
                'contingency_table': contingency_table.tolist(),
                'hypothesis_supported': hypothesis_supported,
                'effect_size_interpretation': self._interpret_effect_size(cramers_v)
            }
        
        # Save comprehensive results
        self._save_comprehensive_results(results)
        
        return results
    
    def _interpret_effect_size(self, cramers_v):
        """Interpret Cramér's V effect size."""
        if cramers_v < 0.1:
            return "Small effect"
        elif cramers_v < 0.3:
            return "Medium effect"
        elif cramers_v < 0.5:
            return "Large effect"
        else:
            return "Very large effect"
    
    def _save_comprehensive_results(self, results):
        """Save comprehensive statistical analysis with clear interpretation."""
        with open(self.output_dir / "COMPREHENSIVE_HYPOTHESIS_ANALYSIS.txt", 'w') as f:
            f.write("COMPREHENSIVE HYPOTHESIS-DRIVEN ANALYSIS\n")
            f.write("=" * 50 + "\n\n")
            
            f.write("RESEARCH DESIGN:\n")
            f.write("-" * 16 + "\n")
            f.write("• Statistical tests examine CONDITION DIFFERENCES (UEQ vs UEEQ vs RAW)\n")
            f.write("• Keywords derived from comprehensive data examination\n") 
            f.write("• Patterns are hypothesis-driven based on observed phenomena\n")
            f.write("• Chi-square tests determine if conditions differ significantly\n")
            f.write("• Effect sizes (Cramér's V) measure practical significance\n\n")
            
            f.write("HYPOTHESIS TESTING RESULTS:\n")
            f.write("-" * 27 + "\n")
            f.write(f"{'Pattern':<30} {'Supported':<10} {'p-value':<10} {'Effect':<12} {'Max Condition':<15}\n")
            f.write("-" * 77 + "\n")
            
            for pattern_name, data in results.items():
                supported = "YES" if data['statistical_test']['hypothesis_supported'] else "NO"
                p_val = data['statistical_test']['p_value']
                effect = data['statistical_test']['effect_size_interpretation']
                
                # Find condition with highest percentage
                percentages = {cond: data['by_condition'][cond]['percentage'] for cond in ['UEQ', 'UEEQ', 'RAW']}
                max_condition = max(percentages.keys(), key=lambda x: percentages[x])
                max_pct = f"{max_condition} ({percentages[max_condition]:.1f}%)"
                
                f.write(f"{pattern_name:<30} {supported:<10} {p_val:<10.3f} {effect:<12} {max_pct:<15}\n")
            
            f.write("\n" + "=" * 77 + "\n\n")
            
            # Detailed analysis for each pattern
            for pattern_name, data in results.items():
                f.write(f"{pattern_name.upper().replace('_', ' ')}\n")
                f.write("-" * len(pattern_name) + "\n")
                f.write(f"Hypothesis: {data['hypothesis']}\n")
                f.write(f"Expected condition: {data['expected_condition']}\n")
                f.write(f"Keywords analyzed: {data['keyword_count']}\n\n")
                
                # Statistical results
                stat_test = data['statistical_test']
                f.write(f"STATISTICAL RESULTS:\n")
                f.write(f"  Chi-square: χ² = {stat_test['chi2']:.3f}\n")
                f.write(f"  P-value: p = {stat_test['p_value']:.3f}\n")
                f.write(f"  Effect size: {stat_test['cramers_v']:.3f} ({stat_test['effect_size_interpretation']})\n")
                f.write(f"  Statistically significant: {'Yes' if stat_test['significant'] else 'No'}\n")
                f.write(f"  Hypothesis supported: {'Yes' if stat_test['hypothesis_supported'] else 'No'}\n\n")
                
                # Condition breakdown with matched keywords
                f.write(f"CONDITION BREAKDOWN:\n")
                for condition in ['UEQ', 'UEEQ', 'RAW']:
                    cond_data = data['by_condition'][condition]
                    f.write(f"  {condition}: {cond_data['count']}/{cond_data['total']} ({cond_data['percentage']:.1f}%)\n")
                    f.write(f"    Keyword coverage: {cond_data['keyword_coverage']:.1f}%\n")
                    if cond_data['matched_keywords']:
                        f.write(f"    Top matched keywords: {', '.join(cond_data['matched_keywords'][:5])}\n")
                
                # Show examples from highest prevalence condition
                percentages = {cond: data['by_condition'][cond]['percentage'] for cond in ['UEQ', 'UEEQ', 'RAW']}
                max_condition = max(percentages.keys(), key=lambda x: percentages[x])
                
                if data['by_condition'][max_condition]['examples']:
                    f.write(f"\nEXAMPLES FROM {max_condition} (highest prevalence):\n")
                    for i, ex in enumerate(data['by_condition'][max_condition]['examples'][:3], 1):
                        f.write(f"{i}. [P{ex['pattern']}, {ex['decision']}] Keywords: {', '.join(ex['matched_keywords'])}\n")
                        f.write(f"   {ex['text'][:200]}...\n\n")
                
                f.write("=" * 80 + "\n\n")
        
        print("✓ Comprehensive analysis saved")
    
    def _create_comprehensive_visualizations(self, results):
        """Create comprehensive visualizations."""
        fig, axes = plt.subplots(2, 2, figsize=(16, 12))
        
        # 1. Hypothesis support overview
        pattern_names = []
        hypothesis_support = []
        p_values = []
        effect_sizes = []
        
        for name, result in results.items():
            pattern_names.append(name.replace('_', '\\n'))
            hypothesis_support.append(result['statistical_test']['hypothesis_supported'])
            p_values.append(result['statistical_test']['p_value'])
            effect_sizes.append(result['statistical_test']['cramers_v'])
        
        colors = ['green' if sup else 'red' for sup in hypothesis_support]
        bars = axes[0, 0].bar(range(len(pattern_names)), effect_sizes, color=colors, alpha=0.7)
        axes[0, 0].set_xlabel('Pattern')
        axes[0, 0].set_ylabel('Effect Size (Cramér\'s V)')
        axes[0, 0].set_title('Hypothesis Support and Effect Sizes\\n(Green = Hypothesis Supported)')
        axes[0, 0].set_xticks(range(len(pattern_names)))
        axes[0, 0].set_xticklabels(pattern_names, rotation=45, ha='right', fontsize=9)
        
        # Add effect size interpretation lines
        axes[0, 0].axhline(y=0.1, color='orange', linestyle='--', alpha=0.5, label='Small effect')
        axes[0, 0].axhline(y=0.3, color='red', linestyle='--', alpha=0.5, label='Medium effect')
        axes[0, 0].legend()
        
        # 2. Pattern prevalence heatmap
        prevalence_data = []
        for name, result in results.items():
            row = [result['by_condition'][cond]['percentage'] for cond in ['UEQ', 'UEEQ', 'RAW']]
            prevalence_data.append(row)
        
        prevalence_matrix = np.array(prevalence_data)
        pattern_labels = [name.replace('_', '\\n') for name in results.keys()]
        
        im = axes[0, 1].imshow(prevalence_matrix, cmap='Blues', aspect='auto')
        axes[0, 1].set_xticks([0, 1, 2])
        axes[0, 1].set_xticklabels(['UEQ', 'UEEQ', 'RAW'])
        axes[0, 1].set_yticks(range(len(pattern_labels)))
        axes[0, 1].set_yticklabels(pattern_labels, fontsize=9)
        axes[0, 1].set_title('Pattern Prevalence by Condition (%)')
        
        # Add text annotations
        for i in range(len(pattern_labels)):
            for j in range(3):
                text = axes[0, 1].text(j, i, f'{prevalence_matrix[i, j]:.1f}', 
                                     ha="center", va="center", color="black" if prevalence_matrix[i, j] < 15 else "white")
        
        plt.colorbar(im, ax=axes[0, 1])
        
        # 3. Statistical significance scatter
        scatter = axes[1, 0].scatter(effect_sizes, [-np.log10(p) for p in p_values], 
                                   c=colors, alpha=0.7, s=100)
        axes[1, 0].axhline(y=-np.log10(0.05), color='red', linestyle='--', alpha=0.5, label='p = 0.05')
        axes[1, 0].axhline(y=-np.log10(0.01), color='darkred', linestyle='--', alpha=0.5, label='p = 0.01')
        axes[1, 0].set_xlabel('Effect Size (Cramér\'s V)')
        axes[1, 0].set_ylabel('-log10(p-value)')
        axes[1, 0].set_title('Statistical Significance vs Effect Size')
        axes[1, 0].legend()
        
        # Add pattern labels for significant results
        for i, (name, p_val, effect) in enumerate(zip(pattern_names, p_values, effect_sizes)):
            if p_val < 0.05:  # Only label significant patterns
                axes[1, 0].annotate(name, (effect, -np.log10(p_val)), 
                                  xytext=(5, 5), textcoords='offset points', fontsize=8)
        
        # 4. Keyword coverage analysis
        pattern_names_clean = [name.replace('_', ' ').title() for name in results.keys()]
        avg_coverage = []
        for name, result in results.items():
            coverages = [result['by_condition'][cond]['keyword_coverage'] for cond in ['UEQ', 'UEEQ', 'RAW']]
            avg_coverage.append(np.mean(coverages))
        
        bars = axes[1, 1].barh(range(len(pattern_names_clean)), avg_coverage, alpha=0.7)
        axes[1, 1].set_yticks(range(len(pattern_names_clean)))
        axes[1, 1].set_yticklabels(pattern_names_clean, fontsize=9)
        axes[1, 1].set_xlabel('Average Keyword Coverage (%)')
        axes[1, 1].set_title('Pattern Recognition Quality\\n(Higher = Better Keyword Match)')
        
        plt.tight_layout()
        plt.savefig(self.output_dir / "comprehensive_hypothesis_analysis.png", dpi=300, bbox_inches='tight')
        plt.close()
        
        print("✓ Comprehensive visualizations created")

def main():
    """Main comprehensive analysis pipeline."""
    print("IMPROVED HYPOTHESIS-DRIVEN ANALYSIS")
    print("=" * 45)
    print("Analyzing condition differences with comprehensive keyword lists...")
    
    analyzer = ImprovedHypothesisDrivenAnalyzer()
    
    try:
        analyzer.load_data()
        
        print("\\n1. Analyzing Hypothesis-Driven Patterns...")
        pattern_results = analyzer.analyze_hypothesis_driven_patterns()
        
        print(f"\\n✓ Comprehensive analysis complete!")
        print(f"Results saved to: {analyzer.output_dir}")
        
        # Quick summary
        supported_hypotheses = sum(1 for result in pattern_results.values() 
                                 if result['statistical_test']['hypothesis_supported'])
        significant_patterns = sum(1 for result in pattern_results.values() 
                                 if result['statistical_test']['significant'])
        
        print(f"\\nQUICK SUMMARY:")
        print(f"  Total patterns analyzed: {len(pattern_results)}")
        print(f"  Statistically significant: {significant_patterns}")
        print(f"  Hypotheses supported: {supported_hypotheses}")
        print(f"  Analysis focus: CONDITION DIFFERENCES (UEQ vs UEEQ vs RAW)")
        
    except Exception as e:
        print(f"Error during analysis: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
