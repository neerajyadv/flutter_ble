import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bl/bluetoothPage.dart';
import 'package:flutter_bl/listParser.dart';
import 'package:http/http.dart' as http;

class AllReadings extends StatefulWidget {
  @override
  _AllReadingsState createState() => _AllReadingsState();
}

class _AllReadingsState extends State<AllReadings> {
  DataList dataList;
  bool _dataFetching = false;

  @override
  void initState() {
    _getData();
    super.initState();
  }

  _getData() async {
    var response =
        await http.get("http://weir.akscellenceinfo.com/api/measurement/list");

    List decode = json.decode(response.body);
    dataList = DataList.fromJson(decode);
    setState(() {
      _dataFetching = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => FlutterBlueApp()),
                    ModalRoute.withName("/Home"));
              },
            )
          ],
          title: Text("Readings"),
        ),
        body: _dataFetching == false
            ? Container(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    child: Column(
                      children: <Widget>[
                        Container(
                          height: 60.0,
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Wear History",
                              style: TextStyle(
                                  fontSize: 18.0,
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Container(
                          height: 80.0,
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                flex: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black)),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Remaining Thickness mm",
                                    style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black)),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Remaining Thickness %",
                                    style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black)),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Date",
                                    style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black)),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Time",
                                    style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 400.0,
                          child: ListView.builder(
                              itemCount: dataList.dataList.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  height: 60.0,
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.black)),
                                          child: Text(dataList.dataList[index]
                                              .measurementLocation1),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.black)),
                                          child: Text(dataList.dataList[index]
                                              .measurementLocation2),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.black)),
                                          child: Text(dataList
                                              .dataList[index].updatedDate),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.black)),
                                          child: Text(dataList
                                              .dataList[index].updatedTime),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                        )
                      ],
                    ),
                  ),
                ),
              ));
  }
}
