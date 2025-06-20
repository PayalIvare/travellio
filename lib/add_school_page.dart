import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddSchoolPage extends StatefulWidget {
  @override
  _AddSchoolPageState createState() => _AddSchoolPageState();
}

class _AddSchoolPageState extends State<AddSchoolPage> {
  final TextEditingController schoolNameController = TextEditingController();
  final TextEditingController schoolAddressController = TextEditingController();

  List<RouteInput> routes = [RouteInput()];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String googleApiKey = 'AIzaSyB3ZstK0XOXbOv9MrgHsl05sq-I9D4XnFk';

  /// ✅ New Google Geocoding method
  Future<Map<String, double>> getLatLng(String address) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$googleApiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['results'] != null && json['results'].isNotEmpty) {
        final location = json['results'][0]['geometry']['location'];
        return {
          'lat': location['lat'],
          'lng': location['lng'],
        };
      } else {
        throw 'Invalid address: $address';
      }
    } else {
      throw 'Failed to fetch coordinates for: $address';
    }
  }

  /// ✅ Add school & routes to Firestore
  void addSchool() async {
    final name = schoolNameController.text.trim();
    final address = schoolAddressController.text.trim();

    if (name.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter school name and address')),
      );
      return;
    }

    try {
      final List<Map<String, dynamic>> routeData = [];

      for (var route in routes) {
        final startAddress = route.startController.text.trim();
        final endAddress = route.endController.text.trim();

        if (startAddress.isEmpty || endAddress.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please enter start and end points for all routes')),
          );
          return;
        }

        // ✅ Use Google API for geocoding
        final startLocation = await getLatLng(startAddress);
        final endLocation = await getLatLng(endAddress);

        final startMap = {
          'name': startAddress,
          'location': GeoPoint(startLocation['lat']!, startLocation['lng']!),
        };

        final endMap = {
          'name': endAddress,
          'location': GeoPoint(endLocation['lat']!, endLocation['lng']!),
        };

        // ✅ Stops
        List<Map<String, dynamic>> stops = [];
        for (var stopController in route.stops) {
          final stopAddress = stopController.text.trim();
          if (stopAddress.isEmpty) continue;

          final stopLocation = await getLatLng(stopAddress);

          stops.add({
            'name': stopAddress,
            'location': GeoPoint(stopLocation['lat']!, stopLocation['lng']!),
          });
        }

        routeData.add({
          'start': startMap,
          'end': endMap,
          'stops': stops,
        });
      }

      // ✅ Store in Firestore
      await _firestore.collection('schools').add({
        'name': name,
        'address': address,
        'routes': routeData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      schoolNameController.clear();
      schoolAddressController.clear();
      setState(() {
        routes = [RouteInput()];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('School added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
              decoration: InputDecoration(labelText: "Start Point"),
            ),
            TextField(
              controller: route.endController,
              decoration: InputDecoration(labelText: "End Point"),
            ),
            Text("Bus Stops:"),
            ...route.stops.map((controller) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(labelText: 'Bus Stop'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        setState(() {
                          route.stops.remove(controller);
                        });
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: Icon(Icons.add),
                label: Text("Add Stop"),
                onPressed: () {
                  setState(() {
                    route.stops.add(TextEditingController());
                  });
                },
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
      appBar: AppBar(
        title: Text("Add School"),
        backgroundColor: Color(0xFF77DDE7),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: schoolNameController,
              decoration: InputDecoration(labelText: "School Name"),
            ),
            TextField(
              controller: schoolAddressController,
              decoration: InputDecoration(labelText: "School Address"),
            ),
            SizedBox(height: 16),
            Text("Routes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...routes
                .asMap()
                .entries
                .map((entry) => buildRouteForm(entry.value, entry.key)),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: Icon(Icons.add),
                label: Text("Add Another Route"),
                onPressed: () {
                  setState(() {
                    routes.add(RouteInput());
                  });
                },
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: addSchool,
              child: Text("Add School"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
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
