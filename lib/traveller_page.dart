import 'package:flutter/material.dart';

class TravellerPage extends StatelessWidget {
  const TravellerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textSize = screenWidth > 600 ? 24 : 16;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Traveller Dashboard'),
      ),
      body: Center(
        child: Text(
          'Welcome, Traveller!',
          style: TextStyle(fontSize: textSize),
        ),
      ),
    );
  }
}
