import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class CalibrationView extends StatefulWidget {
  final IO.Socket socket;
  final CameraController cameraController;
  final VoidCallback onCalibrationDone;

  const CalibrationView({
    Key? key,
    required this.socket,
    required this.cameraController,
    required this.onCalibrationDone,
  }) : super(key: key);

  @override
  State<CalibrationView> createState() => _CalibrationViewState();
}

class _CalibrationViewState extends State<CalibrationView>
    with SingleTickerProviderStateMixin {
  final List<Offset> _relativePoints = const [
    Offset(0.1, 0.1),   // haut-gauche
    Offset(0.5, 0.1),   // haut-centre
    Offset(0.9, 0.1),   // haut-droite
    Offset(0.1, 0.5),   // milieu-gauche
    Offset(0.5, 0.5),   // centre
    Offset(0.9, 0.5),   // milieu-droite
    Offset(0.1, 0.9),   // bas-gauche
    Offset(0.5, 0.9),   // bas-centre
    Offset(0.9, 0.9),   // bas-droite
  ];

  int    _currentIndex    = 0;
  // FIX : on commence en phase "fixe" (rouge), pas en collecte
  bool   _collecting      = false;
  bool   _done            = false;
  int    _framesCollected = 0;
  static const int _framesPerPoint = 20;  // plus de frames = moyenne plus stable
  Timer? _collectTimer;
  String _status = 'Regarde le point rouge et reste immobile';

  Uint8List? _lastFrameBytes;

  // Animation pulse pour le point
  late AnimationController _pulseController;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startImageStream();
    _startCalibration();
  }

  DateTime _lastFrameTime = DateTime.fromMillisecondsSinceEpoch(0);

  void _startImageStream() {
    if (!widget.cameraController.value.isStreamingImages) {
      widget.cameraController.startImageStream((CameraImage image) {
        // Throttle : max 1 frame/seconde pour éviter OutOfMemoryError
        final now = DateTime.now();
        if (now.difference(_lastFrameTime).inMilliseconds < 900) return;
        _lastFrameTime = now;
        _convertAndBuffer(image);
      });
    }
  }

  void _convertAndBuffer(CameraImage image) async {
    try {
      // Utiliser directement le plan Y (luminance) sans passer par img.Image
      // pour éviter OutOfMemoryError sur les tablettes avec peu de RAM
      final w = image.width;
      final h = image.height;
      final yPlane = image.planes[0].bytes;

      // Construire une image JPEG via img en niveaux de gris de façon optimisée
      final grayscale = img.Image(width: w, height: h, numChannels: 1);
      final pixelData = grayscale.data;
      if (pixelData != null) {
        int i = 0;
        for (int y = 0; y < h; y++) {
          for (int x = 0; x < w; x++) {
            grayscale.setPixelR(x, y, yPlane[i++]);
          }
        }
      }
      _lastFrameBytes = Uint8List.fromList(img.encodeJpg(grayscale, quality: 40));
    } catch (_) {}
  }

  void _startCalibration() {
    widget.socket.emit('calibration_start');
    widget.socket.once('calibration_ready', (_) {
      if (mounted) _showNextPoint();
    });
  }

  void _showNextPoint() {
    if (!mounted) return;
    if (_currentIndex >= _relativePoints.length) {
      _finishCalibration();
      return;
    }
    // FIX : phase rouge = on regarde, pas encore en collecte
    setState(() {
      _collecting      = false;
      _framesCollected = 0;
      _status = 'Regarde le point rouge et reste immobile\n'
                'Point ${_currentIndex + 1} / ${_relativePoints.length}';
    });

    // Attendre que le stream soit actif ET que l'utilisateur fixe le point
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      // Vérifier que des frames arrivent bien
      if (_lastFrameBytes == null) {
        // Stream pas encore actif, réessayer dans 1s
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) _collectFramesForPoint();
        });
      } else {
        _collectFramesForPoint();
      }
    });
  }

  void _collectFramesForPoint() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final pt   = _relativePoints[_currentIndex];
    final sx   = (pt.dx * size.width).toInt();
    final sy   = (pt.dy * size.height).toInt();

    widget.socket.emit('calibration_point', {'screen_x': sx, 'screen_y': sy});

    // FIX : passe en orange = collecte en cours
    setState(() {
      _collecting = true;
      _status = 'Collecte en cours… ne bouge pas 👁️\n'
                'Point ${_currentIndex + 1} / ${_relativePoints.length}';
    });

    _collectTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
      if (!mounted) { timer.cancel(); return; }
      if (_framesCollected >= _framesPerPoint) {
        timer.cancel();
        if (!mounted) return;
        setState(() {
          _currentIndex++;
          _collecting = false;
        });
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) _showNextPoint();
        return;
      }
      _sendCalibrationFrame();
    });
  }

  void _sendCalibrationFrame() {
    final bytes = _lastFrameBytes;
    if (bytes == null) {
      // Pas encore de frame dispo, on incrémente quand même pour ne pas bloquer
      return;
    }
    widget.socket.emit('calibration_frame', bytes);
    // FIX : on écoute une seule fois mais on comptabilise localement
    // sans attendre la réponse pour ne pas bloquer la progression
    setState(() => _framesCollected++);
    // On écoute quand même la réponse pour les erreurs critiques
    widget.socket.once('calibration_frame_result', (data) {
      if (!mounted) return;
      if (data['success'] == false && data['reason'] == 'decode_error') {
        // Frame corrompue : décrémenter
        if (mounted) setState(() => _framesCollected = (_framesCollected - 1).clamp(0, _framesPerPoint));
      }
    });
  }

  void _finishCalibration() {
    if (!mounted) return;
    widget.socket.emit('calibration_finish');
    widget.socket.once('calibration_done', (data) {
      if (!mounted) return;
      setState(() {
        _done   = true;
        _status = data['success'] == true
            ? '✅ Calibration réussie !\n(${data['points']} frames collectées)'
            : '⚠️ Calibration incomplète\nRelancez depuis le bouton calibration';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) widget.onCalibrationDone();
      });
    });
  }

  @override
  void dispose() {
    _collectTimer?.cancel();
    _pulseController.dispose();
    if (widget.cameraController.value.isStreamingImages) {
      widget.cameraController.stopImageStream();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fond avec croix de guidage légères
          CustomPaint(
            size: size,
            painter: _GridPainter(),
          ),

          // Instructions en haut
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Barre de progression
          if (!_done)
            Positioned(
              bottom: 40,
              left: 40,
              right: 40,
              child: Column(
                children: [
                  Text(
                    _collecting
                        ? 'Frames : $_framesCollected / $_framesPerPoint'
                        : 'Fixez le point…',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _collecting
                        ? _framesCollected / _framesPerPoint
                        : 0.0,
                    backgroundColor: Colors.grey.shade800,
                    color: Colors.orange,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ),

          // Point de calibration animé
          // FIX : rouge = fixe le point, orange = collecte en cours
          if (!_done && _currentIndex < _relativePoints.length)
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) {
                final pt   = _relativePoints[_currentIndex];
                final cx   = pt.dx * size.width;
                final cy   = pt.dy * size.height;
                // Taille : grand et rouge pendant la fixation, plus petit et orange pendant la collecte
                final baseSize = _collecting ? 28.0 : 40.0;
                final dotSize  = _collecting ? baseSize : baseSize * _pulseAnim.value;

                return Positioned(
                  left: cx - dotSize / 2,
                  top:  cy - dotSize / 2,
                  child: Container(
                    width:  dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      // FIX : rouge pendant la fixation, orange pendant la collecte
                      color: _collecting ? Colors.orange : Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: (_collecting ? Colors.orange : Colors.red)
                              .withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Écran de succès
          if (_done)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 100),
                  const SizedBox(height: 24),
                  Text(
                    _status,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Dessine une grille légère pour aider à fixer le regard
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    // Lignes horizontales et verticales tous les 10%
    for (int i = 1; i < 10; i++) {
      final x = size.width * i / 10;
      final y = size.height * i / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}