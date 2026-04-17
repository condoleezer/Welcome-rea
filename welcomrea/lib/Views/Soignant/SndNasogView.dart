import 'package:flutter/material.dart';
import 'package:welcomrea/components/video_player_widget.dart';

class SndNasogView extends StatelessWidget {
  final Color mainColor;
  const SndNasogView({super.key, required this.mainColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('SONDE NASOGASTRIQUE'),
        ),
        backgroundColor: mainColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () {
              // Ajoutez le code pour accéder au microphone ici
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: mainColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                'Nous allons vous poser une sonde gastrique La sonde gastrique est un tuyau introduit par la bouche ou le nez, qui passe dans l’œsophage et qui finit dans l’estomac permettant d’apporter de la nourriture sous forme liquide et des médicaments. Elle peut également servir à aspirer ce qu’il y a dans l’estomac pour le laisser au repos.',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Image.asset('images/Soignant/S43.png', height: 300, width: 300),
                Image.asset('images/Soignant/S44.png', height: 300, width: 300),
                const VideoPlayerWidget(url: 'images/Soignant/sonde_gastrique.mp4', height: 300, width: 300,)
              ],
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

  const ImageWidget({super.key, required this.imagePath, this.width = 50, this.height = 50});

  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          isPressed = true;
        });
      },
      onTapUp: (details) {
        setState(() {
          isPressed = false;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: isPressed
              ? Border.all(color: Colors.red, width: 3)
              : Border.all(color: Colors.transparent, width: 0),
        ),
        child: Image.asset(
          widget.imagePath,
          width: widget.width,
          height: widget.height,
        ),
      ),
    );
  }
}
