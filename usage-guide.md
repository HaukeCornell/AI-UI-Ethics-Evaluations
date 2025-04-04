# UI Assessment System Usage Guide

This guide provides instructions for using the UI Assessment System to compare how different AI models evaluate user interfaces according to ethical UX metrics.

## Setup and Installation

1. **Clone the repository**:
   ```
   git clone https://github.com/yourusername/ui-assessment-system.git
   cd ui-assessment-system
   ```

2. **Install dependencies**:
   ```
   pip install -r requirements.txt
   ```

3. **Set up API keys**:
   Create a `.env` file in the project root directory with your API keys:
   ```
   ANTHROPIC_API_KEY=your_anthropic_api_key
   OPENAI_API_KEY=your_openai_api_key
   QWEN_API_KEY=your_qwen_api_key
   ```

4. **Prepare your interfaces**:
   Place your interface images in the `interfaces/` directory. Create an `interfaces.json` file describing these interfaces following the format in `sample-interfaces.json`.

## Running Assessments

### Option 1: Run Complete Pipeline (Recommended)

Use the `run_all.py` script to execute the entire assessment pipeline:

```
python run_all.py --interfaces interfaces.json --human_results human_results.csv --temperatures 0.0 0.7 --repeats 3
```

Parameters:
- `--interfaces`: Path to interfaces JSON file
- `--human_results`: (Optional) Path to human assessment results
- `--temperatures`: Temperature values for model variation (e.g., 0.0 0.7)
- `--repeats`: Number of times to repeat each assessment
- `--services`: (Optional) Specific AI services to use (e.g., anthropic openai)
- `--models`: (Optional) Specific models to use (e.g., claude-3-opus-20240229 gpt-4o)

This will:
1. Run assessments with all specified models
2. Analyze the results
3. Generate comprehensive visualizations
4. Create a summary report

### Option 2: Run Steps Individually

#### Step 1: Run assessments with multiple models

```
python run_multiple_assessments.py --interfaces interfaces.json --output_dir results --temperatures 0.0 0.7 --repeats 3
```

#### Step 2: Analyze the results

```
python analyze_all_results.py --results_dir results --human_results human_results.csv --output_dir analysis_output
```
<!-- E.g.

```
python analyze_all_results.py --results_dir model_analysis_test --human_results Formatting\ Human\ Survey\ Data/raw_participant_evaluations.csv --output_dir analysis_output
``` -->
## Understanding the Results

After running the assessment, you'll find several outputs:

1. **Combined Results CSV**: Contains all assessments from all models
2. **Model Reliability CSV**: Shows consistency of each model across repeated runs
3. **Human Concordance CSV**: Shows how closely each model matches human assessments
4. **Inter-Annotator Agreement**: Statistical measures of agreement within and between raters
5. **Visualizations**: Including heatmaps, radar charts, and comparison plots
6. **Analysis Summary**: Markdown report summarizing key findings

### Key Metrics

- **Reliability Score**: Measures consistency across repeated runs (higher = more consistent)
- **Human Concordance**: Measures similarity to human assessments (higher = more similar)
- **Krippendorff's Alpha**: Measures inter-annotator agreement (higher = more agreement)
- **Cohen's Kappa**: Measures agreement between two raters (higher = more agreement)

## Testing with Local Open Source Models (Ollama)

To use open source models locally:

1. Install [Ollama](https://ollama.ai/) 
2. Pull models with vision capabilities:
   ```
   ollama pull llava:13b
   ollama pull bakllava:15b
   ```
3. Run the assessment:
   ```
   python run_all.py --interfaces interfaces.json --services ollama --models llava:13b bakllava:15b
   ```

## Extending the System

### Adding New AI Services

1. Add the service to `config.json` under `ai_services`
2. Implement the API call function in `ui_assessment.py`
3. Add the service to the `select_ai_service` method

### Customizing Evaluation Metrics

Modify the `ueeq_scales` section in `config.json` to add, remove, or modify scales.

## Tips for Best Results

1. **Use consistent image formats**: Use JPG or PNG images with consistent dimensions
2. **Run multiple repeats**: At least 3 repeats help establish reliability
3. **Include human assessments**: Provides crucial benchmarks for AI evaluations
4. **Try different temperatures**: Test both deterministic (0.0) and more diverse (0.7) responses
5. **Test a range of interface types**: Include both clear exemplars and ambiguous cases

## Troubleshooting

- **API rate limiting**: Add delays between requests by setting `--delay 5`
- **Inconsistent responses**: Ensure prompt templates are clear and unambiguous
- **Missing data**: Check logs for API errors or parsing issues
