import 'package:flutter/material.dart';

class DialyseView extends StatelessWidget {
  final Color mainColor;
  const DialyseView({super.key, required this.mainColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('DIALYSE'),
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
                'La dialyse permet de filtrer le sang lorsque les reins ne sont plus capables de le faire. Cela permet d’évacuer certains déchets et le surplus d’eau circulant dans le corps. La dialyse peut être sous forme de séances de plusieurs heures ou alors en continue. Elle s’effectue via un cathéter (tuyau) qui se trouve dans une grosse veine au niveau du cou ou du pli de la cuisse. Pour une meilleure réussite de la dialyse il faut éviter de bouger. ',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          /*
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
                    'Images',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

           */
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Image.asset('images/Soignant/S36.jpg', height: 350, width: 350, fit: BoxFit.fitHeight,),
                Image.asset('images/Soignant/dialyse.jpeg', height: 350, width: 350, fit: BoxFit.fitHeight,),
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
