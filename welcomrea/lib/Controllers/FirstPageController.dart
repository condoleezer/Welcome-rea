import 'package:flutter/material.dart';
import 'package:welcomrea/views/FirstPageView.dart';
import 'package:welcomrea/views/PrimoView.dart';
import 'package:welcomrea/models/HospitalData.dart';

class FirstPageController {
  final HospitalData data;

  FirstPageController({required this.data});

  Widget buildView() {
    return FirstPageView(data: data);
  }
}

void main() {
  HospitalData hospitalData = HospitalData(
    imagePath: 'images/Hosto.png',
    welcomeMessage: 'Bienvenue dans notre unité de réanimation!',
    country: 'France',
  );

  FirstPageController controller = FirstPageController(data: hospitalData);

  /*runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: controller.buildView(),
  ));*/

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PrimoView(), // PrimoView comme page d'accueil
  ));
}
