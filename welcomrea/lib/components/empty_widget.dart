import 'package:flutter/material.dart';
import 'dart:async';

class EmptyWidget extends StatefulWidget {
  const EmptyWidget({
    Key? key,
    this.width = 50,
    this.height = 50,
  }) : super(key: key);

  final double width;
  final double height;

  @override
  EmptyWidgetState createState() => EmptyWidgetState();
}

class EmptyWidgetState extends State<EmptyWidget> {
  bool isPressed = false;

  void select() {
    setState(() {
      isPressed = true;
    });
  }

  void deselect() {
    setState(() {
      isPressed = false;
    });
  }

  // Permet de basculer l'état (sélectionné/désélectionné)
  void toggleSelection() {
    if (isPressed) {
      deselect();
    } else {
      select();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: () {
          // Permet à l'utilisateur de changer manuellement l'état
              toggleSelection();
              },
      child:Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        border: isPressed
            ? Border.all(color: Colors.red, width: 3)
            : Border.all(color: Colors.transparent, width: 0),
      ),
    )
    );
  }
}