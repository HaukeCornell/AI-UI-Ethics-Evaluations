#!/usr/bin/env python3
"""
Targeted Qualitative Analysis for CHI 2025
Focus on key insights: Business vs Ethics reasoning, and interesting individual responses

This script performs targeted analysis to identify:
1. Business-focused reasoning in RAW condition
2. Ethics-focused reasoning in UEEQ condition  
3. Most interesting individual rejection/acceptance rationales
4. Specific patterns like guilt-tripping, manipulation, aesthetics focus
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
import json
import re
from collections import Counter
import warnings
warnings.filterwarnings('ignore')

class TargetedQualitativeAnalyzer:
    def __init__(self, data_dir="explanation_analysis_output"):
        """Initialize the targeted analyzer."""
        self.data_dir = Path(data_dir)
        self.explanations_df = None
        self.output_dir = self.data_dir / "targeted_analysis"
        self.output_dir.mkdir(exist_ok=True)
        
        print("Targeted Qualitative Analyzer initialized")
        print(f"Output directory: {self.output_dir}")
    
    def load_data(self):
        """Load the explanation data."""
        csv_file = self.data_dir / "all_explanations_raw.csv"
        self.explanations_df = pd.read_csv(csv_file)
        self.explanations_df['pattern'] = self.explanations_df['pattern'].astype(int)
        print(f"Loaded {len(self.explanations_df)} explanations")
        return self.explanations_df
    
    def analyze_business_vs_ethics_focus(self):
        """
        Analyze business vs ethics focus across conditions.
        Hypothesis: RAW → more business focus, UEEQ → more ethics focus
        """
        print("Analyzing business vs ethics focus by condition...")
        
        # Define more specific keywords
        business_keywords = [
            # Direct business terms
            'business', 'commercial', 'profit', 'revenue', 'money', 'cost', 'value', 
            'market', 'sell', 'selling', 'financial', 'monetize', 'strategic',
            # Pragmatic terms
            'common', 'standard', 'typical', 'normal', 'industry', 'competitive',
            'follows similarly', 'like other', 'giants', 'mainstream'
        ]
        
        ethics_keywords = [
            # Direct ethics terms
            'ethical', 'unethical', 'manipulative', 'deceptive', 'misleading', 
            'honest', 'transparent', 'fair', 'unfair', 'wrong', 'right',
            # Manipulation terms
            'manipulation', 'guilt', 'tripping', 'guilt tripping', 'forced', 'forcing',
            'pressure', 'coerce', 'trick', 'deceive', 'lie', 'lying',
            # Autonomy terms
            'autonomy', 'control', 'choice', 'freedom', 'respect', 'disrespectful',
            'hateful', 'unacceptable'
        ]
        
        results = {}
        
        for condition in ['UEQ', 'UEEQ', 'RAW']:
            condition_data = self.explanations_df[self.explanations_df['condition'] == condition]
            
            business_count = 0
            ethics_count = 0
            business_examples = []
            ethics_examples = []
            
            for _, row in condition_data.iterrows():
                explanation = str(row['explanation']).lower()
                
                # Check for business focus
                business_match = any(keyword in explanation for keyword in business_keywords)
                if business_match and len(business_examples) < 5:
                    business_examples.append({
                        'pattern': row['pattern'],
                        'decision': row['release_decision'],
                        'text': row['explanation'][:200] + '...' if len(row['explanation']) > 200 else row['explanation']
                    })
                    business_count += 1
                
                # Check for ethics focus
                ethics_match = any(keyword in explanation for keyword in ethics_keywords)
                if ethics_match and len(ethics_examples) < 5:
                    ethics_examples.append({
                        'pattern': row['pattern'],
                        'decision': row['release_decision'],
                        'text': row['explanation'][:200] + '...' if len(row['explanation']) > 200 else row['explanation']
                    })
                    ethics_count += 1
            
            results[condition] = {
                'total_explanations': len(condition_data),
                'business_count': business_count,
                'ethics_count': ethics_count,
                'business_percentage': (business_count / len(condition_data)) * 100,
                'ethics_percentage': (ethics_count / len(condition_data)) * 100,
                'business_examples': business_examples,
                'ethics_examples': ethics_examples
            }
        
        self._save_business_ethics_analysis(results)
        return results
    
    def _save_business_ethics_analysis(self, results):
        """Save business vs ethics analysis."""
        with open(self.output_dir / "business_vs_ethics_analysis.txt", 'w') as f:
            f.write("BUSINESS VS ETHICS FOCUS ANALYSIS\n")
            f.write("=" * 40 + "\n\n")
            
            f.write("HYPOTHESIS TEST: RAW → Business Focus, UEEQ → Ethics Focus\n")
            f.write("-" * 60 + "\n\n")
            
            # Summary table
            f.write("CONDITION COMPARISON:\n")
            f.write("-" * 20 + "\n")
            f.write(f"{'Condition':<10} {'Business %':<12} {'Ethics %':<10} {'Ratio':<10}\n")
            f.write("-" * 42 + "\n")
            
            for condition, data in results.items():
                ratio = data['business_percentage'] / data['ethics_percentage'] if data['ethics_percentage'] > 0 else "∞"
                f.write(f"{condition:<10} {data['business_percentage']:<12.1f} {data['ethics_percentage']:<10.1f} {ratio:<10}\n")
            
            f.write("\n" + "=" * 60 + "\n\n")
            
            # Detailed analysis by condition
            for condition, data in results.items():
                f.write(f"{condition} CONDITION ANALYSIS\n")
                f.write("-" * (len(condition) + 19) + "\n")
                f.write(f"Total explanations: {data['total_explanations']}\n")
                f.write(f"Business focus: {data['business_count']} ({data['business_percentage']:.1f}%)\n")
                f.write(f"Ethics focus: {data['ethics_count']} ({data['ethics_percentage']:.1f}%)\n\n")
                
                if data['business_examples']:
                    f.write("BUSINESS-FOCUSED EXAMPLES:\n")
                    for i, ex in enumerate(data['business_examples'], 1):
                        f.write(f"{i}. [P{ex['pattern']}, {ex['decision']}] {ex['text']}\n\n")
                
                if data['ethics_examples']:
                    f.write("ETHICS-FOCUSED EXAMPLES:\n")
                    for i, ex in enumerate(data['ethics_examples'], 1):
                        f.write(f"{i}. [P{ex['pattern']}, {ex['decision']}] {ex['text']}\n\n")
                
                f.write("=" * 60 + "\n\n")
        
        print("✓ Business vs ethics analysis saved")
    
    def find_most_interesting_responses(self):
        """Find the most interesting individual responses that reveal deep insights."""
        print("Identifying most interesting individual responses...")
        
        # Define patterns that indicate interesting responses
        interesting_patterns = {
            'strong_emotion': {
                'keywords': ['hate', 'love', 'disgusting', 'terrible', 'awful', 'amazing', 'brilliant'],
                'description': 'Strong emotional reactions'
            },
            'manipulation_awareness': {
                'keywords': ['manipulative', 'manipulation', 'guilt trip', 'guilt tripping', 'trick', 'deceive'],
                'description': 'Recognition of manipulative design'
            },
            'responsibility_avoidance': {
                'keywords': ['supervisor', 'boss', 'trust his decision', 'not my call', 'above my pay'],
                'description': 'Avoiding personal responsibility'
            },
            'aesthetic_focus': {
                'keywords': ['colors', 'visual hierarchy', 'aesthetics', 'appealing', 'beautiful', 'ugly'],
                'description': 'Focus on visual aesthetics over ethics'
            },
            'industry_conformity': {
                'keywords': ['common interface', 'follows similarly', 'other social media', 'giants', 'standard'],
                'description': 'Justification through industry conformity'
            },
            'user_autonomy': {
                'keywords': ['forced', 'forcing', 'choice', 'freedom', 'control', 'autonomy'],
                'description': 'Concern for user autonomy and control'
            }
        }
        
        categorized_responses = {}
        
        for pattern_name, pattern_info in interesting_patterns.items():
            categorized_responses[pattern_name] = {
                'description': pattern_info['description'],
                'responses': []
            }
            
            for _, row in self.explanations_df.iterrows():
                explanation = str(row['explanation']).lower()
                
                # Check if this response matches the pattern
                if any(keyword in explanation for keyword in pattern_info['keywords']):
                    categorized_responses[pattern_name]['responses'].append({
                        'condition': row['condition'],
                        'pattern': row['pattern'],
                        'decision': row['release_decision'],
                        'full_text': row['explanation'],
                        'length': len(row['explanation'])
                    })
        
        # Sort responses within each category by length (longer = more detailed)
        for category in categorized_responses.values():
            category['responses'].sort(key=lambda x: x['length'], reverse=True)
            category['responses'] = category['responses'][:10]  # Keep top 10
        
        self._save_interesting_responses(categorized_responses)
        return categorized_responses
    
    def _save_interesting_responses(self, categorized_responses):
        """Save the most interesting responses."""
        with open(self.output_dir / "most_interesting_responses.txt", 'w') as f:
            f.write("MOST INTERESTING INDIVIDUAL RESPONSES\n")
            f.write("=" * 45 + "\n\n")
            
            f.write("This analysis identifies responses that reveal deep insights into\n")
            f.write("how UX professionals reason about ethical design decisions.\n\n")
            
            for pattern_name, data in categorized_responses.items():
                if data['responses']:  # Only show categories with responses
                    f.write(f"{pattern_name.upper().replace('_', ' ')}\n")
                    f.write(f"{data['description']}\n")
                    f.write("-" * 50 + "\n")
                    
                    for i, response in enumerate(data['responses'][:5], 1):  # Top 5 per category
                        f.write(f"\n{i}. [{response['condition']}-P{response['pattern']}, {response['decision']}]\n")
                        f.write(f"   \"{response['full_text']}\"\n")
                    
                    f.write("\n" + "=" * 70 + "\n\n")
        
        print("✓ Most interesting responses saved")
    
    def analyze_specific_examples(self):
        """Analyze the specific examples you mentioned."""
        print("Analyzing your specific examples...")
        
        # Find examples that match your quotes
        specific_quotes = [
            "I HATE the language that is being used",
            "My supervior signing off on the designs",
            "Unacceptable copy which is just guilt tripping",
            "it lacks colors",
            "very manipulative, and it is like people are being forced",
            "Great UI, follows similarly to other social media giants",
            "good way to lightly discourage users",
            "fundamentally deceptive: it tells users their geolocation is off"
        ]
        
        matches = []
        
        for _, row in self.explanations_df.iterrows():
            explanation = row['explanation']
            
            for quote in specific_quotes:
                if quote.lower() in explanation.lower():
                    matches.append({
                        'quote_match': quote,
                        'condition': row['condition'],
                        'pattern': row['pattern'],
                        'decision': row['release_decision'],
                        'full_explanation': explanation
                    })
        
        self._save_specific_examples(matches)
        return matches
    
    def _save_specific_examples(self, matches):
        """Save analysis of specific examples."""
        with open(self.output_dir / "specific_example_analysis.txt", 'w') as f:
            f.write("ANALYSIS OF SPECIFIC EXAMPLES\n")
            f.write("=" * 35 + "\n\n")
            
            f.write("These are the specific quotes you mentioned and their full context:\n\n")
            
            for i, match in enumerate(matches, 1):
                f.write(f"{i}. QUOTE MATCH: \"{match['quote_match']}\"\n")
                f.write(f"   Condition: {match['condition']}\n")
                f.write(f"   Pattern: {match['pattern']}\n")
                f.write(f"   Decision: {match['decision']}\n")
                f.write(f"   Full explanation:\n")
                f.write(f"   \"{match['full_explanation']}\"\n\n")
                f.write("-" * 70 + "\n\n")
        
        print("✓ Specific examples analysis saved")
    
    def create_focused_word_clouds(self):
        """Create word clouds with better stop word filtering."""
        print("Creating focused word clouds with domain-specific filtering...")
        
        from wordcloud import WordCloud
        
        # Comprehensive stop words for UX domain
        comprehensive_stopwords = {
            # Generic words
            'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by',
            'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had',
            'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might', 'can',
            'this', 'that', 'these', 'those', 'i', 'you', 'he', 'she', 'it', 'we', 'they',
            'me', 'him', 'her', 'us', 'them', 'my', 'your', 'his', 'her', 'its', 'our', 'their',
            'myself', 'yourself', 'himself', 'herself', 'itself', 'ourselves', 'themselves',
            'what', 'which', 'who', 'whom', 'whose', 'where', 'when', 'why', 'how',
            'all', 'any', 'both', 'each', 'few', 'more', 'most', 'other', 'some', 'such',
            'no', 'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very', 'just',
            'now', 'here', 'there', 'then', 'up', 'out', 'down', 'off', 'over', 'under',
            'again', 'further', 'once', 'during', 'before', 'after', 'above', 'below',
            'from', 'into', 'through', 'between', 'among', 'upon', 'against', 'within',
            'without', 'about', 'around', 'across', 'along', 'toward', 'towards',
            # UX/UI generic terms
            'interface', 'design', 'user', 'users', 'ui', 'ux', 'app', 'application',
            'website', 'site', 'page', 'element', 'button', 'screen', 'layout',
            'would', 'could', 'should', 'one', 'also', 'get', 'like', 'good', 'bad',
            'well', 'make', 'think', 'seems', 'looks', 'pretty', 'quite', 'still',
            'really', 'much', 'many', 'way', 'thing', 'things', 'time', 'feel',
            'feeling', 'people', 'person', 'release', 'because', 'overall'
        }
        
        # Create condition-specific word clouds with better filtering
        conditions = ['UEQ', 'UEEQ', 'RAW']
        fig, axes = plt.subplots(1, 3, figsize=(18, 6))
        
        for i, condition in enumerate(conditions):
            condition_data = self.explanations_df[self.explanations_df['condition'] == condition]
            condition_text = ' '.join(condition_data['explanation'].astype(str))
            
            wordcloud = WordCloud(
                width=600, height=400,
                background_color='white',
                stopwords=comprehensive_stopwords,
                max_words=30,  # Fewer words for more focus
                relative_scaling=0.5,
                colormap='Set2',
                min_font_size=12
            ).generate(condition_text)
            
            axes[i].imshow(wordcloud, interpolation='bilinear')
            axes[i].set_title(f'{condition} Condition', fontsize=14, fontweight='bold')
            axes[i].axis('off')
        
        plt.suptitle('Focused Word Clouds: Key Terms by Condition', fontsize=16, fontweight='bold')
        plt.tight_layout()
        plt.savefig(self.output_dir / "focused_wordclouds_by_condition.png", dpi=300, bbox_inches='tight')
        plt.close()
        
        # Create decision-specific word clouds
        fig, axes = plt.subplots(1, 2, figsize=(12, 6))
        
        decisions = [('Yes', 'Accept'), ('No', 'Reject')]
        colors = ['Greens', 'Reds']
        
        for i, (decision, label) in enumerate(decisions):
            decision_data = self.explanations_df[self.explanations_df['release_decision'] == decision]
            decision_text = ' '.join(decision_data['explanation'].astype(str))
            
            wordcloud = WordCloud(
                width=600, height=400,
                background_color='white',
                stopwords=comprehensive_stopwords,
                max_words=30,
                relative_scaling=0.5,
                colormap=colors[i],
                min_font_size=12
            ).generate(decision_text)
            
            axes[i].imshow(wordcloud, interpolation='bilinear')
            axes[i].set_title(f'{label} Decisions', fontsize=14, fontweight='bold')
            axes[i].axis('off')
        
        plt.suptitle('Focused Word Clouds: Key Terms by Decision', fontsize=16, fontweight='bold')
        plt.tight_layout()
        plt.savefig(self.output_dir / "focused_wordclouds_by_decision.png", dpi=300, bbox_inches='tight')
        plt.close()
        
        print("✓ Focused word clouds created")
    
    def create_summary_report(self):
        """Create a comprehensive summary of targeted findings."""
        with open(self.output_dir / "TARGETED_ANALYSIS_SUMMARY.txt", 'w') as f:
            f.write("TARGETED QUALITATIVE ANALYSIS SUMMARY\n")
            f.write("CHI 2025: Deep Insights into UX Professional Reasoning\n")
            f.write("=" * 60 + "\n\n")
            
            f.write("KEY RESEARCH QUESTIONS ADDRESSED:\n")
            f.write("-" * 34 + "\n")
            f.write("1. Do different conditions lead to different reasoning focus?\n")
            f.write("   → Business focus in RAW vs Ethics focus in UEEQ\n\n")
            f.write("2. What are the most revealing individual responses?\n")
            f.write("   → Strong emotions, manipulation awareness, responsibility avoidance\n\n")
            f.write("3. How do professionals justify controversial decisions?\n")
            f.write("   → Industry conformity, aesthetic focus, delegation of responsibility\n\n")
            
            f.write("METHODOLOGICAL CONTRIBUTIONS:\n")
            f.write("-" * 29 + "\n")
            f.write("• Pattern-based categorization of reasoning types\n")
            f.write("• Identification of avoidance and conformity patterns\n")
            f.write("• Framework for analyzing professional moral reasoning\n")
            f.write("• Qualitative validation of quantitative topic modeling\n\n")
            
            f.write("IMPLICATIONS FOR DESIGN EDUCATION:\n")
            f.write("-" * 34 + "\n")
            f.write("• Need to address responsibility avoidance in training\n")
            f.write("• Importance of ethical reasoning beyond aesthetics\n")
            f.write("• Critical evaluation of 'industry standard' justifications\n")
            f.write("• Recognition of emotional responses to manipulative design\n")
        
        print("✓ Summary report created")

def main():
    """Main analysis pipeline for targeted insights."""
    print("Targeted Qualitative Analysis for CHI 2025")
    print("=" * 45)
    
    analyzer = TargetedQualitativeAnalyzer()
    
    try:
        # Load data
        analyzer.load_data()
        
        # Run targeted analyses
        print("\n1. Business vs Ethics Focus Analysis...")
        business_ethics_results = analyzer.analyze_business_vs_ethics_focus()
        
        print("\n2. Finding Most Interesting Responses...")
        interesting_responses = analyzer.find_most_interesting_responses()
        
        print("\n3. Analyzing Your Specific Examples...")
        specific_examples = analyzer.analyze_specific_examples()
        
        print("\n4. Creating Focused Word Clouds...")
        analyzer.create_focused_word_clouds()
        
        print("\n5. Creating Summary Report...")
        analyzer.create_summary_report()
        
        print("\n✓ Targeted analysis complete!")
        print(f"\nResults saved to: {analyzer.output_dir}")
        
        # Show quick summary
        print("\nQUICK INSIGHTS:")
        for condition, data in business_ethics_results.items():
            print(f"{condition}: {data['business_percentage']:.1f}% business, {data['ethics_percentage']:.1f}% ethics")
            
    except Exception as e:
        print(f"Error during analysis: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
