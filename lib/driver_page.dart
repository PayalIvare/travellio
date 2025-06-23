import 'package:flutter/material.dart';

class DriverPage extends StatelessWidget {
  const DriverPage({Key? key}) : super(key: key); // safe constructor

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final screenWidth = mediaQuery?.size.width ?? 400; // fallback if null
    final double textSize = screenWidth > 600 ? 24 : 16;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
      ),
      body: Center(
        child: Text(
          'Welcome, Driver!',
          style: TextStyle(fontSize: textSize),
        ),
      ),
    );
  }
}
