from flask import Flask, request, jsonify
import cv2
import mediapipe as mp
import numpy as np
import time
from flask_cors import CORS


app = Flask(__name__)
CORS(app)

face_mesh = mp.solutions.face_mesh.FaceMesh(refine_landmarks=True)
last_eye_detection_time = None
EYE_DETECTION_TIMEOUT = 15

# Gérer l'activation/désactivation de la caméra
camera = None

@app.route('/eye_tracking', methods=['POST'])
def eye_tracking():
    global last_eye_detection_time, camera
    
    enable = request.json.get('enable', False)

    if enable:
        # Initialiser la caméra
        camera = cv2.VideoCapture(0)
    
    if camera is None or not camera.isOpened():
        return jsonify({'error': 'Camera not initialized'}), 400
    
    ret, frame = camera.read()
    if not ret:
        return jsonify({'error': 'Failed to capture frame from camera'}), 500
    
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = face_mesh.process(rgb_frame)

    if results.multi_face_landmarks:
        landmarks = results.multi_face_landmarks[0].landmark
        
        left_eye = [landmarks[145], landmarks[159]]
        right_eye = [landmarks[374], landmarks[386]]

        h, w, _ = frame.shape
        gaze_left_x = sum(landmark.x for landmark in left_eye) / len(left_eye) * w
        gaze_left_y = sum(landmark.y for landmark in left_eye) / len(left_eye) * h
        gaze_right_x = sum(landmark.x for landmark in right_eye) / len(right_eye) * w
        gaze_right_y = sum(landmark.y for landmark in right_eye) / len(right_eye) * h

        last_eye_detection_time = time.time()

        return jsonify({
            'gaze_left_x': gaze_left_x,
            'gaze_left_y': gaze_left_y,
            'gaze_right_x': gaze_right_x,
            'gaze_right_y': gaze_right_y
        })

    if last_eye_detection_time and (time.time() - last_eye_detection_time) > EYE_DETECTION_TIMEOUT:
        # Arrêter la caméra si les yeux ne sont pas détectés dans le délai
        if camera is not None:
            camera.release()
        return jsonify({'timeout': True}), 200

    return jsonify({'error': 'Failed to detect eyes'}), 400

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=3000)
