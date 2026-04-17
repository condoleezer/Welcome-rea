import 'package:flutter/material.dart';

class IrmView extends StatelessWidget {
  final Color mainColor;
  const IrmView({super.key, required this.mainColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('IRM'),
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
          // IRM
          Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: mainColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                'IRM : L’imagerie par résonnance magnétique est une technique spécifique pour diagnostiquer certaines maladies. L’examen dure environ 20 min, vous serez allongé dans un tunnel bruyant avec une sonnette  pour joindre le personnel si nécessaire. Il faudra rester immobile le temps de l’examen.',
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
                Image.asset('images/Soignant/irm.jpg', height: 400, width: 400),
                Image.asset('images/Soignant/irm2.jpg', height: 400, width: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
