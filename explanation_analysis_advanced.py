#!/usr/bin/env python3
"""
Advanced Explanation Analysis with Word Clouds and Text Analysis

This script creates word clouds and performs advanced text analysis using
the already extracted explanation data.

Author: Analysis for CHI 2025 Paper
Date: September 2025
"""

import csv
import json
from collections import Counter
from pathlib import Path
import matplotlib.pyplot as plt

try:
    from wordcloud import WordCloud
    WORDCLOUD_AVAILABLE = True
except ImportError:
    WORDCLOUD_AVAILABLE = False
    print("WordCloud not available. Install with: pip install wordcloud")

class AdvancedTextAnalyzer:
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
    
    def generate_word_clouds(self):
        """Generate word clouds for different groupings."""
        if not WORDCLOUD_AVAILABLE:
            print("WordCloud library not available. Skipping word cloud generation.")
            return
        
        print("Generating word clouds...")
        
        # Overall word cloud
        all_texts = ' '.join([d['explanation'] for d in self.explanations_data])
        self._create_word_cloud(all_texts, "overall", "Overall Explanations")
        
        # Word clouds by condition
        for condition in ['UEQ', 'UEEQ', 'RAW']:
            condition_texts = ' '.join([d['explanation'] for d in self.explanations_data 
                                      if d['condition'] == condition])
            if condition_texts.strip():
                self._create_word_cloud(condition_texts, f"condition_{condition}", 
                                      f"{condition} Condition")
        
        # Word clouds by release decision
        for decision in ['Yes', 'No']:
            decision_texts = ' '.join([d['explanation'] for d in self.explanations_data 
                                     if d['release_decision'] == decision])
            if decision_texts.strip():
                self._create_word_cloud(decision_texts, f"release_{decision}", 
                                      f"Release Decision: {decision}")
        
        # Combined word clouds
        self._create_combined_word_clouds()
    
    def _create_word_cloud(self, text, filename_suffix, title):
        """Create and save a word cloud."""
        try:
            # Basic text cleaning
            text = text.lower()
            
            # Remove common stop words and UX-specific terms to focus on decision rationale
            stop_words = {
                'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
                'by', 'from', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
                'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should',
                'may', 'might', 'must', 'can', 'this', 'that', 'these', 'those', 'i', 'you',
                'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them', 'my', 'your',
                'interface', 'design', 'user', 'users', 'one', 'also', 'get', 'like', 'well',
                'make', 'think', 'seems', 'looks', 'pretty', 'quite'
            }
            
            # Create word cloud
            wordcloud = WordCloud(
                width=1200, height=600,
                background_color='white',
                max_words=100,
                colormap='viridis',
                stopwords=stop_words,
                collocations=False,
                relative_scaling=0.5,
                max_font_size=60
            ).generate(text)
            
            # Create figure
            plt.figure(figsize=(15, 7.5))
            plt.imshow(wordcloud, interpolation='bilinear')
            plt.axis('off')
            plt.title(title, fontsize=16, fontweight='bold', pad=20)
            plt.tight_layout()
            
            # Save
            output_file = self.data_dir / f"wordcloud_{filename_suffix}.png"
            plt.savefig(output_file, dpi=300, bbox_inches='tight', facecolor='white')
            plt.close()
            
            print(f"  ✓ Generated word cloud: {output_file}")
            
        except Exception as e:
            print(f"  Warning: Could not generate word cloud for {filename_suffix}: {e}")
    
    def _create_combined_word_clouds(self):
        """Create word clouds for combined conditions."""
        if not WORDCLOUD_AVAILABLE:
            return
        
        # Create a 2x3 subplot for different combinations
        fig, axes = plt.subplots(2, 3, figsize=(18, 12))
        fig.suptitle('Word Clouds by Condition and Release Decision', fontsize=16, fontweight='bold')
        
        conditions = ['UEQ', 'UEEQ', 'RAW']
        decisions = ['Yes', 'No']
        
        stop_words = {
            'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
            'by', 'from', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
            'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should',
            'interface', 'design', 'user', 'users', 'one', 'also', 'get', 'like', 'well',
            'make', 'think', 'seems', 'looks'
        }
        
        for i, decision in enumerate(decisions):
            for j, condition in enumerate(conditions):
                # Get texts for this combination
                texts = [d['explanation'] for d in self.explanations_data 
                        if d['condition'] == condition and d['release_decision'] == decision]
                combined_text = ' '.join(texts).lower()
                
                if combined_text.strip():
                    try:
                        wordcloud = WordCloud(
                            width=400, height=300,
                            background_color='white',
                            max_words=50,
                            colormap='viridis',
                            stopwords=stop_words,
                            collocations=False
                        ).generate(combined_text)
                        
                        axes[i, j].imshow(wordcloud, interpolation='bilinear')
                        axes[i, j].axis('off')
                        axes[i, j].set_title(f'{condition} - Release: {decision}\n({len(texts)} explanations)')
                    except:
                        axes[i, j].text(0.5, 0.5, f'No data\n{condition} - {decision}', 
                                      ha='center', va='center', transform=axes[i, j].transAxes)
                        axes[i, j].axis('off')
                else:
                    axes[i, j].text(0.5, 0.5, f'No data\n{condition} - {decision}', 
                                  ha='center', va='center', transform=axes[i, j].transAxes)
                    axes[i, j].axis('off')
        
        plt.tight_layout()
        output_file = self.data_dir / "wordcloud_combined_matrix.png"
        plt.savefig(output_file, dpi=300, bbox_inches='tight', facecolor='white')
        plt.close()
        
        print(f"  ✓ Generated combined word cloud matrix: {output_file}")
    
    def analyze_key_themes(self):
        """Analyze key themes in explanations."""
        print("Analyzing key themes...")
        
        # Define theme keywords
        themes = {
            'usability': ['usability', 'usable', 'easy', 'difficult', 'hard', 'confusing', 'clear', 'unclear'],
            'business_value': ['business', 'profit', 'revenue', 'cost', 'value', 'money', 'commercial'],
            'user_experience': ['experience', 'satisfaction', 'frustration', 'enjoyable', 'annoying'],
            'ethics_manipulation': ['manipulative', 'deceptive', 'misleading', 'unethical', 'ethical', 'honest', 'transparent'],
            'user_autonomy': ['autonomy', 'control', 'choice', 'freedom', 'forced', 'pressure', 'coerce'],
            'trust': ['trust', 'trustworthy', 'suspicious', 'reliable', 'credible'],
            'design_quality': ['attractive', 'aesthetics', 'beautiful', 'ugly', 'appealing', 'professional'],
            'functionality': ['functional', 'working', 'broken', 'bugs', 'issues', 'problems', 'effective']
        }
        
        # Count theme occurrences
        theme_counts = {theme: {'total': 0, 'by_condition': {}, 'by_release': {}} 
                       for theme in themes}
        
        for explanation_data in self.explanations_data:
            explanation = explanation_data['explanation'].lower()
            condition = explanation_data['condition']
            release = explanation_data['release_decision']
            
            for theme, keywords in themes.items():
                theme_found = any(keyword in explanation for keyword in keywords)
                if theme_found:
                    theme_counts[theme]['total'] += 1
                    
                    if condition not in theme_counts[theme]['by_condition']:
                        theme_counts[theme]['by_condition'][condition] = 0
                    theme_counts[theme]['by_condition'][condition] += 1
                    
                    if release not in theme_counts[theme]['by_release']:
                        theme_counts[theme]['by_release'][release] = 0
                    theme_counts[theme]['by_release'][release] += 1
        
        # Save theme analysis
        with open(self.data_dir / "theme_analysis.json", 'w') as f:
            json.dump(theme_counts, f, indent=2)
        
        # Create theme report
        with open(self.data_dir / "theme_analysis_report.txt", 'w') as f:
            f.write("KEY THEMES ANALYSIS\n")
            f.write("=" * 30 + "\n\n")
            
            f.write("Theme occurrences across all explanations:\n")
            for theme, data in sorted(theme_counts.items(), key=lambda x: x[1]['total'], reverse=True):
                f.write(f"\n{theme.replace('_', ' ').title()}: {data['total']} occurrences\n")
                
                f.write("  By condition:\n")
                for condition in ['UEQ', 'UEEQ', 'RAW']:
                    count = data['by_condition'].get(condition, 0)
                    f.write(f"    {condition}: {count}\n")
                
                f.write("  By release decision:\n")
                for decision in ['Yes', 'No']:
                    count = data['by_release'].get(decision, 0)
                    f.write(f"    {decision}: {count}\n")
        
        print(f"  ✓ Theme analysis saved to theme_analysis_report.txt")
    
    def create_comparative_analysis(self):
        """Create comparative analysis between conditions and release decisions."""
        print("Creating comparative analysis...")
        
        # Analyze explanation patterns
        patterns = {
            'length_analysis': self._analyze_lengths(),
            'sentiment_indicators': self._analyze_sentiment_indicators(),
            'decision_rationale': self._analyze_decision_rationale()
        }
        
        # Save comparative analysis
        with open(self.data_dir / "comparative_analysis.json", 'w') as f:
            json.dump(patterns, f, indent=2)
        
        # Create comparative report
        with open(self.data_dir / "comparative_analysis_report.txt", 'w') as f:
            f.write("COMPARATIVE ANALYSIS REPORT\n")
            f.write("=" * 35 + "\n\n")
            
            f.write("1. EXPLANATION LENGTH ANALYSIS\n")
            f.write("-" * 30 + "\n")
            for category, data in patterns['length_analysis'].items():
                f.write(f"\n{category}:\n")
                for key, value in data.items():
                    f.write(f"  {key}: {value:.1f} characters\n")
            
            f.write("\n2. SENTIMENT INDICATORS\n")
            f.write("-" * 25 + "\n")
            for category, data in patterns['sentiment_indicators'].items():
                f.write(f"\n{category}:\n")
                for key, value in data.items():
                    f.write(f"  {key}: {value} occurrences\n")
            
            f.write("\n3. DECISION RATIONALE PATTERNS\n")
            f.write("-" * 30 + "\n")
            for category, data in patterns['decision_rationale'].items():
                f.write(f"\n{category}:\n")
                for key, value in data.items():
                    f.write(f"  {key}: {value} occurrences\n")
        
        print(f"  ✓ Comparative analysis saved to comparative_analysis_report.txt")
    
    def _analyze_lengths(self):
        """Analyze explanation lengths by different categories."""
        length_analysis = {}
        
        # By condition
        length_analysis['by_condition'] = {}
        for condition in ['UEQ', 'UEEQ', 'RAW']:
            lengths = [len(d['explanation']) for d in self.explanations_data 
                      if d['condition'] == condition]
            length_analysis['by_condition'][condition] = sum(lengths) / len(lengths) if lengths else 0
        
        # By release decision
        length_analysis['by_release'] = {}
        for decision in ['Yes', 'No']:
            lengths = [len(d['explanation']) for d in self.explanations_data 
                      if d['release_decision'] == decision]
            length_analysis['by_release'][decision] = sum(lengths) / len(lengths) if lengths else 0
        
        return length_analysis
    
    def _analyze_sentiment_indicators(self):
        """Analyze sentiment indicators in explanations."""
        positive_words = ['good', 'great', 'excellent', 'positive', 'beautiful', 'attractive', 'clear', 'easy']
        negative_words = ['bad', 'poor', 'terrible', 'negative', 'ugly', 'confusing', 'difficult', 'problematic']
        
        sentiment_analysis = {}
        
        # By condition
        sentiment_analysis['by_condition'] = {}
        for condition in ['UEQ', 'UEEQ', 'RAW']:
            texts = [d['explanation'].lower() for d in self.explanations_data 
                    if d['condition'] == condition]
            combined_text = ' '.join(texts)
            
            sentiment_analysis['by_condition'][condition] = {
                'positive_indicators': sum(combined_text.count(word) for word in positive_words),
                'negative_indicators': sum(combined_text.count(word) for word in negative_words)
            }
        
        # By release decision
        sentiment_analysis['by_release'] = {}
        for decision in ['Yes', 'No']:
            texts = [d['explanation'].lower() for d in self.explanations_data 
                    if d['release_decision'] == decision]
            combined_text = ' '.join(texts)
            
            sentiment_analysis['by_release'][decision] = {
                'positive_indicators': sum(combined_text.count(word) for word in positive_words),
                'negative_indicators': sum(combined_text.count(word) for word in negative_words)
            }
        
        return sentiment_analysis
    
    def _analyze_decision_rationale(self):
        """Analyze decision rationale patterns."""
        rationale_keywords = {
            'data_driven': ['score', 'scores', 'data', 'metrics', 'numbers', 'results'],
            'user_focused': ['user', 'users', 'people', 'customers', 'audience'],
            'business_focused': ['business', 'profit', 'revenue', 'commercial', 'market'],
            'ethical_concerns': ['ethical', 'unethical', 'manipulative', 'deceptive', 'honest', 'transparent']
        }
        
        rationale_analysis = {}
        
        # By condition
        rationale_analysis['by_condition'] = {}
        for condition in ['UEQ', 'UEEQ', 'RAW']:
            texts = [d['explanation'].lower() for d in self.explanations_data 
                    if d['condition'] == condition]
            combined_text = ' '.join(texts)
            
            rationale_analysis['by_condition'][condition] = {}
            for rationale, keywords in rationale_keywords.items():
                count = sum(combined_text.count(word) for word in keywords)
                rationale_analysis['by_condition'][condition][rationale] = count
        
        # By release decision
        rationale_analysis['by_release'] = {}
        for decision in ['Yes', 'No']:
            texts = [d['explanation'].lower() for d in self.explanations_data 
                    if d['release_decision'] == decision]
            combined_text = ' '.join(texts)
            
            rationale_analysis['by_release'][decision] = {}
            for rationale, keywords in rationale_keywords.items():
                count = sum(combined_text.count(word) for word in keywords)
                rationale_analysis['by_release'][decision][rationale] = count
        
        return rationale_analysis

def main():
    """Main function to run the advanced analysis."""
    print("Advanced UX Survey Explanation Analysis")
    print("=" * 40)
    
    # Initialize analyzer
    analyzer = AdvancedTextAnalyzer()
    
    if not analyzer.explanations_data:
        print("No data found. Please run explanation_analysis_simple.py first.")
        return
    
    # Generate word clouds
    analyzer.generate_word_clouds()
    
    # Analyze key themes
    analyzer.analyze_key_themes()
    
    # Create comparative analysis
    analyzer.create_comparative_analysis()
    
    print("\n✓ Advanced analysis complete!")
    print("\nAdditional files generated:")
    output_dir = Path("explanation_analysis_output")
    new_files = [
        "wordcloud_overall.png",
        "wordcloud_condition_UEQ.png",
        "wordcloud_condition_UEEQ.png",
        "wordcloud_condition_RAW.png",
        "wordcloud_release_Yes.png",
        "wordcloud_release_No.png",
        "wordcloud_combined_matrix.png",
        "theme_analysis.json",
        "theme_analysis_report.txt",
        "comparative_analysis.json",
        "comparative_analysis_report.txt"
    ]
    
    for filename in new_files:
        if (output_dir / filename).exists():
            print(f"  - {filename}")

if __name__ == "__main__":
    main()
