import pandas as pd
import re

def create_html_table(row, condition='enhanced'):
    """Create HTML table for a single pattern row"""
    
    # Map TSV columns to display names and categories
    ux_metrics = {
        'inefficient': ('Efficienc I', 'Inefficient vs. Efficient'),
        'cluttered': ('Efficiency II', 'Cluttered vs. Organized'),
        'complicated': ('Perspicuity I', 'Complicated vs. Easy'), 
        'confusing': ('Perspicuity II', 'Confusing vs. Clear'),
        'unpredictable': ('Dependability I', 'Unpredictable vs. Predictable'),
        'obstructive': ('Dependability II', 'Obstructive vs. Supportive'),
        'boring': ('Stimulation I', 'Boring vs. Exciting'),
        'not interesting': ('Stimulation II', 'Not Interesting vs. Interesting'),
        'annoying': ('Attractiveness I', 'Annoying vs. Enjoyable'),
        'unfriendly': ('Attractiveness II', 'Unfriendly vs. Friendly')
    }
    
    ethics_metrics = {
        'pressuring': ('Coercion', 'Pressuring vs. Suggesting'),
        'addictive': ('Addictiveness', 'Addictive vs. Non-addictive'),
        'covert': ('Disguise', 'Covert vs. Revealed'),
        'deceptive': ('Deception', 'Deceptive vs. Benevolent')
    }
    
    # Start HTML with improved header
    if condition == 'enhanced':
        header_note = "<p style='font-size: 11px; color: #666; margin-bottom: 10px;'><em>Note: yellow-highlighted items assess perceived autonomy, and are not part of the validated User Experience Questionnaire UX evaluation metrics</em></p>"
    else:
        header_note = ""
    
    html = f"""<div style='background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin-bottom: 20px;'>
<h4>UX Evaluation Details</h4>
{header_note}
<table style='width: 100%; border-collapse: collapse;'>
<tr style='background-color: #e0e0e0;'>
<th style='padding: 8px; border: 1px solid #ccc;'>Metric Category</th>
<th style='padding: 8px; border: 1px solid #ccc;'>Specific Measure</th>
<th style='padding: 8px; border: 1px solid #ccc;'>Score</th>
</tr>"""

    # Add UX metrics
    for col, (category, measure) in ux_metrics.items():
        if col in row and pd.notna(row[col]):
            score = row[col]
            html += f"\n<tr><td style='padding: 8px; border: 1px solid #ccc;'><strong>{category}</strong></td><td style='padding: 8px; border: 1px solid #ccc;'>{measure}</td><td style='padding: 8px; border: 1px solid #ccc; text-align: center;'>{score:.2f}</td></tr>"
    
    # Add ethics metrics only for enhanced condition
    if condition == 'enhanced':
        for col, (category, measure) in ethics_metrics.items():
            if col in row and pd.notna(row[col]):
                score = row[col]
                html += f"\n<tr style='background-color: #FBF3DB;'><td style='padding: 8px; border: 1px solid #ccc;'><strong>{category}</strong></td><td style='padding: 8px; border: 1px solid #ccc;'>{measure}</td><td style='padding: 8px; border: 1px solid #ccc; text-align: center; color: #CB912F;'>{score:.2f}</td></tr>"
    
    # Add overall UX quality score (UEQ metrics only)
    ux_score = row['UX KPI'] if 'UX KPI' in row and pd.notna(row['UX KPI']) else 'N/A'
    html += f"\n<tr style='background-color: #E7F3F8; font-weight: bold;'><td style='padding: 8px; border: 1px solid #ccc;'><strong>Overall UX Quality</strong></td><td style='padding: 8px; border: 1px solid #ccc;'>Composite Score (UX metrics only)</td><td style='padding: 8px; border: 1px solid #ccc; text-align: center;'>{ux_score}</td></tr>"
    
    # Add overall mean for enhanced condition
    if condition == 'enhanced':
        overall_mean = row['MEAN'] if 'MEAN' in row and pd.notna(row['MEAN']) else 'N/A'
        html += f"\n<tr style='background-color: #F6F3F9; font-weight: bold;'><td style='padding: 8px; border: 1px solid #ccc;'><strong>Overall Mean</strong></td><td style='padding: 8px; border: 1px solid #ccc;'>All metrics combined</td><td style='padding: 8px; border: 1px solid #ccc; text-align: center;'>{overall_mean}</td></tr>"
    
    # Close HTML
    html += """
</table>
<p style='font-size: 12px; color: #666; margin-top: 10px;'><em>Scale: -3 (strongly negative) to +3 (strongly positive)</em></p>
</div>"""
    
    return html

def generate_ordered_tables(tsv_file):
    """Generate HTML tables in the order matching Qualtrics Loop & Merge"""
    
    # Read TSV file
    df = pd.read_csv(tsv_file, sep='\t')
    
    # Clean column names (remove extra spaces)
    df.columns = df.columns.str.strip()
    
    # Define the exact order from your Qualtrics Loop & Merge
    qualtrics_order = [
        'Sneaking Bad Default',
        'Content Customization',  
        'Endlessness',
        'Expectation Result Mismatch',
        'False Hierarchy',
        'Forced Access',
        'Gamification',
        'Hindering Account Deletion',
        'Nagging',
        'Overcomplicated Process',
        'Pull To Refresh',
        'Social Connector',
        'Toying With Emotion',
        'Trick Wording',
        'Social Pressure'
    ]
    
    enhanced_tables = []
    standard_tables = []
    
    # Generate tables in Qualtrics order
    for i, pattern_name in enumerate(qualtrics_order, 1):
        # Find the row for this pattern
        pattern_row = df[df['Pattern'].str.strip() == pattern_name.strip()]
        
        if pattern_row.empty:
            print(f"Warning: Pattern '{pattern_name}' not found in TSV file")
            continue
            
        row = pattern_row.iloc[0]
        
        # Enhanced condition (with ethics metrics)
        enhanced_html = create_html_table(row, condition='enhanced')
        enhanced_tables.append({
            'pattern': pattern_name,
            'html': enhanced_html,
            'index': i,
            'slug': pattern_name.lower().replace(' ', '-')
        })
        
        # Standard condition (UX metrics only)
        standard_html = create_html_table(row, condition='standard')
        standard_tables.append({
            'pattern': pattern_name,
            'html': standard_html,
            'index': i,
            'slug': pattern_name.lower().replace(' ', '-')
        })
    
    return enhanced_tables, standard_tables

def create_separate_csvs(enhanced_tables, standard_tables):
    """Create separate CSV files for Enhanced and Standard conditions"""
    
    import csv
    
    # Enhanced condition CSV
    enhanced_data = []
    for i, table in enumerate(enhanced_tables, 1):
        enhanced_data.append({
            'Field 1': f'https://github.com/HaukeCornell/AI-UI-Ethics-Evaluations/blob/main/dark-patterns/{table["slug"]}.png?raw=true',
            'Field 2': table['slug'],
            'Field 3': f'Interface {i}',
            'Field 4': f'https://github.com/HaukeCornell/AI-UI-Ethics-Evaluations/blob/main/Gauge/UEEQ-RISK/gauge_{i}.png?raw=true',
            'Field 5': table['html']
        })
    
    with open('qualtrics_enhanced_condition.csv', 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['Field 1', 'Field 2', 'Field 3', 'Field 4', 'Field 5'])
        writer.writeheader()
        writer.writerows(enhanced_data)
    
    # Standard condition CSV  
    standard_data = []
    for i, table in enumerate(standard_tables, 1):
        standard_data.append({
            'Field 1': f'https://github.com/HaukeCornell/AI-UI-Ethics-Evaluations/blob/main/dark-patterns/{table["slug"]}.png?raw=true',
            'Field 2': table['slug'],
            'Field 3': f'Interface {i}',
            'Field 4': f'https://github.com/HaukeCornell/AI-UI-Ethics-Evaluations/blob/main/Gauge/UEEQ-RISK/gauge_{i}.png?raw=true',
            'Field 5': table['html']
        })
    
    with open('qualtrics_standard_condition.csv', 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['Field 1', 'Field 2', 'Field 3', 'Field 4', 'Field 5'])
        writer.writeheader()
        writer.writerows(standard_data)
    
    print("Created separate CSV files:")
    print("- qualtrics_enhanced_condition.csv (with ethics metrics)")
    print("- qualtrics_standard_condition.csv (UX metrics only)")

if __name__ == "__main__":
    # Run the script
    tsv_file = "Pattern-Means.tsv"  # Update with your file path
    
    enhanced_tables, standard_tables = generate_ordered_tables(tsv_file)
    create_separate_csvs(enhanced_tables, standard_tables)
    
    print(f"Generated {len(enhanced_tables)} tables in Qualtrics order")