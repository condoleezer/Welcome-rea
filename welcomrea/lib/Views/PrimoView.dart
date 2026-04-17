import 'package:flutter/material.dart';
import 'package:welcomrea/views/FirstPageView.dart';
import 'package:welcomrea/models/HospitalData.dart';

class PrimoView extends StatelessWidget {
  const PrimoView({super.key});

  @override
  Widget build(BuildContext context) {
    HospitalData hospitalData = HospitalData(
      imagePath: 'images/Hosto.png',
      welcomeMessage: 'Bienvenue en réanimation à Corbeil Essonne',
      country: 'France',
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FirstPageView(
                data: hospitalData), // Passer les données à FirstPageView
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'images/Well.jpg',
                height: 500,
              ),
              const SizedBox(height: 20),
              const Text(
                'Cliquer pour passer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
