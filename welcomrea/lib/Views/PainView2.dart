import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/empty_widget.dart';
import '../components/record_widget.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class PainView extends StatefulWidget {
  const PainView({Key? key}) : super(key: key);

  @override
  State<PainView> createState() => _PainViewState();
}


class _PainViewState extends State<PainView> {
  IO.Socket? socket;
  bool _isTracking = false;
  double _gazeLeftX = 0.0;
  double _gazeLeftY = 0.0;
  double _gazeRightX = 0.0;
  double _gazeRightY = 0.0;
  CameraController? _controller;
  bool showErrorDialog = false;
  DateTime lastErrorTime = DateTime.now();
  Timer? _frameTimer;
  int _frameInterval = 100; // Intervalle en millisecondes (10 FPS)

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  Future<void> _initializeEyeTracking() async {
    try {
      await _initializeCamera();
      _startCapturingAndSending();
      /*_sendTestImage();*/
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
    _controller = CameraController(cameras[1], ResolutionPreset.medium);

    try {
      await _controller!.initialize();
      print("Camera initialized");
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> _connectToServer() async {
    socket = IO.io('http://localhost:5000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });
    socket!.connect();
    socket!.on('connect', (_) {
      print('Connected to server');
      // Test sending a simple message
      socket!.emit('test_message', 'Hello from Flutter');
    });
    socket!.on('gaze_data', (data) => _handleGazeData(data));
    socket!.on('error', (data) {
      print('Error received: ${data['message']}');
      if (data['message'] == 'Failed to detect eyes') {
        _handleEyeDetectionError();
      }
    });
    socket!.on('disconnect', (_) => print('Disconnected from server'));
  }

  void _handleEyeDetectionError() {
    final currentTime = DateTime.now();
    // Show the dialog only if at least 20 seconds have passed since the last error
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
          title: Text('Error'),
          content: Text('Failed to detect eyes. Please adjust your position or lighting.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _startCapturingAndSending() {
    _controller!.startImageStream((CameraImage image) {
      if (_frameTimer == null || !_frameTimer!.isActive) {
        _sendFrameToServer(image);
        _frameTimer = Timer(Duration(milliseconds: _frameInterval), () {});
      }
    });
    setState(() {
      _isTracking = true;
      print("Tracking started");
    });
  }

  void _handleGazeData(dynamic data) {
    setState(() {
      _gazeLeftX = data['gaze_left_x'] ?? 0.0;
      _gazeLeftY = data['gaze_left_y'] ?? 0.0;
      _gazeRightX = data['gaze_right_x'] ?? 0.0;
      _gazeRightY = data['gaze_right_y'] ?? 0.0;
    });
  }
  /*void _sendTestImage() async {
    final ByteData data = await rootBundle.load('images/test.jpg');
    final Uint8List bytes = data.buffer.asUint8List();
    socket!.emit('handle_frame', bytes);
  }*/

  void _sendFrameToServer(CameraImage image) async {
    if (!_isTracking) return;
    try {
      final bytes = await _convertImageToBytes(image);
      print("Sending frame to server: ${bytes.length} bytes");
      socket!.emit('handle_frame', bytes);
    } catch (e) {
      print('Error sending frame: $e');
    }
  }

  Future<Uint8List> _convertImageToBytes(CameraImage image) async {
    try {
      img.Image capturedImage;
      print("Image format: ${image.format}");
      print("Image format group: ${image.format.group}");
      if (image.format.group == ImageFormatGroup.yuv420) {
        capturedImage = _convertYUV420(image);
      } else {
        capturedImage = img.Image.fromBytes(
          width: image.width,
          height: image.height,
          bytes: image.planes[0].bytes.buffer,
          format: img.Format.uint8,  // or whatever format you need
        );
      }
      print("Captured image width: ${capturedImage.width}, height: ${capturedImage.height}");
      return Uint8List.fromList(img.encodeJpg(capturedImage, quality: 80));
    } catch (e) {
      print('Error converting image to bytes: $e');
      rethrow;
    }
  }

  img.Image _convertYUV420(CameraImage image) {
    img.Image imgResult = img.Image(width: image.width, height: image.height);

    for (int x = 0; x < image.width; x++) {
      for (int y = 0; y < image.height; y++) {
        final int uvIndex = (y ~/ 2) * (image.width ~/ 2) + (x ~/ 2);
        final int index = y * image.width + x;

        // Y plane component
        final int Y = image.planes[0].bytes[index];
        // U plane component
        final int U = image.planes[1].bytes[uvIndex];
        // V plane component
        final int V = image.planes[2].bytes[uvIndex];

        // Calculate color
        int r = (Y + 1.13983 * (V - 128)).round().clamp(0, 255);
        int g = (Y - 0.39465 * (U - 128) - 0.58060 * (V - 128)).round().clamp(0, 255);
        int b = (Y + 2.03211 * (U - 128)).round().clamp(0, 255);
        int a = (Y + 2.03211 * (U - 128)).round().clamp(0, 255);

        imgResult.setPixelRgba(x, y, r, g, b, a);
      }
    }
    return imgResult;
  }

  void _stopEyeTracking() {
    setState(() {
      _isTracking = false;
    });
    _stopCamera();
    print("Eye tracking stopped");
  }

  Future<void> _stopCamera() async {
    if (_controller != null) {
      await _controller!.stopImageStream();
      await _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _stopEyeTracking();
    super.dispose();
  }




  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    const double tablet = 500;
    // Obtenir la taille de l'écran
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

// Ajuster les coordonnées si nécessaire (exemple : inversion des axes X)
    final double adjustedGazeLeftX = screenWidth - _gazeLeftX;
    final double adjustedGazeRightX = screenWidth - _gazeRightX;

// Calculer la position moyenne
    final double averageX = (adjustedGazeLeftX + adjustedGazeRightX) / 2;
    final double averageY = (_gazeLeftY + _gazeRightY) / 2;

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Center(
          child: Text(
            'DOULEURS',
            style: TextStyle(fontSize: 15),
          ),
        ),
        backgroundColor: Colors.green.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () {
              Future<void> showMyDialog() async {
                return showDialog<void>(
                  context: context,
                  barrierDismissible: false, // user must tap button!
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
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              }

              showMyDialog();
            },
          ),

          //Start Eye Tracking
          // IconButton to start Eye Tracking
          // Start Eye Tracking
          IconButton(
            icon: const Icon(Icons.remove_red_eye_outlined),
            onPressed: () {
              // Function to show the dialog for toggling eye tracking
              Future<void> showMyDialog() async {
                return showDialog<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Eye Tracking'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text('Voulez-vous activer ou désactiver le eye tracking?')
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
              }
              // Show the dialog
              showMyDialog();
            },
          )

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
                  // Bande verte avec la question "Avez-vous mal?"
                  Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade900,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Padding(
                      padding:  EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Text(
                            'Avez-vous mal?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Images pour la question "Avez-vous mal?"
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      height: 80,
                      child: FittedBox(
                        child: Wrap(
                          direction: Axis.horizontal,
                          spacing: 10,
                          //direction: (size.width <= tablet) ? Axis.vertical : Axis.horizontal,
                          children: [
                            ImageWidget(
                              imagePath: 'images/Pain/PousseV.png',
                              height: 60,
                              width: 60,
                              circle: true,
                            ),
                            ImageWidget(
                              imagePath: 'images/Pain/Pousse.png',
                              height: 60,
                              width: 60,
                              circle: true,
                            ),
                            ImageWidget(
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
                  // Bande verte avec la question "Où?"
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
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Images pour la question "Où?"
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
                                  width: (size.width <= tablet) ? 200 : 500,
                                  height: 500),
                              const Positioned(
                                  top: 60,
                                  left: 182,
                                  child: EmptyWidget(
                                    width: 50, height: 50,)
                              ),
                              const Positioned(
                                  top: 120,
                                  left: 160,
                                  child: EmptyWidget(
                                    width: 100, height: 50,)
                              ),

                              //Le coude
                              const Positioned(
                                  top: 172,
                                  left: 264,
                                  child: EmptyWidget(
                                    width: 30, height: 30,)
                              ),
                              const Positioned(
                                  top: 172,
                                  left: 122,
                                  child: EmptyWidget(
                                    width: 30, height: 30,)
                              ),

                              const Positioned(
                                  top: 210,
                                  left: 160,
                                  child: EmptyWidget(
                                    width: 100, height: 20,)
                              ),
                              const Positioned(
                                  top: 240,
                                  left: 160,
                                  child: EmptyWidget(
                                    width: 100, height: 30,)
                              ),

                              //Le Mollet
                              const Positioned(
                                  top: 394,
                                  left: 212,
                                  child: EmptyWidget(
                                    width: 30, height: 30,)
                              ),
                              const Positioned(
                                  top: 394,
                                  left: 174,
                                  child: EmptyWidget(
                                    width: 30, height: 30,)
                              ),

                              //Talon
                              const Positioned(
                                  top: 448,
                                  left: 208,
                                  child: EmptyWidget(
                                    width: 24, height: 24,)
                              ),
                              const Positioned(
                                  top: 448,
                                  left: 182,
                                  child: EmptyWidget(
                                    width: 24, height: 24,)
                              ),

                              //Orteils
                              const Positioned(
                                  top: 454,
                                  left: 160,
                                  child: EmptyWidget(
                                    width: 20, height: 20,)
                              ),
                              const Positioned(
                                  top: 455,
                                  left: 235,
                                  child: EmptyWidget(
                                    width: 20, height: 20,)
                              ),
                            ],
                          ),
                          Stack(
                            children: [
                              Image.asset('images/Pain/ManFace.jpg',
                                  width: (size.width <= tablet) ? 200 : 500,
                                  height: 500),
                              const Positioned(
                                  top: 58,
                                  left: 222,
                                  child: EmptyWidget(
                                    width: 100, height: 30,)
                              ),
                              const Positioned(
                                  top: 160,
                                  left: 257,
                                  child: EmptyWidget(
                                    width: 30, height: 20,)
                              ),

                              //Les épaules
                              const Positioned(
                                  top: 174,
                                  left: 217,
                                  child: EmptyWidget(
                                    width: 30, height: 20,)
                              ),
                              const Positioned(
                                  top: 174,
                                  left: 302,
                                  child: EmptyWidget(
                                    width: 30, height: 20,)
                              ),

                              //Les bras
                              const Positioned(
                                  top: 202,
                                  left: 214,
                                  child: EmptyWidget(
                                    width: 25, height: 30,)
                              ),
                              const Positioned(
                                  top: 202,
                                  left: 306,
                                  child: EmptyWidget(
                                    width: 25, height: 30,)
                              ),

                              //L'avant bras
                              const Positioned(
                                  top: 244,
                                  left: 210,
                                  child: EmptyWidget(
                                    width: 25, height: 25,)
                              ),
                              const Positioned(
                                  top: 244,
                                  left: 311,
                                  child: EmptyWidget(
                                    width: 25, height: 25,)
                              ),

                              //Les poignets
                              const Positioned(
                                  top: 274,
                                  left: 208,
                                  child: EmptyWidget(
                                    width: 20, height: 20,)
                              ),
                              const Positioned(
                                  top: 274,
                                  left: 318,
                                  child: EmptyWidget(
                                    width: 20, height: 20,)
                              ),

                              //La main
                              const Positioned(
                                  top: 298,
                                  left: 208,
                                  child: EmptyWidget(
                                    width: 24, height: 28,)
                              ),

                              //Les doigts
                              const Positioned(
                                  top: 304,
                                  left: 316,
                                  child: EmptyWidget(
                                    width: 26, height: 27,)
                              ),

                              //Le genou
                              const Positioned(
                                  top: 347,
                                  left: 285,
                                  child: EmptyWidget(
                                    width: 26, height: 28,)
                              ),

                              //La cuisse
                              const Positioned(
                                  top: 320,
                                  left: 240,
                                  child: EmptyWidget(
                                    width: 28, height: 32,)
                              ),

                              //La jambe
                              const Positioned(
                                  top: 370,
                                  left: 240,
                                  child: EmptyWidget(
                                    width: 26, height: 28,)
                              ),

                              //La cheville
                              const Positioned(
                                  top: 408,
                                  left: 242,
                                  child: EmptyWidget(
                                    width: 24, height: 22,)
                              ),
                              const Positioned(
                                  top: 408,
                                  left: 289,
                                  child: EmptyWidget(
                                    width: 24, height: 22,)
                              ),

                              //Les pieds
                              const Positioned(
                                  top: 438,
                                  left: 218,
                                  child: EmptyWidget(
                                    width: 36, height: 22,)
                              ),
                              const Positioned(
                                  top: 438,
                                  left: 298,
                                  child: EmptyWidget(
                                    width: 36, height: 22,)
                              ),

                              //La poitrine
                              const Positioned(
                                  top: 184,
                                  left: 250,
                                  child: EmptyWidget(
                                    width: 50, height: 30,)
                              ),

                              //Le ventre
                              const Positioned(
                                  top: 234,
                                  left: 242,
                                  child: EmptyWidget(
                                    width: 60, height: 30,)
                              ),
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
                                //Le crâne
                                const Positioned(
                                    top: 28,
                                    left: 102,
                                    child: EmptyWidget(
                                      width: 120, height: 30,)
                                ),

                                //Le front
                                const Positioned(
                                    top: 60,
                                    left: 114,
                                    child: EmptyWidget(
                                      width: 100, height: 28,)
                                ),

                                //Les yeux
                                const Positioned(
                                    top: 94,
                                    left: 120,
                                    child: EmptyWidget(
                                      width: 40, height: 24,)
                                ),
                                const Positioned(
                                    top: 94,
                                    left: 172,
                                    child: EmptyWidget(
                                      width: 40, height: 24,)
                                ),

                                //Le nez
                                const Positioned(
                                    top: 120,
                                    left: 150,
                                    child: EmptyWidget(
                                      width: 30, height: 18,)
                                ),

                                //Les joues
                                const Positioned(
                                    top: 128,
                                    left: 190,
                                    child: EmptyWidget(
                                      width: 30, height: 26,)
                                ),
                                const Positioned(
                                    top: 128,
                                    left: 110,
                                    child: EmptyWidget(
                                      width: 30, height: 26,)
                                ),

                                //La bouche
                                const Positioned(
                                    top: 140,
                                    left: 146,
                                    child: EmptyWidget(
                                      width: 38, height: 18,)
                                ),

                                //Le cou
                                const Positioned(
                                    top: 170,
                                    left: 146,
                                    child: EmptyWidget(
                                      width: 36, height: 20,)
                                ),

                                //Les épaules
                                const Positioned(
                                    top: 186,
                                    left: 106,
                                    child: EmptyWidget(
                                      width: 36, height: 20,)
                                ),
                                const Positioned(
                                    top: 186,
                                    left: 190,
                                    child: EmptyWidget(
                                      width: 36, height: 20,)
                                ),

                                //Les oreilles
                                const Positioned(
                                    top: 94,
                                    left: 98,
                                    child: EmptyWidget(
                                      width: 20, height: 36,)
                                ),
                                const Positioned(
                                    top: 94,
                                    left: 214,
                                    child: EmptyWidget(
                                      width: 20, height: 36,)
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
                            'Quel type de douleurs?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 500,
                    child: FittedBox(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            // Image ManDoul au centre
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Image à gauche de ManDoul
                                Column(
                                  children: [
                                    // Image en haut de ManDoul
                                    ImageWidget(
                                        imagePath: 'images/Pain/P1.jpg',
                                        height: 350,
                                        width: 350),
                                    Text(
                                      'ça pique',
                                      style: TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    ImageWidget(
                                        imagePath: 'images/Pain/P3.jpg',
                                        height: 350,
                                        width: 350),
                                    Text(
                                      'ça gratte / ça démange',
                                      style: TextStyle(
                                          fontSize: 25,fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 300, height: 300,),
                                Column(
                                  children: [
                                    // Image en bas de ManDoul
                                    ImageWidget(
                                        imagePath: 'images/Pain/P6.png',
                                        height: 350,
                                        width: 350),
                                    Text(
                                      'Comme un coup de poignard',
                                      style: TextStyle(
                                          fontSize: 25,fontWeight: FontWeight.bold),
                                    ),
                                    ImageWidget(
                                        imagePath: 'images/Pain/P4.png',
                                        height: 350,
                                        width: 350),
                                    Text(
                                      'Fourmillements',
                                      style: TextStyle(
                                          fontSize: 25, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 300, height: 300,),
                                Column(
                                  children: [
                                    ImageWidget(
                                        imagePath: 'images/Pain/P5.jpg',
                                        height: 350,
                                        width: 350),
                                    Text(
                                      'ça brûle',
                                      style: TextStyle(
                                          fontSize: 25, fontWeight: FontWeight.bold),
                                    ),
                                    ImageWidget(
                                        imagePath: 'images/Pain/P2.png',
                                        height: 350,
                                        width: 350),
                                    Text(
                                      'Oppression / Qui serre',
                                      style: TextStyle(
                                          fontSize: 25,fontWeight: FontWeight.bold),
                                    ),
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
                      padding:  EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Text(
                            'A quelle échelle?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Images pour la question "Avez-vous mal?"
                  /*
                  SizedBox(
                    height: 100,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: const [
                            ImageWidget(
                                imagePath: 'images/Pain/D0.jpg',
                                height: 100,
                                width: 100),
                            ImageWidget(
                                imagePath: 'images/Pain/D2.jpg',
                                height: 100,
                                width: 100),
                            ImageWidget(
                                imagePath: 'images/Pain/D4.jpg',
                                height: 100,
                                width: 100),
                            ImageWidget(
                                imagePath: 'images/Pain/D6.jpg',
                                height: 100,
                                width: 100),
                            ImageWidget(
                                imagePath: 'images/Pain/D8.jpg',
                                height: 100,
                                width: 100),
                            ImageWidget(
                                imagePath: 'images/Pain/D10.jpg',
                                height: 100,
                                width: 100),
                          ],
                        ),
                      ),
                    ),
                  ),

                   */
                  SizedBox(
                    height: (size.width <= tablet) ? size.height * 0.3 : 200,
                    child: FittedBox(
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Image.asset('images/Pain/ladder.jpg', height: 300, width: 500),
                              //Les emojis
                              const Positioned(
                                  top: 50,
                                  left: 8,
                                  child: EmptyWidget(
                                    width: 50, height: 50,)
                              ),
                              const Positioned(
                                  top: 50,
                                  left: 54,
                                  child: EmptyWidget(
                                    width: 50, height: 50,)
                              ),
                              const Positioned(
                                  top: 50,
                                  left: 100,
                                  child: EmptyWidget(
                                    width: 50, height: 50,)
                              ),
                              const Positioned(
                                  top: 50,
                                  left: 148,
                                  child: EmptyWidget(
                                    width: 50, height: 50,)
                              ),
                              const Positioned(
                                  top: 50,
                                  left: 195,
                                  child: EmptyWidget(
                                    width: 50, height: 50,)
                              ),
                              const Positioned(
                                  top: 50,
                                  left: 240,
                                  child: EmptyWidget(
                                    width: 50, height: 50,)
                              ),

                              //Les échelles en longueur
                              const Positioned(
                                  top: 130,
                                  left: 13,
                                  child: EmptyWidget(
                                    width: 20, height: 50,)
                              ),
                              const Positioned(
                                  top: 130,
                                  left: 36,
                                  child: EmptyWidget(
                                    width: 20, height: 50,)
                              ),
                              const Positioned(
                                  top: 130,
                                  left: 59,
                                  child: EmptyWidget(
                                    width: 20, height: 50,)
                              ),
                              const Positioned(
                                  top: 130,
                                  left: 83,
                                  child: EmptyWidget(
                                    width: 20, height: 50,)
                              ),
                              const Positioned(
                                  top: 130,
                                  left: 106,
                                  child: EmptyWidget(
                                    width: 20, height: 50,)
                              ),
                              const Positioned(
                                  top: 130,
                                  left: 129,
                                  child: EmptyWidget(
                                    width: 20, height: 50,)
                              ),
                              const Positioned(
                                  top: 130,
                                  left: 153,
                                  child: EmptyWidget(
                                    width: 20, height: 50,)
                              ),
                              const Positioned(
                                  top: 130,
                                  left: 176,
                                  child: EmptyWidget(
                                    width: 20, height: 50,)
                              ),
                              const Positioned(
                                  top: 130,
                                  left: 200,
                                  child: EmptyWidget(
                                    width: 20, height: 50,)
                              ),
                              const Positioned(
                                  top: 130,
                                  left: 223,
                                  child: EmptyWidget(
                                    width: 20, height: 50,)
                              ),
                              const Positioned(
                                  top: 130,
                                  left: 247,
                                  child: EmptyWidget(
                                    width: 20, height: 50,)
                              ),
                              Positioned(
                                  top: 130,
                                  left: 725,
                                  child: EmptyWidget(
                                    width: 20,
                                    height: 50,)
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  )
                  // ... (ajoutez d'autres éléments au besoin)
                ],
              ),
              Visibility(
                visible: _gazeLeftX != 0 && _gazeLeftY != 0 && _gazeRightX != 0 && _gazeRightY != 0,
                child: Positioned(
                  left: averageX,
                  top: averageY,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.7),
                      shape: BoxShape.circle, // Rendre le container circulaire
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class ImageWidget extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;
  final bool circle;
  final double gazeLeftX;
  final double gazeLeftY;
  final double gazeRightX;
  final double gazeRightY;

  const ImageWidget({
    super.key,
    required this.imagePath,
    this.width = 50,
    this.height = 50,
    this.circle = false,
    this.gazeLeftX = 0.0,
    this.gazeLeftY = 0.0,
    this.gazeRightX = 0.0,
    this.gazeRightY = 0.0,
  });


  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  bool isPressed = false;
  bool isGazeOnTarget = false;
  Timer? gazeTimer;

  // Fonction pour vérifier si le regard est sur l'image
  bool _isGazeOnImage() {
    // Calculer la position moyenne du regard
    final double averageX = (widget.gazeLeftX + widget.gazeRightX) / 2;
    final double averageY = (widget.gazeLeftY + widget.gazeRightY) / 2;

    // Vérifier si la position moyenne est dans les limites de l'image
    return averageX >= 0 &&
        averageX <= widget.width &&
        averageY >= 0 &&
        averageY <= widget.height;
  }

  // Fonction pour simuler un clic
  void _simulateClick() {
    setState(() {
      isPressed = true; // Définir explicitement l'état
    });
    // Vous pouvez ajouter ici d'autres actions à effectuer lors du clic
  }

  // Fonction pour gérer l'état du regard
  void _handleGaze() {
    if (_isGazeOnImage()) {
      // Si le regard est sur l'objet, démarrer ou continuer le timer
      if (!isGazeOnTarget) {
        setState(() {
          isGazeOnTarget = true;
        });
        gazeTimer = Timer(Duration(seconds: 5), () {
          // Si le regard reste sur l'objet pendant 5 secondes, simuler un clic
          _simulateClick();
        });
      }
    } else {
      // Si le regard n'est plus sur l'objet, annuler le timer
      if (isGazeOnTarget) {
        setState(() {
          isGazeOnTarget = false;
        });
        gazeTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    gazeTimer?.cancel(); // Annuler le timer lors de la destruction du widget
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Appeler _handleGaze à chaque frame pour vérifier l'état du regard
    _handleGaze();

    return GestureDetector(
      onTap: () {
        _simulateClick(); // Utiliser la même méthode pour le clic manuel
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          border: isPressed
              ? Border.all(color: Colors.deepPurple, width: 3)
              : Border.all(color: Colors.transparent, width: 0),
          shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
          image: DecorationImage(image: AssetImage(widget.imagePath)),
        ),
      ),
    );
  }
}