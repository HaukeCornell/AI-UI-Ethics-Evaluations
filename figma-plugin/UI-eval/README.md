# AI UI Ethics Evaluation Figma Plugin

This Figma plugin evaluates UI designs using AI vision models and generates UX KPI metrics with an emphasis on ethical considerations in design.

## Features

- Evaluate UI designs using leading multimodal AI models:
  - Anthropic Claude
  - OpenAI GPT-4 Vision
  - (Coming soon: Alibaba Qwen-VL, Ollama local models)
- Generate comprehensive UX KPI metrics based on a semantic differential scale
- Create interactive gauge visualizations inspired by the Python Plotly implementation
- Identify potential ethical issues and dark patterns in UI designs
- Generate detailed explanations with actionable feedback

## How to Use

1. Select a frame, component, or instance in your Figma document
2. Run the plugin
3. Choose an AI service (Anthropic Claude or OpenAI GPT-4)
4. Enter your API key for the selected service
5. Click "Evaluate Selected Frame"
6. Wait for the evaluation to complete (typically 5-10 seconds)
7. The plugin will create:
   - An enhanced gauge visualization with color-coded sections
   - A detailed explanation frame with assessment commentary

## Enhanced Gauge Visualization

The plugin creates a visually rich gauge that shows:
- Overall score with color coding (green/yellow/red)
- The worst aspect of the design with its specific score
- Overall UX KPI value with a threshold marker
- Ethical risk assessment (Low/Medium/High)
- Color-coded risk sections (1-3: good, 3-5: medium, 5-7: concerning)

## Metrics Evaluated

The plugin evaluates a UI design along 14 dimensions on a 1-7 scale:

- Efficiency (inefficient to efficient)
- Interest level (interesting to not interesting)
- Clarity (clear to confusing)
- Enjoyability (enjoyable to annoying)
- Organization (organized to cluttered)
- Addictiveness (addictive to non-addictive)
- Supportiveness (supportive to obstructive)
- Pressure (pressuring to suggesting)
- Excitement (boring to exciting)
- Transparency (revealed to covert)
- Complexity (complicated to easy)
- Predictability (unpredictable to predictable)
- Friendliness (friendly to unfriendly)
- Ethics (deceptive to benevolent)

## UX KPI Calculation

The UX KPI is calculated as the mean of several key aspects:
- Boring/exciting (inverted)
- Interesting/not interesting
- Complicated/easy (inverted)
- Clear/confusing
- Inefficient/efficient (inverted)
- Organized/cluttered
- Unpredictable/predictable (inverted)
- Supportive/obstructive

A higher UX KPI score (closer to 7) indicates potential usability or ethical concerns.

## Development Setup

This plugin is built with TypeScript. To set up the development environment:

1. Install Node.js and npm: https://nodejs.org/en/download/
2. Install TypeScript: `npm install -g typescript`
3. Install dependencies: `npm install`
4. Build the plugin: `npm run build` or `npm run watch` for continuous compilation

## API Keys

You'll need to provide your own API keys for:
- Anthropic Claude: https://www.anthropic.com/
- OpenAI GPT-4: https://openai.com/

## Security Note

API keys are only used within the plugin for evaluation requests and are not stored between sessions. Keys are transmitted only to the respective AI service APIs over secure connections.

## Credits

This plugin is part of a research project on AI-based UI evaluation with a focus on ethical considerations in user interface design.

## Acknowledgements

The gauge visualization was inspired by the Python-based gauge implementation using Plotly in the parent project.
