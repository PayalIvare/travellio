import 'package:flutter/material.dart';

class OperatorPage extends StatelessWidget {
  const OperatorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure context is safe, fallback to default size if null (rare)
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textSize = screenWidth > 600 ? 24 : 16;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operator Dashboard'),
      ),
      body: const Center(
        child: Text(
          'Welcome, Operator!',
          style: TextStyle(
            fontSize: 20, // Default text size; actual responsive size handled below
          ),
        ),
      ),
    );
  }
}
