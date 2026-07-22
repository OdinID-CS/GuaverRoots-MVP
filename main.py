from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
import uuid
import random
from typing import List, Optional

app = FastAPI(title="GuaverRoots API", version="1.0.0")

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


@app.get("/")
async def root():
    """Health check endpoint."""
    return {"status": "ok", "message": "GuaverRoots API is running"}


@app.post("/analyze")
async def analyze_image(file: UploadFile = File(...)):
    """
    Analyze a single crop image for disease detection.
    
    Returns a diagnosis with disease name, confidence, severity, and treatment recommendations.
    """
    try:
        # Validate file type
        if not file.content_type or not file.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        # In a real implementation, this would:
        # 1. Save the uploaded file
        # 2. Process it with an AI model
        # 3. Return actual analysis results
        
        # For demo, return random disease data
        disease = get_random_disease()
        
        response = {
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
        
        return response
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")


@app.post("/analyze-area")
async def analyze_area(files: List[UploadFile] = File(...)):
    """
    Analyze multiple crop images for area-level disease detection.
    
    Returns a combined diagnosis with health status across the scanned area.
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
        
        # In a real implementation, this would:
        # 1. Save all uploaded files
        # 2. Process each with an AI model
        # 3. Aggregate results for area-level analysis
        
        # For demo, return random disease data
        disease = get_random_disease()
        
        response = {
            "id": str(uuid.uuid4()),
            "image_path": f"/uploads/{files[0].filename}",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "disease_name": disease["name"],
            "confidence": disease["confidence"],
            "severity": disease["severity"],
            "treatment": disease["treatment"],
            "urgency": disease["urgency"],
            "description": disease["description"],
            "is_area_scan": True,
            "area_scan_images": [f"/uploads/{f.filename}" for f in files],
            "notes": f"Area scan completed with {len(files)} locations analyzed",
        }
        
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Area analysis failed: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
