import plotly.graph_objects as go
import pandas as pd

# Read the TSV file
df = pd.read_csv('Pattern-Means.tsv', sep='\t')

# Dictionary to store pattern and its worst scale value
pattern_worst_scales = {}

# Process each pattern (row)
for idx, row in df.iterrows():
    pattern = row['Pattern ']  # Note the space after 'Pattern'
    # Get the first 14 columns (excluding Pattern, Distractors, Worst Assessment, MEAN, UX KPI)
    scale_values = row.iloc[1:15].astype(float)
    # Find the minimum value and its corresponding column name
    worst_value = scale_values.min()
    worst_scale = scale_values.idxmin()  # This will give us the column name (adjective)
    # Get the UX KPI value for this pattern
    ux_kpi = float(row['UX KPI'])
    pattern_worst_scales[pattern] = (worst_scale, worst_value, ux_kpi)

# Create gauge for each pattern
for pattern, (scale, score, ux_kpi) in pattern_worst_scales.items():
    # Calculate an offset to show the actual UX KPI value instead of the difference
    display_reference = score + ux_kpi
    
    # Determine color based on score
    if score < -0.75:
        text_color = "lightcoral"
    elif score < 0.75:
        text_color = "orange"
    else:
        text_color = "lightgreen"
    
    fig = go.Figure(go.Indicator(
        mode="gauge+number+delta",
        value=score,
        domain={'x': [0, 1], 'y': [0, 0.9]},
        delta={
            'reference': display_reference,
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
            'suffix': f"<br><b><span style='font-size:1.0em;color:{text_color}'>{scale}</span>",
        },
        gauge={
            'axis': {'range': [-3, 3]},
            'bar': {'color': "red" if score < -0.75 else "orange" if score < 0.75 else "green"},
            'steps': [
                {'range': [-3, -0.75], 'color': "lightcoral"},
                {'range': [-0.75, 0.75], 'color': "lightyellow"},
                {'range': [0.75, 3], 'color': "lightgreen"}
            ],
            'threshold': {
                'line': {'color': "black", 'width': 4},
                'thickness': 0.75,
                'value': ux_kpi
            }
        }
    ))
    
    fig.update_layout(
        margin=dict(l=20, r=20, t=50, b=100),  # Increased bottom margin
        height=600  # Increased overall height
    )
    fig.show()