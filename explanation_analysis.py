#!/usr/bin/env python3
"""
Explanation Analysis Script for UX Survey Data

This script analyzes explanations from the UX survey data, grouping them by:
- Condition (UEQ, UEEQ, RAW)
- Pattern (1-15)
- Release decision (Yes/No)

It also performs text analysis including:
- Word frequency analysis
- Word clouds
- Sentiment analysis
- Topic modeling (using scientifically accepted methods)

Author: Analysis for CHI 2025 Paper
Date: September 2025
"""

import pandas as pd
import numpy as np
import re
from collections import Counter, defaultdict
import json
from pathlib import Path
import matplotlib.pyplot as plt
import seaborn as sns
from wordcloud import WordCloud
import nltk
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize
from nltk.stem import WordNetLemmatizer
from nltk.sentiment import SentimentIntensityAnalyzer
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.decomposition import LatentDirichletAllocation
from sklearn.cluster import KMeans
import warnings
warnings.filterwarnings('ignore')

# Download required NLTK data
try:
    nltk.data.find('tokenizers/punkt')
except LookupError:
    nltk.download('punkt')

try:
    nltk.data.find('corpora/stopwords')
except LookupError:
    nltk.download('stopwords')

try:
    nltk.data.find('corpora/wordnet')
except LookupError:
    nltk.download('wordnet')

try:
    nltk.data.find('vader_lexicon')
except LookupError:
    nltk.download('vader_lexicon')

class ExplanationAnalyzer:
    def __init__(self, data_file):
        """Initialize the analyzer with the survey data file."""
        self.data_file = data_file
        self.df = None
        self.explanations_data = []
        self.output_dir = Path("explanation_analysis_output")
        self.output_dir.mkdir(exist_ok=True)
        
        # Initialize text processing tools
        self.lemmatizer = WordNetLemmatizer()
        self.sia = SentimentIntensityAnalyzer()
        self.stop_words = set(stopwords.words('english'))
        
        # Add domain-specific stop words
        self.stop_words.update([
            'interface', 'design', 'user', 'users', 'would', 'could', 'should',
            'one', 'also', 'get', 'like', 'good', 'bad', 'well', 'make', 'think'
        ])
    
    def load_and_process_data(self):
        """Load the TSV file and extract explanation data."""
        print("Loading survey data...")
        
        # Read the TSV file
        self.df = pd.read_csv(self.data_file, sep='\t', low_memory=False)
        
        # Find the actual data start (skip header info)
        data_start = 0
        for i, row in self.df.iterrows():
            if pd.notna(row.iloc[0]) and str(row.iloc[0]).startswith('2025-'):
                data_start = i
                break
        
        # Keep only actual response data
        self.df = self.df.iloc[data_start:].reset_index(drop=True)
        
        print(f"Found {len(self.df)} survey responses")
        
        # Extract explanations for each condition and pattern
        self._extract_explanations()
        
    def _extract_explanations(self):
        """Extract explanations from the survey data."""
        conditions = ['UEQ', 'UEEQ', 'RAW']
        
        for _, row in self.df.iterrows():
            response_id = row.get('ResponseId', 'Unknown')
            
            for condition in conditions:
                for pattern in range(1, 16):  # Patterns 1-15
                    # Column names follow pattern: {pattern}_{condition} {field}
                    release_col = f"{pattern}_{condition} Release"
                    explanation_col = f"{pattern}_{condition} Explanation"
                    
                    if release_col in row and explanation_col in row:
                        release_decision = row[release_col]
                        explanation = row[explanation_col]
                        
                        # Only include if we have both release decision and explanation
                        if pd.notna(release_decision) and pd.notna(explanation) and str(explanation).strip():
                            self.explanations_data.append({
                                'response_id': response_id,
                                'condition': condition,
                                'pattern': pattern,
                                'release_decision': str(release_decision).strip(),
                                'explanation': str(explanation).strip()
                            })
        
        print(f"Extracted {len(self.explanations_data)} explanation entries")
    
    def export_grouped_explanations(self):
        """Export explanations grouped by various criteria."""
        df_explanations = pd.DataFrame(self.explanations_data)
        
        # Export by condition
        self._export_by_condition(df_explanations)
        
        # Export by pattern
        self._export_by_pattern(df_explanations)
        
        # Export by release decision
        self._export_by_release_decision(df_explanations)
        
        # Export combined groupings
        self._export_combined_groups(df_explanations)
        
        # Export raw data
        df_explanations.to_csv(self.output_dir / "all_explanations_raw.csv", index=False)
        print(f"✓ Exported raw explanations data to {self.output_dir / 'all_explanations_raw.csv'}")
    
    def _export_by_condition(self, df):
        """Export explanations grouped by condition."""
        output_file = self.output_dir / "explanations_by_condition.txt"
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("EXPLANATIONS GROUPED BY CONDITION\n")
            f.write("=" * 50 + "\n\n")
            
            for condition in ['UEQ', 'UEEQ', 'RAW']:
                condition_data = df[df['condition'] == condition]
                f.write(f"\n{condition} CONDITION ({len(condition_data)} explanations)\n")
                f.write("-" * 30 + "\n")
                
                for _, row in condition_data.iterrows():
                    f.write(f"Pattern {row['pattern']} | {row['release_decision']} | {row['explanation']}\n")
        
        print(f"✓ Exported explanations by condition to {output_file}")
    
    def _export_by_pattern(self, df):
        """Export explanations grouped by pattern."""
        output_file = self.output_dir / "explanations_by_pattern.txt"
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("EXPLANATIONS GROUPED BY PATTERN\n")
            f.write("=" * 50 + "\n\n")
            
            for pattern in range(1, 16):
                pattern_data = df[df['pattern'] == pattern]
                f.write(f"\nPATTERN {pattern} ({len(pattern_data)} explanations)\n")
                f.write("-" * 30 + "\n")
                
                for _, row in pattern_data.iterrows():
                    f.write(f"{row['condition']} | {row['release_decision']} | {row['explanation']}\n")
        
        print(f"✓ Exported explanations by pattern to {output_file}")
    
    def _export_by_release_decision(self, df):
        """Export explanations grouped by release decision."""
        output_file = self.output_dir / "explanations_by_release_decision.txt"
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("EXPLANATIONS GROUPED BY RELEASE DECISION\n")
            f.write("=" * 50 + "\n\n")
            
            for decision in ['Yes', 'No']:
                decision_data = df[df['release_decision'] == decision]
                f.write(f"\nRELEASE: {decision} ({len(decision_data)} explanations)\n")
                f.write("-" * 30 + "\n")
                
                for _, row in decision_data.iterrows():
                    f.write(f"{row['condition']} | Pattern {row['pattern']} | {row['explanation']}\n")
        
        print(f"✓ Exported explanations by release decision to {output_file}")
    
    def _export_combined_groups(self, df):
        """Export explanations with combined groupings."""
        output_file = self.output_dir / "explanations_combined_groups.txt"
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("EXPLANATIONS WITH COMBINED GROUPINGS\n")
            f.write("=" * 50 + "\n\n")
            
            # Group by condition and release decision
            for condition in ['UEQ', 'UEEQ', 'RAW']:
                f.write(f"\n{condition} CONDITION\n")
                f.write("=" * 20 + "\n")
                
                condition_data = df[df['condition'] == condition]
                
                for decision in ['Yes', 'No']:
                    decision_data = condition_data[condition_data['release_decision'] == decision]
                    f.write(f"\n  Release: {decision} ({len(decision_data)} explanations)\n")
                    f.write("  " + "-" * 25 + "\n")
                    
                    for _, row in decision_data.iterrows():
                        f.write(f"  Pattern {row['pattern']: <2} | {row['explanation']}\n")
        
        print(f"✓ Exported combined groupings to {output_file}")
    
    def perform_text_analysis(self):
        """Perform comprehensive text analysis."""
        print("\nPerforming text analysis...")
        
        df = pd.DataFrame(self.explanations_data)
        
        # Word frequency analysis
        self._word_frequency_analysis(df)
        
        # Generate word clouds
        self._generate_word_clouds(df)
        
        # Sentiment analysis
        self._sentiment_analysis(df)
        
        # Topic modeling
        self._topic_modeling(df)
        
        # Generate summary statistics
        self._generate_summary_statistics(df)
    
    def _preprocess_text(self, text):
        """Preprocess text for analysis."""
        # Convert to lowercase
        text = text.lower()
        
        # Remove special characters and digits
        text = re.sub(r'[^a-zA-Z\s]', '', text)
        
        # Tokenize
        tokens = word_tokenize(text)
        
        # Remove stop words and short words
        tokens = [self.lemmatizer.lemmatize(token) for token in tokens 
                 if token not in self.stop_words and len(token) > 2]
        
        return tokens
    
    def _word_frequency_analysis(self, df):
        """Analyze word frequencies across different groups."""
        print("  - Analyzing word frequencies...")
        
        # Overall word frequency
        all_texts = ' '.join(df['explanation'].tolist())
        all_tokens = self._preprocess_text(all_texts)
        word_freq = Counter(all_tokens)
        
        # Save overall word frequency
        freq_df = pd.DataFrame(word_freq.most_common(50), columns=['word', 'frequency'])
        freq_df.to_csv(self.output_dir / "word_frequency_overall.csv", index=False)
        
        # Word frequency by condition
        for condition in ['UEQ', 'UEEQ', 'RAW']:
            condition_texts = ' '.join(df[df['condition'] == condition]['explanation'].tolist())
            condition_tokens = self._preprocess_text(condition_texts)
            condition_freq = Counter(condition_tokens)
            
            freq_df = pd.DataFrame(condition_freq.most_common(30), columns=['word', 'frequency'])
            freq_df.to_csv(self.output_dir / f"word_frequency_{condition}.csv", index=False)
        
        # Word frequency by release decision
        for decision in ['Yes', 'No']:
            decision_texts = ' '.join(df[df['release_decision'] == decision]['explanation'].tolist())
            decision_tokens = self._preprocess_text(decision_texts)
            decision_freq = Counter(decision_tokens)
            
            freq_df = pd.DataFrame(decision_freq.most_common(30), columns=['word', 'frequency'])
            freq_df.to_csv(self.output_dir / f"word_frequency_release_{decision}.csv", index=False)
    
    def _generate_word_clouds(self, df):
        """Generate word clouds for different groups."""
        print("  - Generating word clouds...")
        
        # Overall word cloud
        all_texts = ' '.join(df['explanation'].tolist())
        self._create_word_cloud(all_texts, "overall")
        
        # Word clouds by condition
        for condition in ['UEQ', 'UEEQ', 'RAW']:
            condition_texts = ' '.join(df[df['condition'] == condition]['explanation'].tolist())
            if condition_texts.strip():
                self._create_word_cloud(condition_texts, f"condition_{condition}")
        
        # Word clouds by release decision
        for decision in ['Yes', 'No']:
            decision_texts = ' '.join(df[df['release_decision'] == decision]['explanation'].tolist())
            if decision_texts.strip():
                self._create_word_cloud(decision_texts, f"release_{decision}")
    
    def _create_word_cloud(self, text, suffix):
        """Create and save a word cloud."""
        try:
            # Preprocess text
            tokens = self._preprocess_text(text)
            processed_text = ' '.join(tokens)
            
            if not processed_text.strip():
                return
            
            # Create word cloud
            wordcloud = WordCloud(
                width=800, height=400,
                background_color='white',
                max_words=100,
                colormap='viridis'
            ).generate(processed_text)
            
            # Save word cloud
            plt.figure(figsize=(10, 5))
            plt.imshow(wordcloud, interpolation='bilinear')
            plt.axis('off')
            plt.title(f'Word Cloud - {suffix.replace("_", " ").title()}')
            plt.tight_layout()
            plt.savefig(self.output_dir / f"wordcloud_{suffix}.png", dpi=300, bbox_inches='tight')
            plt.close()
            
        except Exception as e:
            print(f"    Warning: Could not generate word cloud for {suffix}: {e}")
    
    def _sentiment_analysis(self, df):
        """Perform sentiment analysis on explanations."""
        print("  - Analyzing sentiment...")
        
        # Calculate sentiment scores
        df['sentiment_compound'] = df['explanation'].apply(
            lambda x: self.sia.polarity_scores(x)['compound']
        )
        df['sentiment_positive'] = df['explanation'].apply(
            lambda x: self.sia.polarity_scores(x)['pos']
        )
        df['sentiment_negative'] = df['explanation'].apply(
            lambda x: self.sia.polarity_scores(x)['neg']
        )
        df['sentiment_neutral'] = df['explanation'].apply(
            lambda x: self.sia.polarity_scores(x)['neu']
        )
        
        # Categorize sentiment
        df['sentiment_category'] = df['sentiment_compound'].apply(
            lambda x: 'positive' if x >= 0.05 else ('negative' if x <= -0.05 else 'neutral')
        )
        
        # Save sentiment analysis results
        sentiment_results = df[['condition', 'pattern', 'release_decision', 'explanation', 
                               'sentiment_compound', 'sentiment_category']].copy()
        sentiment_results.to_csv(self.output_dir / "sentiment_analysis.csv", index=False)
        
        # Generate sentiment summary
        sentiment_summary = df.groupby(['condition', 'release_decision', 'sentiment_category']).size().unstack(fill_value=0)
        sentiment_summary.to_csv(self.output_dir / "sentiment_summary.csv")
        
        # Create sentiment visualization
        self._plot_sentiment_analysis(df)
    
    def _plot_sentiment_analysis(self, df):
        """Create visualizations for sentiment analysis."""
        fig, axes = plt.subplots(2, 2, figsize=(15, 10))
        
        # Sentiment by condition
        condition_sentiment = df.groupby(['condition', 'sentiment_category']).size().unstack(fill_value=0)
        condition_sentiment.plot(kind='bar', ax=axes[0,0], title='Sentiment by Condition')
        axes[0,0].set_xlabel('Condition')
        axes[0,0].set_ylabel('Count')
        axes[0,0].legend(title='Sentiment')
        
        # Sentiment by release decision
        release_sentiment = df.groupby(['release_decision', 'sentiment_category']).size().unstack(fill_value=0)
        release_sentiment.plot(kind='bar', ax=axes[0,1], title='Sentiment by Release Decision')
        axes[0,1].set_xlabel('Release Decision')
        axes[0,1].set_ylabel('Count')
        axes[0,1].legend(title='Sentiment')
        
        # Sentiment scores distribution
        df['sentiment_compound'].hist(bins=20, ax=axes[1,0], alpha=0.7)
        axes[1,0].set_title('Distribution of Sentiment Scores')
        axes[1,0].set_xlabel('Sentiment Score')
        axes[1,0].set_ylabel('Frequency')
        
        # Sentiment by condition (box plot)
        df.boxplot(column='sentiment_compound', by='condition', ax=axes[1,1])
        axes[1,1].set_title('Sentiment Score Distribution by Condition')
        axes[1,1].set_xlabel('Condition')
        axes[1,1].set_ylabel('Sentiment Score')
        
        plt.tight_layout()
        plt.savefig(self.output_dir / "sentiment_analysis_plots.png", dpi=300, bbox_inches='tight')
        plt.close()
    
    def _topic_modeling(self, df):
        """Perform topic modeling using LDA."""
        print("  - Performing topic modeling...")
        
        try:
            # Prepare texts
            texts = df['explanation'].tolist()
            processed_texts = [' '.join(self._preprocess_text(text)) for text in texts]
            processed_texts = [text for text in processed_texts if text.strip()]
            
            if len(processed_texts) < 10:
                print("    Warning: Too few texts for meaningful topic modeling")
                return
            
            # Vectorize texts
            vectorizer = TfidfVectorizer(
                max_features=100,
                min_df=2,
                max_df=0.8,
                ngram_range=(1, 2)
            )
            
            doc_term_matrix = vectorizer.fit_transform(processed_texts)
            
            # Perform LDA
            n_topics = min(5, len(processed_texts) // 4)  # Adaptive number of topics
            lda = LatentDirichletAllocation(
                n_components=n_topics,
                random_state=42,
                max_iter=10,
                learning_method='online'
            )
            
            lda.fit(doc_term_matrix)
            
            # Extract topics
            feature_names = vectorizer.get_feature_names_out()
            topics = []
            
            for topic_idx, topic in enumerate(lda.components_):
                top_words = [feature_names[i] for i in topic.argsort()[-10:][::-1]]
                topics.append({
                    'topic_id': topic_idx,
                    'top_words': top_words,
                    'word_weights': topic[topic.argsort()[-10:][::-1]].tolist()
                })
            
            # Save topics
            with open(self.output_dir / "topics_lda.json", 'w') as f:
                json.dump(topics, f, indent=2)
            
            # Save topic assignments
            doc_topic_probs = lda.transform(doc_term_matrix)
            topic_assignments = doc_topic_probs.argmax(axis=1)
            
            df_subset = df.iloc[:len(topic_assignments)].copy()
            df_subset['topic'] = topic_assignments
            df_subset['topic_probability'] = doc_topic_probs.max(axis=1)
            
            topic_results = df_subset[['condition', 'pattern', 'release_decision', 
                                     'explanation', 'topic', 'topic_probability']].copy()
            topic_results.to_csv(self.output_dir / "topic_assignments.csv", index=False)
            
            # Generate topic summary
            topic_summary = df_subset.groupby(['condition', 'release_decision', 'topic']).size().unstack(fill_value=0)
            topic_summary.to_csv(self.output_dir / "topic_summary.csv")
            
        except Exception as e:
            print(f"    Warning: Topic modeling failed: {e}")
    
    def _generate_summary_statistics(self, df):
        """Generate summary statistics."""
        print("  - Generating summary statistics...")
        
        summary = {
            'total_explanations': len(df),
            'explanations_by_condition': df['condition'].value_counts().to_dict(),
            'explanations_by_release': df['release_decision'].value_counts().to_dict(),
            'explanations_by_pattern': df['pattern'].value_counts().to_dict(),
            'average_explanation_length': df['explanation'].str.len().mean(),
            'median_explanation_length': df['explanation'].str.len().median(),
            'explanation_length_by_condition': df.groupby('condition')['explanation'].str.len().mean().to_dict(),
            'explanation_length_by_release': df.groupby('release_decision')['explanation'].str.len().mean().to_dict()
        }
        
        # Add text statistics
        all_text = ' '.join(df['explanation'].tolist())
        all_tokens = self._preprocess_text(all_text)
        
        summary['total_unique_words'] = len(set(all_tokens))
        summary['total_words'] = len(all_tokens)
        summary['vocabulary_richness'] = len(set(all_tokens)) / len(all_tokens) if all_tokens else 0
        
        # Save summary
        with open(self.output_dir / "analysis_summary.json", 'w') as f:
            json.dump(summary, f, indent=2)
        
        # Create summary report
        with open(self.output_dir / "analysis_report.txt", 'w') as f:
            f.write("EXPLANATION ANALYSIS SUMMARY REPORT\n")
            f.write("=" * 50 + "\n\n")
            
            f.write(f"Total explanations analyzed: {summary['total_explanations']}\n\n")
            
            f.write("Explanations by condition:\n")
            for condition, count in summary['explanations_by_condition'].items():
                f.write(f"  {condition}: {count}\n")
            
            f.write("\nExplanations by release decision:\n")
            for decision, count in summary['explanations_by_release'].items():
                f.write(f"  {decision}: {count}\n")
            
            f.write(f"\nAverage explanation length: {summary['average_explanation_length']:.1f} characters\n")
            f.write(f"Median explanation length: {summary['median_explanation_length']:.1f} characters\n")
            
            f.write(f"\nTotal unique words: {summary['total_unique_words']}\n")
            f.write(f"Vocabulary richness: {summary['vocabulary_richness']:.3f}\n")

def main():
    """Main function to run the analysis."""
    data_file = "UI-Eval-Survey-Data/UX+Metrics+Design+Decision+Impact_September+2%2C+2025_11.31_Filter-Completed.tsv"
    
    print("UX Survey Explanation Analysis")
    print("=" * 40)
    
    # Initialize analyzer
    analyzer = ExplanationAnalyzer(data_file)
    
    # Load and process data
    analyzer.load_and_process_data()
    
    # Export grouped explanations
    print("\nExporting grouped explanations...")
    analyzer.export_grouped_explanations()
    
    # Perform text analysis
    analyzer.perform_text_analysis()
    
    print(f"\n✓ Analysis complete! Results saved to: {analyzer.output_dir}")
    print("\nGenerated files:")
    for file_path in sorted(analyzer.output_dir.glob("*")):
        print(f"  - {file_path.name}")

if __name__ == "__main__":
    main()
