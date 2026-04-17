import numpy as np
from flask import Flask, jsonify, request
import cv2
import mediapipe as mp

app = Flask(__name__)

# Initialisation de MediaPipe pour la détection des visages
mp_face_mesh = mp.solutions.face_mesh

class FaceMeshDetector:

    def __init__(self, static_image_mode=False, max_num_faces=1, refine_landmarks=False, min_detection_con=0.5,
                 min_tracking_con=0.5):
        # Initialize the parameters for face mesh detection
        self.static_image_mode = static_image_mode  # Whether to process images (True) or video stream (False)
        self.max_num_faces = max_num_faces  # Maximum number of faces to detect
        self.refine_landmarks = refine_landmarks  # Whether to refine iris landmarks for better precision
        self.min_detection_con = min_detection_con  # Minimum confidence for face detection
        self.min_tracking_con = min_tracking_con  # Minimum confidence for tracking

        # Initialize Mediapipe FaceMesh solution
        self.mpFaceMesh = mp.solutions.face_mesh
        self.faceMesh = self.mpFaceMesh.FaceMesh(self.static_image_mode,
                                                 self.max_num_faces,
                                                 self.refine_landmarks,
                                                 self.min_detection_con,
                                                 self.min_tracking_con)

        # Store the landmark indices for specific facial features
        # These are predefined Mediapipe indices for left and right eyes, iris, nose, and mouth

        self.LEFT_EYE_LANDMARKS = [463, 398, 384, 385, 386, 387, 388, 466, 263, 249, 390, 373, 374, 380, 381, 382, 362]  # Left eye landmarks

        self.RIGHT_EYE_LANDMARKS = [33, 246, 161, 160, 159, 158, 157, 173, 133, 155, 154, 153, 145, 144, 163, 7]  # Right eye landmarks

        self.LEFT_IRIS_LANDMARKS = [474, 475, 477, 476]  # Left iris landmarks
        self.RIGHT_IRIS_LANDMARKS = [469, 470, 471, 472]  # Right iris landmarks

        self.NOSE_LANDMARKS = [193, 168, 417, 122, 351, 196, 419, 3, 248, 236, 456, 198, 420, 131, 360, 49, 279, 48,
                               278, 219, 439, 59, 289, 218, 438, 237, 457, 44, 19, 274]  # Nose landmarks

        self.MOUTH_LANDMARKS = [0, 267, 269, 270, 409, 306, 375, 321, 405, 314, 17, 84, 181, 91, 146, 61, 185, 40, 39,
                                37]  # Mouth landmarks

    def findMeshInFace(self, img):
        # Initialize a dictionary to store the landmarks for facial features
        landmarks = {}

        # Convert the input image to RGB as Mediapipe expects RGB images
        imgRGB = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

        # Process the image to find face landmarks using the FaceMesh model
        results = self.faceMesh.process(imgRGB)

        # Check if any faces were detected
        if results.multi_face_landmarks:
            # Iterate over detected faces (here, max_num_faces = 1, so usually one face)
            for faceLms in results.multi_face_landmarks:
                # Initialize lists in the landmarks dictionary to store each facial feature's coordinates
                landmarks["left_eye_landmarks"] = []
                landmarks["right_eye_landmarks"] = []
                landmarks["left_iris_landmarks"] = []
                landmarks["right_iris_landmarks"] = []
                landmarks["nose_landmarks"] = []
                landmarks["mouth_landmarks"] = []
                landmarks["all_landmarks"] = []  # Store all face landmarks for complete face mesh

                # Loop through all face landmarks
                for i, lm in enumerate(faceLms.landmark):
                    h, w, ic = img.shape  # Get image height, width, and channel count
                    x, y = int(lm.x * w), int(lm.y * h)  # Convert normalized coordinates to pixel values

                    # Store the coordinates of all landmarks
                    landmarks["all_landmarks"].append((x, y))

                    # Store specific feature landmarks based on the predefined indices
                    if i in self.LEFT_EYE_LANDMARKS:
                        landmarks["left_eye_landmarks"].append((x, y))  # Left eye
                    if i in self.RIGHT_EYE_LANDMARKS:
                        landmarks["right_eye_landmarks"].append((x, y))  # Right eye
                    if i in self.LEFT_IRIS_LANDMARKS:
                        landmarks["left_iris_landmarks"].append((x, y))  # Left iris
                    if i in self.RIGHT_IRIS_LANDMARKS:
                        landmarks["right_iris_landmarks"].append((x, y))  # Right iris
                    if i in self.NOSE_LANDMARKS:
                        landmarks["nose_landmarks"].append((x, y))  # Nose
                    if i in self.MOUTH_LANDMARKS:
                        landmarks["mouth_landmarks"].append((x, y))  # Mouth

        # Return the processed image and the dictionary of feature landmarks
        return img, landmarks


@app.route('/eye_track', methods=['POST'])
def eye_tracking():
    data = request.get_json()

    # Extract screen dimensions
    width = data.get('width')
    height = data.get('height')

    # Initialize the FaceMeshDetector with refined iris landmarks for better precision
    detector = FaceMeshDetector(refine_landmarks=True)

    # Define the facial features (eyes, nose, mouth, iris, and all landmarks) we are interested in
    face_parts = ["left_eye_landmarks", "right_eye_landmarks", "nose_landmarks",
                  "mouth_landmarks", "all_landmarks", "left_iris_landmarks",
                  "right_iris_landmarks"]

    # Specify which facial feature to detect (index 2 refers to the nose landmarks here)
    face_part = 5
    face_part2 = 6

    # Capture video from webcam/camera
    cap = cv2.VideoCapture(0)

    print("camera")
    print(cap)
    print("camera ouverte ?")
    print(cap.isOpened())
    print("camera lecture")
    print(cap.read())

    if not cap.isOpened():
        print("Error: Could not open video device.")

    # Read the next frame from the video capture
    success, image = cap.read()

    # If reading the frame was unsuccessful (e.g., end of video), break the loop
    if not success:
        return jsonify({'error': 'No face detected'}), 404

    # Use the FaceMeshDetector to find facial landmarks in the current frame
    image, landmarks = detector.findMeshInFace(image)

    def calculate_centroid(points):
        """Calculate the centroid of a list of points."""
        if not points:
            return None  # Handle empty input

        # Sum x and y coordinates
        sum_x = sum(point[0] for point in points)
        sum_y = sum(point[1] for point in points)

        # Calculate the average
        centroid_x = sum_x / len(points)
        centroid_y = sum_y / len(points)

        return (centroid_x, centroid_y)

    def calculate_gaze_coordinates(left_centroid, right_centroid):
        """Calculate the gaze coordinates based on the left and right centroids."""
        # Unpack centroid coordinates
        left_x, left_y = left_centroid
        right_x, right_y = right_centroid

        # Calculate the average coordinates
        gaze_x = (left_x + right_x) / 2
        gaze_y = (left_y + right_y) / 2

        return gaze_x, gaze_y

    def map_coordinates_to_screen(iris_centroid, screen_size):
        """Map iris centroid coordinates to screen coordinates."""
        # Unpack coordinates and screen dimensions
        iris_x, iris_y = iris_centroid
        screen_width, screen_height = screen_size

        # Define the real-world dimensions of the iris region (example values)
        iris_region_width = 100  # Width of the area containing the iris (in pixels)
        iris_region_height = 50  # Height of the area containing the iris (in pixels)

        # Normalize the iris coordinates to the screen size
        mapped_x = iris_x / screen_width
        mapped_y =  iris_y / screen_height

        return mapped_x, mapped_y

    def calculate_iris_center(points):
        """Calculate the centroid of the iris landmarks."""
        x_coords = [point[0] for point in points]
        y_coords = [point[1] for point in points]
        center_x = sum(x_coords) / len(points)
        center_y = sum(y_coords) / len(points)
        return center_x, center_y

    def calculate_gaze_direction(iris_landmarks, eye_center):
        """Calculate the gaze direction based on iris landmarks and eye center."""
        # Calculate the iris center
        iris_center = calculate_iris_center(iris_landmarks)

        # Convert coordinates to numpy arrays for vector calculations
        iris_center_np = np.array(iris_center)
        eye_center_np = np.array(eye_center)

        # Calculate the gaze vector
        gaze_vector = eye_center_np - iris_center_np

        # Normalize the gaze vector
        gaze_vector_normalized = np.linalg.norm(gaze_vector)
        #gaze_vector_normalized = gaze_vector / np.linalg.norm(gaze_vector)

        return gaze_vector_normalized

    # API future
    print("left iris")
    print(landmarks[face_parts[face_part]])
    left_iris = landmarks[face_parts[face_part]]
    print("right iris")
    print(landmarks[face_parts[face_part2]])
    right_iris = landmarks[face_parts[face_part2]]

    #calculate left iris gaze
    left_iris_gaze = calculate_gaze_direction(left_iris,calculate_iris_center(landmarks[face_parts[0]]))
    print("left iris gaze")
    print(left_iris_gaze)

    #calculate right iris gaze
    right_iris_gaze = calculate_gaze_direction(right_iris, calculate_iris_center(landmarks[face_parts[1]]))
    print("right iris gaze")
    print(right_iris_gaze)

    #Final gaze_coordinates
    #gaze_coordinates = calculate_gaze_coordinates(left_iris_gaze, right_iris_gaze)
    #print("Gaze Coordinates:", gaze_coordinates)

    centroid_left_iris = calculate_centroid(left_iris)
    print("Left Centroid coordinates:", centroid_left_iris)

    centroid_right_iris = calculate_centroid(right_iris)
    print("Right Centroid coordinates:", centroid_right_iris)

    gaze_coordinates = calculate_gaze_coordinates(centroid_left_iris, centroid_right_iris)
    print("Gaze Coordinates:", gaze_coordinates)
    print("Screen size : ", width,height)

    #gaze = map_coordinates_to_screen(gaze_coordinates,(width,height))
    #print("Mapped Gaze Coordinates:", gaze)

    return jsonify({
        'success': True, 
        'gaze_left_x': centroid_left_iris[0], 
        'gaze_left_y': centroid_left_iris[0],
        'gaze_right_x': centroid_right_iris[0], 
        'gaze_right_y': centroid_right_iris[0]
    })

@app.route('/')
def home():
    return jsonify({'message': 'Eye tracking server is running.'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)