import 'package:flutter/material.dart';

import '../components/record_widget.dart';

class DiscomfortView extends StatelessWidget {
  const DiscomfortView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Center(
          child: Text('INCONFORT',
            style: TextStyle(fontSize: 30),),
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
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.green.shade200,
        padding: const EdgeInsets.all(16.0),
        child: const SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SingleChildScrollView(
                scrollDirection : Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RoundedImageWidget(
                      imagePath: 'images/Discomfort/Dis1.png',
                      width: 300,
                      height: 300,
                      labelText: 'J’ai Froid',
                    ),
                    SizedBox(width: 90,),
                    RoundedImageWidget(
                      imagePath: 'images/Discomfort/Dis2.png',
                      width: 300,
                      height: 300,
                      labelText: 'J’ai chaud',
                    ),
                    SizedBox(width: 50,),
                    RoundedImageWidget(
                      imagePath: 'images/Discomfort/Dis3.jpg',
                      width: 300,
                      height: 300,
                      labelText: 'J’ai soif',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50,),
              SingleChildScrollView(
                scrollDirection : Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RoundedImageWidget(
                      imagePath: 'images/Discomfort/Dis3.png',
                      width: 300,
                      height: 300,
                      labelText: 'Trop de bruit',
                    ),
                    SizedBox(width: 50,),
                    RoundedImageWidget(
                      imagePath: 'images/Discomfort/Dis4.png',
                      width: 300,
                      height: 300,
                      labelText: 'Trop de lumière',
                    ),
                    SizedBox(width: 50,),
                    RoundedImageWidget(
                      imagePath: 'images/Discomfort/Dis12.png',
                      width: 300,
                      height: 300,
                      labelText: 'Je stresse',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50,),
              SingleChildScrollView(
                scrollDirection : Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RoundedImageWidget(
                      imagePath: 'images/Discomfort/Dis12.png',
                      width: 300,
                      height: 300,
                      labelText: 'Je stresse',
                    ),
                    SizedBox(width: 50,),
                    RoundedImageWidget(
                      imagePath: 'images/Discomfort/Dis11.png',
                      width: 300,
                      height: 300,
                      labelText: 'Peur/Angoisse',
                    ),
                    SizedBox(width: 50,),
                    RoundedImageWidget(
                      imagePath: 'images/Discomfort/Dis8.png',
                      width: 300,
                      height: 300,
                      labelText: 'Colère',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50,),
              SingleChildScrollView(
                scrollDirection : Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RoundedImageWidget(
                      imagePath: 'images/Discomfort/Dis10.png',
                      width: 300,
                      height: 300,
                      labelText: 'Je suis Triste',
                    ),
                    SizedBox(width: 50,),
                    RoundedImageWidget(
                      imagePath: 'images/Discomfort/Dis9.png',
                      width: 300,
                      height: 300,
                      labelText: 'Je ne veux pas\nNON',
                    ),
                    SizedBox(width: 50,),
                    RoundedImageWidget(
                      imagePath: 'images/Discomfort/Dis5.png',
                      width: 300,
                      height: 300,
                      labelText: 'Je me sens oppressé',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50,),
              SingleChildScrollView(
                scrollDirection : Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RoundedImageWidget(
                      imagePath: 'images/Discomfort/Dis8.jpg',
                      width: 300,
                      height: 300,
                      labelText: 'J’étouffe',
                    ),
                    SizedBox(width: 50,),
                    RoundedImageWidget(
                      imagePath: 'images/Discomfort/Dis7.png',
                      width: 300,
                      height: 300,
                      labelText: 'Tête qui tourne',
                    ),
                    SizedBox(width: 50,),
                    RoundedImageWidget(
                      imagePath: 'images/Discomfort/Dis6.jpg',
                      width: 300,
                      height: 300,
                      labelText: 'Nausée',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50,),
              SingleChildScrollView(
                scrollDirection : Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RoundedImageWidget(
                      imagePath: 'images/Discomfort/Dis13.jpg',
                      width: 300,
                      height: 300,
                      labelText: 'Je suis fatigué',
                    ),
                    SizedBox(width: 50,),
                    RoundedImageWidget(
                      imagePath: 'images/Discomfort/Dis13.png',
                      width: 300,
                      height: 300,
                      labelText: 'J’ai fait un cauchemar',
                    ),
                    SizedBox(width: 50,),
                    RoundedImageWidget(
                      imagePath: 'images/Discomfort/Dis14.jpg',
                      width: 300,
                      height: 300,
                      labelText: 'J’ai une insomnie',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20,),
              /*
              LayoutBuilder(
                builder: (context, constraints) {
                  // Determine the number of columns based on the screen width
                  int crossAxisCount = constraints.maxWidth > 1200
                      ? 4
                      : constraints.maxWidth > 800
                      ? 3
                      : 2;
          
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    children: const [
                      RoundedImageWidget(
                        imagePath: 'images/Discomfort/Dis1.png',
                        width: 300,
                        height: 300,
                        labelText: 'J’ai Froid',
                      ),
                      RoundedImageWidget(
                        imagePath: 'images/Discomfort/Dis2.png',
                        width: 300,
                        height: 300,
                        labelText: 'J’ai chaud',
                      ),
                      RoundedImageWidget(
                        imagePath: 'images/Discomfort/Dis3.jpg',
                        width: 300,
                        height: 300,
                        labelText: 'J’ai soif',
                      ),
                      RoundedImageWidget(
                        imagePath: 'images/Discomfort/Dis3.png',
                        width: 300,
                        height: 300,
                        labelText: 'Trop de bruit',
                      ),
                      RoundedImageWidget(
                        imagePath: 'images/Discomfort/Dis4.png',
                        width: 300,
                        height: 300,
                        labelText: 'Trop de lumière',
                      ),
          
                      RoundedImageWidget(
                        imagePath: 'images/Discomfort/Dis12.png',
                        width: 300,
                        height: 300,
                        labelText: 'Je stresse',
                      ),
                      RoundedImageWidget(
                        imagePath: 'images/Discomfort/Dis11.png',
                        width: 300,
                        height: 300,
                        labelText: 'Peur/Angoisse',
                      ),
                      RoundedImageWidget(
                        imagePath: 'images/Discomfort/Dis8.png',
                        width: 300,
                        height: 300,
                        labelText: 'Colère',
                      ),
                      RoundedImageWidget(
                        imagePath: 'images/Discomfort/Dis10.png',
                        width: 300,
                        height: 300,
                        labelText: 'Je suis Triste',
                      ),
                      RoundedImageWidget(
                        imagePath: 'images/Discomfort/Dis9.png',
                        width: 300,
                        height: 300,
                        labelText: 'Je ne veux pas\nNON',
                      ),
          
                      RoundedImageWidget(
                        imagePath: 'images/Discomfort/Dis5.png',
                        width: 300,
                        height: 300,
                        labelText: 'Je me sens oppressé',
                      ),
                      RoundedImageWidget(
                        imagePath: 'images/Discomfort/Dis8.jpg',
                        width: 300,
                        height: 300,
                        labelText: 'J’étouffe',
                      ),
                      RoundedImageWidget(
                        imagePath: 'images/Discomfort/Dis7.png',
                        width: 300,
                        height: 300,
                        labelText: 'Tête qui tourne',
                      ),
                      RoundedImageWidget(
                        imagePath: 'images/Discomfort/Dis6.jpg',
                        width: 300,
                        height: 300,
                        labelText: 'Nausée',
                      ),
          
                      RoundedImageWidget(
                        imagePath: 'images/Discomfort/Dis13.jpg',
                        width: 300,
                        height: 300,
                        labelText: 'Je suis fatigué',
                      ),
                      RoundedImageWidget(
                        imagePath: 'images/Discomfort/Dis13.png',
                        width: 300,
                        height: 300,
                        labelText: 'J’ai fait un cauchemar',
                      ),
                      RoundedImageWidget(
                        imagePath: 'images/Discomfort/Dis14.jpg',
                        width: 300,
                        height: 300,
                        labelText: 'J’ai une insomnie',
                      ),
                    ],
                  );
                },
              ),
          
               */
            ],
          ),
        ),
      ),
    );
  }
}

class RoundedImageWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: ImageWidget(
        imagePath: imagePath,
        width: width,
        height: height,
        labelText: labelText,
      ),
    );
  }
}

class ImageWidget extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;
  final String labelText;

  const ImageWidget({super.key, 
    required this.imagePath,
    this.width = 50,
    this.height = 50,
    required this.labelText,
  });

  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      /*onTapDown: (details) {
        setState(() {
          isPressed = true;
        });
      },*/
      onTap: () {
        setState(() {
          isPressed = !isPressed;
        });
      },
      /*
      onTapUp: (details) async {
        setState(() {
          isPressed = false;
        });

        // Ajouter le texte à la liste avec une virgule
        final need = widget.labelText;

        // Imprimer la liste pour vérification
        print(need);

        // Enregistrez le besoin dans la base de données
        /* try {
          await PatientController.addNeedsToPatient(widget.bedNumber, [need]);
          print('Besoin enregistré avec succès dans la base de données.');
        } catch (error) {
          print('Erreur lors de l\'enregistrement du besoin dans la base de données: $error');
        }*/
      },*/
      child: Container(
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30, // Augmentez cette valeur selon vos besoins
              ),
              textAlign: TextAlign.center, // Pour centrer le texte si multiligne
            ),
          ],
        ),
      ),
    );
  }
}
