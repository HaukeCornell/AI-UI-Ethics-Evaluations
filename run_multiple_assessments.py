#!/usr/bin/env python3
"""
Script to run multiple UI assessments across different models and with multiple simulations.
This script extends run_assessments.py to add temperature variation and repeated runs.
"""

import os
import json
import argparse
import subprocess
import logging
from datetime import datetime
import csv
import time

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("run_multiple_assessments.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def load_config(config_path):
    """Load configuration from JSON file."""
    try:
        with open(config_path, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        logger.error(f"Configuration file not found: {config_path}")
        raise

def initialize_usage_tracking(output_dir):
    """Initialize a CSV file to track API usage across runs."""
    usage_file = os.path.join(output_dir, "api_usage.csv")
    
    # Check if file exists, if not create with headers
    if not os.path.exists(usage_file):
        with open(usage_file, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow([
                "timestamp", 
                "ai_service", 
                "model", 
                "temperature", 
                "run_number", 
                "num_interfaces",
                "tokens_in",
                "tokens_out"
            ])
    
    return usage_file

def update_usage_tracking(usage_file, usage_data):
    """Append usage data to the tracking CSV."""
    with open(usage_file, 'a', newline='') as file:
        writer = csv.writer(file)
        writer.writerow([
            usage_data["timestamp"],
            usage_data["ai_service"],
            usage_data["model"],
            usage_data["temperature"],
            usage_data["run_number"],
            usage_data["num_interfaces"],
            usage_data.get("tokens_in", "N/A"),
            usage_data.get("tokens_out", "N/A")
        ])

def estimate_tokens(ai_service, model, num_interfaces):
    """Provide a rough estimate of token usage."""
    # These are very rough estimates and should be adjusted based on actual usage
    tokens_per_interface = {
        "anthropic": {"input": 800, "output": 600},
        "openai": {"input": 700, "output": 550},
        "qwen": {"input": 700, "output": 550},
        "ollama": {"input": 700, "output": 550}
    }
    
    # Use default values if the specific service isn't in our reference
    tokens_in = tokens_per_interface.get(ai_service, {"input": 750, "output": 550})["input"] * num_interfaces
    tokens_out = tokens_per_interface.get(ai_service, {"input": 750, "output": 550})["output"] * num_interfaces
    
    return {
        "tokens_in": tokens_in,
        "tokens_out": tokens_out
    }

def count_interfaces(interfaces_path):
    """Count the number of interfaces in the interfaces file."""
    try:
        with open(interfaces_path, 'r') as f:
            interfaces = json.load(f)
            return len(interfaces)
    except Exception as e:
        logger.error(f"Error counting interfaces: {e}")
        return 0

def run_multiple_assessments(interfaces_path, config_path, output_dir, temperatures, repeats, selected_services=None, selected_models=None):
    """Run assessments with multiple AI services, models, temperatures, and repeated runs."""
    # Load configuration
    config = load_config(config_path)
    
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Initialize usage tracking
    usage_file = initialize_usage_tracking(output_dir)
    
    # Get timestamp for unique run ID
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Count number of interfaces
    num_interfaces = count_interfaces(interfaces_path)
    
    # Loop through all AI services
    for service_name, service_config in config["ai_services"].items():
        # Skip if not in selected services
        if selected_services and service_name not in selected_services:
            continue
            
        # Loop through all models for this service
        for model_name in service_config["models"]:
            # Skip if not in selected models
            if selected_models and model_name not in selected_models:
                continue
                
            # Loop through all temperatures
            for temperature in temperatures:
                # Loop through all repeats
                for repeat_num in range(1, repeats + 1):
                    # Generate output file path
                    output_file = os.path.join(
                        output_dir, 
                        f"results_{service_name}_{model_name.replace('-', '_').replace('.', '_')}_temp{temperature}_run{repeat_num}_{timestamp}.csv"
                    )
                    
                    # Construct command
                    cmd = [
                        "python", "ui_assessment.py",
                        "--interfaces", interfaces_path,
                        "--ai_service", service_name,
                        "--model", model_name,
                        "--output", output_file,
                        "--config", config_path,
                        "--temperature", str(temperature),
                        "--repeat", "1"  # We handle repeats at this level
                    ]
                    
                    # Log the command
                    logger.info(f"Running: {' '.join(cmd)}")
                    
                    # Track usage
                    usage_data = {
                        "timestamp": datetime.now().isoformat(),
                        "ai_service": service_name,
                        "model": model_name,
                        "temperature": temperature,
                        "run_number": repeat_num,
                        "num_interfaces": num_interfaces
                    }
                    
                    # Add token estimates
                    usage_data.update(estimate_tokens(service_name, model_name, num_interfaces))
                    
                    try:
                        # Run the assessment
                        start_time = time.time()
                        result = subprocess.run(cmd, check=True)
                        end_time = time.time()
                        
                        elapsed_time = end_time - start_time
                        logger.info(f"Assessment completed in {elapsed_time:.2f} seconds: {output_file}")
                        
                        # Update usage tracking
                        update_usage_tracking(usage_file, usage_data)
                        
                    except subprocess.CalledProcessError as e:
                        logger.error(f"Assessment failed: {e}")
                        continue
                        
                    # Add a delay between runs to avoid rate limiting
                    time.sleep(2)
    
    logger.info("All assessments completed")
    logger.info(f"API usage tracking saved to {usage_file}")

def main():
    """Main function to parse arguments and run assessments."""
    parser = argparse.ArgumentParser(description="Run Multiple UI Assessments with Simulations")
    parser.add_argument("--interfaces", required=True, help="Path to interfaces JSON file")
    parser.add_argument("--config", default="config.json", help="Path to configuration file")
    parser.add_argument("--output_dir", default="results", help="Directory to save assessment results")
    parser.add_argument("--temperatures", type=float, nargs="+", default=[0.0], help="Temperature values to use")
    parser.add_argument("--repeats", type=int, default=1, help="Number of times to repeat each assessment")
    parser.add_argument("--services", nargs="+", help="Specific AI services to use (e.g., anthropic openai)")
    parser.add_argument("--models", nargs="+", help="Specific models to use (e.g., claude-3-opus-20240229 gpt-4o)")
    
    args = parser.parse_args()
    
    try:
        run_multiple_assessments(
            args.interfaces, 
            args.config, 
            args.output_dir, 
            args.temperatures, 
            args.repeats,
            args.services,
            args.models
        )
    except Exception as e:
        logger.error(f"Error running assessments: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())