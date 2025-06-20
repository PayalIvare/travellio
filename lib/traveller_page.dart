import 'package:flutter/material.dart';

class TravellerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double textSize = MediaQuery.of(context).size.width > 600 ? 24 : 16;
    return Scaffold(
      appBar: AppBar(title: Text('Traveller Dashboard')),
      body: Center(
        child: Text(
          'Welcome, Traveller!',
          style: TextStyle(fontSize: textSize),
        ),
      ),
    );
  }
}
