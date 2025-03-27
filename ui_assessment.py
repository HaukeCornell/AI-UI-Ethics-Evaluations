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
    def __init__(self, config_path='config.json'):
        """Initialize the UI Assessment System with configuration."""
        self.load_config(config_path)
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
        """Encode image to base64 for API requests."""
        try:
            with open(image_path, "rb") as image_file:
                return base64.b64encode(image_file.read()).decode('utf-8')
        except FileNotFoundError:
            logger.error(f"Image file not found: {image_path}")
            raise
            
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
        Please analyze this user interface and provide an assessment.
        
        UI Description: {ui_description}
        
        Rate this interface on the following scales (1-7 where 1 is the left term and 7 is the right term):
        
        {scales_text}
        
        Please format your response as a JSON object with the following structure:
        {{
            "assessment": {example_assessment},
            "explanation": "Short explanation of your assessment..."
        }}
        
        Please ensure your response contains only this JSON object and no other text.
        """
        return prompt

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
            # Determine media type based on file extension
            if image_path.lower().endswith('.png'):
                media_type = "image/png"
            elif image_path.lower().endswith(('.jpg', '.jpeg')):
                media_type = "image/jpeg"
            else:
                # Default to jpeg if unknown
                media_type = "image/jpeg"
                
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
                messages=[{"role": "user", "content": content}]
            )
            return response.content[0].text
        except Exception as e:
            logger.error(f"API request failed: {str(e)}")
            return None
            
    def call_openai_gpt4v(self, prompt, image_path=None, model_name=None):
        """Call OpenAI's GPT-4 Vision API with prompt and optional image."""
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            logger.error("OPENAI_API_KEY not found in environment variables")
            raise ValueError("OPENAI_API_KEY not found")
            
        # Get service config
        service_config = self.config.get("ai_services", {}).get("openai", {})
        
        # Use custom headers from config if available
        headers = service_config.get("headers", {})
        headers["Authorization"] = f"Bearer {api_key}"
        
        messages = [{"role": "user", "content": [{"type": "text", "text": prompt}]}]
        
        # Add image if provided
        if image_path:
            base64_image = self.encode_image(image_path)
            # Determine media type based on file extension
            if image_path.lower().endswith('.png'):
                media_type = "image/png"
            elif image_path.lower().endswith(('.jpg', '.jpeg')):
                media_type = "image/jpeg"
            else:
                # Default to jpeg if unknown
                media_type = "image/jpeg"
                
            messages[0]["content"].append({
                "type": "image_url",
                "image_url": {
                    "url": f"data:{media_type};base64,{base64_image}"
                }
            })
            
        payload = {
            "model": model_name or service_config.get("models", [])[0],
            "messages": messages,
            "max_tokens": 1000
        }
        
        # Use endpoint from config if available
        endpoint = service_config.get("endpoint", "https://api.openai.com/v1/chat/completions")
        
        try:
            response = requests.post(
                endpoint,
                headers=headers,
                json=payload
            )
            response.raise_for_status()
            return response.json()["choices"][0]["message"]["content"]
        except requests.exceptions.RequestException as e:
            logger.error(f"API request failed: {str(e)}")
            return None
    
    def select_ai_service(self, service_name):
        """Select the appropriate AI service function based on name."""
        service_map = {
            "anthropic": self.call_anthropic_claude,
            "openai": self.call_openai_gpt4v,
            # Add more services as needed
        }
        
        return service_map.get(service_name.lower())
        
    def process_interface(self, interface_data, ai_service, model_name):
        """Process a single interface with the specified AI service."""
        description = interface_data.get("description", "")
        image_path = interface_data.get("image_path")
        pattern_type = interface_data.get("pattern_type", "")
        
        prompt = self.format_ueq_prompt(description)
        ai_service_fn = self.select_ai_service(ai_service)
        
        if not ai_service_fn:
            logger.error(f"Unknown AI service: {ai_service}")
            return None
            
        # Call the AI service
        try:
            logger.info(f"Calling {ai_service} ({model_name}) for interface: {pattern_type}")
            response = ai_service_fn(prompt, image_path, model_name)
            
            if not response:
                logger.error(f"No response from {ai_service} for interface: {pattern_type}")
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
                    logger.error(f"No JSON found in response for interface: {pattern_type}")
                    return None
                    
                # Add metadata
                result["metadata"] = {
                    "timestamp": datetime.now().isoformat(),
                    "ai_service": ai_service,
                    "model": model_name,
                    "pattern_type": pattern_type,
                    "interface_id": interface_data.get("id", "")
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
    parser.add_argument("--ai_service", default="anthropic", choices=["anthropic", "openai"], help="AI service to use")
    parser.add_argument("--model", required=True, help="Model name/version")
    parser.add_argument("--output", default="results.csv", help="Output CSV file path")
    
    args = parser.parse_args()
    
    try:
        # Initialize system
        system = UIAssessmentSystem(args.config)
        
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
