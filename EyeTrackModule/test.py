from flask import Flask, jsonify
from flask_socketio import SocketIO, emit
from flask_cors import CORS
import cv2
import mediapipe as mp
import numpy as np
import logging
import os
from datetime import datetime

app = Flask(__name__)
CORS(app)
CORS(app, resources={r"/": {"origins": "*", "methods": ["GET", "POST"], "allow_headers": ["Content-Type", "Authorization"]}})
socketio = SocketIO(app, cors_allowed_origins="*")

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

face_mesh = mp.solutions.face_mesh.FaceMesh(refine_landmarks=True)

# Chemin du répertoire pour enregistrer les frames (utilisation d'une chaîne brute)
SAVE_DIR = r"C:\Users\duval\Desktop\Project\MSR_PROJECTS\MSR_WelcomeRea\WelcomReaApp\EyeTrackModule\images"

# Créer le répertoire s'il n'existe pas
if not os.path.exists(SAVE_DIR):
    os.makedirs(SAVE_DIR)

@socketio.on('connect')
def handle_connect():
    logger.info("Client connected")

@socketio.on('test_message')
def handle_test_message(message):
    logger.info(f"Received test message: {message}")

@socketio.on('disconnect')
def handle_disconnect():
    logger.info("Client disconnected")

@socketio.on('handle_frame')
def handle_frame(data):
    logger.debug("Received frame data")
    try:
        nparr = np.frombuffer(data, np.uint8)
        logger.debug(f"Frame data size: {len(nparr)} bytes")
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if frame is not None:
            logger.debug("Frame decoded successfully")

            # Enregistrer la frame dans le répertoire
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")  # Horodatage unique
            frame_filename = os.path.join(SAVE_DIR, f"frame_{timestamp}.jpg")
            cv2.imwrite(frame_filename, frame)
            logger.debug(f"Frame saved to {frame_filename}")

            # Traiter la frame pour obtenir les données de regard
            gaze_data = process_frame(frame)
            emit('gaze_data', gaze_data)
            logger.debug("Processed frame and sent gaze data")
        else:
            logger.error("Failed to decode frame")
            emit('error', {'message': 'Failed to decode frame'})
    except Exception as e:
        logger.error(f'Error in processing frame: {str(e)}')
        emit('error', {'message': f'Error in processing frame: {str(e)}'})


def process_frame(frame):
    # Redimensionner l'image pour correspondre à la taille de l'écran de la tablette
    screen_width, screen_height = 1280, 800  # Remplacez ces valeurs par la résolution de votre tablette
    frame_resized = cv2.resize(frame, (screen_width, screen_height))

    h, w, _ = frame_resized.shape
    rgb_frame = cv2.cvtColor(frame_resized, cv2.COLOR_BGR2RGB)
    results = face_mesh.process(rgb_frame)
    
    if results.multi_face_landmarks:
        landmarks = results.multi_face_landmarks[0].landmark
        left_eye = [landmarks[145], landmarks[159]]
        right_eye = [landmarks[374], landmarks[386]]

        gaze_left_x = sum(landmark.x for landmark in left_eye) / len(left_eye) * w
        gaze_left_y = sum(landmark.y for landmark in left_eye) / len(left_eye) * h
        gaze_right_x = sum(landmark.x for landmark in right_eye) / len(right_eye) * w
        gaze_right_y = sum(landmark.y for landmark in right_eye) / len(right_eye) * h
        
        print("left:", gaze_left_x, gaze_left_y)
        print("right:", gaze_right_x, gaze_right_y)

        return {
            'gaze_left_x': gaze_left_x,
            'gaze_left_y': gaze_left_y,
            'gaze_right_x': gaze_right_x,
            'gaze_right_y': gaze_right_y
        }
    logger.warning("Failed to detect eyes")
    return {'error': 'Failed to detect eyes'}

@app.route('/')
def home():
    return jsonify({'message': 'Eye tracking server is running.'})

if __name__ == '__main__':
    socketio.run(app, debug=True, host='0.0.0.0', port=5000)
