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

class _CalibrationViewState extends State<CalibrationView> {
  // 5 points : coins + centre
  final List<Offset> _relativePoints = const [
    Offset(0.1, 0.1),   // haut-gauche
    Offset(0.9, 0.1),   // haut-droite
    Offset(0.5, 0.5),   // centre
    Offset(0.1, 0.9),   // bas-gauche
    Offset(0.9, 0.9),   // bas-droite
  ];

  int _currentIndex = 0;
  bool _collecting = false;
  bool _done = false;
  int _framesCollected = 0;
  static const int _framesPerPoint = 15;
  Timer? _collectTimer;
  String _status = 'Regarde le point rouge et reste immobile';
  
  // Buffer pour la dernière frame du stream
  Uint8List? _lastFrameBytes;

  @override
  void initState() {
    super.initState();
    _startImageStream();
    _startCalibration();
  }

  void _startImageStream() {
    // Démarrer le stream pour avoir des frames fraîches
    if (!widget.cameraController.value.isStreamingImages) {
      widget.cameraController.startImageStream((CameraImage image) {
        // Convertir et garder la dernière frame en buffer
        _convertAndBuffer(image);
      });
    }
  }

  void _convertAndBuffer(CameraImage image) async {
    try {
      img.Image converted;
      if (image.format.group == ImageFormatGroup.yuv420) {
        converted = _convertYUV420(image);
      } else {
        converted = img.Image.fromBytes(
          width: image.width,
          height: image.height,
          bytes: image.planes[0].bytes.buffer,
          format: img.Format.uint8,
        );
      }
      _lastFrameBytes = Uint8List.fromList(img.encodeJpg(converted, quality: 80));
    } catch (_) {}
  }

  img.Image _convertYUV420(CameraImage image) {
    final result = img.Image(width: image.width, height: image.height);
    for (int x = 0; x < image.width; x++) {
      for (int y = 0; y < image.height; y++) {
        final uvIndex = (y ~/ 2) * (image.width ~/ 2) + (x ~/ 2);
        final index = y * image.width + x;
        final Y = image.planes[0].bytes[index];
        final U = image.planes[1].bytes[uvIndex];
        final V = image.planes[2].bytes[uvIndex];
        final r = (Y + 1.13983 * (V - 128)).round().clamp(0, 255);
        final g = (Y - 0.39465 * (U - 128) - 0.58060 * (V - 128)).round().clamp(0, 255);
        final b = (Y + 2.03211 * (U - 128)).round().clamp(0, 255);
        result.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return result;
  }

  void _startCalibration() {
    widget.socket.emit('calibration_start');
    widget.socket.once('calibration_ready', (_) {
      _showNextPoint();
    });
  }

  void _showNextPoint() {
    if (_currentIndex >= _relativePoints.length) {
      _finishCalibration();
      return;
    }
    setState(() {
      _collecting = false;
      _framesCollected = 0;
      _status = 'Regarde le point rouge et reste immobile';
    });

    // Attendre 1.5s que l'utilisateur fixe le point, puis collecter
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _collectFramesForPoint();
    });
  }

  void _collectFramesForPoint() {
    final size = MediaQuery.of(context).size;
    final pt = _relativePoints[_currentIndex];
    final sx = (pt.dx * size.width).toInt();
    final sy = (pt.dy * size.height).toInt();

    widget.socket.emit('calibration_point', {'screen_x': sx, 'screen_y': sy});

    setState(() {
      _collecting = true;
      _status = 'Collecte en cours...';
    });

    _collectTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
      if (_framesCollected >= _framesPerPoint) {
        timer.cancel();
        setState(() {
          _currentIndex++;
          _collecting = false;
        });
        await Future.delayed(const Duration(milliseconds: 500));
        _showNextPoint();
        return;
      }
      _sendCalibrationFrame();
    });
  }

  void _sendCalibrationFrame() {
    final bytes = _lastFrameBytes;
    if (bytes == null) return; // pas encore de frame disponible
    widget.socket.emit('calibration_frame', bytes);
    widget.socket.once('calibration_frame_result', (data) {
      if (data['success'] == true) {
        if (mounted) setState(() => _framesCollected++);
      }
    });
  }

  void _finishCalibration() {
    widget.socket.emit('calibration_finish');
    widget.socket.once('calibration_done', (data) {
      setState(() {
        _done = true;
        _status = data['success'] == true
            ? 'Calibration réussie ! (${data['points']} points)'
            : 'Calibration incomplète';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) widget.onCalibrationDone();
      });
    });
  }

  @override
  void dispose() {
    _collectTimer?.cancel();
    // Arrêter le stream pour libérer la caméra pour PainView
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
          // Instructions
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _status,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _done ? '' : 'Point ${_currentIndex + 1} / ${_relativePoints.length}',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),

          // Point de calibration actuel
          if (!_done && _currentIndex < _relativePoints.length)
            Positioned(
              left: _relativePoints[_currentIndex].dx * size.width - 20,
              top:  _relativePoints[_currentIndex].dy * size.height - 20,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _collecting ? 30 : 40,
                height: _collecting ? 30 : 40,
                decoration: BoxDecoration(
                  color: _collecting ? Colors.orange : Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),

          // Terminé
          if (_done)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 80),
                  const SizedBox(height: 20),
                  Text(
                    _status,
                    style: const TextStyle(color: Colors.white, fontSize: 22),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
