import requests
from PIL import Image
import numpy as np
import io

# Create a simple test image (green leaf-like color)
def create_test_image():
    # Create a 224x224 green image (simulating a leaf)
    img_array = np.zeros((224, 224, 3), dtype=np.uint8)
    img_array[:, :] = [34, 139, 34]  # Forest green
    
    img = Image.fromarray(img_array)
    img_bytes = io.BytesIO()
    img.save(img_bytes, format='JPEG')
    img_bytes.seek(0)
    return img_bytes

# Test the endpoint
def test_analyze_endpoint():
    url = "http://localhost:8000/analyze"
    
    # Create test image
    image_bytes = create_test_image()
    
    # Send request
    files = {'file': ('test_leaf.jpg', image_bytes, 'image/jpeg')}
    
    try:
        response = requests.post(url, files=files)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.json()}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_analyze_endpoint()
