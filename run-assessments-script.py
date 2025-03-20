#!/usr/bin/env python3
"""
Script to run multiple UI assessments with different AI services and models.
"""

import os
import json
import argparse
import subprocess
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("run_assessments.log"),
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

def run_assessments(interfaces_path, config_path, output_dir):
    """Run assessments with all configured AI services and models."""
    # Load configuration
    config = load_config(config_path)
    
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Get timestamp for unique run ID
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Loop through all AI services and models
    for service_name, service_config in config["ai_services"].items():
        for model_name in service_config["models"]:
            # Generate output file path
            output_file = os.path.join(
                output_dir, 
                f"results_{service_name}_{model_name.replace('-', '_').replace('.', '_')}_{timestamp}.csv"
            )
            
            # Construct command
            cmd = [
                "python", "ui_assessment.py",
                "--interfaces", interfaces_path,
                "--ai_service", service_name,
                "--model", model_name,
                "--output", output_file,
                "--config", config_path
            ]
            
            # Log the command
            logger.info(f"Running: {' '.join(cmd)}")
            
            try:
                # Run the assessment
                result = subprocess.run(cmd, check=True)
                logger.info(f"Assessment completed: {output_file}")
            except subprocess.CalledProcessError as e:
                logger.error(f"Assessment failed: {e}")
                continue
    
    logger.info("All assessments completed")

def main():
    """Main function to parse arguments and run assessments."""
    parser = argparse.ArgumentParser(description="Run Multiple UI Assessments")
    parser.add_argument("--interfaces", required=True, help="Path to interfaces JSON file")
    parser.add_argument("--config", default="config.json", help="Path to configuration file")
    parser.add_argument("--output_dir", default="results", help="Directory to save assessment results")
    
    args = parser.parse_args()
    
    try:
        run_assessments(args.interfaces, args.config, args.output_dir)
    except Exception as e:
        logger.error(f"Error running assessments: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
