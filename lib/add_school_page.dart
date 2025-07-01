import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddSchoolPage extends StatefulWidget {
  const AddSchoolPage({super.key});

  @override
  _AddSchoolPageState createState() => _AddSchoolPageState();
}

class _AddSchoolPageState extends State<AddSchoolPage> {
  final TextEditingController schoolNameController = TextEditingController();
  final TextEditingController schoolAddressController = TextEditingController();

  List<RouteInput> routes = [];
  bool showRoutes = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String googleApiKey = 'AIzaSyB3ZstK0XOXbOv9MrgHsl05sq-I9D4XnFk';

  Future<Map<String, double>> getLatLng(String address) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$googleApiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['results'] != null && json['results'].isNotEmpty) {
        final location = json['results'][0]['geometry']['location'];
        return {'lat': location['lat'], 'lng': location['lng']};
      } else {
        throw 'Invalid address: $address';
      }
    } else {
      throw 'Failed to fetch coordinates for: $address';
    }
  }

  void addSchool() async {
    final name = schoolNameController.text.trim();
    final address = schoolAddressController.text.trim();

    if (name.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter school name and address')));
      return;
    }

    try {
      final List<Map<String, dynamic>> routeData = [];
      for (var route in routes) {
        final startAddress = route.startController.text.trim();
        final endAddress = route.endController.text.trim();

        if (startAddress.isEmpty || endAddress.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('Please enter start and end points for all routes')));
          return;
        }

        final startLocation = await getLatLng(startAddress);
        final endLocation = await getLatLng(endAddress);

        List<Map<String, dynamic>> stops = [];
        for (var stopController in route.stops) {
          final stopAddress = stopController.text.trim();
          if (stopAddress.isEmpty) continue;
          final stopLocation = await getLatLng(stopAddress);
          stops.add({
            'name': stopAddress,
            'location': GeoPoint(
                stopLocation['lat'] ?? 0.0, stopLocation['lng'] ?? 0.0),
          });
        }

        routeData.add({
          'start': {
            'name': startAddress,
            'location': GeoPoint(
                startLocation['lat'] ?? 0.0, startLocation['lng'] ?? 0.0),
          },
          'end': {
            'name': endAddress,
            'location':
                GeoPoint(endLocation['lat'] ?? 0.0, endLocation['lng'] ?? 0.0),
          },
          'stops': stops,
        });
      }

      await _firestore.collection('schools').add({
        'name': name,
        'address': address,
        'routes': routeData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      schoolNameController.clear();
      schoolAddressController.clear();
      setState(() {
        routes.clear();
        showRoutes = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('School added successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget buildRouteForm(RouteInput route, int index) {
    return Card(
      color: Colors.grey[100],
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Route ${index + 1}",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
                controller: route.startController,
                decoration: InputDecoration(labelText: "Start Point")),
            TextField(
                controller: route.endController,
                decoration: InputDecoration(labelText: "End Point")),
            Text("Bus Stops:"),
            ...route.stops.map((controller) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                        child: TextField(
                            controller: controller,
                            decoration:
                                InputDecoration(labelText: 'Bus Stop'))),
                    IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: () =>
                            setState(() => route.stops.remove(controller))),
                  ],
                ),
              );
            }).toList(),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: Icon(Icons.add),
                label: Text("Add Stop"),
                onPressed: () =>
                    setState(() => route.stops.add(TextEditingController())),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text("Add School"), backgroundColor: Color(0xFF77DDE7)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 20),
            TextField(
                controller: schoolNameController,
                decoration: InputDecoration(labelText: "School Name")),
            SizedBox(height: 20),
            TextField(
                controller: schoolAddressController,
                decoration: InputDecoration(labelText: "School Address")),
            SizedBox(height: 30),
            if (showRoutes) ...[
              Text("Routes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ...routes
                  .asMap()
                  .entries
                  .map((entry) => buildRouteForm(entry.value, entry.key))
                  .toList(),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: Icon(Icons.add),
                  label: Text("Add Routes"),
                  onPressed: () => setState(() => routes.add(RouteInput())),
                ),
              ),
            ],
            if (!showRoutes)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: Icon(Icons.add),
                  label: Text("Add Routes"),
                  onPressed: () => setState(() {
                    showRoutes = true;
                    routes.add(RouteInput());
                  }),
                ),
              ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: addSchool,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: TextStyle(fontSize: 16),
              ),
              child: Text("Add School", textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

class RouteInput {
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();
  final List<TextEditingController> stops = [TextEditingController()];
}
