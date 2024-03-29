//import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';

class MyPongBall extends StatelessWidget {
  //final bool go;
  final x;
  final y;

  MyPongBall({this.x, this.y});

  @override
  Widget build(BuildContext context) {
    return 
      Container(
          alignment: Alignment(x, y),
          child: Container(
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: Colors.deepPurple[700]),
            width: 14,
            height: 14,
          ),
      );
  }
}
