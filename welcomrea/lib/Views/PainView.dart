import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../components/empty_widget.dart';
import '../components/record_widget.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'CalibrationView.dart';

class PainView extends StatefulWidget {
  const PainView({Key? key}) : super(key: key);

  @override
  State<PainView> createState() => _PainViewState();
}

class _PainViewState extends State<PainView> {
  IO.Socket? socket;
  bool _isTracking = false;

  // FIX #1 : On garde les coordonnées brutes reçues du serveur
  double _gazeLeftX = 0.0;
  double _gazeLeftY = 0.0;
  double _gazeRightX = 0.0;
  double _gazeRightY = 0.0;

  CameraController? _controller;
  bool showErrorDialog = false;
  DateTime lastErrorTime = DateTime.now();
  Timer? _frameTimer;

  double screenWidth = 0.0;
  double screenHeight = 0.0;

  // FIX #2 : Coordonnées moyennes finales (en pixels écran)
  double averageX = 0.0;
  double averageY = 0.0;

  // Le serveur envoie directement des coordonnées en pixels écran (après calibration)
  bool _serverSendsNormalized = false;

  // Non utilisé car le serveur envoie déjà des coords écran directement
  final double _cameraWidth = 1.0;
  final double _cameraHeight = 1.0;

  final List<GlobalKey<EmptyWidgetState>> _emptyWidgetKeys = [];
  final List<GlobalKey<_ImageWidgetState>> _imageWidgetKeys = [];
  Timer? _gazeTimer;
  GlobalKey? _hoveredWidgetKey;

  // FIX #4 : Flag pour envoyer la taille écran seulement quand le socket est prêt
  bool _screenSizeSent = false;

  @override
  void initState() {
    super.initState();
    _connectToServer();

    for (int i = 0; i < 70; i++) {
      _emptyWidgetKeys.add(GlobalKey<EmptyWidgetState>());
    }
    for (int i = 0; i < 20; i++) {
      _imageWidgetKeys.add(GlobalKey<_ImageWidgetState>());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        screenWidth = MediaQuery.of(context).size.width;
        screenHeight = MediaQuery.of(context).size.height;
      });
      // On essaie d'envoyer la taille, mais seulement si déjà connecté
      _trySendScreenSize();
    });
  }

  // FIX #4 : Méthode sécurisée pour envoyer la taille écran
  void _trySendScreenSize() {
    if (_screenSizeSent) return;
    if (socket == null || !socket!.connected) return;
    if (screenWidth == 0 || screenHeight == 0) return;

    // Récupérer l'orientation du capteur caméra
    final sensorOrientation = _controller?.description.sensorOrientation ?? 0;

    socket!.emit('screen_size', {
      'width': screenWidth,
      'height': screenHeight,
      'sensor_orientation': sensorOrientation,
    });
    _screenSizeSent = true;
    print("Screen size sent: ${screenWidth}x${screenHeight}, sensor: ${sensorOrientation}°");
  }

  Future<void> _initializeEyeTracking() async {
    try {
      await _initializeCamera();
      _startCapturingAndSending();
    } catch (e) {
      print('Error initializing eye tracking: $e');
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      print("No cameras available!");
      return;
    }

    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras[0],
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      // FIX #5 : Désactiver la correction automatique d'orientation
      // pour que les frames soient envoyées dans leur orientation native
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller!.initialize();
      print("Camera initialized: ${frontCamera.name}");
      print("Camera sensor orientation: ${frontCamera.sensorOrientation}°");
      // Renvoyer la taille écran avec l'orientation maintenant qu'on la connaît
      _screenSizeSent = false;
      _trySendScreenSize();
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> _connectToServer() async {
    socket = IO.io('http://10.77.248.6:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionAttempts': 999,
    });

    socket!.connect();

    socket!.on('connect', (_) {
      print('Connected to server');
      // FIX #4 : Envoyer la taille écran dès la connexion établie
      _screenSizeSent = false; // Reset pour renvoyer après reconnexion
      _trySendScreenSize();

      if (_isTracking &&
          (_controller == null || !_controller!.value.isInitialized)) {
        _initializeEyeTracking();
      }
    });

    socket!.on('gaze_data', (data) => _handleGazeData(data));

    socket!.on('error', (data) {
      print('Error received: ${data['message']}');
      if (data['message'] == 'Failed to detect eyes') {
        _handleEyeDetectionError();
      }
    });

    socket!.on('disconnect', (_) {
      print('Disconnected from server - reconnecting...');
    });
  }

  void _handleEyeDetectionError() {
    final currentTime = DateTime.now();
    if (currentTime.difference(lastErrorTime).inSeconds >= 20) {
      lastErrorTime = currentTime;
      _showErrorDialog();
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Erreur'),
          content: Text(
              'Les yeux ne sont pas détectés. Ajustez votre position ou l\'éclairage.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _startCapturingAndSending() {
    _frameTimer?.cancel();

    if (kIsWeb) {
      setState(() {
        _isTracking = true;
        print("Web tracking started - simulation mode");
      });
      _simulateGazeData();
      return;
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      print("Erreur: Le contrôleur de la caméra n'est pas initialisé.");
      return;
    }

    if (!_controller!.value.isStreamingImages) {
      _controller!.startImageStream((CameraImage image) {
        if (_frameTimer == null || !_frameTimer!.isActive) {
          _sendFrameToServer(image);
          _frameTimer = Timer(Duration(milliseconds: 500), () {});
        }
      });
    }

    setState(() {
      _isTracking = true;
      print("Tracking started");
    });
  }

  void _simulateGazeData() {
    Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (!_isTracking) {
        timer.cancel();
        return;
      }
      final random = Random();
      final x = random.nextDouble() * screenWidth;
      final y = random.nextDouble() * screenHeight;
      _handleGazeData({
        'gaze_left_x': x,
        'gaze_left_y': y,
        'gaze_right_x': x,
        'gaze_right_y': y,
      });
    });
  }

  // FIX #1 : Conversion correcte des coordonnées reçues → pixels écran
  void _handleGazeData(dynamic data) {
    if (!mounted) return;

    double rawLeftX = data['gaze_left_x']?.toDouble() ?? 0.0;
    double rawLeftY = data['gaze_left_y']?.toDouble() ?? 0.0;
    double rawRightX = data['gaze_right_x']?.toDouble() ?? 0.0;
    double rawRightY = data['gaze_right_y']?.toDouble() ?? 0.0;

    double screenLeftX, screenLeftY, screenRightX, screenRightY;

    if (_serverSendsNormalized) {
      // Le serveur envoie 0.0–1.0 → on multiplie par la taille écran
      screenLeftX = rawLeftX * screenWidth;
      screenLeftY = rawLeftY * screenHeight;
      screenRightX = rawRightX * screenWidth;
      screenRightY = rawRightY * screenHeight;
    } else {
      // Le serveur envoie déjà des pixels écran directement
      screenLeftX = rawLeftX;
      screenLeftY = rawLeftY;
      screenRightX = rawRightX;
      screenRightY = rawRightY;
    }

    setState(() {
      _gazeLeftX = screenLeftX;
      _gazeLeftY = screenLeftY;
      _gazeRightX = screenRightX;
      _gazeRightY = screenRightY;

      averageX = (_gazeLeftX + _gazeRightX) / 2;
      averageY = (_gazeLeftY + _gazeRightY) / 2;

      _checkGazeOnWidgets(averageX, averageY);
    });

    print(
        'Gaze écran: (${averageX.toInt()}, ${averageY.toInt()}) | Écran: ${screenWidth.toInt()}x${screenHeight.toInt()}');
  }

  void _checkGazeOnWidgets(double x, double y) {
    List<GlobalKey> allKeys = [];
    allKeys.addAll(_emptyWidgetKeys);
    allKeys.addAll(_imageWidgetKeys);
    bool found = false;

    for (var key in allKeys) {
      final context = key.currentContext;
      if (context != null) {
        final renderBox = context.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        if (x >= position.dx &&
            x <= position.dx + size.width &&
            y >= position.dy &&
            y <= position.dy + size.height) {
          if (_hoveredWidgetKey != key) {
            _startGazeTimer(key);
          }
          found = true;
          break;
        }
      }
    }

    if (!found) {
      _resetGazeTimer();
    }
  }

  void _startGazeTimer(GlobalKey key) {
    _resetGazeTimer();
    setState(() {
      _hoveredWidgetKey = key;
    });

    _gazeTimer = Timer(Duration(seconds: 5), () {
      if (key.currentState != null) {
        if (key.currentState is _ImageWidgetState) {
          (key.currentState as _ImageWidgetState).toggleSelection();
        } else if (key.currentState is EmptyWidgetState) {
          (key.currentState as EmptyWidgetState).toggleSelection();
        }
      }
    });
  }

  void _resetGazeTimer() {
    _gazeTimer?.cancel();
    _gazeTimer = null;
    _hoveredWidgetKey = null;
  }

  void _sendFrameToServer(CameraImage image) async {
    if (!_isTracking) return;
    try {
      final bytes = await _convertImageToBytes(image);
      print("Sending frame: ${bytes.length} bytes");
      // Envoyer les bytes directement, pas un dict
      socket!.emit('handle_frame', bytes);
    } catch (e) {
      print('Error sending frame: $e');
    }
  }

  Future<Uint8List> _convertImageToBytes(CameraImage image) async {
    try {
      img.Image capturedImage;

      if (image.format.group == ImageFormatGroup.yuv420) {
        capturedImage = _convertYUV420(image);
      } else {
        capturedImage = img.Image.fromBytes(
          width: image.width,
          height: image.height,
          bytes: image.planes[0].bytes.buffer,
          format: img.Format.uint8,
        );
      }

      return Uint8List.fromList(img.encodeJpg(capturedImage, quality: 80));
    } catch (e) {
      print('Error converting image to bytes: $e');
      rethrow;
    }
  }

  img.Image _convertYUV420(CameraImage image) {
    img.Image imgResult =
        img.Image(width: image.width, height: image.height);

    for (int x = 0; x < image.width; x++) {
      for (int y = 0; y < image.height; y++) {
        final int uvIndex =
            (y ~/ 2) * (image.width ~/ 2) + (x ~/ 2);
        final int index = y * image.width + x;

        final int Y = image.planes[0].bytes[index];
        final int U = image.planes[1].bytes[uvIndex];
        final int V = image.planes[2].bytes[uvIndex];

        int r = (Y + 1.13983 * (V - 128)).round().clamp(0, 255);
        int g = (Y - 0.39465 * (U - 128) - 0.58060 * (V - 128))
            .round()
            .clamp(0, 255);
        int b = (Y + 2.03211 * (U - 128)).round().clamp(0, 255);

        imgResult.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return imgResult;
  }

  void _stopEyeTracking() {
    setState(() {
      _isTracking = false;
      averageX = 0.0;
      averageY = 0.0;
    });
    _stopCamera();
    print("Eye tracking stopped");
  }

  Future<void> _stopCamera() async {
    if (_controller != null) {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
      await _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _gazeTimer?.cancel();
    _stopCamera();
    socket?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    const double tablet = 500;

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Center(
          child: Text(
            'DOULEURS',
            style: TextStyle(fontSize: 30),
          ),
        ),
        backgroundColor: Colors.green.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () {
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return SizedBox(
                    height: 300,
                    width: 300,
                    child: AlertDialog(
                      alignment: Alignment.bottomRight,
                      content: const RecordWidget(),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Fermer'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Calibration',
            onPressed: () async {
              await _initializeCamera();
              if (_controller == null ||
                  !_controller!.value.isInitialized) return;
              if (!mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CalibrationView(
                    socket: socket!,
                    cameraController: _controller!,
                    onCalibrationDone: () => Navigator.pop(context),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isTracking
                  ? Icons.remove_red_eye
                  : Icons.remove_red_eye_outlined,
              // FIX #6 : Icône change selon l'état actif/inactif
            ),
            tooltip: _isTracking ? 'Tracking actif' : 'Activer le tracking',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Eye Tracking'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                            'Voulez-vous activer ou désactiver le eye tracking?')
                      ],
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Désactiver'),
                        onPressed: () {
                          _stopEyeTracking();
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text('Activer'),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _initializeEyeTracking();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: SizedBox(
              width: size.width * 0.9,
              height: size.height * 0.9,
              child: Stack(
                children: [
                  ListView(
                children: [
                  Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade900,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Text(
                            'Avez-vous mal?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: 80,
                      child: FittedBox(
                        child: Wrap(
                          direction: Axis.horizontal,
                          spacing: 50,
                          children: [
                            ImageWidget(
                              key: _imageWidgetKeys[0],
                              imagePath: 'images/Pain/PousseV.png',
                              height: 60,
                              width: 60,
                              circle: true,
                            ),
                            ImageWidget(
                              key: _imageWidgetKeys[1],
                              imagePath: 'images/Pain/Pousse.png',
                              height: 60,
                              width: 60,
                              circle: true,
                            ),
                            ImageWidget(
                              key: _imageWidgetKeys[2],
                              imagePath: 'images/Pain/Pinterro.png',
                              height: 60,
                              width: 60,
                              circle: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade900,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Text(
                            'Où?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: (size.width <= tablet) ? size.height * 0.3 : 500,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Stack(
                            children: [
                              Image.asset('images/Pain/ManDos.png',
                                  width:
                                      (size.width <= tablet) ? 200 : 500,
                                  height: 500),
                              Positioned(top: 60, left: 182, child: EmptyWidget(key: _emptyWidgetKeys[0], width: 50, height: 50)),
                              Positioned(top: 120, left: 160, child: EmptyWidget(key: _emptyWidgetKeys[1], width: 100, height: 50)),
                              Positioned(top: 172, left: 264, child: EmptyWidget(key: _emptyWidgetKeys[2], width: 30, height: 30)),
                              Positioned(top: 172, left: 122, child: EmptyWidget(key: _emptyWidgetKeys[3], width: 30, height: 30)),
                              Positioned(top: 210, left: 160, child: EmptyWidget(key: _emptyWidgetKeys[4], width: 100, height: 20)),
                              Positioned(top: 240, left: 160, child: EmptyWidget(key: _emptyWidgetKeys[5], width: 100, height: 30)),
                              Positioned(top: 394, left: 212, child: EmptyWidget(key: _emptyWidgetKeys[6], width: 30, height: 30)),
                              Positioned(top: 394, left: 174, child: EmptyWidget(key: _emptyWidgetKeys[7], width: 30, height: 30)),
                              Positioned(top: 448, left: 208, child: EmptyWidget(key: _emptyWidgetKeys[8], width: 24, height: 24)),
                              Positioned(top: 448, left: 182, child: EmptyWidget(key: _emptyWidgetKeys[9], width: 24, height: 24)),
                              Positioned(top: 454, left: 160, child: EmptyWidget(key: _emptyWidgetKeys[10], width: 20, height: 20)),
                              Positioned(top: 455, left: 235, child: EmptyWidget(key: _emptyWidgetKeys[11], width: 20, height: 20)),
                            ],
                          ),
                          Stack(
                            children: [
                              Image.asset('images/Pain/ManFace.jpg',
                                  width:
                                      (size.width <= tablet) ? 200 : 500,
                                  height: 500),
                              Positioned(top: 58, left: 222, child: EmptyWidget(key: _emptyWidgetKeys[12], width: 100, height: 30)),
                              Positioned(top: 160, left: 257, child: EmptyWidget(key: _emptyWidgetKeys[13], width: 30, height: 20)),
                              Positioned(top: 174, left: 217, child: EmptyWidget(key: _emptyWidgetKeys[14], width: 30, height: 20)),
                              Positioned(top: 174, left: 302, child: EmptyWidget(key: _emptyWidgetKeys[15], width: 30, height: 20)),
                              Positioned(top: 202, left: 214, child: EmptyWidget(key: _emptyWidgetKeys[16], width: 25, height: 30)),
                              Positioned(top: 202, left: 306, child: EmptyWidget(key: _emptyWidgetKeys[17], width: 25, height: 30)),
                              Positioned(top: 244, left: 210, child: EmptyWidget(key: _emptyWidgetKeys[18], width: 25, height: 25)),
                              Positioned(top: 244, left: 311, child: EmptyWidget(key: _emptyWidgetKeys[19], width: 25, height: 25)),
                              Positioned(top: 274, left: 208, child: EmptyWidget(key: _emptyWidgetKeys[20], width: 20, height: 20)),
                              Positioned(top: 274, left: 318, child: EmptyWidget(key: _emptyWidgetKeys[21], width: 20, height: 20)),
                              Positioned(top: 298, left: 208, child: EmptyWidget(key: _emptyWidgetKeys[22], width: 24, height: 28)),
                              Positioned(top: 304, left: 316, child: EmptyWidget(key: _emptyWidgetKeys[23], width: 26, height: 27)),
                              Positioned(top: 347, left: 285, child: EmptyWidget(key: _emptyWidgetKeys[24], width: 26, height: 28)),
                              Positioned(top: 320, left: 240, child: EmptyWidget(key: _emptyWidgetKeys[25], width: 28, height: 32)),
                              Positioned(top: 370, left: 240, child: EmptyWidget(key: _emptyWidgetKeys[26], width: 26, height: 28)),
                              Positioned(top: 408, left: 242, child: EmptyWidget(key: _emptyWidgetKeys[27], width: 24, height: 22)),
                              Positioned(top: 408, left: 289, child: EmptyWidget(key: _emptyWidgetKeys[28], width: 24, height: 22)),
                              Positioned(top: 438, left: 218, child: EmptyWidget(key: _emptyWidgetKeys[29], width: 36, height: 22)),
                              Positioned(top: 438, left: 298, child: EmptyWidget(key: _emptyWidgetKeys[30], width: 36, height: 22)),
                              Positioned(top: 184, left: 250, child: EmptyWidget(key: _emptyWidgetKeys[31], width: 50, height: 30)),
                              Positioned(top: 234, left: 242, child: EmptyWidget(key: _emptyWidgetKeys[32], width: 60, height: 30)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: (size.width <= tablet) ? size.height * 0.4 : 300,
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              children: [
                                Image.asset('images/Pain/ManProfil.jpg',
                                    height: 200, width: 300),
                                Positioned(top: 28, left: 102, child: EmptyWidget(key: _emptyWidgetKeys[33], width: 120, height: 30)),
                                Positioned(top: 60, left: 114, child: EmptyWidget(key: _emptyWidgetKeys[34], width: 100, height: 28)),
                                Positioned(top: 94, left: 120, child: EmptyWidget(key: _emptyWidgetKeys[35], width: 40, height: 24)),
                                Positioned(top: 94, left: 172, child: EmptyWidget(key: _emptyWidgetKeys[36], width: 40, height: 24)),
                                Positioned(top: 120, left: 150, child: EmptyWidget(key: _emptyWidgetKeys[37], width: 30, height: 18)),
                                Positioned(top: 128, left: 190, child: EmptyWidget(key: _emptyWidgetKeys[38], width: 30, height: 26)),
                                Positioned(top: 128, left: 110, child: EmptyWidget(key: _emptyWidgetKeys[39], width: 30, height: 26)),
                                Positioned(top: 140, left: 146, child: EmptyWidget(key: _emptyWidgetKeys[40], width: 38, height: 18)),
                                Positioned(top: 170, left: 146, child: EmptyWidget(key: _emptyWidgetKeys[41], width: 36, height: 20)),
                                Positioned(top: 186, left: 106, child: EmptyWidget(key: _emptyWidgetKeys[42], width: 36, height: 20)),
                                Positioned(top: 186, left: 190, child: EmptyWidget(key: _emptyWidgetKeys[43], width: 36, height: 20)),
                                Positioned(top: 94, left: 98, child: EmptyWidget(key: _emptyWidgetKeys[44], width: 20, height: 36)),
                                Positioned(top: 94, left: 214, child: EmptyWidget(key: _emptyWidgetKeys[45], width: 20, height: 36)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade900,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Text(
                            'Quel type de douleurs?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 500,
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    ImageWidget(key: _imageWidgetKeys[4], imagePath: 'images/Pain/P1.jpg', height: 250, width: 250),
                                    const Text('ça pique', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 40),
                                    ImageWidget(key: _imageWidgetKeys[5], imagePath: 'images/Pain/P3.jpg', height: 250, width: 250),
                                    const Text('ça gratte / ça démange', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(width: 300, height: 300),
                                Column(
                                  children: [
                                    ImageWidget(key: _imageWidgetKeys[6], imagePath: 'images/Pain/P6.png', height: 250, width: 250),
                                    const Text('Comme un coup de poignard', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 40),
                                    ImageWidget(key: _imageWidgetKeys[7], imagePath: 'images/Pain/P4.png', height: 250, width: 250),
                                    const Text('Fourmillements', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(width: 300, height: 300),
                                Column(
                                  children: [
                                    ImageWidget(key: _imageWidgetKeys[8], imagePath: 'images/Pain/P5.jpg', height: 250, width: 250),
                                    const Text('ça brûle', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 40),
                                    ImageWidget(key: _imageWidgetKeys[9], imagePath: 'images/Pain/P2.png', height: 250, width: 250),
                                    const Text('Oppression / Qui serre', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade900,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Text(
                            'A quelle échelle?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: (size.width <= tablet) ? size.height * 0.3 : 200,
                    child: FittedBox(
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Image.asset('images/Pain/ladder.jpg', height: 200, width: 300),
                              Positioned(top: 50, left: 8, child: EmptyWidget(key: _emptyWidgetKeys[46], width: 50, height: 50)),
                              Positioned(top: 50, left: 54, child: EmptyWidget(key: _emptyWidgetKeys[47], width: 50, height: 50)),
                              Positioned(top: 50, left: 100, child: EmptyWidget(key: _emptyWidgetKeys[48], width: 50, height: 50)),
                              Positioned(top: 50, left: 148, child: EmptyWidget(key: _emptyWidgetKeys[49], width: 50, height: 50)),
                              Positioned(top: 50, left: 195, child: EmptyWidget(key: _emptyWidgetKeys[50], width: 50, height: 50)),
                              Positioned(top: 50, left: 240, child: EmptyWidget(key: _emptyWidgetKeys[51], width: 50, height: 50)),
                              Positioned(top: 130, left: 13, child: EmptyWidget(key: _emptyWidgetKeys[52], width: 20, height: 50)),
                              Positioned(top: 130, left: 36, child: EmptyWidget(key: _emptyWidgetKeys[53], width: 20, height: 50)),
                              Positioned(top: 130, left: 59, child: EmptyWidget(key: _emptyWidgetKeys[54], width: 20, height: 50)),
                              Positioned(top: 130, left: 83, child: EmptyWidget(key: _emptyWidgetKeys[55], width: 20, height: 50)),
                              Positioned(top: 130, left: 106, child: EmptyWidget(key: _emptyWidgetKeys[56], width: 20, height: 50)),
                              Positioned(top: 130, left: 129, child: EmptyWidget(key: _emptyWidgetKeys[57], width: 20, height: 50)),
                              Positioned(top: 130, left: 153, child: EmptyWidget(key: _emptyWidgetKeys[58], width: 20, height: 50)),
                              Positioned(top: 130, left: 176, child: EmptyWidget(key: _emptyWidgetKeys[59], width: 20, height: 50)),
                              Positioned(top: 130, left: 200, child: EmptyWidget(key: _emptyWidgetKeys[60], width: 20, height: 50)),
                              Positioned(top: 130, left: 223, child: EmptyWidget(key: _emptyWidgetKeys[61], width: 20, height: 50)),
                              Positioned(top: 130, left: 247, child: EmptyWidget(key: _emptyWidgetKeys[63], width: 20, height: 50)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
          // Curseur de regard - par-dessus tout, dans le Stack extérieur
          if (_isTracking)
            Positioned(
              left: averageX.clamp(0, size.width - 50),
              top: averageY.clamp(0, size.height - 50),
              child: IgnorePointer(
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.remove_red_eye, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          // Debug overlay
          Positioned(
            top: 8,
            right: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Gaze: (${averageX.toInt()}, ${averageY.toInt()})\nÉcran: ${screenWidth.toInt()}x${screenHeight.toInt()}\nTracking: $_isTracking',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ImageWidget extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;
  final bool circle;

  const ImageWidget(
      {Key? key,
      required this.imagePath,
      this.width = 50,
      this.height = 50,
      this.circle = false})
      : super(key: key);

  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  bool isPressed = false;

  void select() => setState(() => isPressed = true);
  void deselect() => setState(() => isPressed = false);
  void toggleSelection() => isPressed ? deselect() : select();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggleSelection,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          border: isPressed
              ? Border.all(color: Colors.deepPurple, width: 3)
              : Border.all(color: Colors.transparent, width: 0),
          shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
          image: DecorationImage(
              image: AssetImage(widget.imagePath)),
        ),
      ),
    );
  }
}