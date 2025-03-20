import requests
import base64
import json
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# API key
api_key = os.getenv("ANTHROPIC_API_KEY")
if not api_key:
    raise ValueError("ANTHROPIC_API_KEY not found in environment variables")

# Image path
image_path = "interfaces/example_interface.jpg"

# Encode image to base64
with open(image_path, "rb") as image_file:
    base64_image = base64.b64encode(image_file.read()).decode('utf-8')

# Prompt
prompt = """
Please analyze this user interface and provide an assessment using the UEQ-S and additional questions.

Rate this interface on the following scales (1-7 where 1 is the left term and 7 is the right term):

UEQ-S:
- inefficient (1) to efficient (7)
- interesting (1) to not interesting (7)
- clear (1) to confusing (7)
- enjoyable (1) to annoying (7)

Please format your response as a JSON object with the following structure:
{
    "assessment": {
        "inefficient_efficient": 5,
        "interesting_not_interesting": 3,
        "clear_confusing": 2,
        "enjoyable_annoying": 4
    },
    "explanation": "Short explanation of your assessment..."
}

Please ensure your response contains only this JSON object and no other text.
"""

# API request
headers = {
    "x-api-key": api_key,
    "anthropic-version": "2023-06-01",
    "content-type": "application/json"
}

payload = {
    "model": "claude-3-opus-20240229",
    "max_tokens": 1000,
    "messages": [
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": prompt
                },
                {
                    "type": "image",
                    "source": {
                        "type": "base64",
                        "media_type": "image/jpeg",
                        "data": base64_image
                    }
                }
            ]
        }
    ]
}

response = requests.post(
    "https://api.anthropic.com/v1/messages",
    headers=headers,
    json=payload
)

# Parse response
if response.status_code == 200:
    print("Request successful!")
    response_json = response.json()
    print(json.dumps(response_json, indent=2))
    
    # Extract the text from the response
    response_text = response_json["content"][0]["text"]
    print("\nResponse text:")
    print(response_text)
    
    # Extract the JSON from the response text (if it contains only JSON)
    try:
        response_data = json.loads(response_text)
        print("\nExtracted JSON data:")
        print(json.dumps(response_data, indent=2))
    except json.JSONDecodeError:
        print("\nResponse text is not valid JSON.")
else:
    print(f"Request failed with status code: {response.status_code}")
    print(response.text)
