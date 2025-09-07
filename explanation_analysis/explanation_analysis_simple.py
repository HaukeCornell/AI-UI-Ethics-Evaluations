#!/usr/bin/env python3
"""
Simplified Explanation Analysis Script for UX Survey Data

This script analyzes explanations from the UX survey data, grouping them by:
- Condition (UEQ, UEEQ, RAW)
- Pattern (1-15)
- Release decision (Yes/No)

It also performs basic text analysis including:
- Word frequency analysis
- Basic statistics

Author: Analysis for CHI 2025 Paper
Date: September 2025
"""

import csv
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

class SimpleExplanationAnalyzer:
    def __init__(self, data_file):
        """Initialize the analyzer with the survey data file."""
        self.data_file = data_file
        self.explanations_data = []
        self.output_dir = Path("explanation_analysis_output")
        self.output_dir.mkdir(exist_ok=True)
        
        # Common stop words
        self.stop_words = {
            'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
            'by', 'from', 'up', 'about', 'into', 'through', 'during', 'before', 'after', 'above',
            'below', 'between', 'among', 'be', 'have', 'do', 'say', 'get', 'make', 'go', 'know',
            'take', 'see', 'come', 'think', 'look', 'want', 'give', 'use', 'find', 'tell', 'ask',
            'work', 'seem', 'feel', 'try', 'leave', 'call', 'is', 'are', 'was', 'were', 'been',
            'being', 'has', 'had', 'having', 'does', 'did', 'doing', 'will', 'would', 'could',
            'should', 'may', 'might', 'must', 'can', 'this', 'that', 'these', 'those', 'i', 'you',
            'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them', 'my', 'your', 'his',
            'its', 'our', 'their', 'interface', 'design', 'user', 'users', 'would', 'could', 'should',
            'one', 'also', 'like', 'good', 'bad', 'well', 'make', 'think', 'seems', 'looks'
        }
    
    def load_and_process_data(self):
        """Load the TSV file and extract explanation data."""
        print("Loading survey data...")
        
        # Read the TSV file (handle UTF-16 encoding)
        try:
            with open(self.data_file, 'r', encoding='utf-16') as f:
                content = f.read()
        except UnicodeDecodeError:
            try:
                with open(self.data_file, 'r', encoding='utf-8') as f:
                    content = f.read()
            except UnicodeDecodeError:
                with open(self.data_file, 'r', encoding='latin-1') as f:
                    content = f.read()
        
        lines = content.split('\n')
        
        # Find the header line
        header_line = 0
        for i, line in enumerate(lines):
            if line.startswith('StartDate\t'):
                header_line = i
                break
        
        # Find the actual data start (skip consent form text)
        data_start = header_line + 1
        for i in range(header_line + 1, len(lines)):
            if lines[i].strip() and lines[i].startswith('2025-'):
                data_start = i
                break
        
        # Parse header
        headers = lines[header_line].split('\t')
        
        # Parse data
        data_rows = []
        for i in range(data_start, len(lines)):
            if lines[i].strip():
                row = lines[i].split('\t')
                if len(row) >= len(headers):
                    data_rows.append(row)
        
        print(f"Found {len(data_rows)} survey responses")
        
        # Extract explanations
        self._extract_explanations(headers, data_rows)
        
    def _extract_explanations(self, headers, data_rows):
        """Extract explanations from the parsed data."""
        conditions = ['UEQ', 'UEEQ', 'RAW']
        
        # Find column indices
        response_id_col = None
        for i, header in enumerate(headers):
            if 'ResponseId' in header:
                response_id_col = i
                break
        
        for row in data_rows:
            response_id = row[response_id_col] if response_id_col else 'Unknown'
            
            for condition in conditions:
                for pattern in range(1, 16):  # Patterns 1-15
                    # Find column indices for this pattern and condition
                    release_col = None
                    explanation_col = None
                    
                    for i, header in enumerate(headers):
                        if f"{pattern}_{condition} Release" in header:
                            release_col = i
                        elif f"{pattern}_{condition} Explanation" in header:
                            explanation_col = i
                    
                    if release_col is not None and explanation_col is not None:
                        if release_col < len(row) and explanation_col < len(row):
                            release_decision = row[release_col].strip()
                            explanation = row[explanation_col].strip()
                            
                            # Only include if we have both release decision and explanation
                            if release_decision and explanation and explanation != '':
                                self.explanations_data.append({
                                    'response_id': response_id,
                                    'condition': condition,
                                    'pattern': pattern,
                                    'release_decision': release_decision,
                                    'explanation': explanation
                                })
        
        print(f"Extracted {len(self.explanations_data)} explanation entries")
    
    def export_grouped_explanations(self):
        """Export explanations grouped by various criteria."""
        # Export by condition
        self._export_by_condition()
        
        # Export by pattern
        self._export_by_pattern()
        
        # Export by release decision
        self._export_by_release_decision()
        
        # Export combined groupings
        self._export_combined_groups()
        
        # Export raw data as CSV
        self._export_raw_csv()
        
        print(f"✓ Exported explanations data to {self.output_dir}")
    
    def _export_by_condition(self):
        """Export explanations grouped by condition."""
        output_file = self.output_dir / "explanations_by_condition.txt"
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("EXPLANATIONS GROUPED BY CONDITION\n")
            f.write("=" * 50 + "\n\n")
            
            for condition in ['UEQ', 'UEEQ', 'RAW']:
                condition_data = [d for d in self.explanations_data if d['condition'] == condition]
                f.write(f"\n{condition} CONDITION ({len(condition_data)} explanations)\n")
                f.write("-" * 30 + "\n")
                
                for entry in condition_data:
                    f.write(f"Pattern {entry['pattern']} | {entry['release_decision']} | {entry['explanation']}\n")
        
        print(f"✓ Exported explanations by condition to {output_file}")
    
    def _export_by_pattern(self):
        """Export explanations grouped by pattern."""
        output_file = self.output_dir / "explanations_by_pattern.txt"
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("EXPLANATIONS GROUPED BY PATTERN\n")
            f.write("=" * 50 + "\n\n")
            
            for pattern in range(1, 16):
                pattern_data = [d for d in self.explanations_data if d['pattern'] == pattern]
                f.write(f"\nPATTERN {pattern} ({len(pattern_data)} explanations)\n")
                f.write("-" * 30 + "\n")
                
                for entry in pattern_data:
                    f.write(f"{entry['condition']} | {entry['release_decision']} | {entry['explanation']}\n")
        
        print(f"✓ Exported explanations by pattern to {output_file}")
    
    def _export_by_release_decision(self):
        """Export explanations grouped by release decision."""
        output_file = self.output_dir / "explanations_by_release_decision.txt"
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("EXPLANATIONS GROUPED BY RELEASE DECISION\n")
            f.write("=" * 50 + "\n\n")
            
            for decision in ['Yes', 'No']:
                decision_data = [d for d in self.explanations_data if d['release_decision'] == decision]
                f.write(f"\nRELEASE: {decision} ({len(decision_data)} explanations)\n")
                f.write("-" * 30 + "\n")
                
                for entry in decision_data:
                    f.write(f"{entry['condition']} | Pattern {entry['pattern']} | {entry['explanation']}\n")
        
        print(f"✓ Exported explanations by release decision to {output_file}")
    
    def _export_combined_groups(self):
        """Export explanations with combined groupings."""
        output_file = self.output_dir / "explanations_combined_groups.txt"
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("EXPLANATIONS WITH COMBINED GROUPINGS\n")
            f.write("=" * 50 + "\n\n")
            
            # Group by condition and release decision
            for condition in ['UEQ', 'UEEQ', 'RAW']:
                f.write(f"\n{condition} CONDITION\n")
                f.write("=" * 20 + "\n")
                
                condition_data = [d for d in self.explanations_data if d['condition'] == condition]
                
                for decision in ['Yes', 'No']:
                    decision_data = [d for d in condition_data if d['release_decision'] == decision]
                    f.write(f"\n  Release: {decision} ({len(decision_data)} explanations)\n")
                    f.write("  " + "-" * 25 + "\n")
                    
                    for entry in decision_data:
                        f.write(f"  Pattern {entry['pattern']: <2} | {entry['explanation']}\n")
        
        print(f"✓ Exported combined groupings to {output_file}")
    
    def _export_raw_csv(self):
        """Export raw data as CSV."""
        output_file = self.output_dir / "all_explanations_raw.csv"
        
        with open(output_file, 'w', newline='', encoding='utf-8') as f:
            fieldnames = ['response_id', 'condition', 'pattern', 'release_decision', 'explanation']
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(self.explanations_data)
        
        print(f"✓ Exported raw explanations data to {output_file}")
    
    def perform_text_analysis(self):
        """Perform basic text analysis."""
        print("\nPerforming text analysis...")
        
        # Word frequency analysis
        self._word_frequency_analysis()
        
        # Generate summary statistics
        self._generate_summary_statistics()
    
    def _preprocess_text(self, text):
        """Preprocess text for analysis."""
        # Convert to lowercase
        text = text.lower()
        
        # Remove special characters and digits
        text = re.sub(r'[^a-zA-Z\s]', '', text)
        
        # Split into words
        words = text.split()
        
        # Remove stop words and short words
        words = [word for word in words 
                if word not in self.stop_words and len(word) > 2]
        
        return words
    
    def _word_frequency_analysis(self):
        """Analyze word frequencies across different groups."""
        print("  - Analyzing word frequencies...")
        
        # Overall word frequency
        all_texts = ' '.join([d['explanation'] for d in self.explanations_data])
        all_words = self._preprocess_text(all_texts)
        word_freq = Counter(all_words)
        
        # Save overall word frequency
        self._save_word_frequency(word_freq.most_common(50), "word_frequency_overall.csv")
        
        # Word frequency by condition
        for condition in ['UEQ', 'UEEQ', 'RAW']:
            condition_texts = ' '.join([d['explanation'] for d in self.explanations_data 
                                      if d['condition'] == condition])
            condition_words = self._preprocess_text(condition_texts)
            condition_freq = Counter(condition_words)
            
            self._save_word_frequency(condition_freq.most_common(30), f"word_frequency_{condition}.csv")
        
        # Word frequency by release decision
        for decision in ['Yes', 'No']:
            decision_texts = ' '.join([d['explanation'] for d in self.explanations_data 
                                     if d['release_decision'] == decision])
            decision_words = self._preprocess_text(decision_texts)
            decision_freq = Counter(decision_words)
            
            self._save_word_frequency(decision_freq.most_common(30), f"word_frequency_release_{decision}.csv")
    
    def _save_word_frequency(self, word_freq_list, filename):
        """Save word frequency data to CSV."""
        output_file = self.output_dir / filename
        
        with open(output_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['word', 'frequency'])
            writer.writerows(word_freq_list)
    
    def _generate_summary_statistics(self):
        """Generate summary statistics."""
        print("  - Generating summary statistics...")
        
        # Count by condition
        condition_counts = Counter([d['condition'] for d in self.explanations_data])
        
        # Count by release decision
        release_counts = Counter([d['release_decision'] for d in self.explanations_data])
        
        # Count by pattern
        pattern_counts = Counter([d['pattern'] for d in self.explanations_data])
        
        # Calculate explanation lengths
        explanation_lengths = [len(d['explanation']) for d in self.explanations_data]
        avg_length = sum(explanation_lengths) / len(explanation_lengths) if explanation_lengths else 0
        
        # Calculate lengths by condition
        condition_lengths = defaultdict(list)
        for d in self.explanations_data:
            condition_lengths[d['condition']].append(len(d['explanation']))
        
        condition_avg_lengths = {}
        for condition, lengths in condition_lengths.items():
            condition_avg_lengths[condition] = sum(lengths) / len(lengths) if lengths else 0
        
        # Calculate lengths by release decision
        release_lengths = defaultdict(list)
        for d in self.explanations_data:
            release_lengths[d['release_decision']].append(len(d['explanation']))
        
        release_avg_lengths = {}
        for decision, lengths in release_lengths.items():
            release_avg_lengths[decision] = sum(lengths) / len(lengths) if lengths else 0
        
        # Text statistics
        all_text = ' '.join([d['explanation'] for d in self.explanations_data])
        all_words = self._preprocess_text(all_text)
        
        summary = {
            'total_explanations': len(self.explanations_data),
            'explanations_by_condition': dict(condition_counts),
            'explanations_by_release': dict(release_counts),
            'explanations_by_pattern': dict(pattern_counts),
            'average_explanation_length': round(avg_length, 1),
            'explanation_length_by_condition': {k: round(v, 1) for k, v in condition_avg_lengths.items()},
            'explanation_length_by_release': {k: round(v, 1) for k, v in release_avg_lengths.items()},
            'total_unique_words': len(set(all_words)),
            'total_words': len(all_words),
            'vocabulary_richness': round(len(set(all_words)) / len(all_words), 3) if all_words else 0
        }
        
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
            
            f.write(f"\nAverage explanation length: {summary['average_explanation_length']} characters\n")
            
            f.write("\nAverage explanation length by condition:\n")
            for condition, length in summary['explanation_length_by_condition'].items():
                f.write(f"  {condition}: {length} characters\n")
            
            f.write("\nAverage explanation length by release decision:\n")
            for decision, length in summary['explanation_length_by_release'].items():
                f.write(f"  {decision}: {length} characters\n")
            
            f.write(f"\nTotal unique words: {summary['total_unique_words']}\n")
            f.write(f"Vocabulary richness: {summary['vocabulary_richness']}\n")
            
            # Most common patterns
            f.write("\nMost common patterns (by number of explanations):\n")
            for pattern, count in Counter(pattern_counts).most_common(10):
                f.write(f"  Pattern {pattern}: {count} explanations\n")

def main():
    """Main function to run the analysis."""
    data_file = "UI-Eval-Survey-Data/UX+Metrics+Design+Decision+Impact_September+2%2C+2025_11.31_Filter-Completed.tsv"
    
    print("UX Survey Explanation Analysis (Simplified)")
    print("=" * 45)
    
    # Initialize analyzer
    analyzer = SimpleExplanationAnalyzer(data_file)
    
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
