import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bl/allReadings.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_bl/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class FlutterBlueApp extends StatefulWidget {
  FlutterBlueApp({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _FlutterBlueAppState createState() => new _FlutterBlueAppState();
}

class _FlutterBlueAppState extends State<FlutterBlueApp> {
  Timer _timer;
  FlutterBlue _flutterBlue = FlutterBlue.instance;

  /// Scanning
  StreamSubscription _scanSubscription;
  Map<DeviceIdentifier, ScanResult> scanResults = new Map();
  bool isScanning = false;

  /// State
  StreamSubscription _stateSubscription;
  BluetoothState state = BluetoothState.unknown;

  /// Device
  BluetoothDevice device;
  bool get isConnected => (device != null);
  StreamSubscription deviceConnection;
  StreamSubscription deviceStateSubscription;
  List<BluetoothService> services = new List();
  Map<Guid, StreamSubscription> valueChangedSubscriptions = {};
  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;

  @override
  void initState() {
    super.initState();
    // Immediately get the state of FlutterBlue
    _flutterBlue.state.then((s) {
      setState(() {
        state = s;
      });
    });
    // Subscribe to state changes
    _stateSubscription = _flutterBlue.onStateChanged().listen((s) {
      setState(() {
        state = s;
      });
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _stateSubscription = null;
    _scanSubscription?.cancel();
    _scanSubscription = null;
    deviceConnection?.cancel();
    deviceConnection = null;
    _timer.cancel();
    super.dispose();
  }

  _startScan() {
    _scanSubscription = _flutterBlue
        .scan(
      timeout: const Duration(seconds: 5),
      /*withServices: [
          new Guid('0000180F-0000-1000-8000-00805F9B34FB')
        ]*/
    )
        .listen((scanResult) {
      print('localName: ${scanResult.advertisementData.localName}');
      print(
          'manufacturerData: ${scanResult.advertisementData.manufacturerData}');
      print('serviceData: ${scanResult.advertisementData.serviceData}');
      setState(() {
        scanResults[scanResult.device.id] = scanResult;
      });
    }, onDone: _stopScan);

    setState(() {
      isScanning = true;
    });
  }

  _stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    setState(() {
      isScanning = false;
    });
  }

  _connect(BluetoothDevice d) async {
    device = d;
    // Connect to device
    deviceConnection = _flutterBlue
        .connect(device, timeout: const Duration(seconds: 4))
        .listen(
          null,
          onDone: _disconnect,
        );

    // Update the connection state immediately
    device.state.then((s) {
      setState(() {
        deviceState = s;
      });
    });

    // Subscribe to connection changes
    deviceStateSubscription = device.onStateChanged().listen((s) {
      setState(() {
        deviceState = s;
      });
      if (s == BluetoothDeviceState.connected) {
        device.discoverServices().then((s) {
          setState(() {
            services = s;
          });
        });
      }
    });
  }

  _disconnect() {
    // Remove all value changed listeners
    valueChangedSubscriptions.forEach((uuid, sub) => sub.cancel());
    valueChangedSubscriptions.clear();
    deviceStateSubscription?.cancel();
    deviceStateSubscription = null;
    deviceConnection?.cancel();
    deviceConnection = null;
    setState(() {
      device = null;
    });
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  void showInSnackBar(String value) {
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(value)));
  }

  _createData(List<int> dataList) {
    List<String> data = List();

    for (int i = 0; i < dataList.length; i++) {
      if (dataList[i] == 95) {
      } else {
        data.add(String.fromCharCode(dataList[i]));
      }
    }

    Navigator.push(
        context, MaterialPageRoute(builder: (context) => FetchedData(data)));
  }

  _readCharacteristic(BluetoothCharacteristic c) async {
    List<int> a = await device.readCharacteristic(c);
    print("inside read");

    if (a != null) {
      // FetchedData(a);
      _createData(a);
    } else {
      print("No data, try again");
    }
    setState(() {});
  }

  _writeCharacteristic(BluetoothCharacteristic c) async {
    showInSnackBar("Getting data, wait please...");

    await device.writeCharacteristic(c, [0x12],
        type: CharacteristicWriteType.withResponse);

    _timer = new Timer(const Duration(milliseconds: 400), () {
      _readCharacteristic(c);
    });

    setState(() {});
  }

  _readDescriptor(BluetoothDescriptor d) async {
    await device.readDescriptor(d);
    setState(() {});
  }

  _writeDescriptor(BluetoothDescriptor d) async {
    await device.writeDescriptor(d, [0x12, 0x34]);
    setState(() {});
  }

  _setNotification(BluetoothCharacteristic c) async {
    if (c.isNotifying) {
      await device.setNotifyValue(c, false);
      // Cancel subscription
      valueChangedSubscriptions[c.uuid]?.cancel();
      valueChangedSubscriptions.remove(c.uuid);
    } else {
      await device.setNotifyValue(c, true);
      // ignore: cancel_subscriptions
      final sub = device.onValueChanged(c).listen((d) {
        setState(() {
          print('onValueChanged $d');
        });
      });
      // Add to map
      valueChangedSubscriptions[c.uuid] = sub;
    }
    setState(() {});
  }

  _refreshDeviceState(BluetoothDevice d) async {
    var state = await d.state;
    setState(() {
      deviceState = state;
      print('State refreshed: $deviceState');
    });
  }

  _buildScanningButton() {
    if (isConnected || state != BluetoothState.on) {
      return null;
    }
    if (isScanning) {
      return new FloatingActionButton(
        child: new Icon(Icons.stop),
        onPressed: _stopScan,
        backgroundColor: Colors.red,
      );
    } else {
      return new FloatingActionButton(
          child: new Icon(Icons.search), onPressed: _startScan);
    }
  }

  _buildScanResultTiles() {
    return scanResults.values
        .map((r) => ScanResultTile(
              result: r,
              onTap: () => _connect(r.device),
            ))
        .toList();
  }

  List<Widget> _buildServiceTiles() {
    return services
        .map(
          (s) => new ServiceTile(
                service: s,
                characteristicTiles: s.characteristics
                    .map(
                      (c) => new CharacteristicTile(
                            characteristic: c,
                            onReadPressed: () => _readCharacteristic(c),
                            onWritePressed: () => _writeCharacteristic(c),
                            onNotificationPressed: () => _setNotification(c),
                            descriptorTiles: c.descriptors
                                .map(
                                  (d) => new DescriptorTile(
                                        descriptor: d,
                                        onReadPressed: () => _readDescriptor(d),
                                        onWritePressed: () =>
                                            _writeDescriptor(d),
                                      ),
                                )
                                .toList(),
                          ),
                    )
                    .toList(),
              ),
        )
        .toList();
  }
//
//  _buildActionButtons() {
//    if (isConnected) {
//      return <Widget>[
//        new IconButton(
//          icon: const Icon(Icons.cancel),
//          onPressed: () => _disconnect(),
//        )
//      ];
//    }
//  }

  _buildAlertTile() {
    return new Container(
      color: Colors.redAccent,
      child: new ListTile(
        title: new Text(
          'Bluetooth adapter is ${state.toString().substring(15)}',
          style: Theme.of(context).primaryTextTheme.subhead,
        ),
        trailing: new Icon(
          Icons.error,
          color: Theme.of(context).primaryTextTheme.subhead.color,
        ),
      ),
    );
  }

  _buildDeviceStateTile() {
    return new ListTile(
        leading: (deviceState == BluetoothDeviceState.connected)
            ? const Icon(Icons.bluetooth_connected)
            : const Icon(Icons.bluetooth_disabled),
        title: new Text('Device is ${deviceState.toString().split('.')[1]}.'),
        subtitle: new Text('${device.id}'),
        trailing: new IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _refreshDeviceState(device),
          color: Theme.of(context).iconTheme.color.withOpacity(0.5),
        ));
  }

  _buildProgressBarTile() {
    return new LinearProgressIndicator();
  }

  @override
  Widget build(BuildContext context) {
    var tiles = new List<Widget>();
    if (state != BluetoothState.on) {
      tiles.add(_buildAlertTile());
    }
    if (isConnected) {
      tiles.add(_buildDeviceStateTile());
      tiles.addAll(_buildServiceTiles());
    } else {
      tiles.addAll(_buildScanResultTiles());
    }
    return new MaterialApp(
        debugShowCheckedModeBanner: false,
        home: new Scaffold(
          key: _scaffoldKey,
          appBar: isConnected == true
              ? AppBar(
                  iconTheme: IconThemeData(color: Colors.black),
                  backgroundColor: Colors.white,
                  title: Container(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Container(
                            child: Center(
                              child: Icon(Icons.settings),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AllReadings()));
                            },
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Icon(Icons.remove_red_eye),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Container(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Sensor Details",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                              child: isConnected == true
                                  ? IconButton(
                                      icon: Icon(Icons.cancel),
                                      onPressed: () {
                                        _disconnect();
                                      },
                                    )
                                  : Container()),
                        )
                      ],
                    ),
                  ),
                )
              : AppBar(
                  title: Text("Scan"),
                ),
          floatingActionButton: _buildScanningButton(),
          bottomNavigationBar: !isConnected
              ? BottomAppBar(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    height: 50.0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Scan or select device..",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                )
              : Container(
                  height: 0.0,
                ),
          body: isConnected == true
              ? Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        height: 80.0,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32.0, vertical: 16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.amber),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8.0),
                                  )),
                              child: Center(
                                child: Text(
                                  "SENSOR NAME: DIS-001A61",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ContainerReturner("Site Name: ", "Newcrest Cadia"),
                      ContainerReturner("Pump Serial No: ", "PW12345678"),
                      ContainerReturner("Pump Name: ", "MCR55OUDC"),
                      ContainerReturner("Sensor Position: ", "DIS-001"),
                      ContainerReturner("Material: ", "A61"),
                      ContainerReturner("Initial Measured Thickness: ",
                          "110mm, 29.12.18,14:15"),
                      ContainerReturner("Error/Fault: ", "N/A"),
                      SizedBox(
                        height: 32.0,
                      ),
                      Container(
                        height: 40.0,
                        child: RaisedButton(
                            color: Colors.indigo[400],
                            child: Text(
                              "Fetch Data",
                              style: TextStyle(
                                  fontSize: 16.0, color: Colors.white),
                            ),
                            onPressed: () {
                              _writeCharacteristic(
                                  services[2].characteristics[0]);
//                              isConnected == true
//                                  ? _writeCharacteristic(
//                                      services[2].characteristics[0])
//                                  : null;
                            }),
                      ),
                      SizedBox(
                        height: 8.0,
                      ),
                      Container(
                        height: 40.0,
                        child: RaisedButton(
                            color: Colors.indigo[400],
                            child: Text(
                              "Rescan",
                              style: TextStyle(
                                  fontSize: 16.0, color: Colors.white),
                            ),
                            onPressed: () {
                              _disconnect();
                            }),
                      )
                    ],
                  ),
                )
              : new Stack(
                  children: <Widget>[
                    (isScanning) ? _buildProgressBarTile() : Container(),
                    ListView(
                      children: tiles,
                    )
                  ],
                ),
        ));
  }
}

class ContainerReturner extends StatelessWidget {
  final String heading, description;
  ContainerReturner(this.heading, this.description);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 40.0,
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  heading,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.indigo),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  description,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class FetchedData extends StatefulWidget {
  final List<String> data;
  FetchedData(this.data);
  @override
  _FetchedDataState createState() => _FetchedDataState();
}

class _FetchedDataState extends State<FetchedData> {
  List<String> data = List();
  TextEditingController textEditingControllerA,
      textEditingControllerB,
      textEditingControllerC,
      textEditingControllerD,
      textEditingControllerE;

  String url = "http://weir.akscellenceinfo.com/api/measurement/create";

  _createData(List<int> dataList) {
    for (int i = 0; i < dataList.length; i++) {
      if (dataList[i] == 95) {
      } else {
        data.add(String.fromCharCode(dataList[i]));
      }
    }
  }

  _submitData(var dataA, var dataB, var dataC, var dataD, String dataE) async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
    formattedDate.substring(0, 10);

    var body = json.encode({
      "MeasurementLocation1": "${dataA.toString()}",
      "MeasurementLocation2": "${dataB.toString()}",
      "MeasurementLocation3": "${dataC.toString()}",
      "MeasurementLocation4": "${dataD.toString()}",
      "UpdatedDate": "${formattedDate.substring(0, 10).toString()}",
      "UpdatedTime": "${formattedDate.substring(13, 18).toString()}",
      "UserId": 1
    });

    var response = await http.post(url,
        headers: {"Content-Type": "Application/Json"}, body: body);

    Map decode = json.decode(response.body);

    print("Hello $decode");

    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AllReadings()),
        ModalRoute.withName("/Home"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Data"),
      ),
      body: SingleChildScrollView(
        child: Container(
            child: Column(
          children: <Widget>[
            Container(
              height: 50.0,
              child: ListTile(
                title: new TextFormField(
                  //initialValue: "Hello",
                  controller: textEditingControllerA,
                  decoration: new InputDecoration(
                      hintText: widget.data[0],
                      labelText: "Measure Location 1"),
                ),
              ),
            ),
            SizedBox(
              height: 16.0,
            ),
            Container(
              height: 50.0,
              child: ListTile(
                title: new TextFormField(
                  //          initialValue: widget.data[1],
                  controller: textEditingControllerB,
                  decoration: new InputDecoration(
                      hintText: widget.data[1],
                      labelText: "Measure Location 2"),
                ),
              ),
            ),
            SizedBox(
              height: 16.0,
            ),
            Container(
              height: 50.0,
              child: ListTile(
                title: new TextFormField(
                  //        initialValue: widget.data[2],
                  controller: textEditingControllerC,
                  decoration: new InputDecoration(
                      hintText: widget.data[2],
                      labelText: "Measure Location 3"),
                ),
              ),
            ),
            SizedBox(
              height: 16.0,
            ),
            Container(
              height: 50.0,
              child: ListTile(
                title: new TextFormField(
                  //       initialValue: widget.data[3],
                  controller: textEditingControllerD,
                  decoration: new InputDecoration(
                      hintText: widget.data[3],
                      labelText: "Measure Location 4"),
                ),
              ),
            ),
            SizedBox(
              height: 16.0,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 50.0,
                child: Container(
                  child: new TextField(
                    controller: textEditingControllerE,
                    decoration: new InputDecoration(
                        hintText: "Write Here", labelText: "Comment"),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                child: Center(
                  child: RaisedButton(
                      color: Colors.indigo,
                      child: Text(
                        "Submit",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        _submitData(
                            widget.data[0].toString() +
                                    textEditingControllerA.text ??
                                "",
                            widget.data[1].toString() +
                                    textEditingControllerB.text ??
                                "",
                            widget.data[2].toString() +
                                    textEditingControllerC.text ??
                                "",
                            widget.data[3].toString() +
                                    textEditingControllerD.text ??
                                "",
                            textEditingControllerE.text ?? "");
                      }),
                ),
              ),
            )
          ],
        )),
      ),
    );
  }

  @override
  void initState() {
    textEditingControllerA = TextEditingController(text: widget.data[0]);
    textEditingControllerB = TextEditingController(text: widget.data[1]);
    textEditingControllerC = TextEditingController(text: widget.data[2]);
    textEditingControllerD = TextEditingController(text: widget.data[3]);
    textEditingControllerE = TextEditingController();

    print(widget.data);

    super.initState();
  }
}
