import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../components/empty_widget.dart';
import '../components/record_widget.dart';
import 'package:permission_handler/permission_handler.dart';


class PainView extends StatefulWidget {
  const PainView({super.key});

  @override
  State<PainView> createState() => _PainViewState();
}

class _PainViewState extends State<PainView> {
  Map<String, dynamic>? _eyeCoordinates;
  late double top =0;
  late double left =0;
  late double leftX =0;
  late double rightX =0;
  late double leftY =0;
  late double rightY =0;

  Future<void> _requestPermission() async {
    await Permission.camera.request();
    print(Permission.camera.status);
  }

  Future<void> sendScreenSize(double width, double height) async {
    const String apiUrl = 'http://10.77.161.14:5000/eye_track'; // Replace with your API URL

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, double>{
        'width': width,
        'height': height,
      }),
    );

    if (response.statusCode == 200) {
      print('Screen size sent successfully!');
      setState(() {
        _eyeCoordinates = json.decode(response.body);
        leftX = _eyeCoordinates!['gaze_left_x'];
        leftY = _eyeCoordinates!['gaze_left_y'];
        rightX = _eyeCoordinates!['gaze_right_x'];
        rightY = _eyeCoordinates!['gaze_right_y'];
      });
    } else {
      print('Failed to get eye coordinates. Status code: ${response.statusCode}');
      var snackBar = const SnackBar(
          content: Text('Une erreur est survenue',));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    const double tablet = 500;

    print("Gaze Coordinates: $top, $left");

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
          IconButton(
            icon: const Icon(Icons.remove_red_eye_outlined),
            onPressed: () async {
              //_requestPermission();
              // Get the screen size
              final Size screenSize = MediaQuery.of(context).size;

              // Send the screen size to the API
              sendScreenSize(screenSize.width, screenSize.height);
              /*
              print('enter');
              final response = await http.get(Uri.parse('http://10.77.2.254:5000/eye_track'));
              print(response);
              print(response.statusCode);
              print(response.body);
              if (response.statusCode == 200) {
                setState(() {
                  _eyeCoordinates = json.decode(response.body);
                  //top = (_eyeCoordinates!['left_eye'][1] + _eyeCoordinates!['right_eye'][1])/2;
                  //left = (_eyeCoordinates!['left_eye'][0] + _eyeCoordinates!['right_eye'][0])/2;
                  top = _eyeCoordinates!['gaze_x'];
                  left = _eyeCoordinates!['gaze_y'];
                  //top = intTop.toDouble();
                  //left = intLeft.toDouble();
                });
              } else {
                print('Failed to get eye coordinates');
              }

               */
            },
          ),

          // Reset eye tracker
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                leftX = 0;
                rightX = 0;
              });
            },
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
                                        height: 250,
                                        width: 250),
                                    Text(
                                      'ça pique',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    ImageWidget(
                                        imagePath: 'images/Pain/P3.jpg',
                                        height: 250,
                                        width: 250),
                                    Text(
                                      'ça gratte / ça démange',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 300, height: 300,),
                                Column(
                                  children: [
                                    // Image en bas de ManDoul
                                    ImageWidget(
                                        imagePath: 'images/Pain/P6.png',
                                        height: 250,
                                        width: 250),
                                    Text(
                                      'Comme un coup de poignard',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    ImageWidget(
                                        imagePath: 'images/Pain/P4.png',
                                        height: 250,
                                        width: 250),
                                    Text(
                                      'Fourmillements',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 300, height: 300,),
                                Column(
                                  children: [
                                    ImageWidget(
                                        imagePath: 'images/Pain/P5.jpg',
                                        height: 250,
                                        width: 250),
                                    Text(
                                      'ça brûle',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    ImageWidget(
                                        imagePath: 'images/Pain/P2.png',
                                        height: 250,
                                        width: 250),
                                    Text(
                                      'Oppression / Qui serre',
                                      style: TextStyle(fontWeight: FontWeight.bold),
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
                              Image.asset('images/Pain/ladder.jpg', height: 200, width: 300),
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
                              const Positioned(
                                  top: 130,
                                  left: 725,
                                  child: EmptyWidget(
                                    width: 20, height: 50,)
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
                visible: leftX != 0,
                child: Positioned(
                  left: leftX,
                  //(MediaQuery.of(context).size.width/2) , // Centrer le container
                  top: leftY ,
                  // MediaQuery.of(context).size.height, // Centrer le container
                  child: Container(
                    width: 50,
                    height: 50,
                    color: Colors.red.withOpacity(0.7),
                  ),
                ),
              ),
              Visibility(
                visible: rightX != 0,
                child: Positioned(
                  left: rightX,
                  //(MediaQuery.of(context).size.width/2) , // Centrer le container
                  top: rightY ,
                  // MediaQuery.of(context).size.height, // Centrer le container
                  child: Container(
                    width: 50,
                    height: 50,
                    color: Colors.green.withOpacity(0.7),
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

  const ImageWidget({super.key, required this.imagePath, this.width = 50, this.height = 50, this.circle= false});

  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      /*onTapDown: (details) {
        setState(() {
          isPressed = true;
        });
      },
      onTapUp: (details) {
        setState(() {
          isPressed = false;
        });
      },*/
      onTap: () {
        setState(() {
          isPressed = !isPressed;
        });
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          border: isPressed
              ? Border.all(color: Colors.deepPurple, width: 3)
              : Border.all(color: Colors.transparent, width: 0),
          shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
          image: DecorationImage(image: AssetImage(widget.imagePath,)),
        ),
      ),
    );
  }
}
