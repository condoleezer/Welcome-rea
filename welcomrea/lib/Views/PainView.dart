import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
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

  // Coordonnées normalisées [0-1] reçues du serveur
  double _gazeNormX = 0.0;
  double _gazeNormY = 0.0;

  CameraController? _controller;
  DateTime lastErrorTime = DateTime.now();
  Timer? _frameTimer;

  double screenWidth = 0.0;
  double screenHeight = 0.0;

  // Coordonnées en pixels écran (pour affichage et hit-test)
  double averageX = 0.0;
  double averageY = 0.0;

  // Orientation du capteur caméra (récupérée depuis CameraDescription)
  int _sensorOrientation = 0;

  // FIX : flag pour envoyer screen_size seulement quand socket ET dimensions sont prêts
  bool _screenSizeSent = false;

  final List<GlobalKey<EmptyWidgetState>> _emptyWidgetKeys = [];
  final List<GlobalKey<_ImageWidgetState>> _imageWidgetKeys = [];
  Timer? _gazeTimer;
  GlobalKey<State<StatefulWidget>>? _hoveredWidgetKey;

  @override
  void initState() {
    super.initState();
    _connectToServer();
    for (int i = 0; i < 70; i++) _emptyWidgetKeys.add(GlobalKey<EmptyWidgetState>());
    for (int i = 0; i < 20; i++) _imageWidgetKeys.add(GlobalKey<_ImageWidgetState>());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        screenWidth  = MediaQuery.of(context).size.width;
        screenHeight = MediaQuery.of(context).size.height;
      });
      // Essayer d'envoyer, mais le socket n'est peut-être pas prêt
      _trySendScreenSize();
    });
  }

  // FIX : envoie screen_size + sensor_orientation de façon sécurisée
  void _trySendScreenSize() {
    if (_screenSizeSent) return;
    if (socket == null || !socket!.connected) return;
    if (screenWidth == 0 || screenHeight == 0) return;

    socket!.emit('screen_size', {
      'width':  screenWidth,
      'height': screenHeight,
      // FIX : on envoie l'orientation capteur pour que Python corrige la rotation
      'sensor_orientation': _sensorOrientation,
    });
    _screenSizeSent = true;
    print('screen_size envoyé : ${screenWidth}x${screenHeight}, capteur : $_sensorOrientation°');
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) { print("Pas de caméra !"); return; }

    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras[0],
    );

    // FIX : récupérer l'orientation du capteur pour la transmettre au serveur
    _sensorOrientation = frontCamera.sensorOrientation;
    print('Caméra : ${frontCamera.name} | sensorOrientation = $_sensorOrientation°');

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,  // Meilleure précision iris
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller!.initialize();
      // Re-envoyer screen_size maintenant qu'on connaît l'orientation capteur
      _screenSizeSent = false;
      _trySendScreenSize();
    } catch (e) {
      print("Erreur init caméra : $e");
    }
  }

  Future<void> _initializeEyeTracking() async {
    try {
      await _initializeCamera();
      _startCapturingAndSending();
    } catch (e) {
      print('Erreur init eye tracking : $e');
    }
  }

  Future<void> _connectToServer() async {
    socket = IO.io('http://10.77.248.16:5000', <String, dynamic>{
      'transports':          ['websocket'],
      'autoConnect':         true,
      'reconnection':        true,
      'reconnectionDelay':   1000,
      'reconnectionAttempts': 999,
    });

    socket!.connect();

    socket!.on('connect', (_) {
      print('Connecté au serveur');
      // FIX : envoyer screen_size dès la connexion établie
      _screenSizeSent = false;
      _trySendScreenSize();

      if (_isTracking && (_controller == null || !_controller!.value.isInitialized)) {
        _initializeEyeTracking();
      }
    });

    socket!.on('gaze_data',  (data) => _handleGazeData(data));
    socket!.on('error',      (data) {
      final msg = data['message'] ?? '';
      if (msg == 'Failed to detect eyes') _handleEyeDetectionError();
    });
    socket!.on('disconnect', (_) => print('Déconnecté — reconnexion...'));
  }

  void _handleEyeDetectionError() {
    final now = DateTime.now();
    if (now.difference(lastErrorTime).inSeconds >= 20) {
      lastErrorTime = now;
      _showErrorDialog();
    }
  }

  void _showErrorDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erreur'),
        content: const Text('Les yeux ne sont pas détectés. Ajustez votre position ou l\'éclairage.'),
        actions: [
          TextButton(child: const Text('OK'), onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  void _startCapturingAndSending() {
    _frameTimer?.cancel();

    if (kIsWeb) {
      setState(() => _isTracking = true);
      _simulateGazeData();
      return;
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      print("Contrôleur caméra non initialisé.");
      return;
    }

    if (!_controller!.value.isStreamingImages) {
      _controller!.startImageStream((CameraImage image) {
        if (_frameTimer == null || !_frameTimer!.isActive) {
          _sendFrameToServer(image);
          _frameTimer = Timer(const Duration(milliseconds: 500), () {});
        }
      });
    }

    setState(() => _isTracking = true);
  }

  void _simulateGazeData() {
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isTracking) { timer.cancel(); return; }
      final rng = Random();
      // Simulation avec coordonnées normalisées [0-1]
      _handleGazeData({
        'gaze_left_x':  rng.nextDouble(),
        'gaze_left_y':  rng.nextDouble(),
        'gaze_right_x': rng.nextDouble(),
        'gaze_right_y': rng.nextDouble(),
      });
    });
  }

  // Lissage Flutter côté affichage
  static const double _flutterAlpha = 0.6;  // plus réactif

  // FIX PRINCIPAL : le serveur envoie du normalisé [0-1]
  // On convertit en pixels écran ici
  void _handleGazeData(dynamic data) {
    if (!mounted) return;

    final double normLeftX  = (data['gaze_left_x']  as num?)?.toDouble() ?? 0.0;
    final double normLeftY  = (data['gaze_left_y']  as num?)?.toDouble() ?? 0.0;
    final double normRightX = (data['gaze_right_x'] as num?)?.toDouble() ?? 0.0;
    final double normRightY = (data['gaze_right_y'] as num?)?.toDouble() ?? 0.0;

    final double normAvgX = (normLeftX + normRightX) / 2.0;
    final double normAvgY = (normLeftY + normRightY) / 2.0;

    // Cible en pixels écran
    final double targetX = normAvgX * screenWidth;
    final double targetY = normAvgY * screenHeight;

    setState(() {
      _gazeNormX = normAvgX;
      _gazeNormY = normAvgY;

      // Lissage exponentiel côté Flutter pour un curseur plus fluide
      if (averageX == 0.0 && averageY == 0.0) {
        averageX = targetX;
        averageY = targetY;
      } else {
        averageX = _flutterAlpha * targetX + (1 - _flutterAlpha) * averageX;
        averageY = _flutterAlpha * targetY + (1 - _flutterAlpha) * averageY;
      }

      _checkGazeOnWidgets(averageX, averageY);
    });

    print('Gaze normalisé=(${normAvgX.toStringAsFixed(3)}, ${normAvgY.toStringAsFixed(3)}) '
          '→ écran=(${averageX.toInt()}, ${averageY.toInt()})');
  }

  // Tolérance hit-test : agrandit virtuellement chaque widget de N pixels
  static const double _hitTolerance = 40.0;

  void _checkGazeOnWidgets(double x, double y) {
    final List<GlobalKey<State<StatefulWidget>>> allKeys = [
      ..._emptyWidgetKeys.cast<GlobalKey<State<StatefulWidget>>>(),
      ..._imageWidgetKeys.cast<GlobalKey<State<StatefulWidget>>>(),
    ];
    bool found = false;

    for (final key in allKeys) {
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox;
      final pos = box.localToGlobal(Offset.zero);
      final sz  = box.size;

      if (x >= pos.dx - _hitTolerance &&
          x <= pos.dx + sz.width  + _hitTolerance &&
          y >= pos.dy - _hitTolerance &&
          y <= pos.dy + sz.height + _hitTolerance) {
        if (_hoveredWidgetKey != key) _startGazeTimer(key);
        found = true;
        break;
      }
    }

    if (!found) _resetGazeTimer();
  }

  void _startGazeTimer(GlobalKey<State<StatefulWidget>> key) {
    _resetGazeTimer();
    setState(() => _hoveredWidgetKey = key);
    _gazeTimer = Timer(const Duration(seconds: 3), () {
      final st = key.currentState;
      if (st is _ImageWidgetState)  st.toggleSelection();
      else if (st is EmptyWidgetState) st.toggleSelection();
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
      print('Frame envoyée : ${bytes.length} bytes');
      // On envoie les bytes directement (decode_frame côté Python accepte ça)
      socket!.emit('handle_frame', bytes);
    } catch (e) {
      print('Erreur envoi frame : $e');
    }
  }

  Future<Uint8List> _convertImageToBytes(CameraImage image) async {
    final w = image.width;
    final h = image.height;
    final yPlane = image.planes[0].bytes;
    final bpr    = image.planes[0].bytesPerRow;
    final grayscale = img.Image(width: w, height: h, numChannels: 1);
    for (int y = 0; y < h; y++) {
      final rowOffset = y * bpr;
      for (int x = 0; x < w; x++) {
        grayscale.setPixelR(x, y, yPlane[rowOffset + x]);
      }
    }
    return Uint8List.fromList(img.encodeJpg(grayscale, quality: 40));
  }

  
  void _stopEyeTracking() {
    setState(() {
      _isTracking = false;
      averageX = 0.0;
      averageY = 0.0;
      _gazeNormX = 0.0;
      _gazeNormY = 0.0;
    });
    _stopCamera();
  }

  Future<void> _stopCamera() async {
    if (_controller != null) {
      if (_controller!.value.isStreamingImages) await _controller!.stopImageStream();
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
    final size = MediaQuery.of(context).size;
    const double tablet = 500;

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Center(child: Text('DOULEURS', style: TextStyle(fontSize: 30))),
        backgroundColor: Colors.green.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => SizedBox(
                height: 300, width: 300,
                child: AlertDialog(
                  alignment: Alignment.bottomRight,
                  content: const RecordWidget(),
                  actions: [TextButton(child: const Text('Fermer'), onPressed: () => Navigator.of(context).pop())],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Calibration',
            onPressed: () async {
              await _initializeCamera();
              if (_controller == null || !_controller!.value.isInitialized) return;
              if (!mounted) return;
              await Navigator.push(context, MaterialPageRoute(
                builder: (_) => CalibrationView(
                  socket: socket!,
                  cameraController: _controller!,
                  onCalibrationDone: () => Navigator.pop(context),
                ),
              ));
            },
          ),
          IconButton(
            icon: Icon(_isTracking ? Icons.remove_red_eye : Icons.remove_red_eye_outlined),
            tooltip: _isTracking ? 'Tracking actif' : 'Activer tracking',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Eye Tracking'),
                content: const Text('Voulez-vous activer ou désactiver le eye tracking?'),
                actions: [
                  TextButton(
                    child: const Text('Désactiver'),
                    onPressed: () { _stopEyeTracking(); Navigator.of(context).pop(); },
                  ),
                  TextButton(
                    child: const Text('Activer'),
                    onPressed: () async { Navigator.of(context).pop(); await _initializeEyeTracking(); },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: size.width * 0.9,
          height: size.height * 0.9,
          child: Stack(
            children: [
              ListView(
                children: [
                  _sectionHeader('Avez-vous mal?'),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: 80,
                      child: FittedBox(
                        child: Wrap(direction: Axis.horizontal, spacing: 50, children: [
                          ImageWidget(key: _imageWidgetKeys[0], imagePath: 'images/Pain/PousseV.png', height: 60, width: 60, circle: true),
                          ImageWidget(key: _imageWidgetKeys[1], imagePath: 'images/Pain/Pousse.png',  height: 60, width: 60, circle: true),
                          ImageWidget(key: _imageWidgetKeys[2], imagePath: 'images/Pain/Pinterro.png',height: 60, width: 60, circle: true),
                        ]),
                      ),
                    ),
                  ),
                  _sectionHeader('Où?'),
                  SizedBox(
                    height: (size.width <= tablet) ? size.height * 0.3 : 500,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView(scrollDirection: Axis.horizontal, children: [
                        Stack(children: [
                          Image.asset('images/Pain/ManDos.png', width: (size.width <= tablet) ? 200 : 500, height: 500),
                          Positioned(top: 60,  left: 182, child: EmptyWidget(key: _emptyWidgetKeys[0],  width: 50,  height: 50)),
                          Positioned(top: 120, left: 160, child: EmptyWidget(key: _emptyWidgetKeys[1],  width: 100, height: 50)),
                          Positioned(top: 172, left: 264, child: EmptyWidget(key: _emptyWidgetKeys[2],  width: 30,  height: 30)),
                          Positioned(top: 172, left: 122, child: EmptyWidget(key: _emptyWidgetKeys[3],  width: 30,  height: 30)),
                          Positioned(top: 210, left: 160, child: EmptyWidget(key: _emptyWidgetKeys[4],  width: 100, height: 20)),
                          Positioned(top: 240, left: 160, child: EmptyWidget(key: _emptyWidgetKeys[5],  width: 100, height: 30)),
                          Positioned(top: 394, left: 212, child: EmptyWidget(key: _emptyWidgetKeys[6],  width: 30,  height: 30)),
                          Positioned(top: 394, left: 174, child: EmptyWidget(key: _emptyWidgetKeys[7],  width: 30,  height: 30)),
                          Positioned(top: 448, left: 208, child: EmptyWidget(key: _emptyWidgetKeys[8],  width: 24,  height: 24)),
                          Positioned(top: 448, left: 182, child: EmptyWidget(key: _emptyWidgetKeys[9],  width: 24,  height: 24)),
                          Positioned(top: 454, left: 160, child: EmptyWidget(key: _emptyWidgetKeys[10], width: 20,  height: 20)),
                          Positioned(top: 455, left: 235, child: EmptyWidget(key: _emptyWidgetKeys[11], width: 20,  height: 20)),
                        ]),
                        Stack(children: [
                          Image.asset('images/Pain/ManFace.jpg', width: (size.width <= tablet) ? 200 : 500, height: 500),
                          Positioned(top: 58,  left: 222, child: EmptyWidget(key: _emptyWidgetKeys[12], width: 100, height: 30)),
                          Positioned(top: 160, left: 257, child: EmptyWidget(key: _emptyWidgetKeys[13], width: 30,  height: 20)),
                          Positioned(top: 174, left: 217, child: EmptyWidget(key: _emptyWidgetKeys[14], width: 30,  height: 20)),
                          Positioned(top: 174, left: 302, child: EmptyWidget(key: _emptyWidgetKeys[15], width: 30,  height: 20)),
                          Positioned(top: 202, left: 214, child: EmptyWidget(key: _emptyWidgetKeys[16], width: 25,  height: 30)),
                          Positioned(top: 202, left: 306, child: EmptyWidget(key: _emptyWidgetKeys[17], width: 25,  height: 30)),
                          Positioned(top: 244, left: 210, child: EmptyWidget(key: _emptyWidgetKeys[18], width: 25,  height: 25)),
                          Positioned(top: 244, left: 311, child: EmptyWidget(key: _emptyWidgetKeys[19], width: 25,  height: 25)),
                          Positioned(top: 274, left: 208, child: EmptyWidget(key: _emptyWidgetKeys[20], width: 20,  height: 20)),
                          Positioned(top: 274, left: 318, child: EmptyWidget(key: _emptyWidgetKeys[21], width: 20,  height: 20)),
                          Positioned(top: 298, left: 208, child: EmptyWidget(key: _emptyWidgetKeys[22], width: 24,  height: 28)),
                          Positioned(top: 304, left: 316, child: EmptyWidget(key: _emptyWidgetKeys[23], width: 26,  height: 27)),
                          Positioned(top: 347, left: 285, child: EmptyWidget(key: _emptyWidgetKeys[24], width: 26,  height: 28)),
                          Positioned(top: 320, left: 240, child: EmptyWidget(key: _emptyWidgetKeys[25], width: 28,  height: 32)),
                          Positioned(top: 370, left: 240, child: EmptyWidget(key: _emptyWidgetKeys[26], width: 26,  height: 28)),
                          Positioned(top: 408, left: 242, child: EmptyWidget(key: _emptyWidgetKeys[27], width: 24,  height: 22)),
                          Positioned(top: 408, left: 289, child: EmptyWidget(key: _emptyWidgetKeys[28], width: 24,  height: 22)),
                          Positioned(top: 438, left: 218, child: EmptyWidget(key: _emptyWidgetKeys[29], width: 36,  height: 22)),
                          Positioned(top: 438, left: 298, child: EmptyWidget(key: _emptyWidgetKeys[30], width: 36,  height: 22)),
                          Positioned(top: 184, left: 250, child: EmptyWidget(key: _emptyWidgetKeys[31], width: 50,  height: 30)),
                          Positioned(top: 234, left: 242, child: EmptyWidget(key: _emptyWidgetKeys[32], width: 60,  height: 30)),
                        ]),
                      ]),
                    ),
                  ),
                  SizedBox(
                    height: (size.width <= tablet) ? size.height * 0.4 : 300,
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Stack(children: [
                            Image.asset('images/Pain/ManProfil.jpg', height: 200, width: 300),
                            Positioned(top: 28,  left: 102, child: EmptyWidget(key: _emptyWidgetKeys[33], width: 120, height: 30)),
                            Positioned(top: 60,  left: 114, child: EmptyWidget(key: _emptyWidgetKeys[34], width: 100, height: 28)),
                            Positioned(top: 94,  left: 120, child: EmptyWidget(key: _emptyWidgetKeys[35], width: 40,  height: 24)),
                            Positioned(top: 94,  left: 172, child: EmptyWidget(key: _emptyWidgetKeys[36], width: 40,  height: 24)),
                            Positioned(top: 120, left: 150, child: EmptyWidget(key: _emptyWidgetKeys[37], width: 30,  height: 18)),
                            Positioned(top: 128, left: 190, child: EmptyWidget(key: _emptyWidgetKeys[38], width: 30,  height: 26)),
                            Positioned(top: 128, left: 110, child: EmptyWidget(key: _emptyWidgetKeys[39], width: 30,  height: 26)),
                            Positioned(top: 140, left: 146, child: EmptyWidget(key: _emptyWidgetKeys[40], width: 38,  height: 18)),
                            Positioned(top: 170, left: 146, child: EmptyWidget(key: _emptyWidgetKeys[41], width: 36,  height: 20)),
                            Positioned(top: 186, left: 106, child: EmptyWidget(key: _emptyWidgetKeys[42], width: 36,  height: 20)),
                            Positioned(top: 186, left: 190, child: EmptyWidget(key: _emptyWidgetKeys[43], width: 36,  height: 20)),
                            Positioned(top: 94,  left: 98,  child: EmptyWidget(key: _emptyWidgetKeys[44], width: 20,  height: 36)),
                            Positioned(top: 94,  left: 214, child: EmptyWidget(key: _emptyWidgetKeys[45], width: 20,  height: 36)),
                          ]),
                        ]),
                      ),
                    ),
                  ),
                  _sectionHeader('Quel type de douleurs?'),
                  SizedBox(
                    height: 500,
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Column(children: [
                            ImageWidget(key: _imageWidgetKeys[4], imagePath: 'images/Pain/P1.jpg', height: 250, width: 250),
                            const Text('ça pique', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 40),
                            ImageWidget(key: _imageWidgetKeys[5], imagePath: 'images/Pain/P3.jpg', height: 250, width: 250),
                            const Text('ça gratte / ça démange', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(width: 300, height: 300),
                          Column(children: [
                            ImageWidget(key: _imageWidgetKeys[6], imagePath: 'images/Pain/P6.png', height: 250, width: 250),
                            const Text('Comme un coup de poignard', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 40),
                            ImageWidget(key: _imageWidgetKeys[7], imagePath: 'images/Pain/P4.png', height: 250, width: 250),
                            const Text('Fourmillements', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(width: 300, height: 300),
                          Column(children: [
                            ImageWidget(key: _imageWidgetKeys[8], imagePath: 'images/Pain/P5.jpg', height: 250, width: 250),
                            const Text('ça brûle', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 40),
                            ImageWidget(key: _imageWidgetKeys[9], imagePath: 'images/Pain/P2.png', height: 250, width: 250),
                            const Text('Oppression / Qui serre', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                          ]),
                        ]),
                      ),
                    ),
                  ),
                  _sectionHeader('A quelle échelle?'),
                  SizedBox(
                    height: (size.width <= tablet) ? size.height * 0.3 : 200,
                    child: FittedBox(
                      child: Row(children: [
                        Stack(children: [
                          Image.asset('images/Pain/ladder.jpg', height: 200, width: 300),
                          Positioned(top: 50, left: 8,   child: EmptyWidget(key: _emptyWidgetKeys[46], width: 50, height: 50)),
                          Positioned(top: 50, left: 54,  child: EmptyWidget(key: _emptyWidgetKeys[47], width: 50, height: 50)),
                          Positioned(top: 50, left: 100, child: EmptyWidget(key: _emptyWidgetKeys[48], width: 50, height: 50)),
                          Positioned(top: 50, left: 148, child: EmptyWidget(key: _emptyWidgetKeys[49], width: 50, height: 50)),
                          Positioned(top: 50, left: 195, child: EmptyWidget(key: _emptyWidgetKeys[50], width: 50, height: 50)),
                          Positioned(top: 50, left: 240, child: EmptyWidget(key: _emptyWidgetKeys[51], width: 50, height: 50)),
                          Positioned(top: 130, left: 13,  child: EmptyWidget(key: _emptyWidgetKeys[52], width: 20, height: 50)),
                          Positioned(top: 130, left: 36,  child: EmptyWidget(key: _emptyWidgetKeys[53], width: 20, height: 50)),
                          Positioned(top: 130, left: 59,  child: EmptyWidget(key: _emptyWidgetKeys[54], width: 20, height: 50)),
                          Positioned(top: 130, left: 83,  child: EmptyWidget(key: _emptyWidgetKeys[55], width: 20, height: 50)),
                          Positioned(top: 130, left: 106, child: EmptyWidget(key: _emptyWidgetKeys[56], width: 20, height: 50)),
                          Positioned(top: 130, left: 129, child: EmptyWidget(key: _emptyWidgetKeys[57], width: 20, height: 50)),
                          Positioned(top: 130, left: 153, child: EmptyWidget(key: _emptyWidgetKeys[58], width: 20, height: 50)),
                          Positioned(top: 130, left: 176, child: EmptyWidget(key: _emptyWidgetKeys[59], width: 20, height: 50)),
                          Positioned(top: 130, left: 200, child: EmptyWidget(key: _emptyWidgetKeys[60], width: 20, height: 50)),
                          Positioned(top: 130, left: 223, child: EmptyWidget(key: _emptyWidgetKeys[61], width: 20, height: 50)),
                          Positioned(top: 130, left: 247, child: EmptyWidget(key: _emptyWidgetKeys[63], width: 20, height: 50)),
                        ]),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

              // ── Curseur de regard ──────────────────────────────────────────
              // FIX : averageX/Y sont déjà en pixels écran, on les utilise directement
              if (_isTracking)
                Positioned(
                  left: averageX - 25,
                  top:  averageY - 25,
                  child: IgnorePointer(
                    child: Container(
                      width: 50, height: 50,
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

              // ── Badge de statut ────────────────────────────────────────────
              Positioned(
                bottom: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (_isTracking ? Colors.green : Colors.grey).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      _isTracking ? Icons.fiber_manual_record : Icons.stop_circle,
                      color: Colors.white, size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isTracking
                          ? 'Tracking (${averageX.toInt()}, ${averageY.toInt()})  norm=(${_gazeNormX.toStringAsFixed(2)}, ${_gazeNormY.toStringAsFixed(2)})'
                          : 'Tracking inactif',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) => Container(
    margin: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.green.shade900, borderRadius: BorderRadius.circular(15)),
    child: Padding(
      padding: const EdgeInsets.all(10.0),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold))),
    ),
  );
}

// ── ImageWidget ────────────────────────────────────────────────────────────────

class ImageWidget extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;
  final bool circle;

  const ImageWidget({Key? key, required this.imagePath, this.width = 50, this.height = 50, this.circle = false})
      : super(key: key);

  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  bool isPressed = false;

  void select()          => setState(() => isPressed = true);
  void deselect()        => setState(() => isPressed = false);
  void toggleSelection() => isPressed ? deselect() : select();

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: toggleSelection,
    child: Container(
      width: widget.width, height: widget.height,
      decoration: BoxDecoration(
        border: isPressed
            ? Border.all(color: Colors.deepPurple, width: 3)
            : Border.all(color: Colors.transparent),
        shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
        image: DecorationImage(image: AssetImage(widget.imagePath)),
      ),
    ),
  );
}