import 'package:flutter/material.dart';

class OperatorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double textSize = MediaQuery.of(context).size.width > 600 ? 24 : 16;
    return Scaffold(
      appBar: AppBar(title: Text('Operator Dashboard')),
      body: Center(
        child: Text(
          'Welcome, Operator!',
          style: TextStyle(fontSize: textSize),
        ),
      ),
    );
  }
}
