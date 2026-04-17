import 'package:flutter/material.dart';

import '../components/record_widget.dart';

class RemovalView extends StatelessWidget {
  const RemovalView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Center(
          child: Text('ELIMINATION', style: TextStyle(fontSize: 30)),
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
        color: Colors.green.shade200,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Je veux aller aux toilettes', style: TextStyle(fontSize: 30)),
              const SizedBox(height: 10,),
              SingleChildScrollView(
                scrollDirection : Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10,),
                    _buildImageColumn(
                        'images/Douche/D1.jpg', 'Je veux uriner', 300, 300),
                    const SizedBox(width: 50,),
                    _buildImageColumn(
                        'images/Douche/D3.jpg', 'Le pistolet', 300, 300),
                    const SizedBox(width: 50,),
                    _buildImageColumn('images/Douche/D6.png',
                        'Je veux aller à la selle', 300, 300),
                  ],
                ),
              ),
              const SizedBox(height: 20,),
              SingleChildScrollView(
                scrollDirection : Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildImageColumn(
                        'images/Douche/D4.png', 'Le bassin', 300, 300),
                    const SizedBox(width: 50,),
                    _buildImageColumn(
                        'images/Douche/D5.jpg', 'La chaise-pot', 300, 300),
                    const SizedBox(width: 50,),
                    _buildImageColumn(
                        'images/Douche/D2.jpg', 'Les toilettes', 300, 300),
                  ],
                ),
              ),
              SizedBox(height: 20,),
              /*
              LayoutBuilder(
                builder: (context, constraints) {
                  // Determine the number of columns based on the screen width
                  int crossAxisCount = constraints.maxWidth > 800
                      ? 4
                      : constraints.maxWidth > 600
                      ? 3
                      : 2;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20.0,
                    mainAxisSpacing: 20.0,
                    children: [

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

  Widget _buildImageColumn(
      String imagePath, String label, double width, double height) {
    return Column(
      children: [
        ImageWidget(
          imagePath: imagePath,
          width: width,
          height: height,
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
        ),
      ],
    );
  }
}

class ImageWidget extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;

  const ImageWidget({super.key, required this.imagePath, this.width = 50, this.height = 50});

  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isPressed = !isPressed;
        });
      },
      /*
      onTapDown: (details) {
        setState(() {
          isPressed = true;
        });
      },
      onTapUp: (details) {
        setState(() {
          isPressed = false;
        });
      },

       */
      child: Container(
        decoration: BoxDecoration(
          border: isPressed
              ? Border.all(color: Colors.red, width: 3)
              : Border.all(color: Colors.transparent, width: 0),
        ),
        child: Image.asset(
          widget.imagePath,
          width: widget.width,
          height: widget.height,
        ),
      ),
    );
  }
}
