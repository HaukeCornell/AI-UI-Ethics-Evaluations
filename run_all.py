#!/usr/bin/env python3
"""
Master script to run the entire UI assessment pipeline:
1. Run assessments with multiple models
2. Analyze the results
3. Generate comprehensive reports
"""

import os
import argparse
import subprocess
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f"ui_assessment_run_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def run_command(cmd, desc):
    """Run a command with logging."""
    logger.info(f"Starting: {desc}")
    logger.info(f"Command: {' '.join(cmd)}")
    
    try:
        result = subprocess.run(cmd, check=True)
        logger.info(f"Completed: {desc}")
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed: {desc}")
        logger.error(f"Error: {e}")
        return False

def main():
    """Main function to run the entire pipeline."""
    parser = argparse.ArgumentParser(description="Run the entire UI assessment pipeline")
    parser.add_argument("--interfaces", default="interfaces.json", help="Path to interfaces JSON file")
    parser.add_argument("--config", default="config.json", help="Path to configuration file")
    parser.add_argument("--human_results", help="Path to human assessment results CSV file (optional)")
    parser.add_argument("--output_base_dir", default="assessment_run", help="Base directory for all outputs")
    parser.add_argument("--temperatures", type=float, nargs="+", default=[0.0, 0.7], help="Temperature values to use")
    parser.add_argument("--repeats", type=int, default=3, help="Number of times to repeat each assessment")
    parser.add_argument("--services", nargs="+", help="Specific AI services to use (default: all)")
    parser.add_argument("--models", nargs="+", help="Specific models to use (default: all)")
    
    args = parser.parse_args()
    
    # Create a timestamped run directory
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    run_dir = f"{args.output_base_dir}_{timestamp}"
    results_dir = os.path.join(run_dir, "results")
    analysis_dir = os.path.join(run_dir, "analysis")
    
    # Create directories
    os.makedirs(run_dir, exist_ok=True)
    os.makedirs(results_dir, exist_ok=True)
    os.makedirs(analysis_dir, exist_ok=True)
    
    # Copy config and interfaces files to run directory for reproducibility
    import shutil
    shutil.copy2(args.config, os.path.join(run_dir, "config.json"))
    shutil.copy2(args.interfaces, os.path.join(run_dir, "interfaces.json"))
    
    # Step 1: Run the assessments
    cmd = [
        "python", "run_multiple_assessments.py",
        "--interfaces", args.interfaces,
        "--config", args.config,
        "--output_dir", results_dir,
        "--temperatures", *[str(t) for t in args.temperatures],
        "--repeats", str(args.repeats)
    ]
    
    # Add optional arguments if provided
    if args.services:
        cmd.extend(["--services", *args.services])
    if args.models:
        cmd.extend(["--models", *args.models])
    
    if not run_command(cmd, "Running multiple assessments"):
        logger.error("Assessment failed, stopping pipeline")
        return 1
    
    # Step 2: Analyze the results
    cmd = [
        "python", "analyze_all_results.py",
        "--results_dir", results_dir,
        "--config", args.config,
        "--output_dir", analysis_dir
    ]
    
    # Add human results if provided
    if args.human_results:
        cmd.extend(["--human_results", args.human_results])
    
    if not run_command(cmd, "Analyzing results"):
        logger.error("Analysis failed, stopping pipeline")
        return 1
    
    # Step 3: Generate final report
    report_file = os.path.join(run_dir, "assessment_report.md")
    
    logger.info(f"Creating final report: {report_file}")
    
    with open(report_file, 'w') as f:
        f.write(f"# UI Assessment Report\n\n")
        f.write(f"Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        
        f.write("## Run Configuration\n\n")
        f.write(f"- Interfaces file: `{args.interfaces}`\n")
        f.write(f"- Configuration file: `{args.config}`\n")
        f.write(f"- Temperatures: {args.temperatures}\n")
        f.write(f"- Repeats per condition: {args.repeats}\n")
        if args.services:
            f.write(f"- Services: {args.services}\n")
        if args.models:
            f.write(f"- Models: {args.models}\n")
        f.write("\n")
        
        # Include summary from analysis
        analysis_summary_path = os.path.join(analysis_dir, "analysis_summary.md")
        if os.path.exists(analysis_summary_path):
            with open(analysis_summary_path, 'r') as summary_file:
                summary_content = summary_file.read()
                # Skip the header from the summary
                if "# UI Assessment Analysis Summary" in summary_content:
                    summary_content = summary_content.split("# UI Assessment Analysis Summary")[1]
                f.write("## Analysis Summary\n")
                f.write(summary_content)
        
        f.write("\n## Files and Directories\n\n")
        f.write(f"- Results directory: `{results_dir}`\n")
        f.write(f"- Analysis directory: `{analysis_dir}`\n")
        f.write(f"- Log file: `{os.path.join(os.getcwd(), f'ui_assessment_run_{timestamp}.log')}`\n")
    
    logger.info(f"Pipeline completed successfully!")
    logger.info(f"Results directory: {results_dir}")
    logger.info(f"Analysis directory: {analysis_dir}")
    logger.info(f"Final report: {report_file}")
    
    return 0

if __name__ == "__main__":
    exit(main())