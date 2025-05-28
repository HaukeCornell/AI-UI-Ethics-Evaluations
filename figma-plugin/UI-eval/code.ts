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
  prompt?: string;
  base64Image?: string;
  config?: any;
  data?: string;
  message?: string;
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
 * Format the prompt for UEQ assessment with direct -3 to +3 scale
 */
function formatUeqPrompt(description: string, scales: UeqScale[]): string {
  // Build scales text for prompt
  let scalesText = "";
  let exampleAssessment = "{";
  
  for (const scale of scales) {
    // Format scales with negative to positive semantics
    // For scales where the negative term is on the right, we need to swap direction
    const { name, left, right } = scale;
    
    // Identify scales where negative is on the right (need to be inverted)
    const needsInversion = [
      "interesting_not_interesting", 
      "clear_confusing", 
      "enjoyable_annoying", 
      "organized_cluttered", 
      "supportive_obstructive", 
      "friendly_unfriendly"
    ].includes(name);
    
    if (needsInversion) {
      // For these scales, the negative term is on the right, so present in reverse
      scalesText += `- ${right} (-3) to ${left} (+3)\n`;
    } else {
      // For these scales, the negative term is on the left
      scalesText += `- ${left} (-3) to ${right} (+3)\n`;
    }
    
    // Example uses a neutral value (0)
    exampleAssessment += `\n                "${name}": 0,`;
  }
  
  // Remove trailing comma and add closing brace
  exampleAssessment = exampleAssessment.substring(0, exampleAssessment.length - 1) + "\n            }";
  
  return `
## UI Element Evaluation

Instruction: In this section, a user interface element is presented to you. Subsequently, pairs of contrasting adjectives are listed. The scale ranges from -3 to +3, representing gradations between the opposites. Please evaluate the interface by selecting one number per line that best aligns with your impression.

UI Description: ${description}

I perceive this interface feature as...

${scalesText}

The numerical scale represents:
-3 = strongly negative term
-2 = moderately negative term
-1 = slightly negative term
0 = neutral
+1 = slightly positive term
+2 = moderately positive term
+3 = strongly positive term
null = not applicable/don't know

Important:
- Negative values (-3 to -1) indicate potential problems or dark patterns
- Positive values (+1 to +3) indicate good UX design
- Zero represents a neutral evaluation

Please format your response as a JSON object with the following structure:
{
    "assessment": ${exampleAssessment},
    "explanation": "Short explanation of your assessment, highlighting both positive and negative aspects"
}

Please ensure your response contains only this JSON object and no other text.
`;
}

/**
 * Call AI API via the UI (to avoid CORS issues)
 */
async function callAIService(service: string, prompt: string, imageBytes: Uint8Array, apiKey: string): Promise<string> {
  const base64Image = await encodeImageToBase64(imageBytes);
  
  return new Promise<string>((resolve, reject) => {
    // Setup message handler
    function handlePluginMessage(msg: any) {
      if (msg.type === 'api-response') {
        // Remove handler once we get a response
        figma.ui.off('message', handlePluginMessage);
        
        if (msg.error) {
          reject(new Error(msg.error));
        } else {
          resolve(msg.data);
        }
      }
    }
    
    // Add the message handler
    figma.ui.on('message', handlePluginMessage);
    
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
        },
        ollama: {
          endpoint: config.ai_services.ollama.endpoint,
          model: config.ai_services.ollama.models[0],
          headers: config.ai_services.ollama.headers
        }
      }
    });
    
    // Set a timeout to reject the promise if we don't get a response
    setTimeout(() => {
      figma.ui.off('message', handlePluginMessage);
      reject(new Error("API request timed out after 60 seconds"));
    }, 60000);
  });
}

/**
 * Encode image to Base64 with safety checks
 */
async function encodeImageToBase64(bytes: Uint8Array): Promise<string> {
  try {
    // Use Figma's built-in base64 encoding function
    const base64 = figma.base64Encode(bytes);
    
    // Validate the base64 string
    if (!base64 || base64.length === 0) {
      console.error("Base64 encoding failed - empty result");
      throw new Error("Failed to encode image: empty result");
    }
    
    // Check if we need to resize the image (if it's too large)
    // Max size ~3MB base64 string (which is roughly a 2.25MB image)
    const MAX_BASE64_LENGTH = 3 * 1024 * 1024;
    if (base64.length > MAX_BASE64_LENGTH) {
      console.warn("Image is very large, base64 length:", base64.length);
      
      // We'd need to re-export at a lower quality, but for now just truncate
      // This is not ideal, but better than failing completely
      console.warn("Base64 image truncated to avoid size issues");
      return base64.substring(0, MAX_BASE64_LENGTH);
    }
    
    return base64;
  } catch (error) {
    console.error("Error in base64 encoding:", error);
    throw new Error("Failed to encode image for API request");
  }
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
 * Calculate UX KPI from assessment result with direct -3 to +3 scale input
 */
function calculateUxKpi(result: AssessmentResult): {
  uxKpi: number;
  worstAspect: string;
  worstValue: number;
  bestAspect: string;
  bestValue: number;
  ethicalRisk: 'Low' | 'Medium' | 'High';
  manipulationScore: number;
} {
  const assessment = result.assessment;
  
  // Map scores to the right format for UX KPI calculation
  const scores: Record<string, number> = {};
  
  // Define mapping for UX KPI calculation 
  // All scales are now directly in -3 to +3 format where positive is good and negative is bad
  const uxMapping: Record<string, {item: string}> = {
    // UX items
    'boring_exciting': {item: 'ux_exciting'}, 
    'interesting_not_interesting': {item: 'ux_interesting'}, 
    'complicated_easy': {item: 'ux_easy'}, 
    'clear_confusing': {item: 'ux_clear'}, 
    'inefficient_efficient': {item: 'ux_efficient'}, 
    'organized_cluttered': {item: 'ux_organized'}, 
    'unpredictable_predictable': {item: 'ux_predictable'}, 
    'supportive_obstructive': {item: 'ux_supportive'}, 
    'enjoyable_annoying': {item: 'ux_enjoyable'}, 
    'friendly_unfriendly': {item: 'ux_friendly'}, 
    
    // Manipulation items - directly in -3 to +3 scale where positive is ethical
    'addictive_non-addictive': {item: 'manip_non_addictive'}, 
    'pressuring_suggesting': {item: 'manip_suggesting'}, 
    'revealed_covert': {item: 'manip_revealed'}, 
    'deceptive_benevolent': {item: 'manip_benevolent'} 
  };
  
  // Set scores directly from assessment
  // Iterate over all available keys in the assessment
  for (const key in assessment) {
    if (key in uxMapping) {
      const mapping = uxMapping[key];
      const value = assessment[key];
      
      // Skip missing or null values
      if (value === null) {
        continue;
      }
      
      // Values are already in -3 to +3 scale
      scores[mapping.item] = value;
    }
  }
  
  // Calculate aspects (best/worst)
  let worstAspect = '';
  let worstValue = 3; // Start with highest possible value since we're looking for the lowest
  let bestAspect = '';
  let bestValue = -3; // Start with lowest possible value since we're looking for the highest
  
  // UX item keys for worst/best calculation
  const uxScoreKeys = [
    'ux_exciting', 'ux_interesting', 'ux_easy', 'ux_clear',
    'ux_efficient', 'ux_organized', 'ux_predictable', 'ux_supportive',
    'ux_enjoyable', 'ux_friendly'
  ];
  
  // Find worst aspect (lowest score)
  for (const key of uxScoreKeys) {
    if (key in scores) {
      const value = scores[key];
      if (value < worstValue) {
        worstValue = value;
        worstAspect = key.replace('ux_', '');
      }
      
      if (value > bestValue) {
        bestValue = value;
        bestAspect = key.replace('ux_', '');
      }
    }
  }
  
  // Calculate UX KPI (mean of all UX scores)
  let uxSum = 0;
  let uxCount = 0;
  for (const key of uxScoreKeys) {
    if (key in scores) {
      uxSum += scores[key];
      uxCount++;
    }
  }
  
  const uxKpi = uxCount > 0 ? uxSum / uxCount : 0;
  
  // Calculate manipulation score from manipulation-specific items
  const manipScoreKeys = [
    'manip_non_addictive', 'manip_suggesting', 'manip_revealed', 'manip_benevolent'
  ];
  
  let manipSum = 0;
  let manipCount = 0;
  for (const key of manipScoreKeys) {
    if (key in scores) {
      manipSum += scores[key];
      manipCount++;
    }
  }
  
  const manipulationScore = manipCount > 0 ? manipSum / manipCount : 0;
  
  // Calculate ethical risk based on manipulation score
  // Lower values indicate more manipulation
  let ethicalRisk: 'Low' | 'Medium' | 'High' = 'Low';
  
  if (manipulationScore < -1) {
    ethicalRisk = 'High';
  } else if (manipulationScore < 1) {
    ethicalRisk = 'Medium';
  } else {
    ethicalRisk = 'Low';
  }
  
  return {
    uxKpi,
    worstAspect,
    worstValue,
    bestAspect,
    bestValue,
    ethicalRisk,
    manipulationScore
  };
}

/**
 * Create a simplified gauge visualization with -3 to +3 scale
 */
function createGauge(
  score: number,         // Worst aspect score (-3 to +3)
  pattern: string,       // Pattern/title
  worstAspect: string,   // Worst aspect name
  ethicalRisk: string,   // Ethical risk level
  uxKpiValue: number,    // Overall UX KPI score
  bestAspect: string,    // Best aspect name
  bestValue: number,     // Best aspect score
  manipScore: number     // Manipulation score
): FrameNode {
  // Create a frame for the gauge
  const gauge = figma.createFrame();
  gauge.name = "UI Evaluation Gauge";
  gauge.resize(350, 180);
  gauge.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
  
  // Add title with UX KPI value
  const titleText = figma.createText();
  
  // Pick UX KPI color based on value
  let kpiColor;
  if (uxKpiValue < -1) {
    kpiColor = { r: 0.9, g: 0.3, b: 0.3 };  // Red
  } else if (uxKpiValue < 1) {
    kpiColor = { r: 0.8, g: 0.6, b: 0.2 };  // Orange
  } else {
    kpiColor = { r: 0.3, g: 0.7, b: 0.3 };  // Green
  }
  
  titleText.characters = `${pattern} (UX KPI: ${uxKpiValue.toFixed(1)})`;
  titleText.fontSize = 16;
  titleText.x = 35;
  titleText.y = 15;
  titleText.fills = [{ type: 'SOLID', color: kpiColor }];
  gauge.appendChild(titleText);
  
  // Create background for the gauge
  const gaugeBackground = figma.createRectangle();
  gaugeBackground.name = "Gauge Background";
  gaugeBackground.resize(280, 50);
  gaugeBackground.x = 35;
  gaugeBackground.y = 50;
  gaugeBackground.fills = [{ type: 'SOLID', color: { r: 0.95, g: 0.95, b: 0.95 } }];
  gaugeBackground.cornerRadius = 25;
  gauge.appendChild(gaugeBackground);
  
  // Create colored sections for the gauge with -3 to +3 scale
  // Red section dark (-3 to -2)
  const redDarkSection = figma.createRectangle();
  redDarkSection.name = "Red Dark Section";
  redDarkSection.resize(47, 50);
  redDarkSection.x = 35;
  redDarkSection.y = 50;
  redDarkSection.fills = [{ type: 'SOLID', color: { r: 0.95, g: 0.3, b: 0.3 } }];
  redDarkSection.topLeftRadius = 25;
  redDarkSection.bottomLeftRadius = 25;
  redDarkSection.topRightRadius = 0;
  redDarkSection.bottomRightRadius = 0;
  gauge.appendChild(redDarkSection);
  
  // Red section light (-2 to -1)
  const redLightSection = figma.createRectangle();
  redLightSection.name = "Red Light Section";
  redLightSection.resize(46, 50);
  redLightSection.x = 82;
  redLightSection.y = 50;
  redLightSection.fills = [{ type: 'SOLID', color: { r: 0.99, g: 0.6, b: 0.6 } }];
  gauge.appendChild(redLightSection);
  
  // Yellow section (-1 to +1)
  const yellowSection = figma.createRectangle();
  yellowSection.name = "Yellow Section";
  yellowSection.resize(93, 50);
  yellowSection.x = 128;
  yellowSection.y = 50;
  yellowSection.fills = [{ type: 'SOLID', color: { r: 1, g: 0.97, b: 0.8 } }];
  gauge.appendChild(yellowSection);
  
  // Green section light (+1 to +2)
  const greenLightSection = figma.createRectangle();
  greenLightSection.name = "Green Light Section";
  greenLightSection.resize(46, 50);
  greenLightSection.x = 221;
  greenLightSection.y = 50;
  greenLightSection.fills = [{ type: 'SOLID', color: { r: 0.6, g: 0.9, b: 0.6 } }];
  gauge.appendChild(greenLightSection);
  
  // Green section dark (+2 to +3)
  const greenDarkSection = figma.createRectangle();
  greenDarkSection.name = "Green Dark Section";
  greenDarkSection.resize(47, 50);
  greenDarkSection.x = 267;
  greenDarkSection.y = 50;
  greenDarkSection.fills = [{ type: 'SOLID', color: { r: 0.2, g: 0.8, b: 0.3 } }];
  greenDarkSection.topLeftRadius = 0;
  greenDarkSection.bottomLeftRadius = 0;
  greenDarkSection.topRightRadius = 25;
  greenDarkSection.bottomRightRadius = 25;
  gauge.appendChild(greenDarkSection);
  
  // Create the gauge indicator (colored bar)
  const gaugeIndicator = figma.createRectangle();
  gaugeIndicator.name = "Gauge Indicator";
  
  // Calculate width based on score (-3 to +3 scale to 0-280px)
  const normalizedScore = score + 3; // Convert -3...+3 to 0...6
  const width = Math.max(10, Math.min(280, (normalizedScore / 6) * 280));
  gaugeIndicator.resize(width, 50);
  gaugeIndicator.x = 35;
  gaugeIndicator.y = 50;
  
  // Set color based on score
  let color;
  if (score < -1) {
    color = { r: 0.9, g: 0.3, b: 0.3 };  // Red for low scores (bad)
  } else if (score < 1) {
    color = { r: 1, g: 0.7, b: 0.2 };    // Orange for medium scores
  } else {
    color = { r: 0.2, g: 0.8, b: 0.3 };  // Green for high scores (good)
  }
  
  gaugeIndicator.fills = [{ type: 'SOLID', color, opacity: 0.75 }];
  // Set individual corner radius properties
  gaugeIndicator.topLeftRadius = 25;
  gaugeIndicator.bottomLeftRadius = 25;
  gaugeIndicator.topRightRadius = width >= 280 ? 25 : 0;
  gaugeIndicator.bottomRightRadius = width >= 280 ? 25 : 0;
  gauge.appendChild(gaugeIndicator);
  
  // Add UX KPI marker (threshold) at uxKpi position
  if (uxKpiValue >= -3 && uxKpiValue <= 3) {
    const threshold = figma.createRectangle();
    threshold.name = "UX KPI Threshold";
    const normalizedUxKpi = uxKpiValue + 3; // Convert -3...+3 to 0...6
    const thresholdX = 35 + (normalizedUxKpi / 6) * 280;
    threshold.resize(4, 60);
    threshold.x = thresholdX - 2;
    threshold.y = 45;
    threshold.fills = [{ type: 'SOLID', color: { r: 0.2, g: 0.2, b: 0.2 } }];
    threshold.cornerRadius = 2;
    gauge.appendChild(threshold);
  }
  
  // Add markers with dashes for worst and best aspects directly on the gauge
  // 1. Add worst aspect marker
  const worstX = 35 + ((score + 3) / 6) * 280; // Positioning based on score
  
  // Add worst marker line
  const worstMarker = figma.createRectangle();
  worstMarker.name = "Worst Marker";
  worstMarker.resize(1, 15);
  worstMarker.x = worstX;
  worstMarker.y = 102; // Bottom aligned
  worstMarker.fills = [{ type: 'SOLID', color: { r: 0.9, g: 0.3, b: 0.3 } }];
  gauge.appendChild(worstMarker);
  
  // Find labels for best and worst aspects
  const getAttributeLabel = (aspect: string, value: number): string => {
    // Find the proper term to display based on the aspect name and value
    // Map from normalized aspect names to left/right terms
    const aspectMapping: Record<string, {positive: string, negative: string}> = {
      'exciting': {positive: 'exciting', negative: 'boring'},
      'interesting': {positive: 'interesting', negative: 'not interesting'},
      'easy': {positive: 'easy', negative: 'complicated'},
      'clear': {positive: 'clear', negative: 'confusing'},
      'efficient': {positive: 'efficient', negative: 'inefficient'},
      'organized': {positive: 'organized', negative: 'cluttered'},
      'predictable': {positive: 'predictable', negative: 'unpredictable'},
      'supportive': {positive: 'supportive', negative: 'obstructive'},
      'enjoyable': {positive: 'enjoyable', negative: 'annoying'},
      'friendly': {positive: 'friendly', negative: 'unfriendly'}
    };
    
    // Default to just using the aspect name if not found in mapping
    if (!(aspect in aspectMapping)) {
      return `${aspect} (${value.toFixed(1)})`;
    }
    
    // Use positive term for positive values, negative term for negative values
    const mapping = aspectMapping[aspect];
    if (value >= 0) {
      return `${mapping.positive} (${value.toFixed(1)})`;
    } else {
      return `${mapping.negative} (${value.toFixed(1)})`;
    }
  };
  
  // Add worst aspect label
  const worstLabel = figma.createText();
  const worstAspectLabel = getAttributeLabel(worstAspect, score);
  worstLabel.characters = worstAspectLabel;
  worstLabel.fontSize = 10;
  // Position horizontally based on where it is on the scale
  if (score < 0) {
    // Left-aligned if in the left half
    worstLabel.x = worstX;
    worstLabel.textAlignHorizontal = "LEFT";
  } else {
    // Right-aligned if in the right half
    worstLabel.x = worstX;
    worstLabel.textAlignHorizontal = "RIGHT";
  }
  worstLabel.y = 120;
  worstLabel.fills = [{ type: 'SOLID', color: { r: 0.9, g: 0.3, b: 0.3 } }];
  gauge.appendChild(worstLabel);
  
  // 2. Add best aspect marker
  const bestX = 35 + ((bestValue + 3) / 6) * 280; // Positioning based on best score
  
  // Add best marker line
  const bestMarker = figma.createRectangle();
  bestMarker.name = "Best Marker";
  bestMarker.resize(1, 15);
  bestMarker.x = bestX;
  bestMarker.y = 35; // Top aligned
  bestMarker.fills = [{ type: 'SOLID', color: { r: 0.2, g: 0.8, b: 0.3 } }];
  gauge.appendChild(bestMarker);
  
  // Add best aspect label
  const bestLabel = figma.createText();
  const bestAspectLabel = getAttributeLabel(bestAspect, bestValue);
  bestLabel.characters = bestAspectLabel;
  bestLabel.fontSize = 10;
  // Position horizontally based on where it is on the scale
  if (bestValue < 0) {
    // Left-aligned if in the left half
    bestLabel.x = bestX;
    bestLabel.textAlignHorizontal = "LEFT";
  } else {
    // Right-aligned if in the right half
    bestLabel.x = bestX;
    bestLabel.textAlignHorizontal = "RIGHT";
  }
  bestLabel.y = 25;
  bestLabel.fills = [{ type: 'SOLID', color: { r: 0.2, g: 0.8, b: 0.3 } }];
  gauge.appendChild(bestLabel);
  
  // Add minimal scale labels (-3, 0, +3)
  const scalePoints = [-3, 0, 3];
  for (const i of scalePoints) {
    const normalizedPosition = i + 3; // Convert -3...+3 to 0...6
    const xPos = 35 + (normalizedPosition / 6) * 280;
    
    // Add tick
    const tick = figma.createRectangle();
    tick.name = `Tick-${i}`;
    tick.resize(2, 6);
    tick.x = xPos - 1;
    tick.y = 102;
    tick.fills = [{ type: 'SOLID', color: { r: 0.5, g: 0.5, b: 0.5 } }];
    gauge.appendChild(tick);
    
    // Add label
    const label = figma.createText();
    label.characters = i === 0 ? "0" : i.toString();
    label.fontSize = 10;
    label.x = xPos;
    label.y = 110;
    label.textAlignHorizontal = "CENTER";
    label.fills = [{ type: 'SOLID', color: { r: 0.5, g: 0.5, b: 0.5 } }];
    gauge.appendChild(label);
  }
  
  // Add ethical risk indicator
  const ethicalRiskLabel = figma.createText();
  const riskText = `Ethical risk: ${ethicalRisk} | Manipulation: ${manipScore.toFixed(1)}`;
  ethicalRiskLabel.characters = riskText;
  ethicalRiskLabel.fontSize = 12;
  ethicalRiskLabel.x = 35;
  ethicalRiskLabel.y = 150;
  
  // Set color based on risk level
  if (ethicalRisk === 'High') {
    ethicalRiskLabel.fills = [{ type: 'SOLID', color: { r: 0.9, g: 0.3, b: 0.3 } }];
  } else if (ethicalRisk === 'Medium') {
    ethicalRiskLabel.fills = [{ type: 'SOLID', color: { r: 0.95, g: 0.6, b: 0.1 } }];
  } else {
    ethicalRiskLabel.fills = [{ type: 'SOLID', color: { r: 0.2, g: 0.8, b: 0.3 } }];
  }
  
  gauge.appendChild(ethicalRiskLabel);
  
  return gauge;
}

/**
 * Create a comment with evaluation explanation
 */
function createEvaluationComment(result: AssessmentResult, uxKpi: {
  uxKpi: number;
  worstAspect: string;
  worstValue: number;
  bestAspect: string;
  bestValue: number;
  ethicalRisk: 'Low' | 'Medium' | 'High';
  manipulationScore: number;
}): FrameNode {
  // Create a frame for the explanation
  const frame = figma.createFrame();
  frame.name = "UI Evaluation Explanation";
  frame.resize(350, 380);
  frame.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
  
  // Add title
  const title = figma.createText();
  title.characters = "AI Evaluation Details";
  title.fontSize = 16;
  title.x = 20;
  title.y = 20;
  title.fills = [{ type: 'SOLID', color: { r: 0.1, g: 0.1, b: 0.1 } }];
  frame.appendChild(title);
  
  // Add explanation text with auto-height
  const explanation = figma.createText();
  explanation.characters = result.explanation;
  explanation.fontSize = 12;
  explanation.x = 20;
  explanation.y = 50;
  explanation.fills = [{ type: 'SOLID', color: { r: 0.3, g: 0.3, b: 0.3 } }];
  explanation.resize(310, 170); // Fixed height to avoid overlap
  frame.appendChild(explanation);
  
  // Create separate colored texts for summary elements
  
  // Worst aspect (red)
  const worstText = figma.createText();
  worstText.characters = `Worst Aspect: ${uxKpi.worstAspect} (${uxKpi.worstValue.toFixed(1)})`;
  worstText.fontSize = 12;
  worstText.x = 20;
  worstText.y = 230;
  worstText.fills = [{ type: 'SOLID', color: { r: 0.9, g: 0.3, b: 0.3 } }];
  frame.appendChild(worstText);
  
  // Best aspect (green)
  const bestText = figma.createText();
  bestText.characters = `Best Aspect: ${uxKpi.bestAspect} (${uxKpi.bestValue.toFixed(1)})`;
  bestText.fontSize = 12;
  bestText.x = 20;
  bestText.y = 250;
  bestText.fills = [{ type: 'SOLID', color: { r: 0.2, g: 0.8, b: 0.3 } }];
  frame.appendChild(bestText);
  
  // UX KPI and manipulation score
  const scoreText = figma.createText();
  scoreText.characters = `UX KPI: ${uxKpi.uxKpi.toFixed(1)}  |  Manipulation: ${uxKpi.manipulationScore.toFixed(1)}`;
  scoreText.fontSize = 12;
  scoreText.x = 20;
  scoreText.y = 270;
  
  // Color based on UX KPI value
  let kpiColor;
  if (uxKpi.uxKpi < -1) {
    kpiColor = { r: 0.9, g: 0.3, b: 0.3 };  // Red
  } else if (uxKpi.uxKpi < 1) {
    kpiColor = { r: 0.8, g: 0.6, b: 0.2 };  // Orange
  } else {
    kpiColor = { r: 0.3, g: 0.7, b: 0.3 };  // Green
  }
  scoreText.fills = [{ type: 'SOLID', color: kpiColor }];
  frame.appendChild(scoreText);
  
  // Ethical risk
  const riskText = figma.createText();
  riskText.characters = `Ethical Risk: ${uxKpi.ethicalRisk}`;
  riskText.fontSize = 12;
  riskText.x = 20;
  riskText.y = 290;
  
  // Set color based on risk level
  if (uxKpi.ethicalRisk === 'High') {
    riskText.fills = [{ type: 'SOLID', color: { r: 0.9, g: 0.3, b: 0.3 } }];
  } else if (uxKpi.ethicalRisk === 'Medium') {
    riskText.fills = [{ type: 'SOLID', color: { r: 0.95, g: 0.6, b: 0.1 } }];
  } else {
    riskText.fills = [{ type: 'SOLID', color: { r: 0.2, g: 0.8, b: 0.3 } }];
  }
  frame.appendChild(riskText);
  
  // Scale information
  const scaleText = figma.createText();
  scaleText.characters = `Scale: -3 (negative) to +3 (positive)`;
  scaleText.fontSize = 12;
  scaleText.x = 20;
  scaleText.y = 310;
  scaleText.fills = [{ type: 'SOLID', color: { r: 0.5, g: 0.5, b: 0.5 } }];
  frame.appendChild(scaleText);
  
  // Add disclaimer
  const disclaimer = figma.createText();
  disclaimer.characters = "This evaluation was generated by AI and should be considered a starting point for further UX analysis.";
  disclaimer.fontSize = 10;
  disclaimer.x = 20;
  disclaimer.y = 340;
  disclaimer.fills = [{ type: 'SOLID', color: { r: 0.6, g: 0.6, b: 0.6 } }];
  disclaimer.resize(310, 40);
  frame.appendChild(disclaimer);
  
  return frame;
}

/**
 * Load required fonts
 */
async function loadRequiredFonts() {
  try {
    console.log("Loading required fonts...");
    await figma.loadFontAsync({ family: "Inter", style: "Regular" });
    await figma.loadFontAsync({ family: "Inter", style: "Medium" });
    await figma.loadFontAsync({ family: "Inter", style: "Bold" });
    console.log("Fonts loaded successfully");
  } catch (error) {
    console.error("Error loading fonts:", error);
    // Try system fonts as fallback
    try {
      await figma.loadFontAsync({ family: "Arial", style: "Regular" });
      await figma.loadFontAsync({ family: "Arial", style: "Bold" });
    } catch (fallbackError) {
      console.error("Error loading fallback fonts:", fallbackError);
      throw new Error("Failed to load required fonts");
    }
  }
}

/**
 * Main evaluation function
 */
async function evaluateUI(service: string, apiKey: string) {
  try {
    console.log("Starting UI evaluation for service:", service);
    
    // Load required fonts first
    await loadRequiredFonts();
    
    // Check if a frame is selected
    const selection = figma.currentPage.selection;
    
    if (selection.length !== 1 || !(selection[0].type === 'FRAME' || selection[0].type === 'COMPONENT' || selection[0].type === 'INSTANCE')) {
      throw new Error("Please select exactly one frame, component, or instance to evaluate");
    }
    
    const selectedNode = selection[0] as FrameNode | ComponentNode | InstanceNode;
    console.log("Selected node:", selectedNode.name, selectedNode.type);
    
    // Get description of the UI frame
    const description = await getFrameDescription(selectedNode);
    console.log("Generated description:", description.substring(0, 100) + "...");
    
    // Format prompt
    const prompt = formatUeqPrompt(description, config.ueeq_scales);
    console.log("Formatted prompt (first 100 chars):", prompt.substring(0, 100) + "...");
    
    // Get image bytes
    console.log("Exporting image...");
    const bytes = await selectedNode.exportAsync({
      format: 'PNG',
      constraint: { type: 'SCALE', value: 2 }
    });
    console.log("Image exported, size:", bytes.length, "bytes");
    
    // Call AI service via the UI (to avoid CORS issues)
    console.log("Calling AI service:", service);
    figma.ui.postMessage({ type: 'status-update', message: 'Sending request to AI service...' });
    const responseText = await callAIService(service, prompt, bytes, apiKey);
    console.log("AI service response received, length:", responseText.length);
    
    // Extract JSON result
    console.log("Extracting JSON from response...");
    figma.ui.postMessage({ type: 'status-update', message: 'Processing AI response...' });
    const result = extractJsonFromResponse(responseText);
    console.log("JSON extracted, assessment keys:", Object.keys(result.assessment).join(", "));
    
    // Calculate UX KPI
    console.log("Calculating UX KPI...");
    const uxKpi = calculateUxKpi(result);
    console.log("UX KPI calculated:", uxKpi);
    
    // Create gauge visualization
    console.log("Creating gauge visualization...");
    figma.ui.postMessage({ type: 'status-update', message: 'Creating visualization...' });
    const gauge = createGauge(
      uxKpi.worstValue,
      "UI Evaluation", 
      uxKpi.worstAspect, 
      uxKpi.ethicalRisk,
      uxKpi.uxKpi,
      uxKpi.bestAspect,
      uxKpi.bestValue,
      uxKpi.manipulationScore
    );
    
    // Create evaluation comment
    console.log("Creating evaluation comment...");
    const comment = createEvaluationComment(result, uxKpi);
    
    // Position the gauge and comment next to the selected node
    gauge.x = selectedNode.x + selectedNode.width + 20;
    gauge.y = selectedNode.y;
    
    comment.x = selectedNode.x + selectedNode.width + 20;
    comment.y = selectedNode.y + gauge.height + 20;
    
    // Add to document
    console.log("Adding elements to document...");
    figma.currentPage.appendChild(gauge);
    figma.currentPage.appendChild(comment);
    
    // Select the new elements
    figma.currentPage.selection = [gauge, comment];
    figma.viewport.scrollAndZoomIntoView([selectedNode, gauge, comment]);
    
    // Notify UI
    console.log("Evaluation complete!");
    figma.ui.postMessage({ type: 'evaluation-complete' });
  } catch (error) {
    console.error('Evaluation error:', error);
    // Get detailed error info
    let errorMessage = "Unknown error";
    if (error instanceof Error) {
      errorMessage = error.message;
      console.error("Error stack:", error.stack);
    } else {
      errorMessage = String(error);
    }
    console.error("Error details:", errorMessage);
    
    figma.ui.postMessage({ 
      type: 'evaluation-error', 
      error: errorMessage 
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
  try {
    if (msg.type === 'evaluate-ui') {
      await evaluateUI(msg.service!, msg.apiKey!);
    } else if (msg.type === 'cancel') {
      figma.closePlugin();
    } else if (msg.type === 'check-selection') {
      figma.ui.postMessage({ 
        type: 'selection-status', 
        hasValidSelection: checkValidSelection() 
      });
    } else if (msg.type === 'api-response') {
      // This is handled by the promise in callAIService
      console.log("Received API response");
    } else {
      console.log("Unknown message type:", msg.type);
    }
  } catch (error) {
    console.error("Error handling message:", error);
    let errorMessage = "Unknown error";
    if (error instanceof Error) {
      errorMessage = error.message;
    } else if (typeof error === 'string') {
      errorMessage = error;
    } else if (error && typeof error === 'object') {
      errorMessage = String(error);
    }
    figma.ui.postMessage({ 
      type: 'evaluation-error', 
      error: errorMessage
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
