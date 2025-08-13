import pandas as pd
import re

def create_html_table(row, condition='enhanced'):
    """Create HTML table for a single pattern row"""
    
    # Map TSV columns to display names and categories
    ux_metrics = {
        'inefficient': ('Efficiency', 'Inefficient vs. Efficient'),
        'complicated': ('Perspicuity', 'Complicated vs. Easy'), 
        'confusing': ('Perspicuity', 'Confusing vs. Clear'),
        'unpredictable': ('Dependability', 'Unpredictable vs. Predictable'),
        'boring': ('Stimulation', 'Boring vs. Exciting'),
        'unfriendly': ('Attractiveness', 'Unfriendly vs. Friendly')
    }
    
    ethics_metrics = {
        'pressuring': ('Manipulation', 'Pressuring vs. Suggesting'),
        'addictive': ('Addiction', 'Addictive vs. Non-addictive'),
        'covert': ('Deception', 'Covert vs. Revealed'),
        'deceptive': ('Benevolence', 'Deceptive vs. Benevolent')
    }
    
    # Start HTML
    html = f"""<div style='background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin-bottom: 20px;'>
<h4>UX Evaluation Results</h4>
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
                html += f"\n<tr style='background-color: #ffebee;'><td style='padding: 8px; border: 1px solid #ccc;'><strong>{category}</strong></td><td style='padding: 8px; border: 1px solid #ccc;'>{measure}</td><td style='padding: 8px; border: 1px solid #ccc; text-align: center; color: #d32f2f;'>{score:.2f}</td></tr>"
    
    # Add overall UX quality score
    ux_score = row['UX KPI'] if 'UX KPI' in row and pd.notna(row['UX KPI']) else 'N/A'
    html += f"\n<tr style='background-color: #e8f5e8; font-weight: bold;'><td style='padding: 8px; border: 1px solid #ccc;'><strong>Overall UX Quality</strong></td><td style='padding: 8px; border: 1px solid #ccc;'>Composite Score</td><td style='padding: 8px; border: 1px solid #ccc; text-align: center;'>{ux_score}</td></tr>"
    
    # Close HTML
    html += """
</table>
<p style='font-size: 12px; color: #666; margin-top: 10px;'><em>Scale: -3 (strongly negative) to +3 (strongly positive)</em></p>
</div>"""
    
    return html

def generate_all_tables(tsv_file):
    """Generate all HTML tables from TSV file"""
    
    # Read TSV file
    df = pd.read_csv(tsv_file, sep='\t')
    
    # Clean column names (remove extra spaces)
    df.columns = df.columns.str.strip()
    
    enhanced_tables = []
    standard_tables = []
    
    # Generate tables for each pattern
    for idx, row in df.iterrows():
        pattern_name = row['Pattern']
        
        # Enhanced condition (with ethics metrics)
        enhanced_html = create_html_table(row, condition='enhanced')
        enhanced_tables.append({
            'pattern': pattern_name,
            'html': enhanced_html,
            'index': idx + 1
        })
        
        # Standard condition (UX metrics only)
        standard_html = create_html_table(row, condition='standard')
        standard_tables.append({
            'pattern': pattern_name,
            'html': standard_html,
            'index': idx + 1
        })
    
    return enhanced_tables, standard_tables

def save_tables_to_files(enhanced_tables, standard_tables):
    """Save tables to separate HTML files"""
    
    # Enhanced condition file
    with open('enhanced_condition_tables.html', 'w') as f:
        f.write("<!-- Enhanced Condition Tables (Standard + Ethics Metrics) -->\n\n")
        for table in enhanced_tables:
            f.write(f"<!-- Pattern {table['index']}: {table['pattern']} -->\n")
            f.write(table['html'])
            f.write("\n\n")
    
    # Standard condition file
    with open('standard_condition_tables.html', 'w') as f:
        f.write("<!-- Standard Condition Tables (UX Metrics Only) -->\n\n")
        for table in standard_tables:
            f.write(f"<!-- Pattern {table['index']}: {table['pattern']} -->\n")
            f.write(table['html'])
            f.write("\n\n")
    
    print(f"Generated {len(enhanced_tables)} enhanced tables")
    print(f"Generated {len(standard_tables)} standard tables")
    print("Files saved: enhanced_condition_tables.html, standard_condition_tables.html")

def create_loop_merge_csv(enhanced_tables, standard_tables):
    """Create CSV file for Qualtrics Loop & Merge"""
    
    loop_data = []
    
    for i, (enh, std) in enumerate(zip(enhanced_tables, standard_tables), 1):
        loop_data.append({
            'InterfaceID': i,
            'PatternName': enh['pattern'],
            'ImageFile': f'interface_{i}.png',  # Update with your actual image filenames
            'EnhancedTable': enh['html'].replace('\n', ' ').replace("'", "&#39;"),
            'StandardTable': std['html'].replace('\n', ' ').replace("'", "&#39;")
        })
    
    # Save to CSV
    import csv
    with open('qualtrics_loop_merge.csv', 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['InterfaceID', 'PatternName', 'ImageFile', 'EnhancedTable', 'StandardTable'])
        writer.writeheader()
        writer.writerows(loop_data)
    
    print("Created qualtrics_loop_merge.csv for Loop & Merge")

if __name__ == "__main__":
    # Run the script
    tsv_file = "Pattern-Means.tsv"  # Update with your file path
    
    enhanced_tables, standard_tables = generate_all_tables(tsv_file)
    save_tables_to_files(enhanced_tables, standard_tables)
    create_loop_merge_csv(enhanced_tables, standard_tables)