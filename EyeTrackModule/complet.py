import cv2
import mediapipe as mp
import numpy as np
import logging
from collections import deque
from flask import Flask, jsonify
from flask_socketio import SocketIO, emit
from flask_cors import CORS
from filterpy.kalman import KalmanFilter

# Initialize Flask app and SocketIO
app = Flask(__name__)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Initialize MediaPipe Face Mesh
mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(
    static_image_mode=False,
    max_num_faces=1,
    refine_landmarks=True,
    min_detection_confidence=0.6,
    min_tracking_confidence=0.6
)

# Default screen size (updated dynamically)
screen_width = 1280
screen_height = 720

# Kalman filter for gaze smoothing
def init_kalman_filter():
    kf = KalmanFilter(dim_x=4, dim_z=2)  # State: [x, y, vx, vy], Measurement: [x, y]
    kf.F = np.array([[1, 0, 1, 0],  # State transition matrix
                     [0, 1, 0, 1],
                     [0, 0, 1, 0],
                     [0, 0, 0, 1]])
    kf.H = np.array([[1, 0, 0, 0],  # Measurement matrix
                     [0, 1, 0, 0]])
    kf.P *= 10.0  # Initial uncertainty
    kf.R = np.array([[0.1, 0],  # Measurement noise
                     [0, 0.1]])
    kf.Q = np.eye(4) * 0.01  # Process noise
    return kf

left_kf = init_kalman_filter()
right_kf = init_kalman_filter()

# Camera intrinsic parameters (approximated for a typical tablet camera)
focal_length = 1000  # In pixels, approximate for tablet cameras
camera_matrix = np.array([[focal_length, 0, screen_width / 2],
                          [0, focal_length, screen_height / 2],
                          [0, 0, 1]], dtype=np.float32)

# History for smoothing (fallback if Kalman fails)
history_length = 5
gaze_history = deque(maxlen=history_length)

@socketio.on('screen_size')
def handle_screen_size(data):
    global screen_width, screen_height, camera_matrix
    try:
        screen_width = int(data['width'])
        screen_height = int(data['height'])
        # Update camera matrix principal point
        camera_matrix[0, 2] = screen_width / 2
        camera_matrix[1, 2] = screen_height / 2
        logger.info(f"Screen size updated: {screen_width}x{screen_height}")
    except Exception as e:
        logger.error(f"Invalid screen size data: {e}")
        screen_width, screen_height = 1280, 720

def enhance_image(image):
    if len(image.shape) == 2 or image.shape[2] == 1:
        image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)
    return cv2.resize(image, (screen_width, screen_height), interpolation=cv2.INTER_CUBIC)

def estimate_head_pose(landmarks, image_width, image_height):
    # 3D model points (generic face model in mm)
    model_points = np.array([
        [0.0, 0.0, 0.0],        # Nose tip
        [0.0, -330.0, -65.0],   # Chin
        [-225.0, 170.0, -135.0], # Left eye left corner
        [225.0, 170.0, -135.0],  # Right eye right corner
        [-150.0, 100.0, -125.0], # Left mouth corner
        [150.0, 100.0, -125.0]   # Right mouth corner
    ], dtype=np.float32)

    # 2D image points (corresponding landmarks)
    image_points = np.array([
        landmarks[1],  # Nose tip
        landmarks[152], # Chin
        landmarks[33],  # Left eye left corner
        landmarks[263], # Right eye right corner
        landmarks[61],  # Left mouth corner
        landmarks[291]  # Right mouth corner
    ], dtype=np.float32) * np.array([image_width, image_height])

    # Solve PnP to estimate head pose
    dist_coeffs = np.zeros((4, 1))  # No lens distortion
    success, rvec, tvec = cv2.solvePnP(model_points, image_points, camera_matrix, dist_coeffs)
    if not success:
        return None, None

    # Convert rotation vector to rotation matrix
    rotation_matrix, _ = cv2.Rodrigues(rvec)
    return rotation_matrix, tvec

def calculate_gaze_direction(iris_center, eye_center, rotation_matrix):
    if iris_center is None or eye_center is None or rotation_matrix is None:
        return None
    # Compute 2D gaze vector and extend to 3D (assume z=0 in image plane)
    gaze_vector_2d = np.array(eye_center) - np.array(iris_center)
    gaze_vector_3d = np.array([gaze_vector_2d[0], gaze_vector_2d[1], 0.0], dtype=np.float32)
    gaze_vector_3d = gaze_vector_3d / (np.linalg.norm(gaze_vector_3d) + 1e-6)
    # Apply head rotation
    gaze_vector_3d = rotation_matrix @ gaze_vector_3d
    return gaze_vector_3d

def project_gaze_to_screen(gaze_vector, face_distance, eye_center):
    if gaze_vector is None:
        return None, None
    # Dynamic scaling based on face distance
    scaling_factor = 1000 * (1 + 1 / (face_distance + 1e-6))
    # Project to screen coordinates using only x, y components
    screen_x = (eye_center[0] + gaze_vector[0] * scaling_factor) * screen_width
    screen_y = (eye_center[1] + gaze_vector[1] * scaling_factor) * screen_height
    return max(0, min(int(screen_x), screen_width - 1)), max(0, min(int(screen_y), screen_height - 1))

@socketio.on('handle_frame')
def handle_frame(data):
    global face_mesh, screen_width, screen_height, left_kf, right_kf
    try:
        frame = cv2.imdecode(np.frombuffer(data, dtype=np.uint8), cv2.IMREAD_COLOR)
        if frame is None:
            emit('error', {'message': 'Failed to decode frame'})
            return

        frame_rgb = enhance_image(frame)
        frame_rgb = cv2.cvtColor(frame_rgb, cv2.COLOR_BGR2RGB)
        image_height, image_width, _ = frame_rgb.shape

        # Explicitly set image dimensions for MediaPipe
        results = face_mesh.process(frame_rgb)
        if not results.multi_face_landmarks:
            emit('error', {'message': 'No face detected'})
            return

        # Select closest face
        faces = [(np.mean([lm.z for lm in face_landmarks.landmark]), face_landmarks)
                 for face_landmarks in results.multi_face_landmarks]
        closest_face = min(faces, key=lambda x: x[0])[1]
        landmarks = np.array([(lm.x, lm.y) for lm in closest_face.landmark])
        face_distance = abs(np.mean([lm.z for lm in closest_face.landmark]))

        # Estimate head pose
        rotation_matrix, tvec = estimate_head_pose(landmarks, image_width, image_height)
        if rotation_matrix is None:
            emit('error', {'message': 'Head pose estimation failed'})
            return

        # Iris and eye landmarks
        left_iris = landmarks[[474, 475, 477, 476]]
        right_iris = landmarks[[469, 470, 471, 472]]
        left_eye = landmarks[[463, 398, 384, 385, 386, 387, 388, 466, 263, 249, 390, 373, 374, 380, 381, 382, 362]]
        right_eye = landmarks[[33, 246, 161, 160, 159, 158, 157, 173, 133, 155, 154, 153, 145, 144, 163, 7]]

        # Calculate centroids
        left_iris_center = np.mean(left_iris, axis=0) if left_iris.size else None
        right_iris_center = np.mean(right_iris, axis=0) if right_iris.size else None
        left_eye_center = np.mean(left_eye, axis=0) if left_eye.size else None
        right_eye_center = np.mean(right_eye, axis=0) if right_eye.size else None

        gaze_points = []
        # Left eye gaze
        if left_iris_center is not None and left_eye_center is not None:
            gaze_left = calculate_gaze_direction(left_iris_center, left_eye_center, rotation_matrix)
            left_x, left_y = project_gaze_to_screen(gaze_left, face_distance, left_eye_center)
            if left_x is not None and left_y is not None:
                left_kf.update(np.array([left_x, left_y]))
                left_kf.predict()
                gaze_points.append((left_kf.x[0], left_kf.x[1]))
            else:
                gaze_points.append((None, None))
        else:
            gaze_points.append((None, None))

        # Right eye gaze
        if right_iris_center is not None and right_eye_center is not None:
            gaze_right = calculate_gaze_direction(right_iris_center, right_eye_center, rotation_matrix)
            right_x, right_y = project_gaze_to_screen(gaze_right, face_distance, right_eye_center)
            if right_x is not None and right_y is not None:
                right_kf.update(np.array([right_x, right_y]))
                right_kf.predict()
                gaze_points.append((right_kf.x[0], right_kf.x[1]))
            else:
                gaze_points.append((None, None))
        else:
            gaze_points.append((None, None))

        # Fallback smoothing with moving average
        valid_gaze_points = [gp for gp in gaze_history if gp[0][0] is not None and gp[1][0] is not None]
        if valid_gaze_points:
            smoothed_gaze = np.mean(valid_gaze_points, axis=0)
        else:
            smoothed_gaze = gaze_points

        gaze_history.append(gaze_points)

        gaze_data = {
            'gaze_left_x': int(smoothed_gaze[0][0]) if gaze_points[0][0] is not None else None,
            'gaze_left_y': int(smoothed_gaze[0][1]) if gaze_points[0][1] is not None else None,
            'gaze_right_x': int(smoothed_gaze[1][0]) if gaze_points[1][0] is not None else None,
            'gaze_right_y': int(smoothed_gaze[1][1]) if gaze_points[1][1] is not None else None,
        }
        emit('gaze_data', gaze_data)

    except Exception as e:
        logger.error(f"Error processing frame: {e}")
        emit('error', {'message': f'Error processing frame: {e}'})

@app.route('/')
def home():
    return jsonify({'message': 'Eye tracking server running'})

if __name__ == '__main__':
    socketio.run(app, debug=True, host='0.0.0.0', port=5000)