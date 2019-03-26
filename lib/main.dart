import 'package:flutter/material.dart';
import 'package:flutter_bl/bluetoothPage.dart';
import 'package:flutter_bl/devicePage.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BLE APP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FlutterBlueApp(),
    );
  }
}
