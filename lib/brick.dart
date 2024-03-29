import 'package:flutter/material.dart';

class MyBrick extends StatelessWidget {
  final x;
  final width;
  final bool isThisTopBrick;

  MyBrick(
      {this.x,
      this.width,
      required this.isThisTopBrick});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment(x, isThisTopBrick ? -0.99 : 0.99),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: width,
          height: 15,
          color: Colors.deepPurple[700])
      ),
      
    );
  }
}