from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
import uuid
import random
from typing import List, Optional
import numpy as np
from PIL import Image
import io
import os
from dotenv import load_dotenv
from groq import Groq

# Try to import tflite_runtime, fallback to tensorflow.lite
try:
    from tflite_runtime.interpreter import Interpreter
    TFLITE_RUNTIME_AVAILABLE = True
except ImportError:
    try:
        from tensorflow.lite.python.interpreter import Interpreter
        TFLITE_RUNTIME_AVAILABLE = False
    except ImportError:
        raise ImportError("Neither tflite_runtime nor tensorflow is installed. Please install one of them.")

app = FastAPI(title="GuaverRoots API", version="1.0.0")

# Model configuration
MODEL_PATH = os.getenv("MODEL_PATH", "model.tflite")
if not os.path.exists(MODEL_PATH):
    MODEL_PATH = os.path.join("models", "model.tflite")

# Class names (39 total)
CLASS_NAMES = [
    "Apple___Apple_scab",
    "Apple___Black_rot",
    "Apple___Cedar_apple_rust",
    "Apple___healthy",
    "Background_without_leaves",
    "Blueberry___healthy",
    "Cherry___Powdery_mildew",
    "Cherry___healthy",
    "Corn___Cercospora_leaf_spot Gray_leaf_spot",
    "Corn___Common_rust",
    "Corn___Northern_Leaf_Blight",
    "Corn___healthy",
    "Grape___Black_rot",
    "Grape___Esca_(Black_Measles)",
    "Grape___Leaf_blight_(Isariopsis_Leaf_Spot)",
    "Grape___healthy",
    "Orange___Haunglongbing_(Citrus_greening)",
    "Peach___Bacterial_spot",
    "Peach___healthy",
    "Pepper,_bell___Bacterial_spot",
    "Pepper,_bell___healthy",
    "Potato___Early_blight",
    "Potato___Late_blight",
    "Potato___healthy",
    "Raspberry___healthy",
    "Soybean___healthy",
    "Squash___Powdery_mildew",
    "Strawberry___Leaf_scorch",
    "Strawberry___healthy",
    "Tomato___Bacterial_spot",
    "Tomato___Early_blight",
    "Tomato___Late_blight",
    "Tomato___Leaf_Mold",
    "Tomato___Septoria_leaf_spot",
    "Tomato___Spider_mites Two-spotted_spider_mite",
    "Tomato___Target_Spot",
    "Tomato___Tomato_mosaic_virus",
    "Tomato___healthy",
]

# Global interpreter
interpreter = None

# Groq API client
groq_client = None
GROQ_API_KEY = None

# Load environment variables
load_dotenv()

# Configure CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify actual origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mock disease data (matches Flutter app's mock data)
MOCK_DISEASES = [
    {
        "name": "Leaf Rust",
        "confidence": 0.87,
        "severity": "Moderate",
        "urgency": "Treat within 3-5 days",
        "treatment": "Apply fungicide spray containing chlorothalonil or mancozeb. Remove and destroy affected leaves. Ensure proper spacing between plants for better air circulation. Avoid overhead irrigation to reduce leaf wetness.",
        "description": "A fungal disease causing orange-brown pustules on leaves",
    },
    {
        "name": "Powdery Mildew",
        "confidence": 0.92,
        "severity": "High",
        "urgency": "Treat immediately",
        "treatment": "Apply sulfur-based fungicide or neem oil spray. Remove heavily infected plant parts. Improve air circulation around plants. Reduce humidity by avoiding dense planting and watering at the base of plants.",
        "description": "White powdery coating on leaves and stems",
    },
    {
        "name": "Bacterial Leaf Spot",
        "confidence": 0.78,
        "severity": "Moderate",
        "urgency": "Treat within 5-7 days",
        "treatment": "Apply copper-based fungicide. Remove infected leaves and plant debris. Avoid working with plants when wet. Use disease-free seeds and seedlings. Rotate crops to break disease cycles.",
        "description": "Water-soaked spots that turn brown with yellow halos",
    },
    {
        "name": "Early Blight",
        "confidence": 0.85,
        "severity": "High",
        "urgency": "Treat within 2-3 days",
        "treatment": "Apply fungicides containing chlorothalonil or copper. Remove lower affected leaves. Mulch plants to prevent soil splash. Ensure proper plant spacing. Avoid overhead irrigation.",
        "description": "Dark concentric rings on lower leaves",
    },
    {
        "name": "Downy Mildew",
        "confidence": 0.81,
        "severity": "High",
        "urgency": "Treat immediately",
        "treatment": "Apply fungicides with mefenoxam or copper. Remove infected plant material immediately. Improve drainage and reduce humidity. Space plants properly for air flow. Water early in the day.",
        "description": "Yellow patches on leaf tops with gray mold underneath",
    },
    {
        "name": "Anthracnose",
        "confidence": 0.74,
        "severity": "Moderate",
        "urgency": "Treat within 4-6 days",
        "treatment": "Apply chlorothalonil or copper fungicides. Prune infected branches during dry weather. Avoid overhead irrigation. Remove and destroy fallen leaves and fruit. Disinfect tools between cuts.",
        "description": "Dark sunken lesions on leaves, stems, and fruit",
    },
    {
        "name": "Fusarium Wilt",
        "confidence": 0.68,
        "severity": "High",
        "urgency": "Treat immediately",
        "treatment": "Remove infected plants entirely - do not compost. Solarize soil before replanting. Use resistant varieties. Rotate with non-host crops. Ensure proper drainage to prevent waterlogging.",
        "description": "Wilting and yellowing leaves despite adequate water",
    },
    {
        "name": "Healthy Plant",
        "confidence": 0.95,
        "severity": "None",
        "urgency": "Continue monitoring",
        "treatment": "No treatment needed. Continue regular monitoring. Maintain proper watering, fertilization, and pest control practices. Consider preventive measures during high-risk weather conditions.",
        "description": "No disease detected - plant appears healthy",
    },
]


def get_random_disease():
    """Get a random disease sample for demo purposes."""
    return MOCK_DISEASES[random.randint(0, len(MOCK_DISEASES) - 1)]


def load_model():
    """Load the TensorFlow Lite model."""
    global interpreter
    try:
        interpreter = Interpreter(model_path=MODEL_PATH)
        interpreter.allocate_tensors()
        print(f"Model loaded successfully from {MODEL_PATH}")
        print(f"Using {'tflite_runtime' if TFLITE_RUNTIME_AVAILABLE else 'tensorflow.lite'}")
        return True
    except Exception as e:
        print(f"Failed to load model: {e}")
        return False


def preprocess_image(image_bytes):
    """
    Preprocess image for model input.
    
    Steps:
    1. Load image from bytes
    2. Resize to 224x224
    3. Convert to RGB
    4. Normalize to 0-1 (divide by 255)
    5. Shape to (1, 224, 224, 3)
    6. Convert to float32
    """
    image = Image.open(io.BytesIO(image_bytes))
    
    # Convert to RGB if necessary
    if image.mode != 'RGB':
        image = image.convert('RGB')
    
    # Resize to 224x224
    image = image.resize((224, 224), Image.Resampling.LANCZOS)
    
    # Convert to numpy array and normalize
    image_array = np.array(image, dtype=np.float32) / 255.0
    
    # Reshape to (1, 224, 224, 3)
    image_array = np.expand_dims(image_array, axis=0)
    
    return image_array


def parse_class_name(raw_class_name):
    """
    Parse raw class name (format: Crop___DiseaseName) into clean components.
    
    Returns:
        crop: Crop type (e.g., "Tomato")
        disease_name: Disease name (e.g., "Early Blight")
        is_healthy: Whether the plant is healthy
    """
    if raw_class_name == "Background_without_leaves":
        return "Unknown", "Background", False
    
    parts = raw_class_name.split("___")
    if len(parts) < 2:
        return "Unknown", raw_class_name, False
    
    crop = parts[0]
    disease_raw = parts[1]
    
    # Check if healthy
    is_healthy = disease_raw.lower() == "healthy"
    
    # Clean up disease name (replace underscores with spaces)
    disease_name = disease_raw.replace("_", " ")
    
    # Handle special cases
    if "Pepper,_bell" in crop:
        crop = "Pepper (bell)"
    
    return crop, disease_name, is_healthy


def infer_severity(confidence, is_healthy):
    """
    Infer severity based on confidence and health status.
    
    Rules:
    - Healthy → "None" or "Low"
    - Otherwise: moderate/high based on confidence
    """
    if is_healthy:
        return "None"
    
    if confidence > 0.8:
        return "High"
    elif confidence > 0.6:
        return "Moderate"
    else:
        return "Low"


async def generate_overall_summary_with_groq(results):
    """
    Generate overall summary for area scan using Groq API.
    
    Args:
        results: List of individual diagnosis results
    
    Returns:
        summary: Farmer-friendly summary of the area scan
    """
    if groq_client is None:
        # Fallback summary
        healthy_count = sum(1 for r in results if r.get("is_healthy", False))
        total_count = len(results)
        return f"Area scan completed. {healthy_count} of {total_count} sections appear healthy."
    
    try:
        # Build summary of results
        results_summary = []
        for i, result in enumerate(results):
            disease = result.get("disease_name", "Unknown")
            confidence = result.get("confidence", 0)
            severity = result.get("severity", "Unknown")
            is_healthy = result.get("is_healthy", False)
            results_summary.append(
                f"Section {i+1}: {disease} ({confidence*100:.1f}% confidence, {severity} severity, {'healthy' if is_healthy else 'diseased'})"
            )
        
        results_text = "\n".join(results_summary)
        
        prompt = f"""A farmer scanned multiple sections of their crop field. Here are the results:
{results_text}

Provide a simple, clear summary for the farmer explaining the overall health of their field. 
Include how many sections show disease vs are healthy, and the overall risk level.
Respond ONLY in this exact JSON format:
{{
  "summary": "2-3 sentences summarizing the overall field health",
  "recommendation": "clear recommendation for next steps"
}}"""

        response = groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "user", "content": prompt}
            ],
            temperature=0.5,
            max_tokens=300,
        )
        
        response_text = response.choices[0].message.content
        
        # Try to parse JSON response
        import json
        try:
            summary_data = json.loads(response_text)
            return {
                "summary": summary_data.get("summary", "Area scan completed."),
                "recommendation": summary_data.get("recommendation", "Continue monitoring your crops.")
            }
        except json.JSONDecodeError:
            print(f"Failed to parse Groq summary as JSON: {response_text}")
            # Fallback
            healthy_count = sum(1 for r in results if r.get("is_healthy", False))
            total_count = len(results)
            return {
                "summary": f"Area scan completed. {healthy_count} of {total_count} sections appear healthy.",
                "recommendation": "Continue monitoring your crops."
            }
            
    except Exception as e:
        print(f"Groq summary API error: {e}")
        # Fallback summary
        healthy_count = sum(1 for r in results if r.get("is_healthy", False))
        total_count = len(results)
        return {
            "summary": f"Area scan completed. {healthy_count} of {total_count} sections appear healthy.",
            "recommendation": "Continue monitoring your crops."
        }


def calculate_risk_level(results):
    """
    Calculate overall risk level based on severity distribution.
    
    Args:
        results: List of individual diagnosis results
    
    Returns:
        risk_level: "green" (low risk), "yellow" (moderate risk), or "red" (high risk)
    """
    if not results:
        return "green"
    
    # Count by severity
    high_severity = sum(1 for r in results if r.get("severity") == "High")
    moderate_severity = sum(1 for r in results if r.get("severity") == "Moderate")
    low_severity = sum(1 for r in results if r.get("severity") in ["Low", "None"])
    
    total = len(results)
    
    # Risk calculation logic
    if high_severity > 0:
        # Any high severity = red
        return "red"
    elif moderate_severity / total >= 0.5:
        # 50% or more moderate = yellow
        return "yellow"
    elif moderate_severity > 0:
        # Some moderate but less than 50% = yellow
        return "yellow"
    else:
        # All low/none = green
        return "green"


async def generate_treatment_with_groq(disease_name, confidence, is_healthy):
    """
    Generate treatment recommendations using Groq API with llama-3.3-70b-versatile.
    
    Returns severity, explanation, treatment, urgency, and alternative causes in farmer-friendly language.
    """
    if groq_client is None:
        # Fallback to generic treatment if API not configured
        if is_healthy:
            return {
                "severity": "low",
                "explanation": f"Your {disease_name.replace('healthy', '').strip()} plant looks healthy!",
                "treatment": "Continue regular monitoring. Maintain proper watering, fertilization, and pest control practices.",
                "urgency": "monitor",
                "alternative_causes": [],
            }
        else:
            return {
                "severity": "moderate",
                "explanation": f"{disease_name} detected. This is a common crop disease that requires attention.",
                "treatment": "Consult local agricultural extension for specific treatment recommendations.",
                "urgency": "act_soon",
                "alternative_causes": ["Environmental stress", "Nutrient deficiency", "Other diseases"],
            }
    
    try:
        confidence_percent = f"{confidence * 100:.1f}%"
        
        if is_healthy:
            prompt = f"""A farmer's crop was scanned and diagnosed as: {disease_name} (confidence: {confidence_percent}).
This is a healthy plant! Explain this to a farmer with no scientific background, in simple, clear, encouraging language.
Respond ONLY in this exact JSON format:
{{
  "severity": "low",
  "explanation": "2-3 simple sentences explaining that the plant is healthy",
  "treatment": "positive maintenance advice to keep the plant healthy",
  "urgency": "monitor",
  "alternative_causes": []
}}"""
        else:
            prompt = f"""A farmer's crop was scanned and diagnosed with: {disease_name} (confidence: {confidence_percent}).
Explain this to a farmer with no scientific background, in simple, clear, encouraging language.
Respond ONLY in this exact JSON format:
{{
  "severity": "low" | "moderate" | "high",
  "explanation": "2-3 simple sentences explaining what this disease is",
  "treatment": "clear, actionable treatment steps",
  "urgency": "monitor" | "act_soon" | "urgent",
  "alternative_causes": ["list", "of", "possible", "other", "causes"] or []
}}"""

        response = groq_client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "user", "content": prompt}
            ],
            temperature=0.5,
            max_tokens=500,
        )
        
        response_text = response.choices[0].message.content
        
        # Try to parse JSON response
        import json
        try:
            treatment_data = json.loads(response_text)
            return {
                "severity": treatment_data.get("severity", "moderate"),
                "explanation": treatment_data.get("explanation", f"{disease_name} detected."),
                "treatment": treatment_data.get("treatment", "Consult local agricultural extension."),
                "urgency": treatment_data.get("urgency", "act_soon"),
                "alternative_causes": treatment_data.get("alternative_causes", []),
            }
        except json.JSONDecodeError:
            # Fallback if response is not valid JSON
            print(f"Failed to parse Groq response as JSON: {response_text}")
            if is_healthy:
                return {
                    "severity": "low",
                    "explanation": f"Your plant looks healthy!",
                    "treatment": "Continue regular monitoring and maintenance.",
                    "urgency": "monitor",
                    "alternative_causes": [],
                }
            else:
                return {
                    "severity": "moderate",
                    "explanation": f"{disease_name} detected.",
                    "treatment": "Consult local agricultural extension for treatment.",
                    "urgency": "act_soon",
                    "alternative_causes": [],
                }
            
    except Exception as e:
        print(f"Groq API error: {e}")
        # Fallback to generic treatment
        if is_healthy:
            return {
                "severity": "low",
                "explanation": f"Your plant looks healthy!",
                "treatment": "Continue regular monitoring and maintenance.",
                "urgency": "monitor",
                "alternative_causes": [],
            }
        else:
            return {
                "severity": "moderate",
                "explanation": f"{disease_name} detected.",
                "treatment": "Consult local agricultural extension for treatment.",
                "urgency": "act_soon",
                "alternative_causes": ["Environmental stress", "Nutrient deficiency"],
            }


@app.on_event("startup")
async def startup_event():
    """Load model and initialize Groq client on startup."""
    global groq_client, GROQ_API_KEY
    
    # Load TensorFlow Lite model
    load_model()
    
    # Get Groq API key from environment
    GROQ_API_KEY = os.getenv("GROQ_API_KEY")
    
    # Initialize Groq client if API key is provided
    if GROQ_API_KEY:
        try:
            groq_client = Groq(api_key=GROQ_API_KEY)
            print("Groq API client initialized")
        except Exception as e:
            print(f"Failed to initialize Groq client: {e}")
    else:
        print("GROQ_API_KEY not set, using fallback treatments")


@app.get("/")
async def root():
    """Health check endpoint."""
    return {"status": "ok", "message": "GuaverRoots API is running"}


@app.post("/analyze")
async def analyze_image(file: UploadFile = File(...)):
    """
    Analyze a single crop image for disease detection using TensorFlow Lite model.
    
    Returns a diagnosis with disease name, confidence, severity, and treatment recommendations.
    """
    try:
        # Validate file type
        if not file.content_type or not file.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        # Check if model is loaded
        if interpreter is None:
            print("Model not loaded, falling back to mock data")
            disease = get_random_disease()
            return {
                "id": str(uuid.uuid4()),
                "image_path": f"/uploads/{file.filename}",
                "timestamp": datetime.utcnow().isoformat() + "Z",
                "disease_name": disease["name"],
                "confidence": disease["confidence"],
                "severity": disease["severity"],
                "treatment": disease["treatment"],
                "urgency": disease["urgency"],
                "description": disease["description"],
                "is_area_scan": False,
                "area_scan_images": None,
                "notes": None,
            }
        
        # Read image bytes
        image_bytes = await file.read()
        
        # Preprocess image
        input_data = preprocess_image(image_bytes)
        
        # Get input and output details
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        # Set input tensor
        interpreter.set_tensor(input_details[0]['index'], input_data)
        
        # Run inference
        interpreter.invoke()
        
        # Get output tensor
        output_data = interpreter.get_tensor(output_details[0]['index'])
        
        # Get argmax class and confidence
        predicted_class_index = int(np.argmax(output_data[0]))
        confidence = float(output_data[0][predicted_class_index])
        
        # Get class name
        raw_class_name = CLASS_NAMES[predicted_class_index]
        
        # Parse class name
        crop, disease_name, is_healthy = parse_class_name(raw_class_name)
        
        # Infer severity
        severity = infer_severity(confidence, is_healthy)
        
        # Generate treatment using Groq API
        treatment_data = await generate_treatment_with_groq(disease_name, confidence, is_healthy)
        
        # Map Groq urgency to Flutter app format
        urgency_map = {
            "monitor": "Continue monitoring",
            "act_soon": "Treat within 3-5 days",
            "urgent": "Treat immediately"
        }
        urgency = urgency_map.get(treatment_data["urgency"], "Treat within 3-5 days")
        
        # Map Groq severity to Flutter app format
        severity_map = {
            "low": "Low",
            "moderate": "Moderate",
            "high": "High"
        }
        final_severity = severity_map.get(treatment_data["severity"], severity)
        
        # Build response
        response = {
            "id": str(uuid.uuid4()),
            "image_path": f"/uploads/{file.filename}",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "disease_name": disease_name,
            "confidence": confidence,
            "severity": final_severity,
            "treatment": treatment_data["treatment"],
            "urgency": urgency,
            "description": treatment_data["explanation"],
            "is_area_scan": False,
            "area_scan_images": None,
            "notes": f"Crop: {crop} | Raw class: {raw_class_name} | Alternative causes: {', '.join(treatment_data['alternative_causes']) if treatment_data['alternative_causes'] else 'None'}",
        }
        
        return response
        
    except Exception as e:
        print(f"Analysis error: {e}")
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")


@app.post("/analyze-area")
async def analyze_area(files: List[UploadFile] = File(...)):
    """
    Analyze multiple crop images for area-level disease detection.
    
    Processes each image through the TFLite model + Groq pipeline and returns:
    - results: array of individual diagnoses with position indices
    - overall_summary: Groq-generated summary of all results
    - risk_level: green/yellow/red based on severity distribution
    """
    try:
        if len(files) == 0:
            raise HTTPException(status_code=400, detail="At least one file must be provided")
        
        if len(files) > 9:
            raise HTTPException(status_code=400, detail="Maximum 9 files allowed")
        
        # Validate all files are images
        for file in files:
            if not file.content_type or not file.content_type.startswith("image/"):
                raise HTTPException(status_code=400, detail="All files must be images")
        
        # Process each image
        results = []
        
        for position_idx, file in enumerate(files):
            try:
                # Read image bytes
                image_bytes = await file.read()
                
                # Check if model is loaded
                if interpreter is None:
                    print(f"Model not loaded for position {position_idx}, falling back to mock data")
                    disease = get_random_disease()
                    
                    result = {
                        "position": position_idx,
                        "id": str(uuid.uuid4()),
                        "image_path": f"/uploads/{file.filename}",
                        "disease_name": disease["name"],
                        "confidence": disease["confidence"],
                        "severity": disease["severity"],
                        "treatment": disease["treatment"],
                        "urgency": disease["urgency"],
                        "description": disease["description"],
                        "is_healthy": disease["name"] == "Healthy Plant",
                        "notes": None,
                    }
                    results.append(result)
                    continue
                
                # Preprocess image
                input_data = preprocess_image(image_bytes)
                
                # Get input and output details
                input_details = interpreter.get_input_details()
                output_details = interpreter.get_output_details()
                
                # Set input tensor
                interpreter.set_tensor(input_details[0]['index'], input_data)
                
                # Run inference
                interpreter.invoke()
                
                # Get output tensor
                output_data = interpreter.get_tensor(output_details[0]['index'])
                
                # Get argmax class and confidence
                predicted_class_index = int(np.argmax(output_data[0]))
                confidence = float(output_data[0][predicted_class_index])
                
                # Get class name
                raw_class_name = CLASS_NAMES[predicted_class_index]
                
                # Parse class name
                crop, disease_name, is_healthy = parse_class_name(raw_class_name)
                
                # Infer severity
                severity = infer_severity(confidence, is_healthy)
                
                # Generate treatment using Groq API
                treatment_data = await generate_treatment_with_groq(disease_name, confidence, is_healthy)
                
                # Map Groq urgency to Flutter app format
                urgency_map = {
                    "monitor": "Continue monitoring",
                    "act_soon": "Treat within 3-5 days",
                    "urgent": "Treat immediately"
                }
                urgency = urgency_map.get(treatment_data["urgency"], "Treat within 3-5 days")
                
                # Map Groq severity to Flutter app format
                severity_map = {
                    "low": "Low",
                    "moderate": "Moderate",
                    "high": "High"
                }
                final_severity = severity_map.get(treatment_data["severity"], severity)
                
                # Build individual result
                result = {
                    "position": position_idx,
                    "id": str(uuid.uuid4()),
                    "image_path": f"/uploads/{file.filename}",
                    "disease_name": disease_name,
                    "confidence": confidence,
                    "severity": final_severity,
                    "treatment": treatment_data["treatment"],
                    "urgency": urgency,
                    "description": treatment_data["explanation"],
                    "is_healthy": is_healthy,
                    "notes": f"Crop: {crop} | Raw class: {raw_class_name} | Alternative causes: {', '.join(treatment_data['alternative_causes']) if treatment_data['alternative_causes'] else 'None'}",
                }
                
                results.append(result)
                
            except Exception as e:
                print(f"Error processing image at position {position_idx}: {e}")
                # Add error result
                results.append({
                    "position": position_idx,
                    "id": str(uuid.uuid4()),
                    "image_path": f"/uploads/{file.filename}",
                    "disease_name": "Analysis Error",
                    "confidence": 0.0,
                    "severity": "Unknown",
                    "treatment": "Unable to analyze this section. Please try again.",
                    "urgency": "Unknown",
                    "description": f"Error: {str(e)}",
                    "is_healthy": False,
                    "notes": "Processing error",
                })
        
        # Calculate overall risk level
        risk_level = calculate_risk_level(results)
        
        # Generate overall summary using Groq
        summary_data = await generate_overall_summary_with_groq(results)
        
        # Build final response
        response = {
            "id": str(uuid.uuid4()),
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "results": results,
            "overall_summary": summary_data.get("summary", "Area scan completed."),
            "recommendation": summary_data.get("recommendation", "Continue monitoring your crops."),
            "risk_level": risk_level,
            "total_sections": len(results),
            "healthy_sections": sum(1 for r in results if r.get("is_healthy", False)),
            "diseased_sections": sum(1 for r in results if not r.get("is_healthy", False)),
        }
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Area analysis error: {e}")
        raise HTTPException(status_code=500, detail=f"Area analysis failed: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
