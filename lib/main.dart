import 'dart:async';
// import 'package:ble5/ball.dart';
// import 'package:ble5/brick.dart';
import 'package:ble5/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:location_permissions/location_permissions.dart';
import 'dart:io' show Platform;

// This flutter app demonstrates an usage of the flutter_reactive_ble flutter plugin
// This app works only with BLE devices which advertise with a Nordic UART Service (NUS) UUID
Uuid _UART_UUID = Uuid.parse("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
Uuid _UART_RX   = Uuid.parse("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");
Uuid _UART_TX   = Uuid.parse("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");


final flutterReactiveBle = FlutterReactiveBle();
List<DiscoveredDevice> _foundBleUARTDevices = [];
late StreamSubscription<DiscoveredDevice> _scanStream;
late Stream<ConnectionStateUpdate> _currentConnectionStream;
late StreamSubscription<ConnectionStateUpdate> _connection;
late QualifiedCharacteristic _txCharacteristic;
late QualifiedCharacteristic _rxCharacteristic;
late Stream<List<int>> _receivedDataStream;
late TextEditingController _dataToSendText;
bool _scanning = false;
bool _connected = false;
String _logTexts = "";
List<String> _receivedData = [];
int _numberOfMessagesReceived = 0;

//screen 2
List<String> _receivedData2 = [];
int _numberOfMessagesReceived2 = 0;
late Stream<List<int>> _receivedDataStream2;

// ignore: constant_identifier_names
enum Direction { UP, DOWN, LEFT, RIGHT }

// brick variables
double brickWidth = 0.3; // out of 2, 2 being the entire width of the screen
double bottomBrickX = 0;
double topBrickX = 0;
var topBrickDirection = Direction.LEFT;

//ball variables
double pongX = 0;
double pongY = 0;
double pongXincrement = 0.005;
double pongYincrement = 0.015;  
var pongDirectionX = Direction.LEFT;
var pongDirectionY = Direction.UP;

//other variables
int player1score = 0;
int player2score = 0;



void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter_reactive_ble example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(title: 'Flutter_reactive_ble UART example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  void initState() {
    super.initState();
    _dataToSendText = TextEditingController();
  }

  void refreshScreen() {
    setState(() {});
  }

  void _sendData() async {
      await flutterReactiveBle.writeCharacteristicWithResponse(_rxCharacteristic, value: _dataToSendText.text.codeUnits);
  }

  void onNewReceivedData(List<int> data) {
    _numberOfMessagesReceived += 1;
    _receivedData.add( "$_numberOfMessagesReceived) ${String.fromCharCodes(data)}");
    if (_receivedData.length > 7) {
      _receivedData.removeAt(0);
    }
    refreshScreen();
  }

  void _disconnect() async {
    await _connection.cancel();
    _connected = false;
    refreshScreen();
  }

  void _stopScan() async {
    await _scanStream.cancel();
    _scanning = false;
    refreshScreen();
  }

  void _changeScreen() async {
    Navigator.push(  
      context,  
      MaterialPageRoute(builder: (context) => const MySecondPage(title: 'Second Page',)),  
    );
    refreshScreen();
  }

  Future<void> showNoPermissionDialog() async => showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) => AlertDialog(
          title: const Text('No location permission '),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('No location permission granted.'),
                Text('Location permission is required for BLE to function.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Acknowledge'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
    );

  void _startScan() async {
    bool goForIt=false;
    PermissionStatus permission;
    if (Platform.isAndroid) {
      permission = await LocationPermissions().requestPermissions();
      if (permission == PermissionStatus.granted)
        goForIt=true;
    } else if (Platform.isIOS) {
      goForIt=true;
    }
    if (goForIt) { //TODO replace True with permission == PermissionStatus.granted is for IOS test
      _foundBleUARTDevices = [];
      _scanning = true;
      refreshScreen();
      _scanStream =
          flutterReactiveBle.scanForDevices(withServices: [_UART_UUID]).listen((
              device) {
            if (_foundBleUARTDevices.every((element) =>
            element.id != device.id)) {
              _foundBleUARTDevices.add(device);
              refreshScreen();
            }
          }, onError: (Object error) {
            _logTexts =
                "${_logTexts}ERROR while scanning:$error \n";
            refreshScreen();
          }
          );
    }
    else {
      await showNoPermissionDialog();
    }
  }

  void onConnectDevice(index) {
    _currentConnectionStream = flutterReactiveBle.connectToAdvertisingDevice(
      id:_foundBleUARTDevices[index].id,
      prescanDuration: const Duration(seconds: 1),
      withServices: [_UART_UUID, _UART_RX, _UART_TX],
    );
    _logTexts = "";
    refreshScreen();
    _connection = _currentConnectionStream.listen((event) {
      var id = event.deviceId.toString();
      switch(event.connectionState) {
        case DeviceConnectionState.connecting:
          {
            _logTexts = "${_logTexts}Connecting to $id\n";
            break;
          }
        case DeviceConnectionState.connected:
          {
            _connected = true;
            _logTexts = "${_logTexts}Connected to $id\n";
            _numberOfMessagesReceived = 0;
            _receivedData = [];
            _receivedData2 = [];
            _txCharacteristic = QualifiedCharacteristic(serviceId: _UART_UUID, characteristicId: _UART_TX, deviceId: event.deviceId);
            _receivedDataStream = flutterReactiveBle.subscribeToCharacteristic(_txCharacteristic);
            _receivedDataStream.listen((data) {
               onNewReceivedData(data);
            }, onError: (dynamic error) {
              _logTexts = "${_logTexts}Error:$error$id\n";
            });
            _rxCharacteristic = QualifiedCharacteristic(serviceId: _UART_UUID, characteristicId: _UART_RX, deviceId: event.deviceId);
            break;
          }
        case DeviceConnectionState.disconnecting:
          {
            _connected = false;
            _logTexts = "${_logTexts}Disconnecting from $id\n";
            break;
          }
        case DeviceConnectionState.disconnected:
          {
            _logTexts = "${_logTexts}Disconnected from $id\n";
            break;
          }
      }
      refreshScreen();
    });
  }

  //  PAGINA CONNESSIONE

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const Text("BLE UART Devices found:"),
            Container(
                margin: const EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.blue,
                  width:2
                )
              ),
              height: 100,
              child: ListView.builder(
                  itemCount: _foundBleUARTDevices.length,
                  itemBuilder: (context, index) => Card(
                        child: ListTile(
                          dense: true,
                          enabled: !((!_connected && _scanning) || (!_scanning && _connected)),
                          trailing: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              (!_connected && _scanning) || (!_scanning && _connected)? (){}: onConnectDevice(index);
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              alignment: Alignment.center,
                              child: const Icon(Icons.add_link),
                            ),
                          ),
                          subtitle: Text(_foundBleUARTDevices[index].id),
                          title: Text("$index: ${_foundBleUARTDevices[index].name}"),
                    ))
              )
            ),
            const Text("Status messages:"),
            Container(
                margin: const EdgeInsets.all(3.0),
                width:1400,
                decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.blue,
                  width:2
                  )
               ),
               height: 90,
               child: Scrollbar(

                   child: SingleChildScrollView(
                      child: Text(_logTexts)
               )
               )
            ),
            const Text("Received data:"),
            Container(
                margin: const EdgeInsets.all(3.0),
                width:1400,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.blue,
                        width:2
                    )
                ),
                height: 130,
                child: Text(_receivedData.join("\n"))
            ),
            const Text("Send message:"),
            Container(
                margin: const EdgeInsets.all(3.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.blue,
                        width:2
                    )
                ),
                child: Row(
                    children: <Widget> [
                      Expanded(
                          child: TextField(
                            enabled: _connected,
                            controller: _dataToSendText,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter a string'
                          ),
                        )
                      ),
                      ElevatedButton(
                          onPressed: _connected ? _sendData: (){},
                          child: Icon(
                            Icons.send,
                            color:_connected ? Colors.blue : Colors.grey,
                          )
                      ),
                    ]
            ))
           ],
        ),
      ),
      persistentFooterButtons: [
        SizedBox(
          height: 35,
          child: Column(
            children: [
              if (_scanning) const Text("Scanning: Scanning") else const Text("Scanning: riposo"),
              if (_connected) const Text("Connected") else const Text("disconnected."),
            ],
          ) ,
        ),
        ElevatedButton(
          onPressed: !_scanning && !_connected ? _startScan : (){},
          child: Icon(
            Icons.play_arrow,
            color: !_scanning && !_connected ? Colors.blue: Colors.grey,
          ),
        ),
        ElevatedButton(
          onPressed: _scanning ? _stopScan: (){},
          child: Icon(
            Icons.stop,
            color:_scanning ? Colors.blue: Colors.grey,
          )
        ),
        ElevatedButton(
            onPressed: _connected ? _disconnect: (){},
            child: Icon(
              Icons.cancel,
              color:_connected ? Colors.blue:Colors.grey,
            )
        ),
        ElevatedButton(
            onPressed: _connected ? _changeScreen: (){
              // _receivedData2 = _receivedData;
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreen,
            ),
            child: Icon(
              Icons.skateboarding_rounded,
              color:_connected ? Colors.blue:Colors.grey,
            )
        )
      ],
    );
}



//  SECONDA PAGINA


class MySecondPage extends StatefulWidget {
  const MySecondPage({super.key, required this.title});
  final String title;
  @override
  _SecondRouteState createState() => _SecondRouteState();
}


class _SecondRouteState extends State<MySecondPage> { 

  void refreshScreen() {
    setState(() {});
  }


  void onNewReceivedData2(List<int> data) {
    _numberOfMessagesReceived2 += 1;
    _receivedData2.add( "$_numberOfMessagesReceived2) ${String.fromCharCodes(data)}");
    if (_receivedData2.length > 7) {
      _receivedData2.removeAt(0);
      _receivedData2.removeAt(_receivedData2.length - 1);
    }
    refreshScreen();
  }

  
  double calculateDist() {

  if (_receivedData2.length < 4) {
      return 0;
  } else {
      int lastDist = _receivedData2.length -1;
      String ultimaDistanza = _receivedData2[lastDist];        
      const startchar = ":";
      int startindex1 = ultimaDistanza.indexOf(startchar);
      String distanzaUltima = ultimaDistanza.substring(startindex1 + 2, ultimaDistanza.length-4);
      int distance1 = int.parse(distanzaUltima);

      int thirdDist = _receivedData2.length -2;
      String terzaDistanza = _receivedData2[thirdDist];
      int startindex2 = terzaDistanza.indexOf(startchar);
      String distanzaPenultima = terzaDistanza.substring(startindex2 + 2, terzaDistanza.length-4);
      int distance2 = int.parse(distanzaPenultima);
      //se dist2 < dist1 allora la distanza è aumentata, movimento verso sinistra 
      //se dist2 > dist1 allora la distanza è diminuita, movimento verso destra  
      double changeDist = (distance2 - distance1) / 100;
      
      return changeDist; // Return the value of changeDist
    }
  }

  // Niccolò Damioli cereates this function on date 13/07/2023
  void move() {
    double change = calculateDist() * brickWidth;
      // move only if it doesn't go off the left edge and off the right one
    if (!((bottomBrickX + change) < -1.2) && !((bottomBrickX + brickWidth + change) > 1.2)) {
      bottomBrickX += change;
    }    
    // setState(() {   
    // });
    refreshScreen();
  }

  
  void updateData() {     // Niccolò Damioli cereated this function on date 13/07/2023
    _receivedDataStream2 = flutterReactiveBle.subscribeToCharacteristic(_txCharacteristic);
    _receivedDataStream2.listen((data) {
      onNewReceivedData2(data);
    }, onError: (dynamic error) {
    _logTexts = "ERRORE/n";
    });
  }


  //  GAME LOGIC
  void startGame() {

    Timer.periodic(const Duration(milliseconds: 25), (timer) {
      updateDirection();
      
      // move the enemy (top brick)
      moveEnemy();

      // move ball
      moveBall();

      // check if ball is out of bounds
      if (isPlayer1Dead()) {
        player2score++;
        timer.cancel();
        resetGame();
      }
      if (isPlayer2Dead()) {
        player1score++;
        timer.cancel();
        resetGame();
      }
    });
  }

  void updateDirection() {
    setState(() {
      // set vertical Direction for ball
      if (pongY >= 0.95) {
        pongDirectionY = Direction.UP;
        // if the ball hits the left side of the brick
        // Direction of pong becomes left
        if (pongX <= bottomBrickX + brickWidth / 2) {
          pongDirectionX = Direction.LEFT;
        }
        // if the ball hits the left side of the brick
        // Direction of pong becomes left
        if (pongX >= bottomBrickX + brickWidth / 2) {
          pongDirectionX = Direction.RIGHT;
        }
      }
      if (pongY <= -0.95) {
        pongDirectionY = Direction.DOWN;
      }

      // set horizontal Direction for ball
      if (pongX >= 1) {
        pongDirectionX = Direction.LEFT;
      }
      if (pongX <= -1) {
        pongDirectionX = Direction.RIGHT;
      }

      // set horizontal Direction for top brick
      if (topBrickX >= 1) {
        topBrickDirection = Direction.LEFT;
      } else if (topBrickX <= -1) {
        topBrickDirection = Direction.RIGHT;
      }
    });
  }

  void moveBall() {
    // y movement for ball
    setState(() {
      if (pongDirectionY == Direction.DOWN) {
        pongY = pongYincrement;
      } else if (pongDirectionY == Direction.UP) {
        pongY -= pongYincrement;
      }
    });

    // x movement for ball
    setState(() {
      if (pongDirectionX == Direction.LEFT) {
        pongX -= pongXincrement;
      } else if (pongDirectionX == Direction.RIGHT) {
        pongX += pongXincrement;
      }
    });
  }

  void moveEnemy() {
    // horizontal movement for top brick
    setState(() {
      topBrickX = pongX;
    });
  }

  bool isPlayer1Dead() {
    if (pongY >= 0.95 && pongX + 0.01 < bottomBrickX - 0.15) {
      return true;
    } else if (pongY >= 0.95 && pongX - 0.01 > bottomBrickX + brickWidth) {
      return true;
    }
    return false;
  }

  bool isPlayer2Dead() {
    if (pongY <= -0.95 && pongX + 0.01 < topBrickX) {
      return true;
    } else if (pongY <= -0.95 && pongX - 0.01 > topBrickX + brickWidth) {
      return true;
    }
    return false;
  }

  // void _showDialog() {
  //   showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (BuildContext context) {
  //         return AlertDialog(
  //           backgroundColor: Colors.deepPurple,
  //           title: Center(
  //             child: Text(
  //               "PURPLE WIN",
  //               style: TextStyle(color: Colors.white),
  //             ),
  //           ),
  //           actions: [
  //             GestureDetector(
  //               onTap: resetGame,
  //               child: ClipRRect(
  //                 borderRadius: BorderRadius.circular(5),
  //                 child: Container(
  //                   padding: EdgeInsets.all(7),
  //                   color: Colors.deepPurple[100],
  //                   child: Text(
  //                     'PLAY AGAIN',
  //                     style: TextStyle(color: Colors.deepPurple[800]),
  //                   ),
  //                 ),
  //               ),
  //             )
  //           ],
  //         );
  //       });
  // }

  //void resetGame() {
    // Navigator.pop(context); // dismisses the alert dialog
    setState(() {
      bottomBrickX = 0;
      topBrickX = 0;
      pongX = 0;
      pongY = 0;
      pongDirectionX = Direction.LEFT;
      pongDirectionY = Direction.UP;
      Future.delayed(const Duration(seconds: 3), (){
        startGame();
      });
    });
  }

  

  @override
  Widget build(BuildContext context) {  

    // screen dimensions
    double totalWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(  
      appBar: AppBar(  
        title: const Text("Second Screen"),  
      ),  
      body: Center(
          child: 
            MyGame(
              topX: topBrickX, 
              bottomX: 0.8 * bottomBrickX, 
              width: totalWidth * brickWidth / 2, 
              ballX: pongX, 
              ballY: pongY, 
              player1score: player1score, 
              player2score: player2score)
      ), 
      persistentFooterButtons: [
        ElevatedButton(  
          onPressed: () {  
            updateData();  
            Timer.periodic(const Duration(milliseconds: 25), (timer) {
              move();
            });
            startGame();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightGreen,
          ),
          child: const Text('Go!'),  
        ),
      ],
    );  
  }
}