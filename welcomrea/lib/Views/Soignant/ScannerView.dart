import 'package:flutter/material.dart';

class ScannerView extends StatelessWidget {
  final Color mainColor;
  const ScannerView({super.key, required this.mainColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('SCANNER'),
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
          //SCANNER
          Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: mainColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                'SCANNER : Le scanner est une technique spécifique pour diagnostiquer certaines maladies. L’examen dure environ 5 min, vous serez allongé dans un anneau. Il faudra rester immobile le temps de l’examen. Une injection de produit de contraste pourra être réalisé grâce à votre perfusion. Cela dégage une sensation de chaleur normale.',
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
                Image.asset('images/Soignant/scan.png', height: 400, width: 420, fit: BoxFit.fill,),
                Image.asset('images/Soignant/scan2.png', height: 400, width: 420, fit: BoxFit.fill,),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
