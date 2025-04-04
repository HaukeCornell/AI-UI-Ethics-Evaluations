import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import argparse
import os

def load_results(csv_path):
    """Load results from CSV file."""
    return pd.read_csv(csv_path)

def calculate_metrics(df):
    """Calculate summary metrics for each AI model."""
    # Get all score columns
    score_cols = [col for col in df.columns if col.startswith('score_')]
    
    # Calculate UX KPI based on negative UX aspects
    # Define mapping from UX KPI items to column names
    ux_kpi_columns_mapping = {
        'boring': 'score_boring_exciting',           # Low = boring
        'not_interesting': 'score_interesting_not_interesting',  # High = not interesting
        'complicated': 'score_complicated_easy',     # Low = complicated
        'confusing': 'score_clear_confusing',        # High = confusing
        'inefficient': 'score_inefficient_efficient', # Low = inefficient
        'cluttered': 'score_organized_cluttered',     # High = cluttered
        'unpredictable': 'score_unpredictable_predictable', # Low = unpredictable
        'obstructive': 'score_supportive_obstructive'  # High = obstructive
    }
    
    # Create inverted values where necessary to ensure all negative aspects are high values
    for ux_item, column in ux_kpi_columns_mapping.items():
        if column in df.columns:
            if ux_item in ['not_interesting', 'confusing', 'cluttered', 'obstructive']:
                # These columns are already oriented so high values = negative aspect
                df[f'ux_{ux_item}'] = df[column]
            else:
                # These columns need to be inverted so high values = negative aspect
                df[f'ux_{ux_item}'] = 8 - df[column]  # 8 - value to invert (1-7 scale becomes 7-1)
    
    # Calculate UX KPI (mean of all items)
    ux_items = [f'ux_{item}' for item in ux_kpi_columns_mapping.keys() if f'ux_{item}' in df.columns]
    
    if ux_items:
        df['ux_kpi'] = df[ux_items].mean(axis=1)
        # Add ux_kpi to score_cols
        score_cols.append('ux_kpi')
    
    # Group by AI service and model
    grouped = df.groupby(['metadata_ai_service', 'metadata_model'])
    
    # Calculate mean, std, min, max for each group and score
    metrics = grouped[score_cols].agg(['mean', 'std', 'min', 'max'])
    
    return metrics

def calculate_pattern_metrics(df):
    """Calculate metrics by pattern type for each AI model."""
    # Get all score columns
    score_cols = [col for col in df.columns if col.startswith('score_')]
    
    # Group by AI service, model, and pattern type
    grouped = df.groupby(['metadata_ai_service', 'metadata_model', 'metadata_pattern_type'])
    
    # Calculate mean for each group and score
    metrics = grouped[score_cols].mean()
    
    return metrics

def create_heatmap(df, output_dir):
    """Create heatmap of scores by pattern type and AI model."""
    # Get all score columns
    score_cols = [col for col in df.columns if col.startswith('score_')]
    
    # Add ux_kpi if available
    if 'ux_kpi' in df.columns:
        score_cols.append('ux_kpi')
    
    # For each score column, create a heatmap
    for score_col in score_cols:
        # Prepare data for heatmap
        pivot = pd.pivot_table(
            df, 
            values=score_col,
            index='metadata_pattern_type',
            columns=['metadata_ai_service', 'metadata_model'],
            aggfunc='mean'
        )
        
        # Create figure
        plt.figure(figsize=(12, 8))
        
        # Choose appropriate color map (viridis by default, RdYlGn_r for ux_kpi)
        cmap = 'RdYlGn_r' if score_col == 'ux_kpi' else 'viridis'
        
        sns.heatmap(pivot, annot=True, cmap=cmap, fmt='.2f', linewidths=.5)
        
        # Clean score column name for display
        if score_col == 'ux_kpi':
            score_name = "UX KPI"
        else:
            score_name = score_col.replace('score_', '').replace('_', ' to ')
        
        plt.title(f'Average Scores for "{score_name}" by Pattern Type and AI Model')
        plt.tight_layout()
        
        # Save figure
        output_path = os.path.join(output_dir, f'heatmap_{score_col}.png')
        plt.savefig(output_path)
        plt.close()
        
    # If ux_kpi is available, create gauge visualizations
    if 'ux_kpi' in df.columns:
        try:
            import subprocess
            results_csv = os.path.join(output_dir, "combined_results.csv" if os.path.exists(os.path.join(output_dir, "combined_results.csv")) else "results.csv")
            df.to_csv(results_csv, index=False)
            
            gauge_output_dir = os.path.join(output_dir, 'gauges')
            os.makedirs(gauge_output_dir, exist_ok=True)
            
            print("Generating UX KPI gauge visualizations...")
            subprocess.run(['python', 'ux_kpi_gauge.py', 
                           '--results', results_csv, 
                           '--output_dir', gauge_output_dir])
            print(f"Gauge visualizations saved to {gauge_output_dir}")
        except Exception as e:
            print(f"Warning: Failed to generate gauge visualizations: {e}")

def create_radar_charts(df, output_dir):
    """Create radar charts comparing AI models."""
    # Get all score columns
    score_cols = [col for col in df.columns if col.startswith('score_')]
    score_names = [col.replace('score_', '') for col in score_cols]
    
    # Group by AI service and model
    grouped = df.groupby(['metadata_ai_service', 'metadata_model'])
    
    # Calculate mean for each group and score
    means = grouped[score_cols].mean()
    
    # For each AI service/model combination, create a radar chart
    for (service, model), scores in means.iterrows():
        # Create figure
        fig = plt.figure(figsize=(10, 10))
        ax = fig.add_subplot(111, polar=True)
        
        # Number of variables
        N = len(score_cols)
        
        # What will be the angle of each axis in the plot
        angles = [n / float(N) * 2 * np.pi for n in range(N)]
        angles += angles[:1]  # Close the loop
        
        # Get score values and close the loop
        values = scores.values.flatten().tolist()
        values += values[:1]
        
        # Draw one axe per variable + add labels
        plt.xticks(angles[:-1], score_names, size=10)
        
        # Draw ylabels
        ax.set_rlabel_position(0)
        plt.yticks([1, 4, 7], ["1", "4", "7"], color="grey", size=8)
        plt.ylim(0, 7)
        
        # Plot data
        ax.plot(angles, values, linewidth=1, linestyle='solid')
        
        # Fill area
        ax.fill(angles, values, 'b', alpha=0.1)
        
        # Add title
        plt.title(f"Radar Chart for {service} {model}")
        
        # Save figure
        output_path = os.path.join(output_dir, f'radar_{service}_{model}.png'.replace('.', '_'))
        plt.savefig(output_path)
        plt.close()

def compare_human_ai(human_df, ai_df, output_dir):
    """Compare human and AI assessment results."""
    if human_df is None:
        print("No human results provided for comparison.")
        return
        
    # Get all score columns
    score_cols = [col for col in ai_df.columns if col.startswith('score_')]
    
    # Group human results by pattern type
    human_grouped = human_df.groupby('metadata_pattern_type')[score_cols].mean()
    
    # Group AI results by pattern type, AI service, and model
    ai_grouped = ai_df.groupby(['metadata_pattern_type', 'metadata_ai_service', 'metadata_model'])[score_cols].mean()
    
    # Reset index to prepare for comparison
    human_grouped = human_grouped.reset_index()
    ai_grouped = ai_grouped.reset_index()
    
    # For each AI service/model combination, create comparison charts
    for (service, model), group_df in ai_grouped.groupby(['metadata_ai_service', 'metadata_model']):
        for score_col in score_cols:
            # Prepare data for comparison
            comparison_data = []
            
            for pattern_type in human_grouped['metadata_pattern_type'].unique():
                human_score = human_grouped[human_grouped['metadata_pattern_type'] == pattern_type][score_col].values[0]
                ai_score = group_df[group_df['metadata_pattern_type'] == pattern_type][score_col].values[0]
                
                comparison_data.append({
                    'Pattern Type': pattern_type,
                    'Human Score': human_score,
                    'AI Score': ai_score,
                    'Difference': ai_score - human_score
                })
                
            comparison_df = pd.DataFrame(comparison_data)
            
            # Create figure for score comparison
            plt.figure(figsize=(12, 6))
            
            # Sort by human score
            comparison_df = comparison_df.sort_values('Human Score')
            
            # Plot scores
            x = np.arange(len(comparison_df))
            width = 0.35
            
            plt.bar(x - width/2, comparison_df['Human Score'], width, label='Human')
            plt.bar(x + width/2, comparison_df['AI Score'], width, label=f'{service} {model}')
            
            plt.xlabel('Pattern Type')
            plt.ylabel('Score')
            
            # Clean score column name for display
            score_name = score_col.replace('score_', '').replace('_', ' to ')
            
            plt.title(f'Comparison of Human vs AI Scores for "{score_name}"')
            plt.xticks(x, comparison_df['Pattern Type'], rotation=45, ha='right')
            plt.legend()
            plt.tight_layout()
            
            # Save figure
            output_path = os.path.join(output_dir, f'comparison_{service}_{model}_{score_col}.png'.replace('.', '_'))
            plt.savefig(output_path)
            plt.close()
            
            # Create figure for difference
            plt.figure(figsize=(12, 6))
            
            # Plot difference
            plt.bar(x, comparison_df['Difference'], color=['g' if d >= 0 else 'r' for d in comparison_df['Difference']])
            
            plt.axhline(y=0, color='black', linestyle='-', alpha=0.3)
            
            plt.xlabel('Pattern Type')
            plt.ylabel('Difference (AI - Human)')
            plt.title(f'Difference Between AI and Human Scores for "{score_name}"')
            plt.xticks(x, comparison_df['Pattern Type'], rotation=45, ha='right')
            plt.tight_layout()
            
            # Save figure
            output_path = os.path.join(output_dir, f'difference_{service}_{model}_{score_col}.png'.replace('.', '_'))
            plt.savefig(output_path)
            plt.close()

def main():
    parser = argparse.ArgumentParser(description="Analyze UI Assessment Results")
    parser.add_argument("--results", required=True, help="Path to results CSV file")
    parser.add_argument("--human_results", help="Path to human assessment results CSV file (optional)")
    parser.add_argument("--output_dir", default="analysis_output", help="Directory to save analysis output")
    
    args = parser.parse_args()
    
    # Create output directory if it doesn't exist
    os.makedirs(args.output_dir, exist_ok=True)
    
    # Load results
    df = load_results(args.results)
    
    # Load human results if provided
    human_df = None
    if args.human_results:
        human_df = load_results(args.human_results)
    
    # Calculate metrics
    metrics = calculate_metrics(df)
    pattern_metrics = calculate_pattern_metrics(df)
    
    # Save metrics to CSV
    metrics.to_csv(os.path.join(args.output_dir, "summary_metrics.csv"))
    pattern_metrics.to_csv(os.path.join(args.output_dir, "pattern_metrics.csv"))
    
    # Create visualizations
    create_heatmap(df, args.output_dir)
    create_radar_charts(df, args.output_dir)
    
    # Compare with human results if available
    if human_df is not None:
        compare_human_ai(human_df, df, args.output_dir)
    
    print(f"Analysis complete. Results saved to {args.output_dir}")

if __name__ == "__main__":
    main()
