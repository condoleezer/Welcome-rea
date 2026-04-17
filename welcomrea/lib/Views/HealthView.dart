import 'package:flutter/material.dart';

import '../components/record_widget.dart';

class HealthView extends StatefulWidget {
  const HealthView({super.key});

  @override
  State<HealthView> createState() => _HealthViewState();
}

class _HealthViewState extends State<HealthView> {
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
          child: Text('HYGIENE', style: TextStyle(fontSize: 30)),
        ),
        backgroundColor: Colors.green.shade800,
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
      backgroundColor: Colors.green.shade200,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            children: [
              // Boutons pour accéder aux pages
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
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
                            height: 60,
                            width: 150,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: _currentPageIndex == 0
                                  ? Colors.green.shade900
                                  : Colors.transparent,
                            ),
                            child: Center(
                                child: Text(
                                  'Toilette',
                                  style: TextStyle(
                                      fontSize: 30,
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
                            height: 60,
                            width: 300,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: _currentPageIndex == 1
                                  ? Colors.green.shade900
                                  : Colors.transparent,
                            ),
                            child: Center(
                                child: Text(
                                  'Soin Bucodentaire',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 30,
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
                            height: 60,
                            width: 150,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                color: _currentPageIndex == 2
                                    ? Colors.green.shade900
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20)),
                            child: Center(
                                child: Text(
                                  'Hygiene',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 30,
                                      color: _currentPageIndex == 2
                                          ? Colors.white
                                          : Colors.black),
                                ))),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20,),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                    });
                  },
                  children: const [
                    // Toilette
                    SingleChildScrollView(
                      scrollDirection : Axis.vertical,
                      child:
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              ImageWithText(
                                imagePath: 'images/Health/H1.png',
                                height: 300,
                                width: 300,
                                labelText: 'Se doucher',
                              ),
                              SizedBox(width: 50,),
                              ImageWithText(
                                imagePath: 'images/Health/H3.gif',
                                height: 300,
                                width: 300,
                                labelText: 'Toilette Intime',
                              ),
                            ],
                          ),
                          SizedBox(width: 50), // Ajout de l'espace
                          Column(
                            children: [
                              ImageWithText(
                                imagePath: 'images/Health/H2.jpg',
                                height: 300,
                                width: 300,
                                labelText: 'Se laver',
                              ),
                              SizedBox(width: 50,),
                              ImageWithText(
                                imagePath: 'images/Health/H4.png',
                                height: 300,
                                width: 300,
                                labelText: 'Changer la protection',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Soin bucodentaire
                    SingleChildScrollView(
                        scrollDirection : Axis.vertical,
                        child:
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                ImageWithText(
                                  imagePath: 'images/Health/I2.png',
                                  height: 300,
                                  width: 300,
                                  labelText: 'Soins de bouche',
                                ),
                                SizedBox(width: 50,),
                                ImageWithText(
                                  imagePath: 'images/Health/I4.jpg',
                                  height: 300,
                                  width: 300,
                                  labelText: 'Brosser les dents',
                                ),
                              ],
                            ),
                            SizedBox(width: 50), // Ajout de l'espace
                            Column(
                              children: [
                                ImageWithText(
                                  imagePath: 'images/Health/I5.jpg',
                                  height: 300,
                                  width: 300,
                                  labelText: 'Mettre le dentier',
                                ),
                                SizedBox(width: 50,),
                                ImageWithText(
                                  imagePath: 'images/Health/I3.jpg',
                                  height: 300,
                                  width: 300,
                                  labelText: 'Retirer le Dentier',
                                ),
                              ],
                            ),
                            SizedBox(width: 50),
                            Column(
                              children: [
                                ImageWithText(
                                  imagePath: 'images/Health/I3.jpg',
                                  height: 300,
                                  width: 300,
                                  labelText: 'Retirer le Dentier',
                                ),
                              ],
                            ),
                          ],
                        ),
                    ),

                    //Hygiene
                    SingleChildScrollView(
                        scrollDirection : Axis.vertical,
                        child:
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    ImageWithText(
                                      imagePath: 'images/Health/S1.jpg',
                                      height: 300,
                                      width: 300,
                                      labelText: 'Soins des Yeux',
                                    ),
                                  ],
                                ),
                                SizedBox(width: 50), // Ajout de l'espace
                                Column(
                                  children: [
                                    ImageWithText(
                                      imagePath: 'images/Health/S2.jpg',
                                      height: 300,
                                      width: 300,
                                      labelText: 'Se Raser',
                                    ),
                                  ],
                                ),
                                SizedBox(width: 50), // Ajout de l'espace
                                Column(
                                  children: [
                                    ImageWithText(
                                      imagePath: 'images/Health/S4.jpg',
                                      height: 300,
                                      width: 300,
                                      labelText: 'Se Coiffer',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 15,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    ImageWithText(
                                      imagePath: r'images/Health/S6.jpg',
                                      height: 300,
                                      width: 300,
                                      labelText: 'Masser',
                                    ),
                                  ],
                                ),
                                SizedBox(width: 50), // Ajout de l'espace
                                Column(
                                  children: [
                                    ImageWithText(
                                      imagePath: r'images/Health/S7.jpg',
                                      height: 300,
                                      width: 300,
                                      labelText: 'Mettre la crème',
                                    ),
                                  ],
                                ),
                                SizedBox(width: 50), // Ajout de l'espace
                                Column(
                                  children: [
                                    ImageWithText(
                                      imagePath: 'images/Health/S3.jpg',
                                      height: 300,
                                      width: 300,
                                      labelText: 'Couper les ongles',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 15,),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  children: [
                                    ImageWithText(
                                      imagePath: r'images/Health/S5.png',
                                      height: 300,
                                      width: 300,
                                      labelText: 'Faire un Shampoing',
                                    ),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20,),
            ],
          );
        },)

      /*
      ListView(
        children: [
          Center(
            child: Column(
              children: [
                const SingleChildScrollView(
                  scrollDirection : Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          ImageWithText(
                            imagePath: 'images/Health/H1.png',
                            height: 300,
                            width: 150,
                            labelText: 'Se doucher',
                          ),
                        ],
                      ),
                      SizedBox(width: 10), // Ajout de l'espace
                      Column(
                        children: [
                          ImageWithText(
                            imagePath: 'images/Health/H2.jpg',
                            height: 300,
                            width: 150,
                            labelText: 'Se laver',
                          ),
                        ],
                      ),
                      SizedBox(width: 10), // Ajout de l'espace
                      Column(
                        children: [
                          ImageWithText(
                            imagePath: 'images/Health/H3.gif',
                            height: 300,
                            width: 150,
                            labelText: 'Toilette Intime',
                          ),
                        ],
                      ),
                      SizedBox(width: 10), // Ajout de l'espace
                      Column(
                        children: [
                          ImageWithText(
                            imagePath: 'images/Health/H4.png',
                            height: 300,
                            width: 150,
                            labelText: 'Changer la protection',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Image en bas
                horizontalBar(), //  la barre horizontale

                const SingleChildScrollView(
                  scrollDirection : Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          ImageWithText(
                            imagePath: 'images/Health/I2.png',
                            height: 300,
                            width: 150,
                            labelText: 'Soins de bouche',
                          ),
                        ],
                      ),
                      SizedBox(width: 10), // Ajout de l'espace
                      Column(
                        children: [
                          ImageWithText(
                            imagePath: 'images/Health/I4.jpg',
                            height: 300,
                            width: 150,
                            labelText: 'Brosser les dents',
                          ),
                        ],
                      ),
                      SizedBox(width: 10), // Ajout de l'espace
                      Column(
                        children: [
                          ImageWithText(
                            imagePath: 'images/Health/I5.jpg',
                            height: 300,
                            width: 150,
                            labelText: 'Mettre le dentier',
                          ),
                        ],
                      ),
                      SizedBox(width: 10),
                      Column(
                        children: [
                          ImageWithText(
                            imagePath: 'images/Health/I3.jpg',
                            height: 300,
                            width: 150,
                            labelText: 'Retirer le Dentier',
                          ),
                        ],
                      ),
                      SizedBox(width: 10), // Ajout de l'espace
                      Column(
                        children: [
                          ImageWithText(
                            imagePath: 'images/Health/I6.jpg',
                            height: 300,
                            width: 300,
                            labelText: 'Changer le cordon de la sonde',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Seconde image au centre

                horizontalBar(), //  la barre horizontale

                const SingleChildScrollView(
                  scrollDirection : Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          ImageWithText(
                            imagePath: 'images/Health/S1.jpg',
                            height: 300,
                            width: 150,
                            labelText: 'Soins des Yeux',
                          ),
                        ],
                      ),
                      SizedBox(width: 10), // Ajout de l'espace
                      Column(
                        children: [
                          ImageWithText(
                            imagePath: 'images/Health/S2.jpg',
                            height: 300,
                            width: 150,
                            labelText: 'Se Raser',
                          ),
                        ],
                      ),
                      SizedBox(width: 10), // Ajout de l'espace
                      Column(
                        children: [
                          ImageWithText(
                            imagePath: 'images/Health/S4.jpg',
                            height: 300,
                            width: 150,
                            labelText: 'Se Coiffer',
                          ),
                        ],
                      ),
                      SizedBox(width: 10),
                      Column(
                        children: [
                          ImageWithText(
                            imagePath: r'images/Health/S5.png',
                            height: 300,
                            width: 150,
                            labelText: 'Faire un Shampoing',
                          ),
                        ],
                      ),
                      SizedBox(width: 10), // Ajout de l'espace
                      Column(
                        children: [
                          ImageWithText(
                            imagePath: r'images/Health/S6.jpg',
                            height: 300,
                            width: 150,
                            labelText: 'Masser',
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          ImageWithText(
                            imagePath: r'images/Health/S7.jpg',
                            height: 300,
                            width: 150,
                            labelText: 'Mettre la crème',
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          ImageWithText(
                            imagePath: 'images/Health/S3.jpg',
                            height: 300,
                            width: 150,
                            labelText: 'Couper les ongles',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

       */
    );
  }

  // Fonction pour créer une barre verticale
  Widget horizontalBar() {
    return Container(
      width: double.infinity, // Largeur de la barre
      height: 5, // Hauteur de la barre
      color: Colors.green.shade800, // Couleur de la barre
      margin: const EdgeInsets.symmetric(vertical: 10), // Ajout de marge verticale
    );
  }
}


class ImageWithText extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final String labelText;

  const ImageWithText({super.key, 
    required this.imagePath,
    required this.width,
    required this.height,
    required this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RoundedImageWidget(
          imagePath: imagePath,
          width: width,
          height: height,
          labelText: labelText,
        ),
      ],
    );
  }
}

class RoundedImageWidget extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;
  final String labelText;

  const RoundedImageWidget({super.key, 
    required this.imagePath,
    this.width = 50,
    this.height = 50,
    required this.labelText,
  });

  @override
  _RoundedImageWidgetState createState() => _RoundedImageWidgetState();
}

class _RoundedImageWidgetState extends State<RoundedImageWidget> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      /*onTapDown: (details) {
        setState(() {
          isPressed = true;
        });
      },
      onTapUp: (details) async {
        setState(() {
          isPressed = false;
        });

        // Ajouter le texte à la liste avec une virgule
        final need = widget.labelText;

        // Imprimer la liste pour vérification
        print(need);

        // Enregistrez le besoin dans la base de données
        /*try {
          await PatientController.addNeedsToPatient(widget.bedNumber, [need]);
          print('Besoin enregistré avec succès dans la base de données.');
        } catch (error) {
          print('Erreur lors de l\'enregistrement du besoin dans la base de données: $error');
        }*/
      },

       */
      onTap: () {
        setState(() {
          isPressed = !isPressed;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(8.0), // Ajout de la marge autour de l'image
        decoration: BoxDecoration(
          border: isPressed
              ? Border.all(color: Colors.red, width: 3)
              : Border.all(color: Colors.transparent, width: 0),
        ),
        child: Column(
          children: [
            Image.asset(
              widget.imagePath,
              width: widget.width,
              height: widget.height,
            ),
            const SizedBox(height: 5),
            Text(
              widget.labelText,
              style: const TextStyle(fontWeight: FontWeight.bold,
                fontSize: 30,),
            ),
          ],
        ),
      ),
    );
  }
}
