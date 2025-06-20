import 'package:flutter/material.dart';

class DriverSelectionPage extends StatelessWidget {
  final List<String> drivers = ["Driver A", "Driver B", "Driver C"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Driver")),
      body: ListView.builder(
        itemCount: drivers.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(drivers[index]),
            onTap: () {
            
              print("Selected driver: ${drivers[index]}");
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
