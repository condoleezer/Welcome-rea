import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../components/record_widget.dart';
import '../components/video_player_widget.dart';

class InstalView extends StatefulWidget {
  const InstalView({super.key});

  @override
  _InstalViewState createState() => _InstalViewState();
}

class _InstalViewState extends State<InstalView> {
  late VideoPlayerController _controller;
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.asset('images/Installation/mise-au-fauteuil.mp4')
          ..initialize().then((_) {
            if (mounted) {
              setState(() {});
            }
          });
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Center(
          child: Text('INSTALLATION/MOBILISATION', style: TextStyle(fontSize: 30)),
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
      backgroundColor: Colors.green.shade200,
      body: LayoutBuilder(builder: (context, constraints) {
        return Column(
          children: [
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
                          width: 300,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: _currentPageIndex == 0
                                ? Colors.green.shade900
                                : Colors.transparent,
                          ),
                          child: Center(
                              child: Text(
                                'Les attaches',
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
                                'Mise au fauteuil',
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
                          width: 300,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: _currentPageIndex == 2
                                  ? Colors.green.shade900
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20)),
                          child: Center(
                              child: Text(
                                'Se coucher',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 30,
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
                          height: 60,
                          width: 300,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: _currentPageIndex == 3
                                  ? Colors.green.shade900
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20)),
                          child: Center(
                              child: Text(
                                'Oreiller',
                                style: TextStyle(
                                    fontSize: 30,
                                    color: _currentPageIndex == 3
                                        ? Colors.white
                                        : Colors.black),
                              ))),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(4,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut);
                      },
                      child: Container(
                          height: 60,
                          width: 300,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: _currentPageIndex == 4
                                  ? Colors.green.shade900
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20)),
                          child: Center(
                              child: Text(
                                'Se lever',
                                style: TextStyle(
                                    fontSize: 30,
                                    color: _currentPageIndex == 4
                                        ? Colors.white
                                        : Colors.black),
                              ))),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(5,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut);
                      },
                      child: Container(
                          height: 60,
                          width: 400,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: _currentPageIndex == 5
                                  ? Colors.green.shade900
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20)),
                          child: Center(
                              child: Text(
                                'Mobilisation Tête/Pieds',
                                style: TextStyle(
                                    fontSize: 30,
                                    color: _currentPageIndex == 5
                                        ? Colors.white
                                        : Colors.black),
                              ))),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                },
                children: const [
                  // Les attaches
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 40,),
                        ImageWidget(
                          imagePath: 'images/Installation/I1.png',
                          labelText: 'Attacher les mains',
                          width: 300,
                          height: 300,
                        ),
                      ],
                    ),
                  ),

                  // Mise en fauteuil
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                'Nous allons vous mettre au fauteuil grâce au lève-malade qui se trouve \n au plafond et à un harnais que nous allons placer entre les \n draps et votre peau. Cela rappellera la sensation d’une balançoire, \n il faut rester calme tout le long du transfert, bien écouter le personnel \n qui va vous guider. Il est impératif de garder les mains sur le ventre \n tout le long de la mise en place au fauteuil. Une fois au fauteuil, nous \n vous laisserons le harnais dans le dos pour pouvoir s’en resservir pour \n vous remettre dans le lit.',
                                maxLines: 6,
                                style: TextStyle(fontSize: 30)
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 40,),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ImageWidget(
                                imagePath: 'images/Installation/I2.png',
                                labelText: '',
                                width: 400,
                                height: 300,
                              ),
                              ImageWidget(
                                imagePath: 'images/Installation/I3.png',
                                labelText: '',
                                width: 400,
                                height: 300,
                              ),
                              ImageWidget(
                                imagePath: 'images/Installation/I4.png',
                                labelText: '',
                                width: 400,
                                height: 300,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 40,
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ImageWidget(
                                imagePath: 'images/Installation/I5.png',
                                labelText: '',
                                width: 400,
                                height: 300,
                              ),
                              ImageWidget(
                                imagePath: 'images/Installation/I6.png',
                                labelText: '',
                                width: 400,
                                height: 300,
                              ),
                              ImageWidget(
                                imagePath: 'images/Installation/I7.png',
                                labelText: '',
                                width: 400,
                                height: 300,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ImageWidget(
                                imagePath: 'images/Installation/I8.png',
                                labelText: '',
                                width: 400,
                                height: 300,
                              ),
                              ImageWidget(
                                imagePath: 'images/Installation/I9.png',
                                labelText: '',
                                width: 400,
                                height: 300,
                              ),
                              VideoPlayerWidget(
                                url: 'images/Installation/mise-au-fauteuil.mp4',
                                width: 300,
                                height: 300,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  //Se coucher
                  SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ImageWidget(
                                imagePath: 'images/Installation/I10.png',
                                labelText: '',
                                width: 300,
                                height: 300,
                              ),SizedBox(
                                width: 40,
                              ),
                              VideoPlayerWidget(
                                url: 'images/Installation/se_recoucher.mp4',
                                width: 300,
                                height: 300,
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 40,
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ImageWidget(
                                imagePath: 'images/Installation/I2.png',
                                labelText: '',
                                width: 400,
                                height: 300,
                              ),
                              ImageWidget(
                                imagePath: 'images/Installation/I3.png',
                                labelText: '',
                                width: 400,
                                height: 300,
                              ),
                              ImageWidget(
                                imagePath: 'images/Installation/I4.png',
                                labelText: '',
                                width: 400,
                                height: 300,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 40,
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ImageWidget(
                                imagePath: 'images/Installation/I5.png',
                                labelText: '',
                                width: 400,
                                height: 300,
                              ),
                              ImageWidget(
                                imagePath: 'images/Installation/I6.png',
                                labelText: '',
                                width: 400,
                                height: 300,
                              ),
                              ImageWidget(
                                imagePath: 'images/Installation/I7.png',
                                labelText: '',
                                width: 400,
                                height: 300,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ImageWidget(
                                imagePath: 'images/Installation/I8.png',
                                labelText: '',
                                width: 400,
                                height: 300,
                              ),
                              ImageWidget(
                                imagePath: 'images/Installation/I9.png',
                                labelText: '',
                                width: 400,
                                height: 300,
                              ),
                              VideoPlayerWidget(
                                url: 'images/Installation/mise-au-fauteuil.mp4',
                                width: 300,
                                height: 300,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  //Oreiller
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ImageWidget(
                          imagePath: 'images/Installation/I11.png',
                          labelText: '',
                          width: 400,
                          height: 300,
                        ),SizedBox(
                          width: 40,
                        ),
                        ImageWidget(
                          imagePath: 'images/Installation/I12.png',
                          labelText: '',
                          width: 400,
                          height: 300,
                        ),
                      ],
                    ),
                  ),

                  //Se lever
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ImageWidget(
                          imagePath: 'images/Installation/I13.png',
                          labelText: '',
                          width: 400,
                          height: 300,
                        ),SizedBox(
                          width: 40,
                        ),
                        ImageWidget(
                          imagePath: 'images/Installation/I14.png',
                          labelText: '',
                          width: 400,
                          height: 300,
                        ),
                      ],
                    ),
                  ),

                  //Mobilisation  de la tête et/ou des pieds
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ImageWidget(
                                imagePath: 'images/Installation/I15.png',
                                labelText: 'Lever les pieds',
                                width: 300,
                                height: 300,
                              ),SizedBox(width: 40,),
                              ImageWidget(
                                imagePath: 'images/Installation/I16.png',
                                labelText: 'Lever la tête',
                                width: 300,
                                height: 300,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 40,),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ImageWidget(
                                imagePath: 'images/Installation/I17.png',
                                labelText: 'Baisser les pieds',
                                width: 300,
                                height: 300,
                              ),SizedBox(width: 40,),
                              ImageWidget(
                                imagePath: 'images/Installation/I18.png',
                                labelText: 'Baisser la tête',
                                width: 300,
                                height: 300,
                              ),
                            ],
                          ),
                        ),SizedBox(height: 20,),
                      ],
                    ),
                  )
                ],
              ),
            ),

            /*
            Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade900,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Padding(
                padding:  EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Text(
                      'Les attaches',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SingleChildScrollView(
              scrollDirection : Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Attacher les mains pour votre sécurité', maxLines: 2,),
                  ImageWidget(imagePath: 'images/Installation/I1.png', labelText: '', width: 250, height: 250,),
                  Text('Détacher les mains')
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Image en bas
            horizontalBar(),
            Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade900,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Padding(
                padding:  EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Text(
                      'Mise en fauteuil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SingleChildScrollView(
              scrollDirection : Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Nous allons vous mettre au fauteuil grâce au lève-malade qui se trouve \n au plafond et à un harnais que nous allons placer entre les \n draps et votre peau. Cela rappellera la sensation d’une balançoire, \n il faut rester calme tout le long du transfert, bien écouter le personnel \n qui va vous guider. Il est impératif de garder les mains sur le ventre \n tout le long de la mise en place au fauteuil. Une fois au fauteuil, nous \n vous laisserons le harnais dans le dos pour pouvoir s’en resservir pour \n vous remettre dans le lit.', maxLines: 6,),
                  ImageWidget(imagePath: 'images/Installation/I2.png', labelText: '', width: 250, height: 250,),
                ],
              ),
            ),
            const SizedBox(height: 10,),
            const SingleChildScrollView(
              scrollDirection : Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ImageWidget(imagePath: 'images/Installation/I3.png', labelText: '', width: 250, height: 250,),
                  ImageWidget(imagePath: 'images/Installation/I4.png', labelText: '', width: 250, height: 250,),
                  ImageWidget(imagePath: 'images/Installation/I5.png', labelText: '', width: 250, height: 250,),
                  ImageWidget(imagePath: 'images/Installation/I6.png', labelText: '', width: 250, height: 250,),
                ],
              ),
            ),
            const SizedBox(height: 10,),
            const SingleChildScrollView(
              scrollDirection : Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ImageWidget(imagePath: 'images/Installation/I7.png', labelText: '', width: 250, height: 250,),
                  ImageWidget(imagePath: 'images/Installation/I8.png', labelText: '', width: 250, height: 250,),
                  ImageWidget(imagePath: 'images/Installation/I9.png', labelText: '', width: 250, height: 250,),
                  VideoPlayerWidget(url: 'images/Installation/mise-au-fauteuil.mp4',)
                ],
              ),
            ),

            const SizedBox(height: 30),
            horizontalBar(),
            Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade900,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Padding(
                padding:  EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Text(
                      'Se recoucher',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SingleChildScrollView(
              scrollDirection : Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ImageWidget(imagePath: 'images/Installation/I10.png', labelText: '', width: 250, height: 250,),
                  VideoPlayerWidget(url: 'images/Installation/se_recoucher.mp4',)
                  ],
              ),
            ),

            const SizedBox(height: 30),
            horizontalBar(),
            Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade900,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Padding(
                padding:  EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Text(
                      'Oreiller',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SingleChildScrollView(
              scrollDirection : Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ImageWidget(imagePath: 'images/Installation/I11.png', labelText: '', width: 250, height: 250,),
                  ImageWidget(imagePath: 'images/Installation/I12.png', labelText: '', width: 250, height: 250,),
                ],
              ),
            ),

            const SizedBox(height: 30),
            horizontalBar(),
            Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade900,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Padding(
                padding:  EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Text(
                      'Se lever',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SingleChildScrollView(
              scrollDirection : Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ImageWidget(imagePath: 'images/Installation/I13.png', labelText: '', width: 250, height: 250,),
                  ImageWidget(imagePath: 'images/Installation/I14.png', labelText: '', width: 250, height: 250,),
                ],
              ),
            ),

            const SizedBox(height: 30),
            horizontalBar(),
            Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade900,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Padding(
                padding:  EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Text(
                      'Mobilisation de la tête et/ou les pieds',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SingleChildScrollView(
              scrollDirection : Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ImageWidget(imagePath: 'images/Installation/I15.png', labelText: 'Lever les pieds', width: 250, height: 250,),
                  ImageWidget(imagePath: 'images/Installation/I16.png', labelText: 'Lever la tête', width: 250, height: 250,),
                ],
              ),
            ),
            const SizedBox(height: 10,),
            const SingleChildScrollView(
              scrollDirection : Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ImageWidget(imagePath: 'images/Installation/I17.png', labelText: 'Baisser les pieds', width: 250, height: 250,),
                  ImageWidget(imagePath: 'images/Installation/I18.png', labelText: 'Baisser la tête', width: 250, height: 250,),
                ],
              ),
            ),

             */
          ],
        );
      },),
    );
  }
}

// Fonction pour créer une barre verticale
Widget horizontalBar() {
  return Container(
    width: double.infinity, // Largeur de la barre
    height: 5, // Hauteur de la barre
    color: Colors.green.shade800, // Couleur de la barre
    margin:
        const EdgeInsets.symmetric(vertical: 10), // Ajout de marge verticale
  );
}

class ImageWidget extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;
  final String labelText;

  const ImageWidget({
    super.key,
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
      onTapDown: (details) {
        setState(() {
          isPressed = true;
        });
      },
      onTapUp: (details) {
        setState(() {
          isPressed = false;
        });

        final need = widget.labelText;
        print(need);

        // Enregistrez le besoin dans la base de données
        /*try {
          await PatientController.addNeedsToPatient(widget.bedNumber, [need]);
          print('Besoin enregistré avec succès dans la base de données.');
        } catch (error) {
          print('Erreur lors de l\'enregistrement du besoin dans la base de données: $error');
        }*/
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
