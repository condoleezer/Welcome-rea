import cv2
import mediapipe as mp
import numpy as np
import logging
import os
from flask import Flask, jsonify
from flask_socketio import SocketIO, emit
from flask_cors import CORS

app = Flask(__name__)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*", max_http_buffer_size=10_000_000)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

face_mesh = mp.solutions.face_mesh.FaceMesh(
    static_image_mode=False,
    max_num_faces=1,
    refine_landmarks=True,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5)

screen_width  = 1280
screen_height = 720
sensor_orientation = 0  # orientation capteur caméra envoyée par Flutter (0/90/180/270)

# Calibration
calibration_points   = []   # liste de (sx, sy, ix, iy)
calibration_matrix   = None # matrice 3x2 : [ix, iy, 1] @ M = [sx, sy]
current_calib_screen = None # (sx, sy) du point en cours

# ── Helpers ───────────────────────────────────────────────────────────────────

def decode_frame(data):
    """Accepte bytes ou list[int] (socket.io envoie parfois une liste)."""
    if isinstance(data, (bytes, bytearray)):
        buf = np.frombuffer(data, dtype=np.uint8)
    else:
        buf = np.array(data, dtype=np.uint8)
    frame = cv2.imdecode(buf, cv2.IMREAD_COLOR)
    return frame


def get_iris(frame, sensor_orientation=0):
    """
    Retourne (ix, iy) normalisés [0-1] dans l'espace ÉCRAN (portrait),
    en tenant compte de l'orientation du capteur caméra.
    
    sensor_orientation : 0, 90, 180, 270 (degrés, sens horaire)
    """
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    # Mapper l'orientation capteur → rotation OpenCV pour redresser la frame
    # On veut que le visage soit "droit" pour MediaPipe
    rotation_map = {
        0:   None,
        90:  cv2.ROTATE_90_COUNTERCLOCKWISE,
        180: cv2.ROTATE_180,
        270: cv2.ROTATE_90_CLOCKWISE,
    }
    rot = rotation_map.get(sensor_orientation, None)
    candidate = cv2.rotate(rgb, rot) if rot is not None else rgb

    r = face_mesh.process(candidate)

    # Si pas de visage avec l'orientation fournie, essayer les autres
    if not r.multi_face_landmarks:
        other_rotations = [None,
                           cv2.ROTATE_90_CLOCKWISE,
                           cv2.ROTATE_180,
                           cv2.ROTATE_90_COUNTERCLOCKWISE]
        for other_rot in other_rotations:
            if other_rot == rot:
                continue
            candidate = cv2.rotate(rgb, other_rot) if other_rot is not None else rgb
            r = face_mesh.process(candidate)
            if r.multi_face_landmarks:
                rot = other_rot
                break

    if not r.multi_face_landmarks:
        return None

    lm = np.array([(l.x, l.y) for l in r.multi_face_landmarks[0].landmark])
    left_center  = lm[[474, 475, 476, 477]].mean(axis=0)
    right_center = lm[[469, 470, 471, 472]].mean(axis=0)
    ix, iy = ((left_center + right_center) / 2.0).tolist()

    # Reconvertir les coordonnées dans l'espace de la frame ORIGINALE (non tournée)
    # pour que ix, iy correspondent à l'espace écran
    if rot == cv2.ROTATE_90_CLOCKWISE:
        # frame tournée 90° CW : (x,y) dans frame tournée → (y, 1-x) dans originale
        ix, iy = iy, 1.0 - ix
    elif rot == cv2.ROTATE_90_COUNTERCLOCKWISE:
        # frame tournée 90° CCW : (x,y) → (1-y, x)
        ix, iy = 1.0 - iy, ix
    elif rot == cv2.ROTATE_180:
        ix, iy = 1.0 - ix, 1.0 - iy
    # rot == None : pas de changement

    return float(ix), float(iy)


def compute_calibration_matrix():
    global calibration_matrix
    if len(calibration_points) < 4:
        return False

    from collections import defaultdict
    groups = defaultdict(list)
    for sx, sy, ix, iy in calibration_points:
        groups[(sx, sy)].append((ix, iy))

    src, dst = [], []
    for (sx, sy), pts in groups.items():
        ix = np.mean([p[0] for p in pts])
        iy = np.mean([p[1] for p in pts])
        src.append([ix, iy])
        dst.append([sx, sy])

    src = np.array(src, dtype=np.float64)
    dst = np.array(dst, dtype=np.float64)
    ones = np.ones((len(src), 1), dtype=np.float64)
    src_h = np.hstack([src, ones])          # shape (N, 3)
    # résoudre src_h @ M = dst  →  M shape (3, 2)
    M, _, _, _ = np.linalg.lstsq(src_h, dst, rcond=None)
    calibration_matrix = M
    logger.info(f"Calibration matrix OK — {len(groups)} points uniques")
    return True


def iris_to_screen(ix, iy):
    """Convertit des coords iris normalisées [0-1] en pixels écran."""
    if calibration_matrix is not None:
        v = np.array([ix, iy, 1.0], dtype=np.float64)
        res = v @ calibration_matrix          # [sx, sy]
        sx = int(np.clip(res[0], 0, screen_width  - 1))
        sy = int(np.clip(res[1], 0, screen_height - 1))
        return sx, sy
    else:
        # Fallback sans calibration : mapping linéaire empirique
        X_MIN, X_MAX = 0.35, 0.65
        Y_MIN, Y_MAX = 0.35, 0.65
        nx = np.clip((ix - X_MIN) / (X_MAX - X_MIN), 0, 1)
        ny = np.clip((iy - Y_MIN) / (Y_MAX - Y_MIN), 0, 1)
        return int(nx * screen_width), int(ny * screen_height)


# ── Socket events ─────────────────────────────────────────────────────────────

@socketio.on('connect')
def on_connect():
    logger.info("Client connecté")

@socketio.on('disconnect')
def on_disconnect():
    logger.info("Client déconnecté")

@socketio.on('screen_size')
def on_screen_size(data):
    global screen_width, screen_height, sensor_orientation
    screen_width       = int(data.get('width',  1280))
    screen_height      = int(data.get('height', 720))
    sensor_orientation = int(data.get('sensor_orientation', 0))
    logger.info(f"Taille écran : {screen_width}x{screen_height}, capteur : {sensor_orientation}°")

# ── Calibration ───────────────────────────────────────────────────────────────

@socketio.on('calibration_start')
def on_calibration_start():
    global calibration_points, calibration_matrix, current_calib_screen
    calibration_points  = []
    calibration_matrix  = None
    current_calib_screen = None
    logger.info("Calibration démarrée")
    emit('calibration_ready')

@socketio.on('calibration_point')
def on_calibration_point(data):
    global current_calib_screen
    current_calib_screen = (int(data['screen_x']), int(data['screen_y']))
    logger.info(f"Point de calibration : {current_calib_screen}")
    emit('calibration_point_ack')

@socketio.on('calibration_frame')
def on_calibration_frame(data):
    """Flutter envoie les bytes directement (pas un dict)."""
    if current_calib_screen is None:
        emit('calibration_frame_result', {'success': False, 'reason': 'no_point'})
        return

    frame = decode_frame(data)
    if frame is None:
        emit('calibration_frame_result', {'success': False, 'reason': 'decode_error'})
        return

    iris = get_iris(frame, sensor_orientation)
    if iris is None:
        emit('calibration_frame_result', {'success': False, 'reason': 'no_face'})
        return

    ix, iy = iris
    sx, sy = current_calib_screen
    calibration_points.append((sx, sy, ix, iy))
    logger.info(f"Calib point : écran=({sx},{sy})  iris=({ix:.4f},{iy:.4f})")
    emit('calibration_frame_result', {'success': True})

@socketio.on('calibration_finish')
def on_calibration_finish():
    ok = compute_calibration_matrix()
    emit('calibration_done', {
        'success': ok,
        'points': len(calibration_points)
    })

# ── Tracking ──────────────────────────────────────────────────────────────────

@socketio.on('handle_frame')
def on_handle_frame(data):
    """Flutter envoie les bytes directement."""
    try:
        frame = decode_frame(data)
        if frame is None:
            emit('error', {'message': 'decode_error'})
            return

        iris = get_iris(frame, sensor_orientation)
        if iris is None:
            emit('error', {'message': 'no_face'})
            return

        ix, iy = iris
        sx, sy = iris_to_screen(ix, iy)
        logger.info(f"iris=({ix:.3f},{iy:.3f}) → écran=({sx},{sy})")

        emit('gaze_data', {
            'gaze_left_x':  sx,
            'gaze_left_y':  sy,
            'gaze_right_x': sx,
            'gaze_right_y': sy,
        })

    except Exception as e:
        logger.error(f"Erreur handle_frame : {e}")
        emit('error', {'message': str(e)})


@app.route('/')
def home():
    return jsonify({'message': 'Eye tracking server running'})

if __name__ == '__main__':
    import eventlet
    socketio.run(app, debug=False, host='0.0.0.0', port=5000)
