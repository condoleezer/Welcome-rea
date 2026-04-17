import 'package:flutter/material.dart';

import '../components/record_widget.dart';

class CareView extends StatelessWidget {
  const CareView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Center(
          child: Text('BIEN-ETRE', style: TextStyle(fontSize: 30)),
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
              // Ajoutez le code pour accéder au microphone ici
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.green.shade200,
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine the number of columns based on the screen width
            int crossAxisCount = constraints.maxWidth > 1200
                ? 3
                : constraints.maxWidth > 800
                ? 2
                : 1;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              children: const [
                ImageLabelWidget(
                  imagePath: 'images/Bien/B3.png',
                  labelText: 'Je veux mes lunettes',
                ),
                ImageLabelWidget(
                  imagePath: 'images/Bien/B1.png',
                  labelText: 'Je veux lire',
                ),
                ImageLabelWidget(
                  imagePath: 'images/Bien/B11.jpg',
                  labelText: 'Je veux écrire',
                ),
                ImageLabelWidget(
                  imagePath: 'images/Bien/B2.jpg',
                  labelText: 'Je veux la musique',
                ),
                ImageLabelWidget(
                  imagePath: 'images/Bien/B6.jpg',
                  labelText: 'Téléphone',
                ),
                ImageLabelWidget(
                  imagePath: 'images/Bien/B7.jpg',
                  labelText: 'Chargeur de téléphone',
                ),
                ImageLabelWidget(
                  imagePath: 'images/Bien/B5.jpg',
                  labelText: 'Télévision',
                ),
                ImageLabelWidget(
                  imagePath: 'images/Bien/B12.png',
                  labelText: 'Je veux dormir',
                ),
                ImageLabelWidget(
                  imagePath: 'images/Bien/B8.png',
                  labelText: 'Laissez-moi tranquille',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ImageLabelWidget extends StatelessWidget {
  final String imagePath;
  final String labelText;

  const ImageLabelWidget({super.key, required this.imagePath, required this.labelText});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ImageWidget(imagePath: imagePath),
        const SizedBox(height: 5),
        Text(
          labelText,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class ImageWidget extends StatefulWidget {
  final String imagePath;

  const ImageWidget({super.key, required this.imagePath});

  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isPressed = !isPressed;
        });
      },
      /*
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

       */
      child: Container(
        decoration: BoxDecoration(
          border: isPressed
              ? Border.all(color: Colors.red, width: 3)
              : Border.all(color: Colors.transparent, width: 0),
        ),
        child: Image.asset(
          widget.imagePath,
          width: 300,
          height: 300,
        ),
      ),
    );
  }
}

