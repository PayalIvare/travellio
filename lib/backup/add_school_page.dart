import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddSchoolPage extends StatefulWidget {
  @override
  _AddSchoolPageState createState() => _AddSchoolPageState();
}

class _AddSchoolPageState extends State<AddSchoolPage> {
  final TextEditingController schoolNameController = TextEditingController();
  final TextEditingController schoolAddressController = TextEditingController();

  List<Map<String, dynamic>> addedSchools = [];
  List<RouteInput> routes = [RouteInput()];

  @override
  void initState() {
    super.initState();
    loadSavedSchools();
  }

  void loadSavedSchools() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? saved = prefs.getString('schools');
    if (saved != null) {
      List decoded = jsonDecode(saved);
      setState(() {
        addedSchools = List<Map<String, dynamic>>.from(decoded);
      });
    }
  }

  void saveSchoolsLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('schools', jsonEncode(addedSchools));
  }

  void addSchool() {
    final name = schoolNameController.text.trim();
    final address = schoolAddressController.text.trim();

    if (name.isNotEmpty && address.isNotEmpty) {
      final routeData = routes.map((route) {
        return {
          'start': route.startController.text.trim(),
          'end': route.endController.text.trim(),
          'stops': route.stops.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
        };
      }).toList();

      setState(() {
        addedSchools.add({
          'name': name,
          'address': address,
          'routes': routeData,
        });

        schoolNameController.clear();
        schoolAddressController.clear();
        routes = [RouteInput()];
      });

      saveSchoolsLocally();
    }
  }

  void showSchoolDetails(Map<String, dynamic> school) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(school['name']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Address: ${school['address']}"),
              SizedBox(height: 10),
              Text("Routes:"),
              ...school['routes'].asMap().entries.map((entry) {
                final idx = entry.key;
                final route = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Route ${idx + 1}:"),
                      Text("Start: ${route['start']}"),
                      Text("End: ${route['end']}"),
                      Text("Stops:"),
                      ...route['stops'].map<Widget>((stop) => Text("• $stop")).toList(),
                      SizedBox(height: 8),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
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
            Text("Route ${index + 1}", style: TextStyle(fontWeight: FontWeight.bold)),
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
            Text("Routes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...routes.asMap().entries.map((entry) => buildRouteForm(entry.value, entry.key)),
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
            ElevatedButton(
              onPressed: addSchool,
              child: Text("Add School"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
            SizedBox(height: 20),
            Divider(),
            Text("Added Schools", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...addedSchools.map((school) => Card(
              child: ListTile(
                title: Text(school['name']),
                trailing: IconButton(
                  icon: Icon(Icons.info_outline),
                  onPressed: () => showSchoolDetails(school),
                ),
              ),
            )),
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
