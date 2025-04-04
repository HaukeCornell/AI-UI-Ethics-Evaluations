#!/usr/bin/env python3
"""
Helper module to write the analysis summary.
"""

import os
from datetime import datetime
import numpy as np

def write_summary(df, args, agreement_results, model_reliability, human_concordance):
    """Write a summary of the analysis to a Markdown file."""
    try:
        with open(os.path.join(args.output_dir, "analysis_summary.md"), 'w') as f:
            f.write("# UI Assessment Analysis Summary\n\n")
            f.write(f"Analysis generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
            f.write("## Overview\n\n")
            f.write(f"- Total assessments analyzed: {len(df)}\n")
            
            # Safely join unique values
            try:
                ai_services = ', '.join(sorted(df['metadata_ai_service'].unique()))
                f.write(f"- AI services: {ai_services}\n")
            except Exception as e:
                f.write(f"- AI services: Error retrieving services ({str(e)})\n")
            
            try:
                models = ', '.join(sorted(df['metadata_model'].unique()))
                f.write(f"- Models: {models}\n")
            except Exception as e:
                f.write(f"- Models: Error retrieving models ({str(e)})\n")
            
            try:
                pattern_types = ', '.join(sorted(df['metadata_pattern_type'].unique()))
                f.write(f"- Pattern types: {pattern_types}\n\n")
            except Exception as e:
                f.write(f"- Pattern types: Error retrieving pattern types ({str(e)})\n\n")
            
            f.write("## Key Findings\n\n")
            
            # Add inter-annotator agreement section
            f.write("### Inter-Annotator Agreement\n\n")
            f.write("Agreement within models (Krippendorff's Alpha, averaged across metrics):\n\n")
            f.write("| Service/Model | Agreement |\n")
            f.write("|---------------|----------|\n")
            
            for model_key, model_data in agreement_results["within_ai"].items():
                try:
                    alphas = [float(alpha) for alpha in model_data["krippendorff_alpha"].values() 
                              if isinstance(alpha, (int, float)) or 
                              (isinstance(alpha, str) and alpha.replace('.', '', 1).isdigit())]
                    if alphas:
                        avg_alpha = np.mean(alphas)
                        f.write(f"| {model_key} | {avg_alpha:.4f} |\n")
                except Exception as e:
                    f.write(f"| {model_key} | Error: {str(e)} |\n")
            
            if agreement_results["within_human"]:
                try:
                    human_alphas = [float(alpha) for alpha in agreement_results["within_human"]["krippendorff_alpha"].values() 
                                  if isinstance(alpha, (int, float)) or 
                                  (isinstance(alpha, str) and alpha.replace('.', '', 1).isdigit())]
                    if human_alphas:
                        avg_human_alpha = np.mean(human_alphas)
                        f.write(f"| Human Participants | {avg_human_alpha:.4f} |\n")
                except Exception as e:
                    f.write(f"| Human Participants | Error: {str(e)} |\n")
            
            f.write("\n")
            
            # Most reliable models
            f.write("### Most Reliable Models\n\n")
            f.write("Models with the most consistent assessments across runs:\n\n")
            f.write("| Service | Model | Reliability Score |\n")
            f.write("|---------|-------|------------------|\n")
            for _, row in model_reliability.head(5).iterrows():
                f.write(f"| {row['metadata_ai_service']} | {row['metadata_model']} | {row['reliability_score']:.4f} |\n")
            f.write("\n")
            
            # Human concordance
            if human_concordance is not None:
                f.write("### Models Most Similar to Human Assessment\n\n")
                f.write("| Service | Model | Human Concordance |\n")
                f.write("|---------|-------|-------------------|\n")
                for _, row in human_concordance.head(5).iterrows():
                    f.write(f"| {row['metadata_ai_service']} | {row['metadata_model']} | {row['human_concordance']:.4f} |\n")
                f.write("\n")
            
            # Add UX KPI section if available
            if 'ux_kpi' in df.columns:
                f.write("\n## UX KPI Analysis\n\n")
                f.write("The UX KPI (User Experience Key Performance Indicator) is calculated as the mean of the following UEQ-S items:\n")
                f.write("- boring\n")
                f.write("- not interesting\n")
                f.write("- complicated\n")
                f.write("- confusing\n") 
                f.write("- inefficient\n")
                f.write("- cluttered\n")
                f.write("- unpredictable\n")
                f.write("- obstructive\n\n")
                
                f.write("Higher UX KPI values indicate more problematic UX patterns, while lower values indicate better user experience.\n\n")
                
                # Add worst performing patterns by UX KPI
                try:
                    pattern_ux_kpi = df.groupby('metadata_pattern_type')['ux_kpi'].mean().reset_index()
                    pattern_ux_kpi = pattern_ux_kpi.sort_values('ux_kpi', ascending=False)
                    
                    f.write("### Patterns Ranked by UX KPI (Worst to Best)\n\n")
                    f.write("| Pattern Type | UX KPI |\n")
                    f.write("|-------------|-------|\n")
                    for _, row in pattern_ux_kpi.head(5).iterrows():
                        f.write(f"| {row['metadata_pattern_type']} | {row['ux_kpi']:.2f} |\n")
                    f.write("\n")
                except Exception as e:
                    f.write(f"Error generating pattern rankings: {str(e)}\n\n")
                
                # Add models with best UX KPI
                try:
                    model_ux_kpi = df.groupby(['metadata_ai_service', 'metadata_model'])['ux_kpi'].mean().reset_index()
                    model_ux_kpi = model_ux_kpi.sort_values('ux_kpi')
                    
                    f.write("### Models with Best UX KPI Scores\n\n")
                    f.write("| Service | Model | UX KPI |\n")
                    f.write("|---------|-------|-------|\n")
                    for _, row in model_ux_kpi.head(5).iterrows():
                        f.write(f"| {row['metadata_ai_service']} | {row['metadata_model']} | {row['ux_kpi']:.2f} |\n")
                    f.write("\n")
                except Exception as e:
                    f.write(f"Error generating model UX KPI rankings: {str(e)}\n\n")
                
                f.write("For each pattern type, a gauge visualization has been generated showing the worst UX aspect and the overall UX KPI value. These visualizations can be found in the 'gauges' subdirectory.\n\n")
            
            f.write("## Visualizations\n\n")
            f.write("The following visualizations have been generated:\n\n")
            f.write("1. Model comparison heatmap\n")
            f.write("2. Pattern type heatmaps by model\n")
            f.write("3. Model reliability comparison\n")
            f.write("4. Inter-annotator agreement comparison\n")
            if human_concordance is not None:
                f.write("5. Human concordance comparison\n")
                f.write("6. Reliability vs. human concordance\n")
                f.write("7. AI-Human agreement heatmap\n")
            f.write("8. Score distributions by model\n")
            if 'ux_kpi' in df.columns:
                f.write("9. UX KPI visualizations\n")
                f.write("   - UX KPI boxplot by model\n")
                f.write("   - UX KPI heatmap by pattern type\n")
                f.write("   - Gauge visualizations for each pattern type\n")
            if 'metadata_temperature' in df.columns and len(df['metadata_temperature'].unique()) > 1:
                f.write("10. Temperature effect plots\n")
            
            f.write("\n## Detailed Results\n\n")
            f.write("Detailed results are available in the CSV files in this directory.\n")
        
        print(f"Summary report created successfully: {os.path.join(args.output_dir, 'analysis_summary.md')}")
        return True
    except Exception as e:
        print(f"Error creating summary report: {e}")
        return False