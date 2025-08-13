import plotly.graph_objects as go
import pandas as pd
from pathlib import Path

df = pd.read_csv('Pattern-Means.tsv', sep='\t')
df.columns = df.columns.str.strip()

# Find pattern column
pattern_col = next((c for c in df.columns if c.strip().lower() == "pattern"), None)
if pattern_col is None:
    raise ValueError(f"No 'Pattern' column found. Columns: {list(df.columns)}")

exclude_cols = {pattern_col.lower(), "distractors", "worst assessment", "mean", "ux kpi"}
# Scale/adjective columns (keep order as in file, excluding known summary columns)
scale_cols_all = [c for c in df.columns if c.lower() not in exclude_cols]
scale_cols_all = scale_cols_all[:14]  # keep same cap

out_dir = Path("gauges")
out_dir.mkdir(exist_ok=True)

for _, row in df.iterrows():
    pattern = row[pattern_col]
    scale_values = row[scale_cols_all].astype(float)
    worst_value = scale_values.min()
    worst_scale = scale_values.idxmin()
    ux_kpi_col = next((c for c in df.columns if c.lower() == "ux kpi"), None)
    ux_kpi = float(row[ux_kpi_col]) if ux_kpi_col else 0.0
    display_reference = worst_value + ux_kpi

    if worst_value < -0.75:
        text_color = "lightcoral"
    elif worst_value < 0.75:
        text_color = "orange"
    else:
        text_color = "lightgreen"

    fig = go.Figure(go.Indicator(
        mode="gauge+number+delta",
        value=worst_value,
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
            'text': (
                f"<span style='font-size:1em;color:gray'>{pattern}</span><br>"
                f"<span style='font-size:1em;color:black'>UX KPI: {ux_kpi:.2f}</span>"
            ),
            'font': {'size': 24}
        },
        number={
            'font': {'size': 80, 'color': text_color},
            'suffix': f"<br><b><span style='font-size:1.0em;color:{text_color}'>{worst_scale}</span>",
        },
        gauge={
            'axis': {'range': [-3, 3]},
            'bar': {'color': "red" if worst_value < -0.75 else "orange" if worst_value < 0.75 else "green"},
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

    fig.update_layout(margin=dict(l=20, r=20, t=50, b=100), height=600)

    # Show each (optional)
    # fig.show()

    safe_name = "".join(ch for ch in pattern if ch.isalnum() or ch in (" ", "_", "-")).strip().replace(" ", "_")
    out_path = out_dir / f"{safe_name}.png"
    try:
        fig.write_image(str(out_path), scale=2)
    except ValueError:
        print("Install kaleido for image export: pip install -U kaleido")
        break

print(f"Done. Images in {out_dir.resolve()}")