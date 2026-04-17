import 'package:flutter/material.dart';

class EcgView extends StatelessWidget {
  final Color mainColor;
  const EcgView({super.key, required this.mainColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('ELECTROCARDIOGRAMME'),
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
                'L’électrocardiogramme permet d’enregistrer l’activité électrique du cœur. Pour cela nous allons poser des patchs sur votre thorax pendant quelques minutes. Il ne faudra pas bouger ni parler pendant l’examen.',
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Image.asset('images/Soignant/S21.jpg', height: 500, width: 500),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
