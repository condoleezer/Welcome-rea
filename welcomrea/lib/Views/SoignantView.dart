import 'package:flutter/material.dart';
import 'package:welcomrea/Views/Soignant/CapGasView.dart';
import 'package:welcomrea/Views/Soignant/CathAstView.dart';
import 'package:welcomrea/Views/Soignant/DialyseView.dart';
import 'package:welcomrea/Views/Soignant/DrThracView.dart';
import 'package:welcomrea/Views/Soignant/EcmoView.dart';
import 'package:welcomrea/Views/Soignant/EcoCarView.dart';
import 'package:welcomrea/Views/Soignant/EcouvNaRectView.dart';
import 'package:welcomrea/Views/Soignant/IntubationView.dart';
import 'package:welcomrea/Views/Soignant/OptiflowView.dart';
import 'package:welcomrea/Views/Soignant/PensEscView.dart';
import 'package:welcomrea/Views/Soignant/PerfView.dart';
import 'package:welcomrea/Views/Soignant/PonctLombView.dart';
import 'package:welcomrea/Views/Soignant/PrelSangView.dart';
import 'package:welcomrea/Views/Soignant/RadioView.dart';
import 'package:welcomrea/Views/Soignant/SndNasogView.dart';
import 'package:welcomrea/Views/Soignant/SndUriView.dart';
import 'package:welcomrea/Views/Soignant/TracheotomieView.dart';
import 'package:welcomrea/Views/Soignant/VacThrpView.dart';
import 'package:welcomrea/Views/Soignant/VenArtView.dart';
import 'package:welcomrea/Views/Soignant/AOTView.dart';
import 'package:welcomrea/Views/Soignant/FibrClsView.dart';
import 'package:welcomrea/Views/Soignant/FibrBrchView.dart';
import 'package:welcomrea/Views/Soignant/VentilNoInvaView.dart';
import 'package:welcomrea/Views/Soignant/VoieVeinView.dart';

import 'Soignant/EcgView.dart';
import 'Soignant/IrmView.dart';
import 'Soignant/ScannerView.dart';

class SoignantView extends StatefulWidget {
  const SoignantView({super.key});

  @override
  _SoignantViewState createState() => _SoignantViewState();
}

class _SoignantViewState extends State<SoignantView> {
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Center(
          child: Text('Espace Soignant',),
        ),
        backgroundColor: Colors.green.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () {
              // Ajoutez le code pour accéder au microphone ici
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Boutons pour accéder aux pages
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut);
                      },
                      child: Container(
                          height: 48,
                          width: 120,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: _currentPageIndex == 0
                                ? Colors.green.shade900
                                : Colors.transparent,
                          ),
                          child: Center(
                              child: Text(
                                'Soins courants',
                                style: TextStyle(
                                    color: _currentPageIndex == 0
                                        ? Colors.white
                                        : Colors.black),
                              ))),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(1,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut);
                      },
                      child: Container(
                          height: 48,
                          width: 120,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: _currentPageIndex == 1
                                ? Colors.green.shade900
                                : Colors.transparent,
                          ),
                          child: Center(
                              child: Text(
                                'Ventilation',
                                style: TextStyle(
                                    color: _currentPageIndex == 1
                                        ? Colors.white
                                        : Colors.black),
                              ))),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(2,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut);
                      },
                      child: Container(
                          height: 48,
                          width: 120,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: _currentPageIndex == 2
                                  ? Colors.green.shade900
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20)),
                          child: Center(
                              child: Text(
                                'Soins Médicaux',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: _currentPageIndex == 2
                                        ? Colors.white
                                        : Colors.black),
                              ))),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(3,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut);
                      },
                      child: Container(
                          height: 48,
                          width: 120,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: _currentPageIndex == 3
                                  ? Colors.green.shade900
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20)),
                          child: Center(
                              child: Text(
                                'Examens',
                                style: TextStyle(
                                    color: _currentPageIndex == 3
                                        ? Colors.white
                                        : Colors.black),
                              ))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24,),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                    });
                  },
                  children: [
                    // Première page avec 15 boutons
                    buildPage1(constraints.maxWidth, constraints.maxHeight),
                    // Deuxième page avec 10 boutons
                    buildPage2(constraints.maxWidth, constraints.maxHeight),
                    buildPage3(constraints.maxWidth, constraints.maxHeight),
                    buildPage4(constraints.maxWidth, constraints.maxHeight),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildPage1(double width, double height) {
    double buttonSize =
        width * 0.15; // Adjust button size based on screen width
    double fontSize = width * 0.015; // Adjust font size based on screen width

    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                buildButton(context, 'PERFUSION', const PerfView(mainColor: Color(0xFFfdfd96),), buttonSize,
                    fontSize, const Color(0xFFfdfd96), Colors.black),
                buildButton(
                    context,
                    'PRÉLÈVEMENT\nSANGUIN',
                    const PrelSangView(mainColor: Color(0xFFfdfd96),),
                    buttonSize,
                    fontSize,
                    const Color(0xFFfdfd96), Colors.black),
                buildButton(context, 'GLYCÉMIE\nCAPILAIRE', const CapGasView(mainColor: Color(0xFFfdfd96),),
                    buttonSize, fontSize, const Color(0xFFfdfd96), Colors.black),
                buildButton(
                    context,
                    'SONDE\nNASOGASTRIQUE',
                    const SndNasogView(mainColor: Color(0xFFfdfd96),),
                    buttonSize,
                    fontSize,
                    const Color(0xFFfdfd96), Colors.black),
                buildButton(context, 'SONDE\nURINAIRE', const SndUriView(mainColor: Color(0xFFfdfd96),),
                    buttonSize, fontSize, const Color(0xFFfdfd96), Colors.black),
                buildButton(context, 'PANSEMENT\nESCARRE', const PensEscView(mainColor: Color(0xFFfdfd96),),
                    buttonSize, fontSize, const Color(0xFFfdfd96), Colors.black),
                buildButton(context, 'VAC thérapie', const VacThrpView(mainColor: Color(0xFFfdfd96),),
                    buttonSize, fontSize, const Color(0xFFfdfd96), Colors.black),
                buildButton(
                    context,
                    'ÉCOUVILLON\nNASAL\nOU RECTAL',
                    const EcouvNaRectView(mainColor: Color(0xFFfdfd96),),
                    buttonSize,
                    fontSize,
                    const Color(0xFFfdfd96), Colors.black),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPage2(double width, double height) {
    double buttonSize =
        width * 0.15; // Adjust button size based on screen width
    double fontSize = width * 0.015; // Adjust font size based on screen width

    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                buildButton(context, 'INTUBATION', const IntubationView(mainColor: Color(0xFFADD8E6),),
                    buttonSize, fontSize, const Color(0xFFADD8E6), Colors.black),
                buildButton(
                    context,
                    'VENTILATION\nARTIFICIELLE',
                    const VenArtView(mainColor : Color(0xFFADD8E6)),
                    buttonSize,
                    fontSize,
                    const Color(0xFFADD8E6), Colors.black),
                buildButton(
                    context,
                    'VENTILATION\nNON INVASIVE',
                    const VentilNoInvaView(mainColor: Color(0xFFADD8E6),),
                    buttonSize,
                    fontSize, 
                    const Color(0xFFADD8E6), Colors.black),
                buildButton(context, 'ASPIRATIONS\nORO-TRACHEALES',
                    const AOTView(mainColor: Color(0xFFADD8E6),), buttonSize, fontSize, const Color(0xFFADD8E6), Colors.black),
                buildButton(
                    context,
                    'OPTIFLOW OU\nOXYGÉNO\nTHÉRAPIE\nÀ HAUT\nDÉBIT',
                    const OptiflowView(mainColor: Color(0xFFADD8E6),),  
                    buttonSize,
                    fontSize,
                    const Color(0xFFADD8E6), Colors.black),
                buildButton(context, 'TRACHÉOTOMIE', const TracheotomieView(mainColor: Color(0xFFADD8E6),),
                    buttonSize, fontSize, const Color(0xFFADD8E6), Colors.black),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPage3(double width, double height) {
    double buttonSize =
        width * 0.15; // Adjust button size based on screen width
    double fontSize = width * 0.015; // Adjust font size based on screen width

    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                buildButton(
                    context,
                    'VOIE VEINEUSE\nCENTRALE OU KTC',
                    const VoieVeinView(mainColor: Color(0xFFF5E5FF),),
                    buttonSize,
                    fontSize,
                    const Color(0xFFF5E5FF), Colors.black),
                buildButton(context, 'CATHETER\nARTERIEL', const CathAstView(mainColor: Color(0xFFF5E5FF),),
                    buttonSize, fontSize, const Color(0xFFF5E5FF), Colors.black),
                buildButton(context, 'DRAIN\nTHORACIQUE', const DrThracView(mainColor: Color(0xFFF5E5FF),),
                    buttonSize, fontSize, const Color(0xFFF5E5FF), Colors.black),
                buildButton(
                    context,
                    'PONCTION\nLOMBAIRE',
                    const PonctLombView(mainColor: Color(0xFFF5E5FF),),
                    buttonSize,
                    fontSize,
                    const Color(0xFFF5E5FF), Colors.black),
                buildButton(context, 'DIALYSE', const DialyseView(mainColor: Color(0xFFF5E5FF),), buttonSize,
                    fontSize, const Color(0xFFF5E5FF), Colors.black),
                buildButton(context, 'ECMO', const EcmoView(mainColor: Color(0xFFF5E5FF),), buttonSize,
                    fontSize, const Color(0xFFF5E5FF), Colors.black),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPage4(double width, double height) {
    double buttonSize =
        width * 0.15; // Adjust button size based on screen width
    double fontSize = width * 0.015; // Adjust font size based on screen width

    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                buildButton(
                    context,
                    'ÉCHOGRAPHIE\nCARDIAQUE',
                    EcoCarView(mainColor: Colors.green.shade200,),
                    buttonSize,
                    fontSize,
                    Colors.green.shade200, Colors.black),
                buildButton(
                    context,
                    'ECG',
                    EcgView(mainColor: Colors.green.shade200,),
                    buttonSize,
                    fontSize,
                    Colors.green.shade200, Colors.black),
                buildButton(context, 'RADIOLOGIE', RadioView(mainColor: Colors.green.shade200,),
                    buttonSize, fontSize, Colors.green.shade200, Colors.black),
                buildButton(context, 'SCANNER', ScannerView(mainColor: Colors.green.shade200,),
                    buttonSize, fontSize, Colors.green.shade200, Colors.black),
                buildButton(context, 'IRM', IrmView(mainColor: Colors.green.shade200,),
                    buttonSize, fontSize, Colors.green.shade200, Colors.black),
                buildButton(
                    context,
                    'FIBROSCOPIE\nCOLOSCOPIE',
                    FibrClsView(mainColor: Colors.green.shade200,),
                    buttonSize,
                    fontSize,
                    Colors.green.shade200, Colors.black),
                buildButton(
                    context,
                    'FIBROSCOPIE\nBRONCHIQUE',
                    FibrBrchView(mainColor: Colors.green.shade200,),
                    buttonSize,
                    fontSize,
                    Colors.green.shade200, Colors.black),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButton(BuildContext context, String text, Widget destination,
      double size, double fontSize, Color color, Color textColor) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      icon: Icon(Icons.medical_services, size: fontSize, color: textColor,), // Ajout de l'icône
      label: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15, color: textColor),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        //Colors.green.shade900,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        fixedSize: Size(size, size), // Ajustement de la taille du bouton
      ),
    );
  }
}
