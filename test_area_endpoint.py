import requests
from PIL import Image
import numpy as np
import io

# Create test images with different colors to simulate different conditions
def create_test_images(count=4):
    images = []
    
    # Create different colored images to simulate different conditions
    colors = [
        [34, 139, 34],   # Forest green (healthy)
        [139, 69, 19],   # Brown (diseased)
        [34, 139, 34],   # Forest green (healthy)
        [255, 140, 0],   # Orange (diseased)
    ]
    
    for i in range(count):
        color = colors[i % len(colors)]
        img_array = np.zeros((224, 224, 3), dtype=np.uint8)
        img_array[:, :] = color
        
        img = Image.fromarray(img_array)
        img_bytes = io.BytesIO()
        img.save(img_bytes, format='JPEG')
        img_bytes.seek(0)
        images.append(('test_section_' + str(i) + '.jpg', img_bytes, 'image/jpeg'))
    
    return images

# Test the area endpoint
def test_analyze_area_endpoint():
    url = "http://localhost:8000/analyze-area"
    
    # Create test images
    images = create_test_images(4)
    
    # Send request - format as dict for requests
    files_dict = []
    for i, (filename, img_bytes, content_type) in enumerate(images):
        files_dict.append(('files', (filename, img_bytes, content_type)))
    
    try:
        response = requests.post(url, files=files_dict)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.json()}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_analyze_area_endpoint()
