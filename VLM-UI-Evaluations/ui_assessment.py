import os
import json
import pandas as pd
import requests
from datetime import datetime
import base64
import argparse
from tqdm import tqdm
import time
import logging
from dotenv import load_dotenv
import anthropic
from openai import OpenAI

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("ui_assessment.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class UIAssessmentSystem:
    def __init__(self, config_path='config.json', temperature=0.0):
        """Initialize the UI Assessment System with configuration."""
        self.load_config(config_path)
        self.temperature = temperature
        self.results = []
        
    def load_config(self, config_path):
        """Load configuration from JSON file."""
        try:
            with open(config_path, 'r') as f:
                self.config = json.load(f)
                logger.info(f"Configuration loaded from {config_path}")
        except FileNotFoundError:
            logger.error(f"Configuration file not found: {config_path}")
            raise
            
    def encode_image(self, image_path):
        """Encode image to base64 for API requests without leaking path information."""
        try:
            with open(image_path, "rb") as image_file:
                # Read the image without including the original path in any metadata
                return base64.b64encode(image_file.read()).decode('utf-8')
        except FileNotFoundError:
            logger.error(f"Image file not found: {image_path}")
            raise
            
    def get_media_type(self, image_path):
        """Determine media type based on file extension."""
        if image_path.lower().endswith('.png'):
            return "image/png"
        elif image_path.lower().endswith(('.jpg', '.jpeg')):
            return "image/jpeg"
        else:
            # Default to jpeg if unknown
            return "image/jpeg"
            
    def format_ueq_prompt(self, ui_description, image_path=None):
        """Format the prompt for UEQ assessment using scales from config."""
        # Get UEQ scales from config
        ueeq_scales = self.config.get("assessment", {}).get("ueeq_scales", [])
        
        # Build scales text for prompt
        scales_text = ""
        example_assessment = "{"
        
        for scale in ueeq_scales:
            name = scale.get("name")
            left = scale.get("left")
            right = scale.get("right")
            scales_text += f"- {left} (1) to {right} (7)\n"
            example_assessment += f'\n                "{name}": 5,'
        
        # Remove trailing comma and add closing brace
        example_assessment = example_assessment.rstrip(',') + "\n            }"
        
        prompt = f"""
        ## UI Element Evaluation
        
        Instruction: In this section, user interface elements are presented to you. Subsequently, pairs of contrasting adjectives are listed. The numbers 1-7 between the adjectives represent gradations between the opposites. Please express your agreement with the adjectives by selecting one number per line that best aligns with your impression. If you find the feature unclear or believe that the adjectives do not describe the feature accurately, select -1 for "don't know / not applicable".

        UI Description: {ui_description}
        
        I perceive this interface feature as...

        {scales_text}
        
        Rate 1-7 where 1 is the left term and 7 is the right term, or -1 for not applicable.
        
        Please format your response as a JSON object with the following structure:
        {{
            "assessment": {example_assessment},
            "explanation": "Short explanation of your assessment..."
        }}
        
        Please ensure your response contains only this JSON object and no other text.
        """
        return prompt

    def write_ueq_prompt_to_file(self, ui_description, output_file, image_path=None):
        """
        Write the formatted UEQ prompt to a file.
        
        Args:
            ui_description (str): Description of the UI to be evaluated
            output_file (str): Path to the output file where the prompt will be written
            image_path (str, optional): Path to an image file if available
        """
        try:
            # Get the formatted prompt
            prompt = self.format_ueq_prompt(ui_description, image_path)
            
            # Write the prompt to the file
            with open(output_file, 'w') as f:
                f.write(prompt)
                
            logger.info(f"UEQ prompt written to {output_file}")
            return True
            
        except Exception as e:
            logger.error(f"Error writing UEQ prompt to file: {str(e)}")
            return False

    def call_anthropic_claude(self, prompt, image_path=None, model_name=None):
        """Call Anthropic's Claude API with prompt and optional image."""
        api_key = os.getenv("ANTHROPIC_API_KEY")
        if not api_key:
            logger.error("ANTHROPIC_API_KEY not found in environment variables")
            raise ValueError("ANTHROPIC_API_KEY not found")
            
        # Get service config
        service_config = self.config.get("ai_services", {}).get("anthropic", {})
        
        # Initialize Anthropic client
        client = anthropic.Anthropic(api_key=api_key)
        
        content = [{"type": "text", "text": prompt}]
        
        # Add image if provided
        if image_path:
            base64_image = self.encode_image(image_path)
            media_type = self.get_media_type(image_path)
                
            content.append({
                "type": "image",
                "source": {
                    "type": "base64",
                    "media_type": media_type,
                    "data": base64_image
                }
            })
            
        try:
            response = client.messages.create(
                model=model_name or service_config.get("models", [])[0],
                max_tokens=1000,
                temperature=self.temperature,
                messages=[{"role": "user", "content": content}]
            )
            return response.content[0].text
        except Exception as e:
            logger.error(f"API request failed: {str(e)}")
            return None
                
    # Modifications for ui_assessment.py to fix rate limit issues

    def call_openai_gpt4v(self, prompt, image_path=None, model_name=None):
        """Call OpenAI's GPT-4 Vision API with prompt and optional image."""
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            logger.error("OPENAI_API_KEY not found in environment variables")
            raise ValueError("OPENAI_API_KEY not found")
            
        # Get service config
        service_config = self.config.get("ai_services", {}).get("openai", {})
        
        # Use OpenAI client instead of direct requests
        client = OpenAI(api_key=api_key)
        
        # Format messages for OpenAI
        content = [{"type": "text", "text": prompt}]
        
        # Add image if provided
        if image_path:
            base64_image = self.encode_image(image_path)
            media_type = self.get_media_type(image_path)
                
            content.append({
                "type": "image_url",
                "image_url": {
                    "url": f"data:{media_type};base64,{base64_image}"
                }
            })
        
        # Calculate expected response length - estimate based on UEQ scale count
        expected_tokens = 250  # Base estimate for JSON structure
        scale_count = len(self.config.get("assessment", {}).get("ueeq_scales", []))
        expected_tokens += scale_count * 10  # Estimate per scale
        
        max_retries = 3
        retry_delay = 5
        
        for attempt in range(max_retries):
            try:
                # Use client.chat.completions.create instead of requests
                response = client.chat.completions.create(
                    model=model_name or service_config.get("models", [])[0],
                    messages=[{"role": "user", "content": content}],
                    max_tokens=expected_tokens,  # Use calculated value instead of fixed 1000
                    temperature=self.temperature
                )
                return response.choices[0].message.content
            except Exception as e:
                error_msg = str(e)
                logger.error(f"API request failed (attempt {attempt+1}/{max_retries}): {error_msg}")
                
                # Check for rate limit errors
                if "rate limit" in error_msg.lower():
                    wait_time = retry_delay * (2 ** attempt)  # Exponential backoff
                    logger.info(f"Rate limit exceeded. Waiting {wait_time} seconds before retry...")
                    time.sleep(wait_time)
                else:
                    # Non-rate limit error, don't retry
                    return None
        
        # If we got here, all retries failed
        logger.error("All retry attempts failed")
        return None
    
    def call_qwen(self, prompt, image_path=None, model_name=None):
        """Call Alibaba Cloud's Qwen API with prompt and optional image."""
        api_key = os.getenv("ALIBABA_API_KEY")
        if not api_key:
            logger.error("ALIBABA_API_KEY not found in environment variables")
            raise ValueError("ALIBABA_API_KEY not found")
            
        # Get service config
        service_config = self.config.get("ai_services", {}).get("qwen", {})
        
        client = OpenAI(
            api_key=api_key,
            base_url="https://dashscope-intl.aliyuncs.com/compatible-mode/v1"
        )
        
        # Format messages for OpenAI-compatible endpoint
        messages = [{"role": "user", "content": [{"type": "text", "text": prompt}]}]
        
        # Add image if provided
        if image_path:
            base64_image = self.encode_image(image_path)
            media_type = self.get_media_type(image_path)
            
            messages[0]["content"].append({
                "type": "image_url",
                "image_url": {
                    "url": f"data:{media_type};base64,{base64_image}"
                }
            })
            
        try:
            completion = client.chat.completions.create(
                model=model_name or service_config.get("models", [])[0],
                messages=messages,
                temperature=self.temperature,
                max_tokens=1000
            )
            return completion.choices[0].message.content
        except Exception as e:
            logger.error(f"API request failed: {str(e)}")
            return None
    
    
    def call_ollama(self, prompt, image_path=None, model_name=None):
        """Call locally hosted Ollama API with prompt and optional image."""
        # Get service config
        service_config = self.config.get("ai_services", {}).get("ollama", {})
        
        # Format content for Ollama
        content = {
            "model": model_name or service_config.get("models", [])[0],
            "prompt": prompt,
            "stream": False,
            "temperature": self.temperature
        }
        
        # Add image if provided
        if image_path:
            base64_image = self.encode_image(image_path)
            # Ollama uses a different format for images
            content["images"] = [base64_image]
            
        # Use endpoint from config if available
        endpoint = service_config.get("endpoint", "http://localhost:11434/api/generate")
        
        try:
            response = requests.post(
                endpoint,
                headers=service_config.get("headers", {}),
                json=content
            )
            response.raise_for_status()
            return response.json()["response"]
        except requests.exceptions.RequestException as e:
            logger.error(f"API request failed: {str(e)}")
            return None
    
    def select_ai_service(self, service_name):
        """Select the appropriate AI service function based on name."""
        service_map = {
            "anthropic": self.call_anthropic_claude,
            "openai": self.call_openai_gpt4v,
            "qwen": self.call_qwen,
            "ollama": self.call_ollama
        }
        
        return service_map.get(service_name.lower())
        
    def process_interface(self, interface_data, ai_service, model_name):
        """Process a single interface with the specified AI service."""
        description = interface_data.get("description", "")
        image_path = interface_data.get("image_path")
        pattern_type = interface_data.get("pattern_type", "")
        interface_id = interface_data.get("id", "")
        
        prompt = self.format_ueq_prompt(description)
        ai_service_fn = self.select_ai_service(ai_service)
        
        if not ai_service_fn:
            logger.error(f"Unknown AI service: {ai_service}")
            return None
            
        # Call the AI service
        try:
            # Only log using a generic ID instead of pattern type
            logger.info(f"Calling {ai_service} ({model_name}) for interface: {interface_id}")
            response = ai_service_fn(prompt, image_path, model_name)
            
            if not response:
                logger.error(f"No response from {ai_service} for interface: {interface_id}")
                return None
                
            # Extract JSON from response
            try:
                # Find JSON object in the response text
                json_start = response.find('{')
                json_end = response.rfind('}') + 1
                if json_start >= 0 and json_end > json_start:
                    json_str = response[json_start:json_end]
                    result = json.loads(json_str)
                else:
                    logger.error(f"No JSON found in response for interface: {interface_id}")
                    return None
                    
                # Add metadata - store pattern type for analysis but don't expose to the model
                result["metadata"] = {
                    "timestamp": datetime.now().isoformat(),
                    "ai_service": ai_service,
                    "model": model_name,
                    "temperature": self.temperature,
                    "pattern_type": pattern_type,
                    "interface_id": interface_id
                }
                
                return result
            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse JSON response: {str(e)}")
                logger.debug(f"Response content: {response}")
                return None
                
        except Exception as e:
            logger.error(f"Error processing interface {pattern_type}: {str(e)}")
            return None
            
    def run_assessment(self, interfaces_path, ai_service, model_name):
        """Run assessment on all interfaces using specified AI service."""
        try:
            # Load interfaces
            with open(interfaces_path, 'r') as f:
                interfaces = json.load(f)
                
            logger.info(f"Starting assessment of {len(interfaces)} interfaces using {ai_service} {model_name}")
            
            # Process each interface
            for interface in tqdm(interfaces):
                result = self.process_interface(interface, ai_service, model_name)
                if result:
                    self.results.append(result)
                    
                # Add a small delay to avoid rate limiting
                time.sleep(1)
                
            logger.info(f"Assessment completed. Processed {len(self.results)} interfaces.")
            
            return self.results
        except Exception as e:
            logger.error(f"Error running assessment: {str(e)}")
            raise
            
    def save_results_to_csv(self, output_path):
        """Save assessment results to CSV file."""
        if not self.results:
            logger.warning("No results to save")
            return
            
        try:
            # Flatten the nested structure
            flattened_results = []
            for result in self.results:
                flat_result = {}
                
                # Add metadata
                for key, value in result.get("metadata", {}).items():
                    flat_result[f"metadata_{key}"] = value
                    
                # Add assessment scores
                for key, value in result.get("assessment", {}).items():
                    flat_result[f"score_{key}"] = value
                    
                # Add explanation
                flat_result["explanation"] = result.get("explanation", "")
                
                flattened_results.append(flat_result)
                
            # Convert to DataFrame and save
            df = pd.DataFrame(flattened_results)
            df.to_csv(output_path, index=False)
            
            logger.info(f"Results saved to {output_path}")
        except Exception as e:
            logger.error(f"Error saving results: {str(e)}")
            raise

def main():
    """Main function to run the UI assessment system."""
    parser = argparse.ArgumentParser(description="UI Assessment System")
    parser.add_argument("--config", default="config.json", help="Path to configuration file")
    parser.add_argument("--interfaces", required=True, help="Path to interfaces JSON file")
    parser.add_argument("--ai_service", default="anthropic", 
                        choices=["anthropic", "openai", "qwen", "ollama"], 
                        help="AI service to use")
    parser.add_argument("--model", required=True, help="Model name/version")
    parser.add_argument("--output", default="results.csv", help="Output CSV file path")
    parser.add_argument("--temperature", type=float, default=0.0, help="Temperature parameter for model (0.0-1.0)")
    parser.add_argument("--repeat", type=int, default=1, help="Number of times to repeat assessment (usually handled by run_multiple_assessments.py)")
    
    args = parser.parse_args()
    
    try:
        # Initialize system with temperature
        system = UIAssessmentSystem(args.config, args.temperature)
        
        # Run assessment
        system.run_assessment(args.interfaces, args.ai_service, args.model)
        
        # Save results
        system.save_results_to_csv(args.output)
        
    except Exception as e:
        logger.error(f"Error in main execution: {str(e)}")
        return 1
        
    return 0

if __name__ == "__main__":
    exit(main())
