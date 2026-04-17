import 'package:flutter/material.dart';

class SndUriView extends StatelessWidget {
  final Color mainColor;
  const SndUriView({super.key, required this.mainColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('SONDE URINAIRE'),
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
                'Nous allons vous poser une sonde urinaire, ce qui vous aidera à faire pipi. Il ne faut pas tirer dessus car il y a un ballon pour la maintenir à l’intérieur, vous pourriez vous faire mal. C’est un tuyau qui va directement dans la vessie donc l’urine coule toute seule, vous n’avez pas besoin de forcer.',
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
                Image.asset('images/Soignant/S17.png', height: 500, width: 500),
                Image.asset('images/Soignant/S18.jpg', height: 350, width: 350),
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
