import 'package:flutter/material.dart';

class DeviceInfoPage extends StatefulWidget {
  @override
  _DeviceInfoPageState createState() => _DeviceInfoPageState();
}

class _DeviceInfoPageState extends State<DeviceInfoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: Icon(Icons.remove_red_eye),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Sensor Details",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.battery_full,
                    color: Colors.green,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      body: Container(
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
                            color: Colors.black, fontWeight: FontWeight.w600),
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
            ContainerReturner(
                "Initial Measured Thickness: ", "110mm, 29.12.18,14:15"),
            ContainerReturner("Error/Fault: ", "N/A"),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 40.0,
          child: RaisedButton(
              color: Colors.indigo[400],
              child: Text(
                "Fetch Data",
                style: TextStyle(fontSize: 16.0, color: Colors.white),
              ),
              onPressed: () {}),
        ),
      ),
    );
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
