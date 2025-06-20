import 'package:flutter/material.dart';

class DriverPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double textSize = MediaQuery.of(context).size.width > 600 ? 24 : 16;
    return Scaffold(
      appBar: AppBar(title: Text('Driver Dashboard')),
      body: Center(
        child: Text(
          'Welcome, Driver!',
          style: TextStyle(fontSize: textSize),
        ),
      ),
    );
  }
}
