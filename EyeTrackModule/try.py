import cv2
import mediapipe as mp
import numpy as np
import logging
import os
from datetime import datetime
from flask import Flask, jsonify
from flask_socketio import SocketIO, emit
from flask_cors import CORS

app = Flask(__name__)
CORS(app, resources={r"/": {"origins": "*", "methods": ["GET", "POST"], "allow_headers": ["Content-Type", "Authorization"]}})
socketio = SocketIO(app, cors_allowed_origins="*")

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(refine_landmarks=True)

def calculate_centroid(points):
    if not points:
        return None
    sum_x = sum(p[0] for p in points)
    sum_y = sum(p[1] for p in points)
    return (sum_x / len(points), sum_y / len(points))

def map_coordinates_to_screen(iris_centroid, screen_size):
    iris_x, iris_y = iris_centroid
    screen_width, screen_height = screen_size if screen_size else (1280, 720)
    mapped_x = float(iris_x * screen_width)
    mapped_y = float(iris_y * screen_height)
    return mapped_x, mapped_y

def calculate_gaze_direction(iris_center, eye_center):
    gaze_vector = np.array(eye_center) - np.array(iris_center)
    # Normaliser le vecteur de direction du regard
    norm = np.linalg.norm(gaze_vector)
    if norm == 0:
        return np.array([0, 0])  # Éviter la division par zéro
    gaze_vector = gaze_vector / norm
    return gaze_vector

def project_gaze_to_screen(eye_center, gaze_vector, screen_size):
    screen_width, screen_height = screen_size if screen_size else (1280, 720)
    eye_x, eye_y = eye_center
    gaze_x, gaze_y = gaze_vector

    # Calculer la distance entre le centre de l'oeil et l'iris
    distance = np.sqrt(gaze_x**2 + gaze_y**2)

    # Ajuster le scaling_factor en fonction de la distance
    scaling_factor = 100 * (0.5 + distance)  # Ajuster la formule selon les besoins

    # Projeter la direction du regard à partir du centre de l'œil
    screen_x = float((eye_x + gaze_x * scaling_factor) * screen_width)
    screen_y = float((eye_y + gaze_y * scaling_factor) * screen_height)

    # S'assurer que les valeurs sont bien dans les limites de l’écran
    screen_x = max(0, min(screen_x, screen_width - 1))
    screen_y = max(0, min(screen_y, screen_height - 1))

    return screen_x, screen_y

@socketio.on('connect')
def handle_connect():
    logger.info("Client connected")

@socketio.on('screen_size')
def handle_screen_size(data):
    global screen_width, screen_height
    try:
        screen_width = int(data['width'])
        screen_height = int(data['height'])
        logger.info(f"Screen size received: {screen_width}x{screen_height}")
    except Exception as e:
        logger.error(f"Invalid screen size data: {e}")
        screen_width, screen_height = 1280, 720

# Chemin du répertoire pour enregistrer les frames
SAVE_DIR = r"C:\Users\duval\Desktop\Project\MSR_PROJECTS\MSR_WelcomeRea\WelcomReaApp\EyeTrackModule\images"

# Global variables to store screen dimensions
screen_width = 1280  # Default width
screen_height = 720  # Default height

# Créer le répertoire s'il n'existe pas
if not os.path.exists(SAVE_DIR):
    os.makedirs(SAVE_DIR)

def enhance_image(image):
    """Améliore la résolution et la couleur de l'image."""
    # Vérifier si l'image est en niveaux de gris et la convertir en couleur
    if len(image.shape) == 2 or image.shape[2] == 1:
        image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)

    # Redimensionner l'image avec une interpolation de haute qualité
    height, width = screen_height, screen_width
    new_size = (width, height)
    enhanced_image = cv2.resize(image, new_size, interpolation=cv2.INTER_CUBIC)

    return enhanced_image

@socketio.on('handle_frame')
def handle_frame(data):
    global screen_width, screen_height, face_mesh
    try:
        frame = np.frombuffer(data, dtype=np.uint8)
        frame = cv2.imdecode(frame, cv2.IMREAD_COLOR)

        if frame is None:
            emit('error', {'message': 'Failed to decode frame'})
            return
        
        #frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # 2. Convert from BGR to RGB (MediaPipe expects RGB images)
        frame_rgb = enhance_image(frame) 
        results = face_mesh.process(frame_rgb)

         # Enregistrer la frame dans le répertoire (optionnel pour le debug)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
        frame_filename = os.path.join(SAVE_DIR, f"frame_{timestamp}.jpg")
        cv2.imwrite(frame_filename, frame_rgb)
        logger.debug(f"Frame saved to {frame_filename}")

        
        if results.multi_face_landmarks:
            for face_landmarks in results.multi_face_landmarks:
                landmarks = [(lm.x, lm.y) for lm in face_landmarks.landmark]
                left_iris = [landmarks[i] for i in [474, 475, 477, 476]]
                right_iris = [landmarks[i] for i in [469, 470, 471, 472]]
                left_eye = [landmarks[i] for i in [263, 362, 387, 373]]
                right_eye = [landmarks[i] for i in [33, 133, 158, 144]]
                
                left_iris_center = calculate_centroid(left_iris)
                right_iris_center = calculate_centroid(right_iris)
                left_eye_center = calculate_centroid(left_eye)
                right_eye_center = calculate_centroid(right_eye)
                
                gaze_left = calculate_gaze_direction(left_iris_center, left_eye_center)
                gaze_right = calculate_gaze_direction(right_iris_center, right_eye_center)
                
                mapped_left_x, mapped_left_y = map_coordinates_to_screen(left_iris_center, (screen_width, screen_height))
                mapped_right_x, mapped_right_y = map_coordinates_to_screen(right_iris_center, (screen_width, screen_height))

                # Calculer le point où l'utilisateur regarde sur l'écran
                gaze_point_left_x, gaze_point_left_y = project_gaze_to_screen(left_eye_center, gaze_left, (screen_width, screen_height))
                gaze_point_right_x, gaze_point_right_y = project_gaze_to_screen(right_eye_center, gaze_right, (screen_width, screen_height))

                
                print('gaze_data', {
                    'gaze_point_left_x': gaze_point_left_x, 'gaze_point_left_y': gaze_point_left_y,
                    'gaze_point_right_x': gaze_point_right_x, 'gaze_point_right_y': gaze_point_right_y
                })

                emit('gaze_data', {
                    'gaze_left_x': gaze_point_left_x, 
                    'gaze_left_y': gaze_point_left_y,
                    'gaze_right_x': gaze_point_right_x, 
                    'gaze_right_y': gaze_point_right_y,
                })
    except Exception as e:
        logger.error(f"Error processing frame: {e}")
        emit('error', {'message': f'Error processing frame: {e}'})

@app.route('/')
def home():
    return jsonify({'message': 'Eye tracking server running'})

if __name__ == '__main__':
    socketio.run(app, debug=True, host='0.0.0.0', port=5000)