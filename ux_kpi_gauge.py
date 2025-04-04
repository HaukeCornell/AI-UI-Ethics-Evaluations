#!/usr/bin/env python3
"""
Script to calculate UX KPI values and generate gauge visualizations.
The UX KPI is calculated as the mean of the following UEQ-S items:
- boring
- not interesting
- complicated
- confusing 
- inefficient
- cluttered
- unpredictable
- obstructive
"""

import os
import pandas as pd
import plotly.graph_objects as go
import argparse
import numpy as np

def calculate_ux_kpi(df):
    """
    Calculate UX KPI for each pattern type based on negative UX aspects.
    Maps the column names from the results CSV to the corresponding UX KPI items.
    Inverts scores where necessary so that negative values always indicate poor UX.
    """
    # Define the mapping from UX KPI items to column names
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
    
    # Create a copy of the dataframe to avoid modifying the original
    result_df = df.copy()
    
    # Create columns with inverted values where necessary
    # For columns where high value = negative UX aspect
    for ux_item, column in ux_kpi_columns_mapping.items():
        if column in result_df.columns:
            if ux_item in ['not_interesting', 'confusing', 'cluttered', 'obstructive']:
                # These columns are already oriented so that high values = negative aspect
                result_df[f'ux_{ux_item}'] = result_df[column]
            else:
                # These columns need to be inverted (7 - value) so that low values = negative aspect
                result_df[f'ux_{ux_item}'] = 8 - result_df[column]  # 8 - value to invert (1-7 scale becomes 7-1)
    
    # Calculate UX KPI (mean of all items)
    ux_items = [f'ux_{item}' for item in ux_kpi_columns_mapping.keys() 
               if f'ux_{item}' in result_df.columns]
    
    if ux_items:
        result_df['ux_kpi'] = result_df[ux_items].mean(axis=1)
    
    return result_df

def find_worst_aspect_per_pattern(df):
    """
    Find the worst-performing UX aspect for each pattern type.
    Returns a DataFrame with pattern types and their worst aspects.
    """
    # Group by pattern type
    pattern_groups = df.groupby('metadata_pattern_type')
    
    # Get UX item columns
    ux_items = [col for col in df.columns if col.startswith('ux_')]
    ux_items = [col for col in ux_items if col != 'ux_kpi']
    
    results = []
    
    for pattern, group in pattern_groups:
        # Calculate mean for each UX item
        item_means = group[ux_items].mean()
        
        # Find the worst item (highest value is worst since we're measuring negative aspects)
        worst_item = item_means.idxmax()
        worst_value = item_means[worst_item]
        
        # Get mean UX KPI
        ux_kpi = group['ux_kpi'].mean() if 'ux_kpi' in group.columns else None
        
        results.append({
            'pattern': pattern,
            'worst_aspect': worst_item.replace('ux_', ''),
            'worst_value': worst_value,
            'ux_kpi': ux_kpi
        })
    
    return pd.DataFrame(results)

def create_gauge(pattern, score, ux_kpi, worst_aspect, output_dir):
    """
    Create a gauge visualization for a pattern.
    
    Parameters:
    - pattern: Name of the UX pattern
    - score: Score for the worst aspect
    - ux_kpi: UX KPI value
    - worst_aspect: Name of the worst aspect
    - output_dir: Directory to save the gauge visualization
    """
    # Determine color based on score
    if score > 5:
        text_color = "lightcoral"
    elif score > 3:
        text_color = "orange"
    else:
        text_color = "lightgreen"
    
    fig = go.Figure(go.Indicator(
        mode="gauge+number+delta",
        value=score,
        domain={'x': [0, 1], 'y': [0, 0.9]},
        delta={
            'reference': ux_kpi,
            'font': {'size': 1},
            'position': "bottom",
            'relative': False,
            'increasing': {'symbol': " "},
            'decreasing': {'symbol': " ", 'color': "white"},
            'valueformat': " "
        },
        title={
            'text': f"<span style='font-size:1em;color:gray'>{pattern}</span><br>" +
                   f"<span style='font-size:1em;color:black'>UX KPI: {ux_kpi:.2f}</span>",
            'font': {'size': 24}
        },
        number={
            'font': {'size': 80, 'color': text_color},
            'suffix': f"<br><b><span style='font-size:1.0em;color:{text_color}'>{worst_aspect}</span>",
        },
        gauge={
            'axis': {'range': [1, 7]},
            'bar': {'color': "green" if score < 3 else "orange" if score < 5 else "red"},
            'steps': [
                {'range': [1, 3], 'color': "lightgreen"},
                {'range': [3, 5], 'color': "lightyellow"},
                {'range': [5, 7], 'color': "lightcoral"}
            ],
            'threshold': {
                'line': {'color': "black", 'width': 4},
                'thickness': 0.75,
                'value': ux_kpi
            }
        }
    ))
    
    fig.update_layout(
        margin=dict(l=20, r=20, t=50, b=100),
        height=600
    )
    
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Save the gauge visualization
    fig.write_image(os.path.join(output_dir, f"{pattern.replace(' ', '_')}.png"))
    
    return fig

def main():
    parser = argparse.ArgumentParser(description="Generate UX KPI Gauge Visualizations")
    parser.add_argument("--results", required=True, help="Path to results CSV file")
    parser.add_argument("--output_dir", default="gauge_output", help="Directory to save gauge visualizations")
    
    args = parser.parse_args()
    
    # Load results
    df = pd.read_csv(args.results)
    
    # Calculate UX KPI
    df_with_kpi = calculate_ux_kpi(df)
    
    # Find worst aspect for each pattern type
    pattern_results = find_worst_aspect_per_pattern(df_with_kpi)
    
    # Save pattern results to CSV
    pattern_results.to_csv(os.path.join(args.output_dir, "pattern_ux_kpi.csv"), index=False)
    
    # Create gauge visualizations
    for _, row in pattern_results.iterrows():
        pattern = row['pattern']
        worst_aspect = row['worst_aspect']
        worst_value = row['worst_value']
        ux_kpi = row['ux_kpi']
        
        print(f"Creating gauge for {pattern} (worst: {worst_aspect} = {worst_value:.2f}, UX KPI: {ux_kpi:.2f})")
        create_gauge(pattern, worst_value, ux_kpi, worst_aspect, args.output_dir)
    
    print(f"Gauge visualizations saved to {args.output_dir}")

if __name__ == "__main__":
    main()