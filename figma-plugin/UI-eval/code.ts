/**
 * AI UI Ethics Evaluation Figma Plugin
 * This plugin evaluates UI designs using AI models and generates UX KPI metrics.
 */

// Show UI
figma.showUI(__html__, { width: 320, height: 380 });

// Configuration based on config.json
const config = {
  ueeq_scales: [
    { name: "inefficient_efficient", left: "inefficient", right: "efficient" },
    { name: "interesting_not_interesting", left: "interesting", right: "not interesting" },
    { name: "clear_confusing", left: "clear", right: "confusing" },
    { name: "enjoyable_annoying", left: "enjoyable", right: "annoying" },
    { name: "organized_cluttered", left: "organized", right: "cluttered" },
    { name: "addictive_non-addictive", left: "addictive", right: "non-addictive" },
    { name: "supportive_obstructive", left: "supportive", right: "obstructive" },
    { name: "pressuring_suggesting", left: "pressuring", right: "suggesting" },
    { name: "boring_exciting", left: "boring", right: "exciting" },
    { name: "revealed_covert", left: "revealed", right: "covert" },
    { name: "complicated_easy", left: "complicated", right: "easy" },
    { name: "unpredictable_predictable", left: "unpredictable", right: "predictable" },
    { name: "friendly_unfriendly", left: "friendly", right: "unfriendly" },
    { name: "deceptive_benevolent", left: "deceptive", right: "benevolent" }
  ],
  ai_services: {
    anthropic: {
      models: ["claude-3-opus-20240229"],
      endpoint: "https://api.anthropic.com/v1/messages",
      headers: {
        "anthropic-version": "2023-06-01",
        "content-type": "application/json"
      }
    },
    openai: {
      models: ["gpt-4-turbo"],
      endpoint: "https://api.openai.com/v1/chat/completions",
      headers: {
        "Content-Type": "application/json"
      }
    },
    qwen: {
      models: ["qwen-vl-max"]
    },
    ollama: {
      models: ["gemma3"],
      endpoint: "http://localhost:11434/api/generate",
      headers: {
        "Content-Type": "application/json"
      }
    }
  }
};

// Types
interface UiEvalMessage {
  type: string;
  service?: string;
  apiKey?: string;
  error?: string;
  hasValidSelection?: boolean;
}

interface UeqScale {
  name: string;
  left: string;
  right: string;
}

interface AssessmentResult {
  assessment: Record<string, number>;
  explanation: string;
}

/**
 * Get a description of the selected frame
 */
async function getFrameDescription(node: FrameNode | ComponentNode | InstanceNode): Promise<string> {
  // Get node properties
  const { name, width, height } = node;
  
  // Create a description of the node's children
  let childrenDescription = "";
  if ('children' in node && node.children.length > 0) {
    childrenDescription = node.children.map(child => {
      if ('characters' in child) {
        return `- Text element "${child.characters}"`;
      } else if (child.type === 'RECTANGLE' || child.type === 'ELLIPSE' || child.type === 'POLYGON') {
        return `- ${child.type.toLowerCase()} shape`;
      } else if (child.type === 'FRAME' || child.type === 'COMPONENT' || child.type === 'INSTANCE') {
        return `- Nested ${child.type.toLowerCase()} "${child.name}"`;
      } else if (child.type === 'GROUP') {
        return `- Group "${child.name}"`;
      } else {
        return `- ${child.type.toLowerCase()} element`;
      }
    }).join('\n');
  }

  return `UI Frame: ${name}
Dimensions: ${width}x${height}px

Elements:
${childrenDescription}`;
}

/**
 * Format the prompt for UEQ assessment
 */
function formatUeqPrompt(description: string, scales: UeqScale[]): string {
  // Build scales text for prompt
  let scalesText = "";
  let exampleAssessment = "{";
  
  for (const scale of scales) {
    const { name, left, right } = scale;
    scalesText += `- ${left} (1) to ${right} (7)\n`;
    exampleAssessment += `\n                "${name}": 5,`;
  }
  
  // Remove trailing comma and add closing brace
  exampleAssessment = exampleAssessment.substring(0, exampleAssessment.length - 1) + "\n            }";
  
  return `
## UI Element Evaluation

Instruction: In this section, a user interface element is presented to you. Subsequently, pairs of contrasting adjectives are listed. The numbers 1-7 between the adjectives represent gradations between the opposites. Please express your agreement with the adjectives by selecting one number per line that best aligns with your impression. If you find the feature unclear or believe that the adjectives do not describe the feature accurately, select -1 for "don't know / not applicable".

UI Description: ${description}

I perceive this interface feature as...

${scalesText}

Rate 1-7 where 1 is the left term and 7 is the right term, or -1 for not applicable.

Please format your response as a JSON object with the following structure:
{
    "assessment": ${exampleAssessment},
    "explanation": "Short explanation of your assessment..."
}

Please ensure your response contains only this JSON object and no other text.
`;
}

/**
 * Call AI API via the UI (to avoid CORS issues)
 */
async function callAIService(service: string, prompt: string, imageBytes: Uint8Array, apiKey: string): Promise<string> {
  const base64Image = await encodeImageToBase64(imageBytes);
  
  // Create a promise that will resolve when we get a response from the UI
  return new Promise((resolve, reject) => {
    // Set up a listener for the response
    const messageListener = (event: MessageEvent) => {
      const msg = event.data.pluginMessage;
      
      if (msg.type === 'api-response') {
        // Remove the listener once we get a response
        window.removeEventListener('message', messageListener);
        
        if (msg.error) {
          reject(new Error(msg.error));
        } else {
          resolve(msg.data);
        }
      }
    };
    
    // Add the listener
    window.addEventListener('message', messageListener);
    
    // Send the request to the UI
    figma.ui.postMessage({
      type: 'api-request',
      service: service,
      apiKey: apiKey,
      prompt: prompt,
      base64Image: base64Image,
      config: {
        anthropic: {
          endpoint: config.ai_services.anthropic.endpoint,
          model: config.ai_services.anthropic.models[0],
          headers: config.ai_services.anthropic.headers
        },
        openai: {
          endpoint: config.ai_services.openai.endpoint,
          model: config.ai_services.openai.models[0],
          headers: config.ai_services.openai.headers
        }
      }
    });
    
    // Set a timeout to reject the promise if we don't get a response
    setTimeout(() => {
      window.removeEventListener('message', messageListener);
      reject(new Error("API request timed out after 60 seconds"));
    }, 60000);
  });
}

/**
 * Encode image to Base64
 */
async function encodeImageToBase64(bytes: Uint8Array): Promise<string> {
  // Use Figma's built-in base64 encoding function
  return figma.base64Encode(bytes);
}

/**
 * Extract JSON from response text
 */
function extractJsonFromResponse(response: string): AssessmentResult {
  const jsonStart = response.indexOf('{');
  const jsonEnd = response.lastIndexOf('}') + 1;
  
  if (jsonStart >= 0 && jsonEnd > jsonStart) {
    const jsonStr = response.substring(jsonStart, jsonEnd);
    return JSON.parse(jsonStr);
  }
  
  throw new Error("No JSON found in response");
}

/**
 * Calculate UX KPI from assessment result
 */
function calculateUxKpi(result: AssessmentResult): {
  uxKpi: number;
  worstAspect: string;
  worstValue: number;
  ethicalRisk: 'Low' | 'Medium' | 'High';
} {
  const assessment = result.assessment;
  
  // Map scores to the right format for UX KPI calculation
  const scores: Record<string, number> = {};
  
  // Define mapping for UX KPI calculation
  const uxMapping: Record<string, {item: string, invert: boolean}> = {
    'boring_exciting': {item: 'ux_boring', invert: true},
    'interesting_not_interesting': {item: 'ux_not_interesting', invert: false},  
    'complicated_easy': {item: 'ux_complicated', invert: true},
    'clear_confusing': {item: 'ux_confusing', invert: false},
    'inefficient_efficient': {item: 'ux_inefficient', invert: true},
    'organized_cluttered': {item: 'ux_cluttered', invert: false},
    'unpredictable_predictable': {item: 'ux_unpredictable', invert: true},
    'supportive_obstructive': {item: 'ux_obstructive', invert: false}
  };
  
  // Calculate inverted scores where necessary
  // Manually iterate over uxMapping keys since Object.entries is not available in ES6
  const keys = ['boring_exciting', 'interesting_not_interesting', 'complicated_easy', 
                'clear_confusing', 'inefficient_efficient', 'organized_cluttered', 
                'unpredictable_predictable', 'supportive_obstructive'];
  
  for (const key of keys) {
    const mapping = uxMapping[key];
    if (key in assessment) {
      const value = assessment[key];
      scores[mapping.item] = mapping.invert ? 8 - value : value;
    }
  }
  
  // Calculate the worst aspect (highest score is worst)
  let worstAspect = '';
  let worstValue = 0;
  
  // Manually iterate over scores since Object.entries is not available in ES6
  const scoreKeys = ['ux_boring', 'ux_not_interesting', 'ux_complicated', 'ux_confusing',
                     'ux_inefficient', 'ux_cluttered', 'ux_unpredictable', 'ux_obstructive'];
  
  for (const key of scoreKeys) {
    if (key in scores) {
      const value = scores[key];
      if (value > worstValue) {
        worstValue = value;
        worstAspect = key.replace('ux_', '');
      }
    }
  }
  
  // Calculate UX KPI (mean of all scores)
  // Manual implementation since Object.values is not available in ES6
  const validScores: number[] = [];
  for (const key of scoreKeys) {
    if (key in scores && scores[key] > 0) {
      validScores.push(scores[key]);
    }
  }
  
  // Calculate mean manually
  let sum = 0;
  for (let i = 0; i < validScores.length; i++) {
    sum += validScores[i];
  }
  const uxKpi = validScores.length > 0 ? sum / validScores.length : 0;
  
  // Calculate ethical risk based on values
  let ethicalRisk: 'Low' | 'Medium' | 'High' = 'Low';
  
  // Check deceptive/benevolent score if available
  if ('deceptive_benevolent' in assessment) {
    const ethicsScore = assessment['deceptive_benevolent'];
    if (ethicsScore <= 3) {
      ethicalRisk = 'High';
    } else if (ethicsScore <= 5) {
      ethicalRisk = 'Medium';
    }
  } else {
    // Fallback based on UX KPI
    if (uxKpi >= 5) {
      ethicalRisk = 'High';
    } else if (uxKpi >= 3) {
      ethicalRisk = 'Medium';
    }
  }
  
  return {
    uxKpi,
    worstAspect,
    worstValue,
    ethicalRisk
  };
}

/**
 * Create a gauge visualization inspired by the Python gauge implementation
 */
function createGauge(
  score: number, 
  pattern: string, 
  worstAspect: string, 
  ethicalRisk: string,
  uxKpiValue: number
): FrameNode {
  // Create a frame for the gauge
  const gauge = figma.createFrame();
  gauge.name = "UI Evaluation Gauge";
  gauge.resize(350, 250);
  gauge.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
  
  // Create background for the gauge
  const gaugeBackground = figma.createRectangle();
  gaugeBackground.name = "Gauge Background";
  gaugeBackground.resize(280, 50);
  gaugeBackground.x = 35;
  gaugeBackground.y = 100;
  gaugeBackground.fills = [{ type: 'SOLID', color: { r: 0.95, g: 0.95, b: 0.95 } }];
  gaugeBackground.cornerRadius = 25;
  gauge.appendChild(gaugeBackground);
  
  // Create colored sections for the gauge (like in the Python implementation)
  // Green section (1-3)
  const greenSection = figma.createRectangle();
  greenSection.name = "Green Section";
  greenSection.resize(93, 50);
  greenSection.x = 35;
  greenSection.y = 100;
  greenSection.fills = [{ type: 'SOLID', color: { r: 0.8, g: 0.97, b: 0.8 } }];
  greenSection.topLeftRadius = 25;
  greenSection.bottomLeftRadius = 25;
  greenSection.topRightRadius = 0;
  greenSection.bottomRightRadius = 0;
  gauge.appendChild(greenSection);
  
  // Yellow section (3-5)
  const yellowSection = figma.createRectangle();
  yellowSection.name = "Yellow Section";
  yellowSection.resize(93, 50);
  yellowSection.x = 128;
  yellowSection.y = 100;
  yellowSection.fills = [{ type: 'SOLID', color: { r: 1, g: 0.97, b: 0.8 } }];
  gauge.appendChild(yellowSection);
  
  // Red section (5-7)
  const redSection = figma.createRectangle();
  redSection.name = "Red Section";
  redSection.resize(94, 50);
  redSection.x = 221;
  redSection.y = 100;
  redSection.fills = [{ type: 'SOLID', color: { r: 0.99, g: 0.8, b: 0.8 } }];
  redSection.topLeftRadius = 0;
  redSection.bottomLeftRadius = 0;
  redSection.topRightRadius = 25;
  redSection.bottomRightRadius = 25;
  gauge.appendChild(redSection);
  
  // Create the gauge indicator (colored bar)
  const gaugeIndicator = figma.createRectangle();
  gaugeIndicator.name = "Gauge Indicator";
  
  // Calculate width based on score (1-7 scale to 0-280px)
  const width = Math.max(10, Math.min(280, ((score - 1) / 6) * 280));
  gaugeIndicator.resize(width, 50);
  gaugeIndicator.x = 35;
  gaugeIndicator.y = 100;
  
  // Set color based on score
  let color;
  if (score >= 5) {
    color = { r: 0.9, g: 0.3, b: 0.3 };  // Red for high scores (bad)
  } else if (score >= 3) {
    color = { r: 1, g: 0.7, b: 0.2 };    // Orange for medium scores
  } else {
    color = { r: 0.2, g: 0.8, b: 0.3 };  // Green for low scores (good)
  }
  
  gaugeIndicator.fills = [{ type: 'SOLID', color, opacity: 0.75 }];
  // Set individual corner radius properties
  gaugeIndicator.topLeftRadius = 25;
  gaugeIndicator.bottomLeftRadius = 25;
  gaugeIndicator.topRightRadius = width >= 280 ? 25 : 0;
  gaugeIndicator.bottomRightRadius = width >= 280 ? 25 : 0;
  gauge.appendChild(gaugeIndicator);
  
  // Add UX KPI marker (threshold) at uxKpi position
  if (uxKpiValue >= 1 && uxKpiValue <= 7) {
    const threshold = figma.createRectangle();
    threshold.name = "UX KPI Threshold";
    const thresholdX = 35 + ((uxKpiValue - 1) / 6) * 280;
    threshold.resize(4, 58);
    threshold.x = thresholdX - 2;
    threshold.y = 96;
    threshold.fills = [{ type: 'SOLID', color: { r: 0.2, g: 0.2, b: 0.2 } }];
    threshold.cornerRadius = 2;
    gauge.appendChild(threshold);
  }
  
  // Add score text
  const scoreText = figma.createText();
  scoreText.characters = score.toFixed(1);
  scoreText.fontSize = 36;
  scoreText.x = 175;
  scoreText.y = 40;
  scoreText.textAlignHorizontal = "CENTER";
  scoreText.fills = [{ type: 'SOLID', color }];
  gauge.appendChild(scoreText);
  
  // Add pattern name text
  const patternText = figma.createText();
  patternText.characters = pattern;
  patternText.fontSize = 18;
  patternText.x = 35;
  patternText.y = 15;
  patternText.fills = [{ type: 'SOLID', color: { r: 0.3, g: 0.3, b: 0.3 } }];
  gauge.appendChild(patternText);
  
  // Add worst aspect text
  const aspectText = figma.createText();
  aspectText.characters = `Worst aspect: ${worstAspect}`;
  aspectText.fontSize = 14;
  aspectText.x = 35;
  aspectText.y = 160;
  aspectText.fills = [{ type: 'SOLID', color: { r: 0.3, g: 0.3, b: 0.3 } }];
  gauge.appendChild(aspectText);
  
  // Add UX KPI text
  const kpiText = figma.createText();
  kpiText.characters = `UX KPI: ${uxKpiValue.toFixed(2)}`;
  kpiText.fontSize = 14;
  kpiText.x = 35;
  kpiText.y = 180;
  kpiText.fills = [{ type: 'SOLID', color: { r: 0.3, g: 0.3, b: 0.3 } }];
  gauge.appendChild(kpiText);
  
  // Add ethical risk text
  const riskText = figma.createText();
  riskText.characters = `Ethical risk: ${ethicalRisk}`;
  riskText.fontSize = 14;
  riskText.x = 35;
  riskText.y = 200;
  
  // Set color based on risk level
  if (ethicalRisk === 'High') {
    riskText.fills = [{ type: 'SOLID', color: { r: 0.9, g: 0.3, b: 0.3 } }];
  } else if (ethicalRisk === 'Medium') {
    riskText.fills = [{ type: 'SOLID', color: { r: 0.95, g: 0.6, b: 0.1 } }];
  } else {
    riskText.fills = [{ type: 'SOLID', color: { r: 0.2, g: 0.8, b: 0.3 } }];
  }
  
  gauge.appendChild(riskText);
  
  // Add gauge ticks
  for (let i = 1; i <= 7; i++) {
    const tick = figma.createRectangle();
    tick.name = `Tick-${i}`;
    tick.resize(2, 15);
    tick.x = 35 + ((i - 1) / 6) * 280;
    tick.y = 155;
    tick.fills = [{ type: 'SOLID', color: { r: 0.5, g: 0.5, b: 0.5 } }];
    gauge.appendChild(tick);
    
    // Add tick label
    const tickLabel = figma.createText();
    tickLabel.characters = i.toString();
    tickLabel.fontSize = 12;
    tickLabel.x = 31 + ((i - 1) / 6) * 280;
    tickLabel.y = 174;
    tickLabel.textAlignHorizontal = "CENTER";
    tickLabel.fills = [{ type: 'SOLID', color: { r: 0.5, g: 0.5, b: 0.5 } }];
    gauge.appendChild(tickLabel);
  }
  
  return gauge;
}

/**
 * Create a comment with evaluation explanation
 */
function createEvaluationComment(result: AssessmentResult, uxKpi: {
  uxKpi: number;
  worstAspect: string;
  worstValue: number;
  ethicalRisk: 'Low' | 'Medium' | 'High';
}): FrameNode {
  // Create a frame for the explanation
  const frame = figma.createFrame();
  frame.name = "UI Evaluation Explanation";
  frame.resize(350, 280);
  frame.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
  
  // Add title
  const title = figma.createText();
  title.characters = "AI Evaluation Results";
  title.fontSize = 16;
  title.x = 20;
  title.y = 20;
  title.fills = [{ type: 'SOLID', color: { r: 0.1, g: 0.1, b: 0.1 } }];
  frame.appendChild(title);
  
  // Add explanation text
  const explanation = figma.createText();
  explanation.characters = result.explanation;
  explanation.fontSize = 12;
  explanation.x = 20;
  explanation.y = 50;
  explanation.fills = [{ type: 'SOLID', color: { r: 0.3, g: 0.3, b: 0.3 } }];
  explanation.resize(310, 120);
  frame.appendChild(explanation);
  
  // Add UX KPI summary
  const kpiSummary = figma.createText();
  kpiSummary.characters = `UX KPI: ${uxKpi.uxKpi.toFixed(2)}\nWorst Aspect: ${uxKpi.worstAspect} (${uxKpi.worstValue.toFixed(1)})\nEthical Risk: ${uxKpi.ethicalRisk}\n\nScale: 1-7 where higher values indicate potential issues`;
  kpiSummary.fontSize = 12;
  kpiSummary.x = 20;
  kpiSummary.y = 180;
  kpiSummary.fills = [{ type: 'SOLID', color: { r: 0.3, g: 0.3, b: 0.3 } }];
  frame.appendChild(kpiSummary);
  
  // Add disclaimer
  const disclaimer = figma.createText();
  disclaimer.characters = "This evaluation was generated by AI and should be considered a starting point for further UX analysis.";
  disclaimer.fontSize = 10;
  disclaimer.x = 20;
  disclaimer.y = 240;
  disclaimer.fills = [{ type: 'SOLID', color: { r: 0.6, g: 0.6, b: 0.6 } }];
  disclaimer.resize(310, 40);
  frame.appendChild(disclaimer);
  
  return frame;
}

/**
 * Main evaluation function
 */
async function evaluateUI(service: string, apiKey: string) {
  try {
    // Check if a frame is selected
    const selection = figma.currentPage.selection;
    
    if (selection.length !== 1 || !(selection[0].type === 'FRAME' || selection[0].type === 'COMPONENT' || selection[0].type === 'INSTANCE')) {
      throw new Error("Please select exactly one frame, component, or instance to evaluate");
    }
    
    const selectedNode = selection[0] as FrameNode | ComponentNode | InstanceNode;
    
    // Get description of the UI frame
    const description = await getFrameDescription(selectedNode);
    
    // Format prompt
    const prompt = formatUeqPrompt(description, config.ueeq_scales);
    
    // Get image bytes
    const bytes = await selectedNode.exportAsync({
      format: 'PNG',
      constraint: { type: 'SCALE', value: 2 }
    });
    
    // Call AI service via the UI (to avoid CORS issues)
    const responseText = await callAIService(service, prompt, bytes, apiKey);
    
    // Extract JSON result
    const result = extractJsonFromResponse(responseText);
    
    // Calculate UX KPI
    const uxKpi = calculateUxKpi(result);
    
    // Create gauge visualization
    const gauge = createGauge(
      uxKpi.worstValue,
      "UI Evaluation", 
      uxKpi.worstAspect, 
      uxKpi.ethicalRisk,
      uxKpi.uxKpi
    );
    
    // Create evaluation comment
    const comment = createEvaluationComment(result, uxKpi);
    
    // Position the gauge and comment next to the selected node
    gauge.x = selectedNode.x + selectedNode.width + 20;
    gauge.y = selectedNode.y;
    
    comment.x = selectedNode.x + selectedNode.width + 20;
    comment.y = selectedNode.y + gauge.height + 20;
    
    // Add to document
    figma.currentPage.appendChild(gauge);
    figma.currentPage.appendChild(comment);
    
    // Select the new elements
    figma.currentPage.selection = [gauge, comment];
    figma.viewport.scrollAndZoomIntoView([selectedNode, gauge, comment]);
    
    // Notify UI
    figma.ui.postMessage({ type: 'evaluation-complete' });
  } catch (error) {
    console.error('Evaluation error:', error);
    figma.ui.postMessage({ 
      type: 'evaluation-error', 
      error: error instanceof Error ? error.message : String(error) 
    });
  }
}

/**
 * Check if a valid frame is selected
 */
function checkValidSelection(): boolean {
  const selection = figma.currentPage.selection;
  return selection.length === 1 && (selection[0].type === 'FRAME' || selection[0].type === 'COMPONENT' || selection[0].type === 'INSTANCE');
}

// Handle messages from UI
figma.ui.onmessage = async (msg: UiEvalMessage) => {
  if (msg.type === 'evaluate-ui') {
    await evaluateUI(msg.service!, msg.apiKey!);
  } else if (msg.type === 'cancel') {
    figma.closePlugin();
  } else if (msg.type === 'check-selection') {
    figma.ui.postMessage({ 
      type: 'selection-status', 
      hasValidSelection: checkValidSelection() 
    });
  }
};

// Listen for selection changes
figma.on("selectionchange", () => {
  figma.ui.postMessage({ 
    type: 'selection-status', 
    hasValidSelection: checkValidSelection() 
  });
});
