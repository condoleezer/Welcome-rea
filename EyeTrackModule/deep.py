import cv2
import mediapipe as mp
import numpy as np
import logging
import os
from collections import deque
from datetime import datetime
from flask import Flask, jsonify
from flask_socketio import SocketIO, emit
from flask_cors import CORS

# Initialisation de l'application Flask et des modules de communication
app = Flask(__name__)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")

# Configuration du logging pour le débogage
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Initialisation de MediaPipe Face Mesh pour le suivi des points du visage
mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(
    static_image_mode=False,
    max_num_faces=1,
    refine_landmarks=True,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5)

screen_width = 1280
screen_height = 748 

# Historique des positions pour le lissage (moyenne mobile)
history_length = 4
gaze_history = deque(maxlen=history_length)

@socketio.on('screen_size')
def handle_screen_size(data):
    global screen_width, screen_height
    try:
        screen_width = int(data['width'])
        screen_height = int(data['height'])
        logger.info(f"Screen size received: {screen_width}x{screen_height}")
    except Exception as e:
        logger.error(f"Invalid screen size data: {e}")
        screen_width, screen_height = 1280, 748

# Fonction pour calculer le centroïde pondéré d'un ensemble de points
def calculate_weighted_centroid(points):
    if points.size == 0:
        return None
    weights = np.linalg.norm(points - np.mean(points, axis=0), axis=1)
    weights = 1 / (weights + 1e-6)
    return np.average(points, axis=0, weights=weights)

# Fonction pour calculer la direction du regard à partir des centres de l'iris et de l'œil
def calculate_gaze_direction(iris_center, eye_center):
    gaze_vector = np.array(eye_center) - np.array(iris_center)
    norm = np.linalg.norm(gaze_vector)
    return gaze_vector / norm if norm > 0 else np.array([0, 0])

# Projection de la direction du regard sur l'écran
def project_gaze_to_screen(eye_center, gaze_vector, iris_center, face_distance):
    scaling_factor = 0 * (1 + (1 / (face_distance + 1e-6)))  # Ajustement dynamique basé sur la distance
    screen_x = int((eye_center[0] + gaze_vector[0] * scaling_factor) * screen_width)
    screen_y = int((eye_center[1] + gaze_vector[1] * scaling_factor) * screen_height)
    return max(0, min(screen_x, screen_width - 1)), max(0, min(screen_y, screen_height - 1))

def enhance_image(image):
    global screen_width, screen_height
    if len(image.shape) == 2 or image.shape[2] == 1:
        image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)
    return cv2.resize(image, (screen_width, screen_height), interpolation=cv2.INTER_CUBIC)

# Gestion des frames envoyées en temps réel depuis le client
@socketio.on('handle_frame')
def handle_frame(data):
    global face_mesh, screen_width, screen_height
    try:
        frame = cv2.imdecode(np.frombuffer(data, dtype=np.uint8), cv2.IMREAD_COLOR)
        if frame is None:
            emit('error', {'message': 'Failed to decode frame'})
            return
        
        frame_rgb = enhance_image(frame)
        frame_rgb = cv2.cvtColor(frame_rgb, cv2.COLOR_BGR2RGB)
        
        # Get image dimensions
        image_height, image_width, _ = frame_rgb.shape
        
        # Process the image with FaceMesh
        results = face_mesh.process(frame_rgb)

        
        if results.multi_face_landmarks:
            # Sélection du visage le plus proche (basé sur la distance moyenne des landmarks)
            faces = [(np.mean([lm.z for lm in face_landmarks.landmark]), face_landmarks)
                     for face_landmarks in results.multi_face_landmarks]
            closest_face = min(faces, key=lambda x: x[0])[1]  # Visage avec la plus petite valeur Z
            
            landmarks = np.array([(lm.x, lm.y) for lm in closest_face.landmark])
            left_iris = landmarks[[474, 475, 477, 476]]
            right_iris = landmarks[[469, 470, 471, 472]]
            left_eye = landmarks[[463, 398, 384, 385, 386, 387, 388, 466, 263, 249, 390, 373, 374, 380, 381, 382, 362]]
            right_eye = landmarks[[33, 246, 161, 160, 159, 158, 157, 173, 133, 155, 154, 153, 145, 144, 163, 7]]
            
            face_distance = abs(np.mean([lm.z for lm in closest_face.landmark]))
            
            left_iris_center = calculate_weighted_centroid(left_iris)
            right_iris_center = calculate_weighted_centroid(right_iris)
            left_eye_center = calculate_weighted_centroid(left_eye)
            right_eye_center = calculate_weighted_centroid(right_eye)
            
            gaze_points = []
            if left_iris_center is not None and left_eye_center is not None:
                gaze_left = calculate_gaze_direction(left_iris_center, left_eye_center)
                gaze_point_left = project_gaze_to_screen(left_eye_center, gaze_left, left_iris_center, face_distance)
                gaze_points.append(gaze_point_left)
            else:
                gaze_points.append((None, None))
            
            if right_iris_center is not None and right_eye_center is not None:
                gaze_right = calculate_gaze_direction(right_iris_center, right_eye_center)
                gaze_point_right = project_gaze_to_screen(right_eye_center, gaze_right, right_iris_center, face_distance)
                gaze_points.append(gaze_point_right)
            else:
                gaze_points.append((None, None))
            
            # Lissage avec une moyenne mobile
            gaze_history.append(gaze_points)
            smoothed_gaze = np.mean(gaze_history, axis=0)

            print('gaze_data', {
                'gaze_left_x': int(smoothed_gaze[0][0]),
                'gaze_left_y': int(smoothed_gaze[0][1]),
                'gaze_right_x': int(smoothed_gaze[1][0]),
                'gaze_right_y': int(smoothed_gaze[1][1]),
            })

            emit('gaze_data', {
                'gaze_left_x': int(smoothed_gaze[0][0]),
                'gaze_left_y': int(smoothed_gaze[0][1]),
                'gaze_right_x': int(smoothed_gaze[1][0]),
                'gaze_right_y': int(smoothed_gaze[1][1]),
            })
    except Exception as e:
        logger.error(f"Error processing frame: {e}")
        emit('error', {'message': f'Error processing frame: {e}'})

# Route de base pour tester le bon fonctionnement du serveur
@app.route('/')
def home():
    return jsonify({'message': 'Eye tracking server running'})

# Lancement du serveur Flask avec SocketIO
if __name__ == '__main__':
    socketio.run(app, debug=True, host='0.0.0.0', port=5000)
