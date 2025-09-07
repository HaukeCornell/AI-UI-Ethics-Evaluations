#!/usr/bin/env python3
"""
Text-Only Advanced Explanation Analysis

This script performs advanced text analysis without requiring matplotlib or numpy.
It focuses on pattern identification, theme analysis, and comparative text analysis.

Author: Analysis for CHI 2025 Paper
Date: September 2025
"""

import csv
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

class TextOnlyAnalyzer:
    def __init__(self, data_dir="explanation_analysis_output"):
        """Initialize with the output directory from the simple analysis."""
        self.data_dir = Path(data_dir)
        self.explanations_data = []
        
        # Load the extracted data
        self._load_extracted_data()
    
    def _load_extracted_data(self):
        """Load the extracted explanation data from CSV."""
        csv_file = self.data_dir / "all_explanations_raw.csv"
        
        if not csv_file.exists():
            print(f"Error: {csv_file} not found. Run the simple analysis first.")
            return
        
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            self.explanations_data = list(reader)
        
        print(f"Loaded {len(self.explanations_data)} explanations from previous analysis")
    
    def analyze_key_themes(self):
        """Analyze key themes in explanations using scientifically validated categories."""
        print("Analyzing key themes...")
        
        # Define theme keywords based on UX and ethics research
        themes = {
            'usability': ['usability', 'usable', 'easy', 'difficult', 'hard', 'confusing', 'clear', 'unclear', 'intuitive', 'complicated'],
            'business_value': ['business', 'profit', 'revenue', 'cost', 'value', 'money', 'commercial', 'financial', 'economic'],
            'user_experience': ['experience', 'satisfaction', 'frustration', 'enjoyable', 'annoying', 'pleasant', 'unpleasant'],
            'ethics_manipulation': ['manipulative', 'deceptive', 'misleading', 'unethical', 'ethical', 'honest', 'transparent', 'fair', 'unfair'],
            'user_autonomy': ['autonomy', 'control', 'choice', 'freedom', 'forced', 'pressure', 'coerce', 'voluntary', 'involuntary'],
            'trust': ['trust', 'trustworthy', 'suspicious', 'reliable', 'credible', 'believable', 'doubt'],
            'design_quality': ['attractive', 'aesthetics', 'beautiful', 'ugly', 'appealing', 'professional', 'polished', 'crude'],
            'functionality': ['functional', 'working', 'broken', 'bugs', 'issues', 'problems', 'effective', 'efficient', 'ineffective'],
            'engagement': ['engaging', 'addictive', 'boring', 'interesting', 'captivating', 'stimulating', 'dull'],
            'cognitive_load': ['overwhelming', 'simple', 'complex', 'cognitive', 'mental', 'effort', 'strain', 'load']
        }
        
        # Count theme occurrences
        theme_counts = {}
        for theme in themes:
            theme_counts[theme] = {
                'total': 0,
                'by_condition': {'UEQ': 0, 'UEEQ': 0, 'RAW': 0},
                'by_release': {'Yes': 0, 'No': 0},
                'by_combination': {},
                'specific_mentions': []
            }
        
        for explanation_data in self.explanations_data:
            explanation = explanation_data['explanation'].lower()
            condition = explanation_data['condition']
            release = explanation_data['release_decision']
            pattern = explanation_data['pattern']
            combination_key = f"{condition}_{release}"
            
            for theme, keywords in themes.items():
                found_keywords = [kw for kw in keywords if kw in explanation]
                if found_keywords:
                    theme_counts[theme]['total'] += 1
                    theme_counts[theme]['by_condition'][condition] += 1
                    theme_counts[theme]['by_release'][release] += 1
                    
                    if combination_key not in theme_counts[theme]['by_combination']:
                        theme_counts[theme]['by_combination'][combination_key] = 0
                    theme_counts[theme]['by_combination'][combination_key] += 1
                    
                    # Store specific mentions for qualitative analysis
                    theme_counts[theme]['specific_mentions'].append({
                        'condition': condition,
                        'release': release,
                        'pattern': pattern,
                        'keywords_found': found_keywords,
                        'explanation_snippet': explanation[:100] + '...' if len(explanation) > 100 else explanation
                    })
        
        # Save theme analysis
        with open(self.data_dir / "theme_analysis_detailed.json", 'w') as f:
            json.dump(theme_counts, f, indent=2)
        
        # Create comprehensive theme report
        self._create_theme_report(theme_counts, themes)
        
        print(f"  ✓ Detailed theme analysis saved to theme_analysis_detailed.json")
        return theme_counts
    
    def _create_theme_report(self, theme_counts, themes):
        """Create a comprehensive theme analysis report."""
        with open(self.data_dir / "theme_analysis_comprehensive.txt", 'w') as f:
            f.write("COMPREHENSIVE THEME ANALYSIS REPORT\n")
            f.write("=" * 45 + "\n\n")
            
            # Overview
            f.write("OVERVIEW\n")
            f.write("-" * 15 + "\n")
            total_explanations = len(self.explanations_data)
            f.write(f"Total explanations analyzed: {total_explanations}\n\n")
            
            # Theme prevalence ranking
            theme_ranking = sorted(theme_counts.items(), key=lambda x: x[1]['total'], reverse=True)
            f.write("THEME PREVALENCE RANKING\n")
            f.write("-" * 25 + "\n")
            for i, (theme, data) in enumerate(theme_ranking, 1):
                percentage = (data['total'] / total_explanations) * 100
                f.write(f"{i:2}. {theme.replace('_', ' ').title(): <20} {data['total']:3} occurrences ({percentage:5.1f}%)\n")
            
            f.write("\n" + "=" * 45 + "\n\n")
            
            # Detailed analysis for each theme
            for theme, data in theme_ranking:
                f.write(f"{theme.replace('_', ' ').title().upper()}\n")
                f.write("-" * len(theme) + "\n")
                f.write(f"Total occurrences: {data['total']} ({(data['total']/total_explanations)*100:.1f}% of explanations)\n\n")
                
                # By condition analysis
                f.write("By Condition:\n")
                for condition in ['UEQ', 'UEEQ', 'RAW']:
                    count = data['by_condition'][condition]
                    condition_total = len([d for d in self.explanations_data if d['condition'] == condition])
                    percentage = (count / condition_total) * 100 if condition_total > 0 else 0
                    f.write(f"  {condition:5}: {count:3} / {condition_total:3} ({percentage:5.1f}%)\n")
                
                # By release decision analysis
                f.write("\nBy Release Decision:\n")
                for decision in ['Yes', 'No']:
                    count = data['by_release'][decision]
                    decision_total = len([d for d in self.explanations_data if d['release_decision'] == decision])
                    percentage = (count / decision_total) * 100 if decision_total > 0 else 0
                    f.write(f"  {decision:3}: {count:3} / {decision_total:3} ({percentage:5.1f}%)\n")
                
                # Combination analysis
                f.write("\nBy Condition-Release Combination:\n")
                for combination, count in sorted(data['by_combination'].items()):
                    condition, release = combination.split('_')
                    combo_total = len([d for d in self.explanations_data 
                                     if d['condition'] == condition and d['release_decision'] == release])
                    percentage = (count / combo_total) * 100 if combo_total > 0 else 0
                    f.write(f"  {condition}-{release}: {count:3} / {combo_total:3} ({percentage:5.1f}%)\n")
                
                f.write("\n" + "=" * 45 + "\n\n")
    
    def analyze_decision_patterns(self):
        """Analyze patterns in decision-making language."""
        print("Analyzing decision patterns...")
        
        # Define decision-making language patterns
        decision_patterns = {
            'certainty_high': ['definitely', 'certainly', 'clearly', 'obviously', 'absolutely', 'without doubt'],
            'certainty_low': ['maybe', 'perhaps', 'possibly', 'might', 'could be', 'seems like'],
            'data_reliance': ['based on', 'according to', 'data shows', 'scores indicate', 'metrics suggest'],
            'emotional_response': ['feel', 'feeling', 'sense', 'gut', 'instinct', 'impression'],
            'comparative': ['better than', 'worse than', 'compared to', 'relative to', 'versus'],
            'conditional': ['if', 'unless', 'provided that', 'assuming', 'depends on'],
            'risk_averse': ['risk', 'risky', 'dangerous', 'safe', 'caution', 'careful'],
            'user_focus': ['user needs', 'user wants', 'user experience', 'for users', 'user-friendly'],
            'business_focus': ['business needs', 'company', 'organization', 'profit', 'revenue', 'commercial']
        }
        
        pattern_analysis = {}
        for pattern_name in decision_patterns:
            pattern_analysis[pattern_name] = {
                'total': 0,
                'by_condition': {'UEQ': 0, 'UEEQ': 0, 'RAW': 0},
                'by_release': {'Yes': 0, 'No': 0},
                'examples': []
            }
        
        for explanation_data in self.explanations_data:
            explanation = explanation_data['explanation'].lower()
            condition = explanation_data['condition']
            release = explanation_data['release_decision']
            
            for pattern_name, keywords in decision_patterns.items():
                found_keywords = [kw for kw in keywords if kw in explanation]
                if found_keywords:
                    pattern_analysis[pattern_name]['total'] += 1
                    pattern_analysis[pattern_name]['by_condition'][condition] += 1
                    pattern_analysis[pattern_name]['by_release'][release] += 1
                    
                    # Store examples
                    if len(pattern_analysis[pattern_name]['examples']) < 3:
                        pattern_analysis[pattern_name]['examples'].append({
                            'condition': condition,
                            'release': release,
                            'keywords': found_keywords,
                            'snippet': explanation[:150] + '...' if len(explanation) > 150 else explanation
                        })
        
        # Save pattern analysis
        with open(self.data_dir / "decision_patterns.json", 'w') as f:
            json.dump(pattern_analysis, f, indent=2)
        
        # Create decision patterns report
        self._create_decision_patterns_report(pattern_analysis)
        
        print(f"  ✓ Decision patterns analysis saved to decision_patterns.json")
        return pattern_analysis
    
    def _create_decision_patterns_report(self, pattern_analysis):
        """Create a decision patterns report."""
        with open(self.data_dir / "decision_patterns_report.txt", 'w') as f:
            f.write("DECISION-MAKING PATTERNS ANALYSIS\n")
            f.write("=" * 40 + "\n\n")
            
            total_explanations = len(self.explanations_data)
            
            # Pattern prevalence
            pattern_ranking = sorted(pattern_analysis.items(), key=lambda x: x[1]['total'], reverse=True)
            
            f.write("PATTERN PREVALENCE\n")
            f.write("-" * 18 + "\n")
            for pattern_name, data in pattern_ranking:
                percentage = (data['total'] / total_explanations) * 100
                f.write(f"{pattern_name.replace('_', ' ').title(): <20} {data['total']:3} ({percentage:5.1f}%)\n")
            
            f.write("\n" + "=" * 40 + "\n\n")
            
            # Detailed analysis
            for pattern_name, data in pattern_ranking:
                if data['total'] > 0:
                    f.write(f"{pattern_name.replace('_', ' ').title().upper()}\n")
                    f.write("-" * len(pattern_name) + "\n")
                    
                    # Condition breakdown
                    f.write("By Condition:\n")
                    for condition in ['UEQ', 'UEEQ', 'RAW']:
                        count = data['by_condition'][condition]
                        f.write(f"  {condition}: {count}\n")
                    
                    # Release decision breakdown
                    f.write("By Release Decision:\n")
                    for decision in ['Yes', 'No']:
                        count = data['by_release'][decision]
                        f.write(f"  {decision}: {count}\n")
                    
                    # Examples
                    if data['examples']:
                        f.write("Examples:\n")
                        for example in data['examples']:
                            f.write(f"  - [{example['condition']}-{example['release']}] {example['snippet']}\n")
                    
                    f.write("\n" + "-" * 40 + "\n\n")
    
    def create_condition_comparison(self):
        """Create detailed comparison between conditions."""
        print("Creating condition comparison...")
        
        comparison = {
            'UEQ': {'explanations': [], 'characteristics': {}},
            'UEEQ': {'explanations': [], 'characteristics': {}},
            'RAW': {'explanations': [], 'characteristics': {}}
        }
        
        # Collect explanations by condition
        for condition in ['UEQ', 'UEEQ', 'RAW']:
            condition_data = [d for d in self.explanations_data if d['condition'] == condition]
            comparison[condition]['explanations'] = condition_data
            
            # Calculate characteristics
            total_explanations = len(condition_data)
            yes_decisions = len([d for d in condition_data if d['release_decision'] == 'Yes'])
            no_decisions = len([d for d in condition_data if d['release_decision'] == 'No'])
            
            avg_length = sum(len(d['explanation']) for d in condition_data) / total_explanations if total_explanations else 0
            
            # Count specific terms
            all_text = ' '.join([d['explanation'].lower() for d in condition_data])
            
            comparison[condition]['characteristics'] = {
                'total_explanations': total_explanations,
                'yes_decisions': yes_decisions,
                'no_decisions': no_decisions,
                'yes_percentage': (yes_decisions / total_explanations * 100) if total_explanations else 0,
                'average_length': avg_length,
                'mentions_score': all_text.count('score'),
                'mentions_user': all_text.count('user'),
                'mentions_business': all_text.count('business'),
                'mentions_ethical': all_text.count('ethical') + all_text.count('unethical'),
                'mentions_data': all_text.count('data'),
                'mentions_experience': all_text.count('experience')
            }
        
        # Save comparison
        with open(self.data_dir / "condition_comparison.json", 'w') as f:
            json.dump(comparison, f, indent=2, default=str)
        
        # Create comparison report
        self._create_condition_comparison_report(comparison)
        
        print(f"  ✓ Condition comparison saved to condition_comparison.json")
        return comparison
    
    def _create_condition_comparison_report(self, comparison):
        """Create a detailed condition comparison report."""
        with open(self.data_dir / "condition_comparison_report.txt", 'w') as f:
            f.write("CONDITION COMPARISON REPORT\n")
            f.write("=" * 30 + "\n\n")
            
            f.write("SUMMARY STATISTICS\n")
            f.write("-" * 18 + "\n")
            f.write(f"{'Metric':<25} {'UEQ':<10} {'UEEQ':<10} {'RAW':<10}\n")
            f.write("-" * 55 + "\n")
            
            metrics = [
                ('Total Explanations', 'total_explanations'),
                ('Yes Decisions', 'yes_decisions'),
                ('No Decisions', 'no_decisions'),
                ('Yes Percentage', 'yes_percentage'),
                ('Avg Length (chars)', 'average_length')
            ]
            
            for metric_name, metric_key in metrics:
                ueeq_val = comparison['UEQ']['characteristics'][metric_key]
                ueeq_val_formatted = comparison['UEEQ']['characteristics'][metric_key]
                raw_val = comparison['RAW']['characteristics'][metric_key]
                
                if 'percentage' in metric_key or 'average' in metric_key:
                    f.write(f"{metric_name:<25} {ueeq_val:<10.1f} {ueeq_val_formatted:<10.1f} {raw_val:<10.1f}\n")
                else:
                    f.write(f"{metric_name:<25} {ueeq_val:<10} {ueeq_val_formatted:<10} {raw_val:<10}\n")
            
            f.write("\n" + "=" * 55 + "\n\n")
            
            f.write("TERMINOLOGY USAGE\n")
            f.write("-" * 17 + "\n")
            f.write(f"{'Term':<15} {'UEQ':<10} {'UEEQ':<10} {'RAW':<10}\n")
            f.write("-" * 45 + "\n")
            
            terms = [
                ('Score', 'mentions_score'),
                ('User', 'mentions_user'),
                ('Business', 'mentions_business'),
                ('Ethical', 'mentions_ethical'),
                ('Data', 'mentions_data'),
                ('Experience', 'mentions_experience')
            ]
            
            for term_name, term_key in terms:
                ueeq_count = comparison['UEQ']['characteristics'][term_key]
                ueeq_count_formatted = comparison['UEEQ']['characteristics'][term_key]
                raw_count = comparison['RAW']['characteristics'][term_key]
                f.write(f"{term_name:<15} {ueeq_count:<10} {ueeq_count_formatted:<10} {raw_count:<10}\n")
            
            f.write("\n" + "=" * 45 + "\n\n")
            
            # Key insights
            f.write("KEY INSIGHTS\n")
            f.write("-" * 12 + "\n")
            
            # Release rate comparison
            ueeq_yes_rate = comparison['UEQ']['characteristics']['yes_percentage']
            ueeq_yes_rate_formatted = comparison['UEEQ']['characteristics']['yes_percentage']
            raw_yes_rate = comparison['RAW']['characteristics']['yes_percentage']
            
            f.write(f"1. Release Rates:\n")
            f.write(f"   - UEQ: {ueeq_yes_rate:.1f}% yes decisions\n")
            f.write(f"   - UEEQ: {ueeq_yes_rate_formatted:.1f}% yes decisions\n")
            f.write(f"   - RAW: {raw_yes_rate:.1f}% yes decisions\n\n")
            
            # Length differences
            ueeq_len = comparison['UEQ']['characteristics']['average_length']
            ueeq_len_formatted = comparison['UEEQ']['characteristics']['average_length']
            raw_len = comparison['RAW']['characteristics']['average_length']
            
            f.write(f"2. Explanation Length:\n")
            f.write(f"   - UEQ: {ueeq_len:.1f} characters (shortest)\n")
            f.write(f"   - UEEQ: {ueeq_len_formatted:.1f} characters (medium)\n")
            f.write(f"   - RAW: {raw_len:.1f} characters (longest)\n\n")
            
            # Score mentions
            ueeq_score = comparison['UEQ']['characteristics']['mentions_score']
            ueeq_score_formatted = comparison['UEEQ']['characteristics']['mentions_score']
            raw_score = comparison['RAW']['characteristics']['mentions_score']
            
            f.write(f"3. Data-Driven Language:\n")
            f.write(f"   - UEQ: {ueeq_score} mentions of 'score'\n")
            f.write(f"   - UEEQ: {ueeq_score_formatted} mentions of 'score'\n")
            f.write(f"   - RAW: {raw_score} mentions of 'score'\n")

def main():
    """Main function to run the text-only analysis."""
    print("Text-Only Advanced Explanation Analysis")
    print("=" * 40)
    
    # Initialize analyzer
    analyzer = TextOnlyAnalyzer()
    
    if not analyzer.explanations_data:
        print("No data found. Please run explanation_analysis_simple.py first.")
        return
    
    # Perform analyses
    analyzer.analyze_key_themes()
    analyzer.analyze_decision_patterns()
    analyzer.create_condition_comparison()
    
    print("\n✓ Text-only advanced analysis complete!")
    print("\nGenerated files:")
    output_dir = Path("explanation_analysis_output")
    new_files = [
        "theme_analysis_detailed.json",
        "theme_analysis_comprehensive.txt", 
        "decision_patterns.json",
        "decision_patterns_report.txt",
        "condition_comparison.json",
        "condition_comparison_report.txt"
    ]
    
    for filename in new_files:
        if (output_dir / filename).exists():
            print(f"  - {filename}")

if __name__ == "__main__":
    main()
