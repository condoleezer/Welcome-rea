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
  final Future<CameraController> Function()? onRestartCamera;

  const CalibrationView({
    Key? key,
    required this.socket,
    required this.cameraController,
    required this.onCalibrationDone,
    this.onRestartCamera,
  }) : super(key: key);

  @override
  State<CalibrationView> createState() => _CalibrationViewState();
}

class _CalibrationViewState extends State<CalibrationView>
    with SingleTickerProviderStateMixin {
  final List<Offset> _relativePoints = const [
    // Grille 3x3 = 9 points, calibration rapide
    Offset(0.1, 0.1), Offset(0.5, 0.1), Offset(0.9, 0.1),
    Offset(0.1, 0.5), Offset(0.5, 0.5), Offset(0.9, 0.5),
    Offset(0.1, 0.9), Offset(0.5, 0.9), Offset(0.9, 0.9),
  ];

  int    _currentIndex    = 0;
  // FIX : on commence en phase "fixe" (rouge), pas en collecte
  bool   _collecting      = false;
  bool   _done            = false;
  bool   _calibSuccess    = false;
  int    _qualityPct      = 0;
  int    _framesCollected = 0;
  static const int _framesPerPoint = 8;  // réduit pour accélérer la calibration
  Timer? _collectTimer;
  String _status = 'Regarde le point rouge et reste immobile';

  Uint8List? _lastFrameBytes;
  bool _converting = false;
  DateTime _streamRestartTime = DateTime.fromMillisecondsSinceEpoch(0);
  late CameraController _activeController;

  // Animation pulse pour le point
  late AnimationController _pulseController;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _activeController = widget.cameraController;

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
    if (!_activeController.value.isStreamingImages) {
      _activeController.startImageStream((CameraImage image) {
        // Throttle : max ~2 frames/seconde
        final now = DateTime.now();
        if (now.difference(_lastFrameTime).inMilliseconds < 400) return;
        _convertAndBuffer(image);
      });
    }
  }

  void _convertAndBuffer(CameraImage image) async {
    if (_converting) return;
    // Ignorer les frames produites avant le dernier restart
    if (DateTime.now().isBefore(_streamRestartTime)) return;
    _converting = true;
    try {
      final w   = image.width;
      final h   = image.height;
      final bpr = image.planes[0].bytesPerRow; // IMPORTANT : tenir compte du padding
      final yPlane = image.planes[0].bytes;

      final grayscale = img.Image(width: w, height: h, numChannels: 1);
      for (int y = 0; y < h; y++) {
        final rowOffset = y * bpr;
        for (int x = 0; x < w; x++) {
          grayscale.setPixelR(x, y, yPlane[rowOffset + x]);
        }
      }
      _lastFrameBytes = Uint8List.fromList(img.encodeJpg(grayscale, quality: 40));
      _lastFrameTime  = DateTime.now(); // marquer quand la frame a été produite
    } catch (e) {
      debugPrint('Erreur conversion frame : $e');
    } finally {
      _converting = false;
    }
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
    Future.delayed(const Duration(milliseconds: 1500), () {
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

    _collectTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) async {
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
    setState(() => _framesCollected++);
    widget.socket.once('calibration_frame_result', (data) {
      if (!mounted) return;
      if (data['success'] == false) {
        final reason = data['reason'] ?? '';
        if (reason == 'decode_error' || reason == 'frozen_frame') {
          // Frame invalide : décrémenter pour ne pas compter cette frame
          if (mounted) setState(() => _framesCollected = (_framesCollected - 1).clamp(0, _framesPerPoint));
        }
      }
    });
  }

 void _finishCalibration() {
    if (!mounted) return;
    widget.socket.emit('calibration_finish');
    widget.socket.once('calibration_done', (data) {
      if (!mounted) return;
      final bool success = data['success'] == true;
      final int  quality = (data['quality'] ?? 0) as int;
      final String errMsg = (data['error_message'] ?? '') as String;

      setState(() {
        _done          = true;
        _calibSuccess  = success;
        _qualityPct    = quality;

        if (success) {
          String qualityLabel;
          if (quality >= 80) {
            qualityLabel = '🟢 Excellente ($quality%)';
          } else if (quality >= 60) {
            qualityLabel = '🟡 Correcte ($quality%)';
          } else {
            qualityLabel = '🔴 Faible ($quality%)';
          }
          _status = '✅ Calibration réussie !\nQualité : $qualityLabel\n(${data['points']} points collectés)';
        } else {
          _status = '❌ Calibration échouée\n$errMsg';
        }
      });

      if (success && quality >= 60) {
        // Bonne calibration → on continue automatiquement
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) widget.onCalibrationDone();
        });
      }
      // Si échec ou qualité faible → l'utilisateur choisit via les boutons
    });
  }

  void _restartCalibration() async {
    _collectTimer?.cancel();
    setState(() {
      _currentIndex    = 0;
      _collecting      = false;
      _done            = false;
      _calibSuccess    = false;
      _qualityPct      = 0;
      _framesCollected = 0;
      _status = 'Préparation… 📷';
      _lastFrameBytes  = null;
    });
    _converting = false;

    // Arrêter le stream
    if (_activeController.value.isStreamingImages) {
      await _activeController.stopImageStream();
    }

    // Attendre que la caméra se stabilise complètement
    await Future.delayed(const Duration(milliseconds: 1200));

    // Marquer le temps de restart — ignorer les frames produites avant
    _streamRestartTime = DateTime.now().add(const Duration(milliseconds: 800));

    // Redémarrer le stream
    _startImageStream();

    // Attendre que de vraies nouvelles frames arrivent
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) _startCalibration();
  }
  @override
  void dispose() {
    _collectTimer?.cancel();
    _pulseController.dispose();
    if (_activeController.value.isStreamingImages) {
      _activeController.stopImageStream();
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

          // Écran de fin
          if (_done)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _calibSuccess ? Icons.check_circle : Icons.error_outline,
                    color: _calibSuccess
                        ? (_qualityPct >= 80 ? Colors.green : Colors.orange)
                        : Colors.red,
                    size: 100,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _status,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Barre de qualité (uniquement si succès)
                  if (_calibSuccess) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _qualityPct / 100.0,
                              backgroundColor: Colors.grey.shade800,
                              color: _qualityPct >= 80
                                  ? Colors.green
                                  : _qualityPct >= 60
                                      ? Colors.orange
                                      : Colors.red,
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Qualité : $_qualityPct%',
                            style: TextStyle(
                              color: _qualityPct >= 80
                                  ? Colors.green
                                  : _qualityPct >= 60
                                      ? Colors.orange
                                      : Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _restartCalibration,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text('Recommencer',
                            style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                        ),
                      ),
                      if (_calibSuccess) ...[
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: widget.onCalibrationDone,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Continuer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _qualityPct >= 60
                                ? Colors.green
                                : Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Avertissement qualité faible
                  if (_calibSuccess && _qualityPct < 60) ...[
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        '⚠️ Qualité faible — recommencez en gardant la tête immobile',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
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