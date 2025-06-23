import 'package:flutter/material.dart';

class DriverSelectionPage extends StatelessWidget {
  const DriverSelectionPage({Key? key}) : super(key: key); // ✅ add const & key

  final List<String> drivers = const ["Driver A", "Driver B", "Driver C"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Driver")),
      body: ListView.builder(
        itemCount: drivers.length,
        itemBuilder: (context, index) {
          final driverName = drivers[index] ?? 'Unnamed Driver'; // defensive fallback
          return ListTile(
            title: Text(driverName),
            onTap: () {
              debugPrint("Selected driver: $driverName");
              Navigator.pop(context, driverName); // return selected driver if needed
            },
          );
        },
      ),
    );
  }
}
