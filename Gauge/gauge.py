import plotly.graph_objects as go

kpi_scores = {
    # "Nagging": -0.94,
    # "Overcomplicated Process": -0.57,
    # "Hindering Account Deletion": 0.18,
    # "Sneaking Bad Default": 0.45,
    # "Expectation Result Mismatch":-0.56,
    # "False Hierarchy": -0.56,
    # "Trick Wording": -0.60,
    # "Toying With Emotion":-0.42,
    # "Forced Access": -0.85,
    # "Gamification": -0.10,
    # "Social Pressure": 0.29,
    # "Social Connector": 0.33,
    # "Content Customization": 0.23,
    # "Endlessness": 0.51,
    "Pull To Refresh": 0.85,
    # "Overall": -0.10
}

for pattern, score in kpi_scores.items():
    fig = go.Figure(go.Indicator(
        mode="gauge+number+delta",
        value=score,
        domain={'x': [0, 1], 'y': [0.5, 1]},  # Adjust y range if needed
        delta_font_color='white',
        delta_increasing_color="white",
        delta_decreasing_color="white",
        title={
            'text': "<span style='font-size:0.8em;color:gray'>UX KPI</span>",  # UX KPI in title
            'font': {'size': 24},
        },
        number={
            'suffix': f"<br><b><span style='font-size:1.0em;color:gray'>{pattern}</span>",  # Keep pattern name large
            'font': {'size': 80},
            # 'suffix': '%',  # Add percentage suffix
            # 'reference': 0  # This sets the starting point at 0
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
                'value': score
            }
        }
    ))
    fig.update_layout(
        margin=dict(l=20, r=20, t=50, b=20),  # Custom margins for narrower crop
    )
    fig.show()