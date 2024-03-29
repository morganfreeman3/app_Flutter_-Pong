import 'package:ble5/ball.dart';
import 'package:ble5/brick.dart';
import 'package:ble5/score.dart';
import 'package:flutter/material.dart';

class MyGame extends StatelessWidget {
  final topX;
  final bottomX;
  final width;
  // final bool topBrick; 
  // final bool bottomBrick;
  final ballX;
  final ballY;
  final int player1score;
  final int player2score;


  MyGame(
      {required this.topX,
      required this.bottomX,
      required this.width,
      // required this.topBrick,
      // required this.bottomBrick,
      required this.ballX,
      required this.ballY,
      required this.player1score,
      required this.player2score});

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.blueGrey[100],
        body: Center(
              child: Stack(
                children: [
                  ScoreBoard(
                    player1score: player1score,
                    player2score: player2score,
                  ),
                  MyBrick(
                      x: topX,
                      width: width,
                      isThisTopBrick: true,
                    ),
                  MyPongBall(
                      x: ballX,
                      y: ballY,
                  ),
                    MyBrick(
                      x: bottomX,
                      width: width,
                      isThisTopBrick: false,
                    ),
                  ],
              ),
            ), 
      );
    } 
}



  




// persistentFooterButtons: [
//         ElevatedButton(  
//               onPressed: () {},
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.lightGreen,
//               ),
//               child: const Text('Go!'),  
//             ),]





// Widget build(BuildContext context) {
//     return Expanded(
//             child: Container(
//               color: Colors.blueGrey[200],
//               padding: EdgeInsets.all(5.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   MyBrick(
//                     x: topX,
//                     width: width,
//                     isThisTopBrick: true,
//                   ),
//                   MyPongBall(
//                     x: ballX,
//                     y: ballY,
//                   ),
//                   MyBrick(
//                     x: bottomX,
//                     width: width,
//                     isThisTopBrick: false,
//                   ),                  
//                 ],
//               ),
//             ),
//           ); 
//   }







