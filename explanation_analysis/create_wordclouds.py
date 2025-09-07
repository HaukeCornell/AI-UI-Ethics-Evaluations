#!/usr/bin/env python3
"""
Word Cloud Generation for UX Survey Explanations
Creating scientifically meaningful word visualizations

This script creates word clouds for different conditions and decisions
to visually represent the most prominent terms in explanations.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
from wordcloud import WordCloud
import json

class WordCloudGenerator:
    def __init__(self, data_dir="explanation_analysis_output"):
        self.data_dir = Path(data_dir)
        self.output_dir = self.data_dir / "scientific_analysis"
        self.explanations_df = None
        
    def load_data(self):
        """Load the explanation data."""
        csv_file = self.data_dir / "all_explanations_raw.csv"
        self.explanations_df = pd.read_csv(csv_file)
        return self.explanations_df
    
    def create_word_clouds(self):
        """Create word clouds for different groups."""
        print("Creating word clouds...")
        
        # Define custom stop words for UX domain
        custom_stopwords = {
            'interface', 'design', 'user', 'users', 'would', 'could', 'should',
            'one', 'also', 'get', 'like', 'good', 'bad', 'well', 'make', 'think',
            'seems', 'looks', 'pretty', 'quite', 'still', 'really', 'much', 'many',
            'ui', 'app', 'application', 'website', 'site', 'page', 'element', 'button',
            'way', 'thing', 'things', 'time', 'feel', 'feeling', 'people', 'person'
        }
        
        # 1. Overall word cloud
        all_text = ' '.join(self.explanations_df['explanation'].astype(str))
        self._create_single_wordcloud(all_text, "Overall Explanations", 
                                    "wordcloud_overall.png", custom_stopwords)
        
        # 2. By condition
        for condition in ['UEQ', 'UEEQ', 'RAW']:
            condition_data = self.explanations_df[self.explanations_df['condition'] == condition]
            condition_text = ' '.join(condition_data['explanation'].astype(str))
            self._create_single_wordcloud(condition_text, f"{condition} Condition", 
                                        f"wordcloud_{condition.lower()}.png", custom_stopwords)
        
        # 3. By release decision
        for decision in ['Yes', 'No']:
            decision_data = self.explanations_df[self.explanations_df['release_decision'] == decision]
            decision_text = ' '.join(decision_data['explanation'].astype(str))
            decision_label = "Accept" if decision == 'Yes' else "Reject"
            self._create_single_wordcloud(decision_text, f"Release {decision_label}", 
                                        f"wordcloud_release_{decision.lower()}.png", custom_stopwords)
        
        # 4. Combined comparison figure
        self._create_comparison_wordclouds(custom_stopwords)
        
        print("✓ Word clouds created")
    
    def _create_single_wordcloud(self, text, title, filename, stopwords):
        """Create a single word cloud."""
        wordcloud = WordCloud(
            width=800, 
            height=400, 
            background_color='white',
            stopwords=stopwords,
            max_words=100,
            relative_scaling=0.5,
            colormap='viridis'
        ).generate(text)
        
        plt.figure(figsize=(10, 5))
        plt.imshow(wordcloud, interpolation='bilinear')
        plt.axis('off')
        plt.title(title, fontsize=16, fontweight='bold', pad=20)
        plt.tight_layout(pad=1)
        plt.savefig(self.output_dir / filename, dpi=300, bbox_inches='tight')
        plt.close()
    
    def _create_comparison_wordclouds(self, stopwords):
        """Create a comparison figure with multiple word clouds."""
        fig, axes = plt.subplots(2, 3, figsize=(18, 12))
        
        # Row 1: Conditions
        conditions = ['UEQ', 'UEEQ', 'RAW']
        for i, condition in enumerate(conditions):
            condition_data = self.explanations_df[self.explanations_df['condition'] == condition]
            condition_text = ' '.join(condition_data['explanation'].astype(str))
            
            wordcloud = WordCloud(
                width=400, height=300, 
                background_color='white',
                stopwords=stopwords,
                max_words=50,
                colormap='Set2'
            ).generate(condition_text)
            
            axes[0, i].imshow(wordcloud, interpolation='bilinear')
            axes[0, i].set_title(f'{condition} Condition', fontsize=14, fontweight='bold')
            axes[0, i].axis('off')
        
        # Row 2: Release decisions and overall
        # Accept
        accept_data = self.explanations_df[self.explanations_df['release_decision'] == 'Yes']
        accept_text = ' '.join(accept_data['explanation'].astype(str))
        
        wordcloud_accept = WordCloud(
            width=400, height=300, 
            background_color='white',
            stopwords=stopwords,
            max_words=50,
            colormap='Greens'
        ).generate(accept_text)
        
        axes[1, 0].imshow(wordcloud_accept, interpolation='bilinear')
        axes[1, 0].set_title('Accept Decisions', fontsize=14, fontweight='bold')
        axes[1, 0].axis('off')
        
        # Reject
        reject_data = self.explanations_df[self.explanations_df['release_decision'] == 'No']
        reject_text = ' '.join(reject_data['explanation'].astype(str))
        
        wordcloud_reject = WordCloud(
            width=400, height=300, 
            background_color='white',
            stopwords=stopwords,
            max_words=50,
            colormap='Reds'
        ).generate(reject_text)
        
        axes[1, 1].imshow(wordcloud_reject, interpolation='bilinear')
        axes[1, 1].set_title('Reject Decisions', fontsize=14, fontweight='bold')
        axes[1, 1].axis('off')
        
        # Overall
        all_text = ' '.join(self.explanations_df['explanation'].astype(str))
        wordcloud_all = WordCloud(
            width=400, height=300, 
            background_color='white',
            stopwords=stopwords,
            max_words=50,
            colormap='viridis'
        ).generate(all_text)
        
        axes[1, 2].imshow(wordcloud_all, interpolation='bilinear')
        axes[1, 2].set_title('Overall Explanations', fontsize=14, fontweight='bold')
        axes[1, 2].axis('off')
        
        plt.suptitle('Word Cloud Comparison: UX Design Decision Explanations', 
                    fontsize=16, fontweight='bold', y=0.98)
        plt.tight_layout()
        plt.savefig(self.output_dir / "wordcloud_comparison.png", dpi=300, bbox_inches='tight')
        plt.close()

def main():
    """Generate word clouds."""
    print("Word Cloud Generation for CHI 2025")
    print("=" * 35)
    
    generator = WordCloudGenerator()
    generator.load_data()
    generator.create_word_clouds()
    
    print(f"Word clouds saved to: {generator.output_dir}")

if __name__ == "__main__":
    main()
