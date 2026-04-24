import cv2
import mediapipe as mp
import numpy as np
import logging
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
sensor_orientation = 270  # défaut tablette portrait, caméra droite

calibration_points   = []
calibration_matrix   = None
current_calib_screen = None

# Rotation fixée après calibration (on ne change plus pendant le tracking)
_fixed_rotation = None
_rotation_locked = False

# Lissage exponentiel du gaze
SMOOTH_ALPHA = 0.7
_gaze_smooth_x = None
_gaze_smooth_y = None

# Historique court pour filtrer les pics aberrants
_iris_history = []
HISTORY_SIZE  = 5       # nb de frames gardées
MAX_JUMP      = 0.08    # saut max autorisé entre frames (en coords iris_rel)


# ── Helpers ───────────────────────────────────────────────────────────────────

def decode_frame(data):
    if isinstance(data, (bytes, bytearray)):
        buf = np.frombuffer(data, dtype=np.uint8)
    else:
        buf = np.array(data, dtype=np.uint8)
    return cv2.imdecode(buf, cv2.IMREAD_COLOR)


def rotation_for_orientation(s_orientation):
    """Retourne la constante OpenCV à appliquer selon l'orientation capteur."""
    # Sur cette tablette (sensorOrientation=270 en paysage),
    # Flutter/Android pré-applique déjà la rotation → frame arrive correcte → None
    return {
        0:   None,
        90:  cv2.ROTATE_90_COUNTERCLOCKWISE,
        180: cv2.ROTATE_180,
        270: None,   # FIX : frame déjà correcte côté Android
    }.get(s_orientation, None)


def apply_rotation(frame_rgb, rot):
    if rot is None:
        return frame_rgb
    return cv2.rotate(frame_rgb, rot)


def unconvert_coords(ix, iy, rot):
    """
    Reconvertit les coords iris dans l'espace de la frame originale
    après rotation `rot`.
    """
    if rot == cv2.ROTATE_90_CLOCKWISE:
        return iy, 1.0 - ix
    elif rot == cv2.ROTATE_90_COUNTERCLOCKWISE:
        return 1.0 - iy, ix
    elif rot == cv2.ROTATE_180:
        return 1.0 - ix, 1.0 - iy
    return ix, iy   # None → pas de changement


def get_iris(frame, use_rotation):
    """
    Détecte les iris avec une rotation FIXE.
    use_rotation : constante OpenCV (ou None).
    Retourne (ix, iy) normalisés [0-1] dans l'espace frame originale, ou None.
    """
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    rotated = apply_rotation(rgb, use_rotation)
    result = face_mesh.process(rotated)

    if not result.multi_face_landmarks:
        return None

    lm = np.array([(l.x, l.y) for l in result.multi_face_landmarks[0].landmark])

    # Bounding box du visage
    x_min, x_max = lm[:, 0].min(), lm[:, 0].max()
    y_min, y_max = lm[:, 1].min(), lm[:, 1].max()
    face_w = x_max - x_min
    face_h = y_max - y_min

    left_iris  = lm[[474, 475, 476, 477]].mean(axis=0)
    right_iris = lm[[469, 470, 471, 472]].mean(axis=0)
    iris_center = (left_iris + right_iris) / 2.0

    # FIX CLEF : coords iris RELATIVES au visage (0=bord gauche, 1=bord droit)
    # Ça neutralise les mouvements de tête et ne garde que le mouvement des yeux
    if face_w > 0.01 and face_h > 0.01:
        ix_rel = (iris_center[0] - x_min) / face_w
        iy_rel = (iris_center[1] - y_min) / face_h
    else:
        ix_rel = iris_center[0]
        iy_rel = iris_center[1]

    logger.info(f"  iris_rel=({ix_rel:.3f},{iy_rel:.3f})")

    # Appliquer la correction de rotation sur les coords relatives
    ix_rel, iy_rel = unconvert_coords(float(ix_rel), float(iy_rel), use_rotation)
    return float(ix_rel), float(iy_rel)


def find_best_rotation(frame):
    """
    Appelé UNE SEULE FOIS pendant la calibration pour trouver la bonne rotation.
    Essaie toutes les rotations et retourne celle qui détecte un visage.
    """
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    # None en premier : si le visage est détecté sans rotation, on s'arrête
    rotations = [
        None,
        cv2.ROTATE_90_CLOCKWISE,
        cv2.ROTATE_90_COUNTERCLOCKWISE,
        cv2.ROTATE_180,
    ]
    for rot in rotations:
        candidate = apply_rotation(rgb, rot)
        r = face_mesh.process(candidate)
        if r.multi_face_landmarks:
            logger.info(f"Rotation trouvée : {rot}")
            return rot
    return None


def compute_calibration_matrix():
    global calibration_matrix
    if len(calibration_points) < 4:
        return False

    from collections import defaultdict
    groups = defaultdict(list)
    for sx, sy, ix, iy in calibration_points:
        groups[(sx, sy)].append((ix, iy))

    if len(groups) < 4:
        logger.warning(f"Seulement {len(groups)} points uniques, calibration insuffisante")
        return False

    src, dst = [], []
    for (sx, sy), pts in groups.items():
        avg_ix = np.mean([p[0] for p in pts])
        avg_iy = np.mean([p[1] for p in pts])
        src.append([avg_ix, avg_iy])
        dst.append([sx / screen_width, sy / screen_height])

    src = np.array(src, dtype=np.float64)
    dst = np.array(dst, dtype=np.float64)

    src_var = src.var(axis=0)
    logger.info(f"Variance iris : x={src_var[0]:.6f}, y={src_var[1]:.6f}")
    if src_var[0] < 1e-6 or src_var[1] < 1e-6:
        logger.error("Variance iris trop faible → calibration invalide")
        return False

    # Régression linéaire avec centrage des features pour plus de stabilité
    ones  = np.ones((len(src), 1), dtype=np.float64)
    src_h = np.hstack([src, ones])   # [ix, iy, 1]
    M, residuals, _, _ = np.linalg.lstsq(src_h, dst, rcond=None)
    calibration_matrix = M
    logger.info(f"Calibration linéaire OK — {len(groups)} points, résidus={residuals}")
    logger.info(f"Matrice:\n{M}")
    return True


def iris_to_normalized(ix, iy):
    """Retourne (nx, ny) normalisés [0-1] pour Flutter."""
    if calibration_matrix is not None:
        v   = np.array([ix, iy, 1.0], dtype=np.float64)
        res = v @ calibration_matrix
        nx  = float(np.clip(res[0], 0.0, 1.0))
        ny  = float(np.clip(res[1], 0.0, 1.0))
        return nx, ny
    else:
        # Fallback sans calibration — plage typique des iris en paysage
        X_MIN, X_MAX = 0.45, 0.75
        Y_MIN, Y_MAX = 0.40, 0.70
        nx = float(np.clip((ix - X_MIN) / (X_MAX - X_MIN), 0.0, 1.0))
        ny = float(np.clip((iy - Y_MIN) / (Y_MAX - Y_MIN), 0.0, 1.0))
        return nx, ny


# ── Socket events ─────────────────────────────────────────────────────────────

@socketio.on('connect')
def on_connect():
    logger.info("Client connecté")

@socketio.on('disconnect')
def on_disconnect():
    global _rotation_locked, _gaze_smooth_x, _gaze_smooth_y
    logger.info("Client déconnecté")
    _rotation_locked = False
    _gaze_smooth_x = None
    _gaze_smooth_y = None
    _iris_history.clear()

@socketio.on('screen_size')
def on_screen_size(data):
    global screen_width, screen_height, sensor_orientation, _fixed_rotation
    screen_width       = int(data.get('width',  1280))
    screen_height      = int(data.get('height', 720))
    sensor_orientation = int(data.get('sensor_orientation', 270))
    # Pré-calculer la rotation à partir de l'orientation déclarée
    _fixed_rotation    = rotation_for_orientation(sensor_orientation)
    logger.info(f"Écran : {screen_width}x{screen_height} | capteur : {sensor_orientation}° → rotation={_fixed_rotation}")


# ── Calibration ───────────────────────────────────────────────────────────────

@socketio.on('calibration_start')
def on_calibration_start():
    global calibration_points, calibration_matrix, current_calib_screen
    global _fixed_rotation, _rotation_locked
    calibration_points   = []
    calibration_matrix   = None
    current_calib_screen = None
    _rotation_locked     = False
    _iris_history.clear()
    _gaze_smooth_x = None
    _gaze_smooth_y = None
    # Réinitialiser la rotation selon l'orientation capteur connue
    _fixed_rotation = rotation_for_orientation(sensor_orientation)
    logger.info(f"Calibration démarrée | rotation initiale={_fixed_rotation}")
    emit('calibration_ready')

@socketio.on('calibration_point')
def on_calibration_point(data):
    global current_calib_screen
    current_calib_screen = (int(data['screen_x']), int(data['screen_y']))
    logger.info(f"Point cible : {current_calib_screen}")
    emit('calibration_point_ack')

@socketio.on('calibration_frame')
def on_calibration_frame(data):
    global _fixed_rotation, _rotation_locked

    if current_calib_screen is None:
        emit('calibration_frame_result', {'success': False, 'reason': 'no_point'})
        return

    frame = decode_frame(data)
    if frame is None:
        emit('calibration_frame_result', {'success': False, 'reason': 'decode_error'})
        return

    # Première frame de calibration : trouver et verrouiller la rotation
    if not _rotation_locked:
        found = find_best_rotation(frame)

        # Verrouiller quelle que soit la valeur (None = pas de rotation = valide)
        _fixed_rotation  = found  # peut être None, c'est OK
        _rotation_locked = True
        logger.info(f"Rotation verrouillée : {_fixed_rotation}")

    iris = get_iris(frame, _fixed_rotation)
    if iris is None:
        emit('calibration_frame_result', {'success': False, 'reason': 'no_face'})
        return

    ix, iy = iris
    sx, sy = current_calib_screen
    calibration_points.append((sx, sy, ix, iy))
    logger.info(f"Calib : écran=({sx},{sy}) iris=({ix:.4f},{iy:.4f})")
    emit('calibration_frame_result', {'success': True})

@socketio.on('calibration_finish')
def on_calibration_finish():
    ok = compute_calibration_matrix()
    emit('calibration_done', {
        'success': ok,
        'points':  len(calibration_points),
    })
    if not ok:
        logger.error("Calibration échouée — relancer la calibration")


# ── Tracking ──────────────────────────────────────────────────────────────────

@socketio.on('handle_frame')
def on_handle_frame(data):
    global _iris_history, _gaze_smooth_x, _gaze_smooth_y
    try:
        frame = decode_frame(data)
        if frame is None:
            emit('error', {'message': 'decode_error'})
            return

        # Utiliser la rotation verrouillée (ou celle déduite de sensor_orientation)
        iris = get_iris(frame, _fixed_rotation)
        if iris is None:
            emit('error', {'message': 'Failed to detect eyes'})
            return

        ix, iy = iris

        # Filtre anti-pic : rejeter les frames avec un saut iris trop grand
        global _iris_history
        if len(_iris_history) >= 2:
            recent_ix = np.mean([h[0] for h in _iris_history[-3:]])
            recent_iy = np.mean([h[1] for h in _iris_history[-3:]])
            jump = abs(ix - recent_ix) + abs(iy - recent_iy)
            if jump > MAX_JUMP:
                logger.info(f"Frame rejetée (saut={jump:.3f} > {MAX_JUMP})")
                # On réémet la dernière valeur lissée sans changer l'état
                if _gaze_smooth_x is not None:
                    emit('gaze_data', {
                        'gaze_left_x':  _gaze_smooth_x,
                        'gaze_left_y':  _gaze_smooth_y,
                        'gaze_right_x': _gaze_smooth_x,
                        'gaze_right_y': _gaze_smooth_y,
                    })
                return

        _iris_history.append((ix, iy))
        if len(_iris_history) > HISTORY_SIZE:
            _iris_history.pop(0)

        nx, ny = iris_to_normalized(ix, iy)

        # Lissage exponentiel pour stabiliser le curseur
        if _gaze_smooth_x is None:
            _gaze_smooth_x, _gaze_smooth_y = nx, ny
        else:
            _gaze_smooth_x = SMOOTH_ALPHA * nx + (1 - SMOOTH_ALPHA) * _gaze_smooth_x
            _gaze_smooth_y = SMOOTH_ALPHA * ny + (1 - SMOOTH_ALPHA) * _gaze_smooth_y

        logger.info(f"iris=({ix:.3f},{iy:.3f}) → norm=({nx:.3f},{ny:.3f}) → smooth=({_gaze_smooth_x:.3f},{_gaze_smooth_y:.3f})")

        emit('gaze_data', {
            'gaze_left_x':  _gaze_smooth_x,
            'gaze_left_y':  _gaze_smooth_y,
            'gaze_right_x': _gaze_smooth_x,
            'gaze_right_y': _gaze_smooth_y,
        })

    except Exception as e:
        logger.error(f"handle_frame error : {e}")
        emit('error', {'message': str(e)})


@app.route('/')
def home():
    return jsonify({'message': 'Eye tracking server running'})

if __name__ == '__main__':
    import eventlet
    socketio.run(app, debug=False, host='0.0.0.0', port=5000)