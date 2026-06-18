import 'package:flutter/material.dart';

// Interface pour communiquer avec le parent (PainView)
abstract class TrackingController {
  void freezeTrackingAt(GlobalKey<State<StatefulWidget>> key, double x, double y);
  void unfreezeTracking();
}

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
  bool isPressed  = false;
  bool isHovered  = false; // encadrement par le regard

  void select()   => setState(() => isPressed = true);
  void deselect() => setState(() => isPressed = false);
  void hover()    => setState(() => isHovered = true);
  void unhover()  => setState(() => isHovered = false);

  void toggleSelection() {
    if (isPressed) {
      deselect();
      // Si on désélectionne, dégeler le tracking
      _notifyParentToUnfreeze();
    } else {
      select();
      // Notifier le parent que ce widget a été sélectionné manuellement
      _notifyParentOfSelection();
    }
  }

  // Notifier le parent (PainView) pour figer le tracking
  void _notifyParentOfSelection() {
    // Trouver le TrackingController parent
    final controller = context.findAncestorStateOfType<State<StatefulWidget>>();
    if (controller != null && controller is TrackingController) {
      final box = context.findRenderObject() as RenderBox;
      final pos = box.localToGlobal(Offset.zero);
      final sz  = box.size;
      final cx  = pos.dx + sz.width  / 2;
      final cy  = pos.dy + sz.height / 2;
      
      (controller as TrackingController).freezeTrackingAt(
        widget.key as GlobalKey<State<StatefulWidget>>, cx, cy
      );
    }
  }

  // Notifier le parent pour dégeler le tracking
  void _notifyParentToUnfreeze() {
    final controller = context.findAncestorStateOfType<State<StatefulWidget>>();
    if (controller != null && controller is TrackingController) {
      (controller as TrackingController).unfreezeTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    double borderWidth;

    if (isPressed) {
      borderColor = Colors.red;
      borderWidth = 3;
    } else if (isHovered) {
      borderColor = Colors.orangeAccent;
      borderWidth = 2.5;
    } else {
      borderColor = Colors.transparent;
      borderWidth = 0;
    }

    return GestureDetector(
      onTap: toggleSelection,
      child: Container(
        height: widget.height,
        width:  widget.width,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: borderWidth),
        ),
      ),
    );
  }
}