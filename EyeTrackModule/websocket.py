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
CORS(app)
CORS(app, resources={r"/": {"origins": "*", "methods": ["GET", "POST"], "allow_headers": ["Content-Type", "Authorization"]}})
socketio = SocketIO(app, cors_allowed_origins="*")

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Initialiser Mediapipe Face Mesh avec les iris
face_mesh = mp.solutions.face_mesh.FaceMesh(
    static_image_mode=False,  # Important: Set to False for video stream
    max_num_faces=1,
    refine_landmarks=True,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

# Landmarks des iris (gauche: 469, droit: 474)
LEFT_IRIS = 469
RIGHT_IRIS = 474

# Store screen dimensions
screen_width = 0
screen_height = 0

# Chemin du répertoire pour enregistrer les frames
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

@socketio.on('screen_size')
def handle_screen_size(data):
    global screen_width, screen_height
    try:
        screen_width = int(data.get('width', 1280))
        screen_height = int(data.get('height', 748))
        logger.info(f"Received screen size: width={screen_width}, height={screen_height}")
    except (ValueError, TypeError):
        logger.warning("Invalid screen size received. Using default values.")
        screen_width, screen_height = 1280, 748


@socketio.on('handle_frame')
def handle_frame(data):
    logger.debug("Received frame data")
    try:
        nparr = np.frombuffer(data, np.uint8)
        logger.debug(f"Frame data size: {len(nparr)} bytes")
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if frame is not None:
            logger.debug("Frame decoded successfully")

            # Enregistrer la frame dans le répertoire (optionnel pour le debug)
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
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

def process_frame(frame):  # Remplacez ces valeurs par la résolution de votre tablette
    frame_resized = cv2.resize(frame, (screen_width, screen_height))
    h, w, _ = frame_resized.shape
    rgb_frame = cv2.cvtColor(frame_resized, cv2.COLOR_BGR2RGB)
    results = face_mesh.process(rgb_frame)

    if results.multi_face_landmarks:
        landmarks = results.multi_face_landmarks[0].landmark

        # Récupérer les coordonnées des iris
        left_iris = landmarks[LEFT_IRIS]
        right_iris = landmarks[RIGHT_IRIS]

        # Convertir les coordonnées normalisées en coordonnées de l'écran
        gaze_left_x = left_iris.x * w
        gaze_left_y = left_iris.y * h
        gaze_right_x = right_iris.x * w
        gaze_right_y = right_iris.y * h
        
        # Normaliser par rapport à la taille de l'écran
        gaze_left_x_normalized = gaze_left_x / screen_width
        gaze_left_y_normalized = gaze_left_y / screen_height
        gaze_right_x_normalized = gaze_right_x / screen_width
        gaze_right_y_normalized = gaze_right_y / screen_height
        

        return {
            'gaze_left_x': gaze_left_x_normalized,
            'gaze_left_y': gaze_left_y_normalized,
            'gaze_right_x': gaze_right_x_normalized,
            'gaze_right_y': gaze_right_y_normalized,
            'screen_width': screen_width,
            'screen_height': screen_height,
        }
    else:
        logger.warning("Failed to detect face landmarks")
        return {'error': 'Failed to detect face landmarks'}

@app.route('/')
def home():
    return jsonify({'message': 'Eye tracking server is running.'})

if __name__ == '__main__':
    socketio.run(app, debug=True, host='0.0.0.0', port=5000)
