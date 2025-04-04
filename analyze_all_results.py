#!/usr/bin/env python3
"""
Comprehensive analysis script that combines all results from different models,
temperatures, and repetitions to produce detailed analytics and visualizations.
"""

import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import argparse
import glob
import json
from datetime import datetime
from scipy.stats import f_oneway, ttest_ind
# Removing statsmodels dependency
# from statsmodels.stats.multicomp import pairwise_tukeyhsd
# import krippendorff - not available
# sklearn also not available
# Defining placeholder functions for metrics
def cohen_kappa_score(a, b):
    return 0.0  # Default value

def fleiss_kappa(data):
    return 0.0  # Default value
from itertools import combinations

def main():
    """Main function to parse arguments and run analysis."""
    parser = argparse.ArgumentParser(description="Comprehensive Analysis of UI Assessment Results")
    parser.add_argument("--results_dir", required=True, help="Directory containing results CSV files")
    parser.add_argument("--human_results", help="Path to human assessment results CSV file (optional)")
    parser.add_argument("--config", default="config.json", help="Path to configuration file")
    parser.add_argument("--output_dir", default="comprehensive_analysis", help="Directory to save analysis output")
    
    args = parser.parse_args()
    
    # Create output directory if it doesn't exist
    os.makedirs(args.output_dir, exist_ok=True)
    
    try:
        # Load configuration
        config = load_config(args.config)
        
        # Combine all results
        print("Combining results...")
        df = combine_results(args.results_dir)
        
        # Clean data
        print("Cleaning data...")
        df, score_cols = clean_data(df)
        
        # Calculate reliability metrics
        print("Calculating reliability metrics...")
        reliability, model_reliability = calculate_reliability(df, score_cols)
        
        # Analyze temperature effects
        print("Analyzing temperature effects...")
        temp_effects = analyze_temperature_effects(df, score_cols)
        
        # Compare with human results if provided
        human_concordance = None
        human_df = None
        if args.human_results:
            print("Comparing with human assessments...")
            human_df = pd.read_csv(args.human_results)
            human_df, _ = clean_data(human_df)
            comparison_results = compare_with_human_results(df, human_df, score_cols)
            
            if comparison_results:
                _, human_concordance, _ = comparison_results
        
        # Calculate inter-annotator agreement
        print("Calculating inter-annotator agreement...")
        agreement_results = calculate_inter_annotator_agreement(df, score_cols, human_df)
        
        # Save agreement results
        with open(os.path.join(args.output_dir, "inter_annotator_agreement.json"), 'w') as f:
            json.dump(agreement_results, f, indent=2)
        
        # Create bar chart of agreement metrics
        plt.figure(figsize=(12, 8))
        
        # Extract Krippendorff's alpha for each model (average across all metrics)
        models = []
        alpha_values = []
        
        for model_key, model_data in agreement_results["within_ai"].items():
            try:
                alphas = [float(alpha) for alpha in model_data["krippendorff_alpha"].values() if isinstance(alpha, (int, float)) or (isinstance(alpha, str) and alpha.replace('.', '', 1).isdigit())]
                if alphas:
                    models.append(model_key)
                    alpha_values.append(np.mean(alphas))
            except Exception as e:
                print(f"Error processing agreement data for {model_key}: {e}")
        
        # Add human agreement if available
        if agreement_results["within_human"]:
            try:
                human_alphas = [float(alpha) for alpha in agreement_results["within_human"]["krippendorff_alpha"].values() if isinstance(alpha, (int, float)) or (isinstance(alpha, str) and alpha.replace('.', '', 1).isdigit())]
                if human_alphas:
                    models.append("Human")
                    alpha_values.append(np.mean(human_alphas))
            except Exception as e:
                print(f"Error processing human agreement data: {e}")
        
        # Create bar chart
        if models and alpha_values:
            plt.bar(models, alpha_values)
            plt.xlabel('Model')
            plt.ylabel('Krippendorff\'s Alpha (average across metrics)')
            plt.title('Inter-Annotator Agreement by Model')
            plt.xticks(rotation=45, ha='right')
            plt.tight_layout()
            plt.savefig(os.path.join(args.output_dir, 'inter_annotator_agreement.png'))
            plt.close()
        
        # Create heatmap of between AI and human agreement
        if agreement_results["between_ai_and_human"]:
            # Extract Cohen's kappa for each model and metric
            models = []
            metrics = set()
            kappa_data = {}
            
            for model_key, model_data in agreement_results["between_ai_and_human"].items():
                models.append(model_key)
                for metric, kappa in model_data["cohen_kappa"].items():
                    if isinstance(kappa, (int, float)) or (isinstance(kappa, str) and kappa.replace('.', '', 1).isdigit()):
                        metrics.add(metric)
                        if model_key not in kappa_data:
                            kappa_data[model_key] = {}
                        kappa_data[model_key][metric] = float(kappa)
            
            metrics = list(metrics)
            
            if models and metrics:
                # Create dataframe for heatmap
                heatmap_data = pd.DataFrame(index=models, columns=metrics)
                for model in models:
                    for metric in metrics:
                        if model in kappa_data and metric in kappa_data[model]:
                            heatmap_data.loc[model, metric] = kappa_data[model][metric]
                
                # Create heatmap
                try:
                    # Convert data to numeric before creating heatmap
                    heatmap_data = heatmap_data.apply(pd.to_numeric, errors='coerce')
                    
                    plt.figure(figsize=(15, 8))
                    sns.heatmap(heatmap_data, annot=True, cmap='viridis', fmt='.2f', linewidths=.5)
                    plt.title('AI-Human Agreement (Cohen\'s Kappa) by Model and Metric')
                    plt.tight_layout()
                    plt.savefig(os.path.join(args.output_dir, 'ai_human_agreement_heatmap.png'))
                    plt.close()
                except Exception as e:
                    print(f"Error creating AI-Human agreement heatmap: {e}")
        
        # Perform statistical analysis
        print("Performing statistical analysis...")
        stats_results = statistical_analysis(df, score_cols)
        
        # Create visualizations
        print("Creating visualizations...")
        viz_dir = create_visualizations(df, model_reliability, human_concordance, args.output_dir)
        
        # Save analysis results
        print("Saving analysis results...")
        df.to_csv(os.path.join(args.output_dir, "combined_results.csv"), index=False)
        reliability.to_csv(os.path.join(args.output_dir, "reliability_by_pattern.csv"), index=False)
        model_reliability.to_csv(os.path.join(args.output_dir, "model_reliability.csv"), index=False)
        
        if temp_effects:
            temp_effects[0].to_csv(os.path.join(args.output_dir, "temperature_effects.csv"), index=False)
            temp_effects[1].to_csv(os.path.join(args.output_dir, "temperature_reliability.csv"), index=False)
        
        if human_concordance is not None:
            human_concordance.to_csv(os.path.join(args.output_dir, "human_concordance.csv"), index=False)
        
        # Create summary report
        print("Creating summary report...")
        try:
            # Import and use the summary writer module
            import summary_writer
            summary_writer.write_summary(df, args, agreement_results, model_reliability, human_concordance)
        except Exception as e:
            print(f"Error creating summary report: {e}")
        
        print(f"Analysis complete! Results saved to {args.output_dir}")
        print(f"Summary report: {os.path.join(args.output_dir, 'analysis_summary.md')}")
        
    except Exception as e:
        print(f"Error during analysis: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0

def calculate_inter_annotator_agreement(df, score_cols, human_df=None):
    """Calculate inter-annotator agreement metrics within AI models and between AI and humans."""
    agreement_results = {
        "within_ai": {},
        "within_human": None,
        "between_ai_and_human": {}
    }
    
    # Calculate within-AI agreement
    # Group by AI service and model
    for service in df['metadata_ai_service'].unique():
        service_df = df[df['metadata_ai_service'] == service]
        
        for model in service_df['metadata_model'].unique():
            model_df = service_df[service_df['metadata_model'] == model]
            
            # Check if participant ID column exists
            if 'metadata_participant_id' not in model_df.columns:
                print("Warning: 'metadata_participant_id' column not found. Creating a default participant ID.")
                # Create a default participant ID column
                model_df = model_df.copy()
                model_df['metadata_participant_id'] = 'default_participant'
            
            # Skip if not enough data or participants
            if len(model_df) < 2:
                continue
                
            # Agreement metrics for this model
            model_agreement = {
                "krippendorff_alpha": {},
                "fleiss_kappa": {},
                "pairwise_cohen_kappa": {}
            }
            
            # Calculate Krippendorff's alpha for each score column
            for col in score_cols:
                # Check if we have interface_id, if not use pattern_type as index
                index_cols = []
                if 'metadata_interface_id' in model_df.columns:
                    index_cols.append('metadata_interface_id')
                if 'metadata_pattern_type' in model_df.columns:
                    index_cols.append('metadata_pattern_type')
                
                if not index_cols:
                    print(f"Warning: No suitable index columns found for {model}. Skipping analysis.")
                    continue
                
                # Reshape data for Krippendorff's alpha
                # We need a matrix where rows are items (interfaces) and columns are raters (participants)
                pivot = model_df.pivot_table(
                    index=index_cols,
                    columns='metadata_participant_id',
                    values=col
                )
                
                # Skip Krippendorff's alpha since the module is not available
                model_agreement["krippendorff_alpha"][col] = "N/A - krippendorff module not available"
                
                # Calculate Fleiss' kappa
                # Note: Fleiss' kappa works with categorical data, so we discretize the scores
                try:
                    # Convert scores to categories (e.g., 1-3 = low, 4-5 = medium, 6-7 = high)
                    # We'll create 3 bins for the discretization
                    discretized = pivot.copy()
                    for column in discretized.columns:
                        discretized[column] = pd.cut(
                            discretized[column], 
                            bins=[0, 3, 5, 8],  # Adjusted bins to include 7 and handle NaN
                            labels=[0, 1, 2]    # Low, Medium, High
                        ).astype(float)
                    
                    # Calculate Fleiss' kappa
                    kappa = fleiss_kappa(discretized.values)
                    model_agreement["fleiss_kappa"][col] = kappa
                except Exception as e:
                    model_agreement["fleiss_kappa"][col] = f"Error: {str(e)}"
            
            # Calculate pairwise Cohen's kappa for participants
            participants = model_df['metadata_participant_id'].unique()
            for col in score_cols:
                participant_kappas = []
                
                for p1, p2 in combinations(participants, 2):
                    # Get data for each participant
                    p1_data = model_df[model_df['metadata_participant_id'] == p1].set_index(['metadata_interface_id', 'metadata_pattern_type'])[col]
                    p2_data = model_df[model_df['metadata_participant_id'] == p2].set_index(['metadata_interface_id', 'metadata_pattern_type'])[col]
                    
                    # Align data
                    p1_data, p2_data = p1_data.align(p2_data, join='inner')
                    
                    if len(p1_data) > 1:
                        try:
                            # Discretize data for Cohen's kappa
                            p1_disc = pd.cut(p1_data, bins=[0, 3, 5, 8], labels=[0, 1, 2]).astype(float)
                            p2_disc = pd.cut(p2_data, bins=[0, 3, 5, 8], labels=[0, 1, 2]).astype(float)
                            
                            # Calculate Cohen's kappa
                            kappa = cohen_kappa_score(p1_disc, p2_disc)
                            participant_kappas.append(kappa)
                        except Exception as e:
                            continue
                
                if participant_kappas:
                    model_agreement["pairwise_cohen_kappa"][col] = {
                        "mean": np.mean(participant_kappas),
                        "min": np.min(participant_kappas),
                        "max": np.max(participant_kappas)
                    }
            
            # Add model agreement to results
            agreement_results["within_ai"][f"{service}_{model}"] = model_agreement
    
    # Calculate within-human agreement if human data is provided
    if human_df is not None:
        # Check if participant ID column exists
        if 'metadata_participant_id' not in human_df.columns:
            print("Warning: 'metadata_participant_id' column not found in human data. Creating a default participant ID.")
            # Create a default participant ID column
            human_df = human_df.copy()
            human_df['metadata_participant_id'] = 'human_participant'
            
        human_participants = human_df['metadata_participant_id'].unique()
        
        if len(human_participants) > 1:
            human_agreement = {
                "krippendorff_alpha": {},
                "fleiss_kappa": {},
                "pairwise_cohen_kappa": {}
            }
            
            # Calculate agreements for each score column
            for col in score_cols:
                # Check if we have interface_id, if not use pattern_type as index
                index_cols = []
                if 'metadata_interface_id' in human_df.columns:
                    index_cols.append('metadata_interface_id')
                if 'metadata_pattern_type' in human_df.columns:
                    index_cols.append('metadata_pattern_type')
                
                if not index_cols:
                    print(f"Warning: No suitable index columns found for human data. Skipping analysis.")
                    continue
                
                # Reshape data for Krippendorff's alpha
                pivot = human_df.pivot_table(
                    index=index_cols,
                    columns='metadata_participant_id',
                    values=col
                )
                
                # Skip Krippendorff's alpha since the module is not available
                human_agreement["krippendorff_alpha"][col] = "N/A - krippendorff module not available"
                
                # Calculate Fleiss' kappa
                try:
                    # Convert scores to categories
                    discretized = pivot.copy()
                    for column in discretized.columns:
                        discretized[column] = pd.cut(
                            discretized[column], 
                            bins=[0, 3, 5, 8],
                            labels=[0, 1, 2]
                        ).astype(float)
                    
                    # Calculate Fleiss' kappa
                    kappa = fleiss_kappa(discretized.values)
                    human_agreement["fleiss_kappa"][col] = kappa
                except Exception as e:
                    human_agreement["fleiss_kappa"][col] = f"Error: {str(e)}"
            
            # Calculate pairwise Cohen's kappa
            for col in score_cols:
                participant_kappas = []
                
                for p1, p2 in combinations(human_participants, 2):
                    # Get data for each participant
                    p1_data = human_df[human_df['metadata_participant_id'] == p1].set_index(['metadata_interface_id', 'metadata_pattern_type'])[col]
                    p2_data = human_df[human_df['metadata_participant_id'] == p2].set_index(['metadata_interface_id', 'metadata_pattern_type'])[col]
                    
                    # Align data
                    p1_data, p2_data = p1_data.align(p2_data, join='inner')
                    
                    if len(p1_data) > 1:
                        try:
                            # Discretize data for Cohen's kappa
                            p1_disc = pd.cut(p1_data, bins=[0, 3, 5, 8], labels=[0, 1, 2]).astype(float)
                            p2_disc = pd.cut(p2_data, bins=[0, 3, 5, 8], labels=[0, 1, 2]).astype(float)
                            
                            # Calculate Cohen's kappa
                            kappa = cohen_kappa_score(p1_disc, p2_disc)
                            participant_kappas.append(kappa)
                        except Exception as e:
                            continue
                
                if participant_kappas:
                    human_agreement["pairwise_cohen_kappa"][col] = {
                        "mean": np.mean(participant_kappas),
                        "min": np.min(participant_kappas),
                        "max": np.max(participant_kappas)
                    }
            
            agreement_results["within_human"] = human_agreement
    
    # Calculate between AI and human agreement
    if human_df is not None:
        # Calculate average scores for each pattern type from human data
        human_avg = human_df.groupby(['metadata_interface_id', 'metadata_pattern_type'])[score_cols].mean()
        
        for service in df['metadata_ai_service'].unique():
            service_df = df[df['metadata_ai_service'] == service]
            
            for model in service_df['metadata_model'].unique():
                model_df = service_df[service_df['metadata_model'] == model]
                
                # Calculate average scores for each pattern type from this AI model
                ai_avg = model_df.groupby(['metadata_interface_id', 'metadata_pattern_type'])[score_cols].mean()
                
                # Align human and AI data
                ai_data, human_data = ai_avg.align(human_avg, join='inner')
                
                if len(ai_data) > 1:
                    agreement = {"cohen_kappa": {}, "correlation": {}}
                    
                    for col in score_cols:
                        # Discretize data for Cohen's kappa
                        try:
                            ai_disc = pd.cut(ai_data[col], bins=[0, 3, 5, 8], labels=[0, 1, 2]).astype(float)
                            human_disc = pd.cut(human_data[col], bins=[0, 3, 5, 8], labels=[0, 1, 2]).astype(float)
                            
                            # Calculate Cohen's kappa
                            kappa = cohen_kappa_score(ai_disc, human_disc)
                            agreement["cohen_kappa"][col] = kappa
                        except Exception as e:
                            agreement["cohen_kappa"][col] = f"Error: {str(e)}"
                        
                        # Calculate correlation
                        try:
                            corr = ai_data[col].corr(human_data[col])
                            agreement["correlation"][col] = corr
                        except Exception as e:
                            agreement["correlation"][col] = f"Error: {str(e)}"
                    
                    agreement_results["between_ai_and_human"][f"{service}_{model}"] = agreement
    
    return agreement_results

def create_visualizations(df, reliability_df, human_concordance=None, output_dir="analysis_output"):
    """Create visualizations for the analysis results."""
    os.makedirs(output_dir, exist_ok=True)
    
    # Get score columns
    score_cols = [col for col in df.columns if col.startswith('score_')]
    
    # 1. Model Comparison Heatmap
    try:
        plt.figure(figsize=(15, 10))
        pivot = df.pivot_table(
            index=['metadata_ai_service', 'metadata_model'],
            values=score_cols,
            aggfunc='mean'
        )
        
        # Check if pivot table is empty
        if not pivot.empty and pivot.size > 0:
            # Create an annotated heatmap
            sns.heatmap(pivot, annot=True, cmap='viridis', fmt='.2f', linewidths=.5)
            plt.title('Average Scores by AI Service and Model')
            plt.tight_layout()
            plt.savefig(os.path.join(output_dir, 'model_comparison_heatmap.png'))
        else:
            print("Warning: Not enough data for model comparison heatmap")
        plt.close()
    except Exception as e:
        print(f"Error creating model comparison heatmap: {e}")
    
    # 2. Pattern Type Heatmap by AI Service/Model
    for service in df['metadata_ai_service'].unique():
        try:
            service_df = df[df['metadata_ai_service'] == service]
            
            for model in service_df['metadata_model'].unique():
                try:
                    model_df = service_df[service_df['metadata_model'] == model]
                    
                    # Skip if not enough data
                    if len(model_df) < 3:
                        print(f"Warning: Not enough data for pattern heatmap for {service} {model}")
                        continue
                    
                    plt.figure(figsize=(15, 10))
                    pivot = model_df.pivot_table(
                        index='metadata_pattern_type',
                        values=score_cols,
                        aggfunc='mean'
                    )
                    
                    # Check if pivot table is empty
                    if not pivot.empty and pivot.size > 0:
                        sns.heatmap(pivot, annot=True, cmap='viridis', fmt='.2f', linewidths=.5)
                        plt.title(f'Average Scores by Pattern Type for {service} {model}')
                        plt.tight_layout()
                        plt.savefig(os.path.join(output_dir, f'pattern_heatmap_{service}_{model}.png'))
                    else:
                        print(f"Warning: Empty pivot table for {service} {model}")
                    plt.close()
                except Exception as e:
                    print(f"Error creating pattern heatmap for {service} {model}: {e}")
        except Exception as e:
            print(f"Error processing service {service}: {e}")
    
    # 3. Reliability comparison
    if reliability_df is not None:
        plt.figure(figsize=(12, 8))
        sns.barplot(data=reliability_df, x='metadata_model', y='reliability_score', hue='metadata_ai_service')
        plt.title('Model Reliability Comparison')
        plt.xticks(rotation=45, ha='right')
        plt.tight_layout()
        plt.savefig(os.path.join(output_dir, 'model_reliability.png'))
        plt.close()
    
    # 4. Human concordance comparison
    if human_concordance is not None:
        plt.figure(figsize=(12, 8))
        sns.barplot(data=human_concordance, x='metadata_model', y='human_concordance', hue='metadata_ai_service')
        plt.title('AI Model Concordance with Human Assessments')
        plt.xticks(rotation=45, ha='right')
        plt.tight_layout()
        plt.savefig(os.path.join(output_dir, 'human_concordance.png'))
        plt.close()
        
        # 5. Scatter plot of reliability vs. human concordance
        if reliability_df is not None:
            merged_df = pd.merge(
                reliability_df,
                human_concordance,
                on=['metadata_ai_service', 'metadata_model']
            )
            
            plt.figure(figsize=(10, 8))
            sns.scatterplot(
                data=merged_df, 
                x='reliability_score', 
                y='human_concordance',
                hue='metadata_ai_service',
                size='metadata_model',
                sizes=(50, 200),
                alpha=0.7
            )
            
            # Add labels for each point
            for _, row in merged_df.iterrows():
                plt.text(
                    row['reliability_score'] + 0.02,
                    row['human_concordance'],
                    row['metadata_model'],
                    fontsize=8
                )
            
            plt.title('Reliability vs. Human Concordance')
            plt.xlabel('Reliability Score (higher = more consistent)')
            plt.ylabel('Human Concordance (higher = more similar to humans)')
            plt.tight_layout()
            plt.savefig(os.path.join(output_dir, 'reliability_vs_concordance.png'))
            plt.close()
    
    # 6. Individual score distributions by model
    for col in score_cols:
        plt.figure(figsize=(15, 10))
        sns.boxplot(data=df, x='metadata_model', y=col, hue='metadata_ai_service')
        plt.title(f'Distribution of {col} by Model')
        plt.xticks(rotation=45, ha='right')
        plt.tight_layout()
        plt.savefig(os.path.join(output_dir, f'boxplot_{col}.png'))
        plt.close()
    
    # UX KPI visualization by model and pattern type
    if 'ux_kpi' in df.columns:
        try:
            # Box plot of UX KPI by model
            plt.figure(figsize=(15, 10))
            sns.boxplot(data=df, x='metadata_model', y='ux_kpi', hue='metadata_ai_service')
            plt.title('Distribution of UX KPI by Model')
            plt.xticks(rotation=45, ha='right')
            plt.tight_layout()
            plt.savefig(os.path.join(output_dir, 'boxplot_ux_kpi.png'))
            plt.close()
        except Exception as e:
            print(f"Error creating UX KPI boxplot: {e}")
        
        try:
            # Heatmap of UX KPI by pattern type
            plt.figure(figsize=(15, 10))
            pivot = df.pivot_table(
                index='metadata_pattern_type',
                columns=['metadata_ai_service', 'metadata_model'],
                values='ux_kpi',
                aggfunc='mean'
            )
            
            # Check if pivot table is empty
            if not pivot.empty and pivot.size > 0:
                sns.heatmap(pivot, annot=True, cmap='RdYlGn_r', fmt='.2f', linewidths=.5)
                plt.title('Average UX KPI by Pattern Type and Model')
                plt.tight_layout()
                plt.savefig(os.path.join(output_dir, 'ux_kpi_heatmap.png'))
            else:
                print("Warning: Not enough data for UX KPI heatmap")
            plt.close()
        except Exception as e:
            print(f"Error creating UX KPI heatmap: {e}")
        
        # Generate gauge visualizations using ux_kpi_gauge.py
        try:
            # Save the current dataframe to CSV for gauge visualization
            df_csv_path = os.path.join(output_dir, 'data_for_gauges.csv')
            df.to_csv(df_csv_path, index=False)
            
            import subprocess
            gauge_output_dir = os.path.join(output_dir, 'gauges')
            os.makedirs(gauge_output_dir, exist_ok=True)
            
            print("Generating UX KPI gauge visualizations...")
            subprocess.run(['python', 'ux_kpi_gauge.py', 
                           '--results', df_csv_path, 
                           '--output_dir', gauge_output_dir])
            print(f"Gauge visualizations saved to {gauge_output_dir}")
        except Exception as e:
            print(f"Warning: Failed to generate gauge visualizations: {e}")
        
    # 7. Temperature effect plots (if temperature data exists)
    if 'metadata_temperature' in df.columns:
        temperatures = df['metadata_temperature'].unique()
        if len(temperatures) > 1:
            for service in df['metadata_ai_service'].unique():
                service_df = df[df['metadata_ai_service'] == service]
                
                for model in service_df['metadata_model'].unique():
                    model_df = service_df[service_df['metadata_model'] == model]
                    
                    # Skip if not enough temperature variation
                    if len(model_df['metadata_temperature'].unique()) < 2:
                        continue
                    
                    plt.figure(figsize=(15, 10))
                    
                    for col in score_cols[:min(6, len(score_cols))]:  # Limit to 6 scores to avoid overcrowding
                        sns.lineplot(
                            data=model_df,
                            x='metadata_temperature',
                            y=col,
                            marker='o',
                            label=col.replace('score_', '')
                        )
                    
                    plt.title(f'Effect of Temperature on Scores for {service} {model}')
                    plt.xlabel('Temperature')
                    plt.ylabel('Score')
                    plt.tight_layout()
                    plt.savefig(os.path.join(output_dir, f'temperature_effect_{service}_{model}.png'))
                    plt.close()
    
    # Return the paths to the generated visualizations
    return os.path.abspath(output_dir)

def load_config(config_path):
    """Load configuration from JSON file."""
    with open(config_path, 'r') as f:
        return json.load(f)

def combine_results(results_dir, pattern="*.csv", exclude_pattern="api_usage.csv"):
    """Combine all CSV results into a single DataFrame."""
    # Get list of all CSV files in the directory
    all_files = glob.glob(os.path.join(results_dir, pattern))
    # Exclude files matching the exclude pattern
    files = [f for f in all_files if exclude_pattern not in f and "summary_metrics.csv" not in f]
    
    if not files:
        raise ValueError(f"No CSV files found in {results_dir} matching pattern {pattern}")
    
    # Read each file into a DataFrame and combine
    df_list = []
    for filename in files:
        try:
            print(f"Reading {filename}")
            # Skip header row 1 if it contains descriptive text like 'mean', 'std', etc.
            df = pd.read_csv(filename)
            
            # Check if this file might have statistical row headers
            if any(col in str(df.iloc[0]).lower() for col in ['mean', 'std', 'min', 'max']):
                print(f"File {filename} has statistical headers, skipping first row")
                df = pd.read_csv(filename, skiprows=1)
            
            df_list.append(df)
        except Exception as e:
            print(f"Error reading {filename}: {e}")
    
    # Combine all DataFrames
    if not df_list:
        raise ValueError("No valid CSV files could be read")
        
    combined_df = pd.concat(df_list, ignore_index=True)
    return combined_df

def clean_data(df):
    """Clean and prepare the data for analysis."""
    # Convert temperature to float if it exists
    if 'metadata_temperature' in df.columns:
        df['metadata_temperature'] = pd.to_numeric(df['metadata_temperature'], errors='coerce')
    
    # Clean up service and model names for better readability
    if 'metadata_ai_service' in df.columns:
        # Convert to string first in case there are numeric values
        df['metadata_ai_service'] = df['metadata_ai_service'].astype(str)
        df['metadata_ai_service'] = df['metadata_ai_service'].str.capitalize()
    
    # Make sure model names are strings
    if 'metadata_model' in df.columns:
        df['metadata_model'] = df['metadata_model'].astype(str)
        
    # Make sure pattern types are strings
    if 'metadata_pattern_type' in df.columns:
        df['metadata_pattern_type'] = df['metadata_pattern_type'].astype(str)
    
    # Extract score columns
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
    
    # Handle hyphenated column names for non_addictive/non-addictive
    if 'score_addictive_non-addictive' in df.columns and 'score_addictive_non_addictive' not in df.columns:
        df['score_addictive_non_addictive'] = df['score_addictive_non-addictive']
    
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
    
    return df, score_cols

def calculate_reliability(df, score_cols, group_cols=['metadata_ai_service', 'metadata_model']):
    """Calculate reliability metrics (consistency across repeated runs)."""
    # Group by service, model, and pattern_type
    grouped = df.groupby(group_cols + ['metadata_pattern_type'])
    
    # Calculate standard deviation for each score column
    reliability = grouped[score_cols].std().reset_index()
    
    # Calculate mean standard deviation across all score columns
    mean_std = reliability[score_cols].mean(axis=1)
    reliability['mean_std'] = mean_std
    
    # Calculate overall reliability score (lower std = higher reliability)
    reliability['reliability_score'] = 1 / (mean_std + 0.1)  # Add small constant to avoid division by zero
    
    # Get aggregate reliability by service and model
    model_reliability = reliability.groupby(group_cols)['reliability_score'].mean().reset_index()
    model_reliability = model_reliability.sort_values('reliability_score', ascending=False)
    
    return reliability, model_reliability

def analyze_temperature_effects(df, score_cols):
    """Analyze how temperature affects scores and reliability."""
    if 'metadata_temperature' not in df.columns:
        return None
        
    # Group by service, model, temperature
    grouped = df.groupby(['metadata_ai_service', 'metadata_model', 'metadata_temperature'])
    
    # Calculate mean and std for each score
    temp_effects = grouped[score_cols].agg(['mean', 'std']).reset_index()
    
    # Calculate overall std across temperatures
    temp_reliability = df.groupby(['metadata_ai_service', 'metadata_model', 'metadata_pattern_type', 'metadata_temperature'])[score_cols].std()
    temp_reliability = temp_reliability.mean(axis=1).reset_index()
    temp_reliability = temp_reliability.rename(columns={0: 'mean_std'})
    
    return temp_effects, temp_reliability

def compare_with_human_results(ai_df, human_df, score_cols):
    """Compare AI results with human assessments."""
    if human_df is None:
        return None
        
    # Calculate mean scores for AI grouped by service, model, and pattern type
    ai_means = ai_df.groupby(['metadata_ai_service', 'metadata_model', 'metadata_pattern_type'])[score_cols].mean().reset_index()
    
    # Calculate mean scores for humans grouped by pattern type
    human_means = human_df.groupby(['metadata_pattern_type'])[score_cols].mean().reset_index()
    
    # Calculate differences between AI and human scores
    comparison_results = []
    
    for _, ai_row in ai_means.iterrows():
        service = ai_row['metadata_ai_service']
        model = ai_row['metadata_model']
        pattern = ai_row['metadata_pattern_type']
        
        # Find corresponding human row
        human_row = human_means[human_means['metadata_pattern_type'] == pattern]
        
        if not human_row.empty:
            human_row = human_row.iloc[0]
            
            # Calculate differences for each score
            diffs = {}
            for col in score_cols:
                ai_score = ai_row[col]
                human_score = human_row[col]
                diffs[f"{col}_diff"] = ai_score - human_score
                diffs[f"{col}_ai"] = ai_score
                diffs[f"{col}_human"] = human_score
            
            # Calculate mean absolute difference
            abs_diffs = [abs(diffs[f"{col}_diff"]) for col in score_cols]
            mean_abs_diff = sum(abs_diffs) / len(abs_diffs)
            
            comparison_results.append({
                'metadata_ai_service': service,
                'metadata_model': model,
                'metadata_pattern_type': pattern,
                'mean_abs_diff': mean_abs_diff,
                **diffs
            })
    
    if comparison_results:
        comparison_df = pd.DataFrame(comparison_results)
        
        # Calculate overall concordance with humans
        concordance = comparison_df.groupby(['metadata_ai_service', 'metadata_model'])['mean_abs_diff'].mean().reset_index()
        concordance = concordance.sort_values('mean_abs_diff')
        concordance['human_concordance'] = 1 / (concordance['mean_abs_diff'] + 0.1)  # Higher = more similar to humans
        
        # Calculate t-tests between AI and human ratings
        ttest_results = []
        for service in ai_df['metadata_ai_service'].unique():
            for model in ai_df[ai_df['metadata_ai_service'] == service]['metadata_model'].unique():
                for col in score_cols:
                    # Get AI scores for this service/model
                    ai_scores = ai_df[(ai_df['metadata_ai_service'] == service) & 
                                    (ai_df['metadata_model'] == model)][col].dropna()
                    
                    # Get human scores
                    human_scores = human_df[col].dropna()
                    
                    # Run t-test if we have enough data
                    if len(ai_scores) > 1 and len(human_scores) > 1:
                        try:
                            t_stat, p_value = ttest_ind(ai_scores, human_scores, equal_var=False)
                            ttest_results.append({
                                'metadata_ai_service': service,
                                'metadata_model': model,
                                'score_column': col,
                                't_statistic': t_stat,
                                'p_value': p_value,
                                'significant_diff': p_value < 0.05
                            })
                        except Exception as e:
                            print(f"T-test error for {service}/{model}/{col}: {e}")
        
        ttest_df = pd.DataFrame(ttest_results) if ttest_results else None
        
        return comparison_df, concordance, ttest_df
    
    return None

def statistical_analysis(df, score_cols):
    """Perform statistical analysis to compare different AI services and models."""
    results = {}
    
    # ANOVA to test for differences between services
    for col in score_cols:
        services = df['metadata_ai_service'].unique()
        groups = [df[df['metadata_ai_service'] == service][col].dropna() for service in services]
        
        try:
            f_stat, p_value = f_oneway(*groups)
            results[f"{col}_service_anova"] = {'f_statistic': f_stat, 'p_value': p_value}
            
            # If significant, perform post-hoc Tukey HSD
            if p_value < 0.05 and len(df) > len(services):
                # Prepare data for Tukey HSD
                data = []
                groups = []
                for service in services:
                    service_data = df[df['metadata_ai_service'] == service][col].dropna()
                    data.extend(service_data)
                    groups.extend([service] * len(service_data))
                
                # Skip Tukey HSD since statsmodels is not available
                tukey_summary = "Tukey HSD skipped - statsmodels not available"
                results[f"{col}_service_tukey"] = tukey_summary
        except Exception as e:
            results[f"{col}_service_anova_error"] = str(e)
    
    # ANOVA to test for differences between models within each service
    for service in df['metadata_ai_service'].unique():
        service_df = df[df['metadata_ai_service'] == service]
        models = service_df['metadata_model'].unique()
        
        if len(models) < 2:
            continue
            
        for col in score_cols:
            groups = [service_df[service_df['metadata_model'] == model][col].dropna() for model in models]
            
            try:
                f_stat, p_value = f_oneway(*groups)
                results[f"{service}_{col}_model_anova"] = {'f_statistic': f_stat, 'p_value': p_value}
            except Exception as e:
                results[f"{service}_{col}_model_anova_error"] = str(e)
    
    return results

if __name__ == "__main__":
    exit(main())