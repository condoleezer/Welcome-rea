import 'package:flutter/material.dart';

import '../components/record_widget.dart';

class FeedView extends StatelessWidget {
  const FeedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Center(
          child: Text('ALIMENTATION', style: TextStyle(fontSize: 30)),
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
              // Code pour accéder au microphone
            },
          ),
        ],
      ),
      backgroundColor: Colors.green.shade200,
      body: const Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20,),
              SingleChildScrollView(
                scrollDirection : Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ImageWidget(
                      imagePath: 'images/Feed/Alim6.png',
                      width: 300,
                      height: 300,
                      labelText: 'J\'ai faim',
                    ),
                    SizedBox(width: 50,),
                    ImageWidget(
                      imagePath: 'images/Feed/Alim.png',
                      width: 300,
                      height: 300,
                      labelText: 'J\'ai Soif',
                    ),
                    SizedBox(width: 50,),
                    ImageWidget(
                      imagePath: 'images/Feed/Alim5.jpg',
                      width: 300,
                      height: 300,
                      labelText: 'Je veux un Thé',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50,),
              SingleChildScrollView(
                scrollDirection : Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ImageWidget(
                      imagePath: 'images/Feed/Alim2.jpg',
                      width: 300,
                      height: 300,
                      labelText: 'Je veux du sel',
                    ),
                    SizedBox(width: 50,),
                    ImageWidget(
                      imagePath: 'images/Feed/Alim1.jpg',
                      width: 300,
                      height: 300,
                      labelText: 'Je veux du Sucre/sucrette ',
                    ),
                    SizedBox(width: 50,),
                    ImageWidget(
                      imagePath: 'images/Feed/Alim4.jpg',
                      width: 300,
                      height: 300,
                      labelText: 'Je veux un Café',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20,),
            ],
          ),
        ),
      ),
    );
  }
}

/*
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

 */

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
      /*
      onTapDown: (details) {
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
            const SizedBox(height: 10),
            Text(
              widget.labelText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30,),
            ),
          ],
        ),
      ),
    );
  }
}
