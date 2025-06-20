import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddDriverPage extends StatefulWidget {
  @override
  _AddDriverPageState createState() => _AddDriverPageState();
}

class _AddDriverPageState extends State<AddDriverPage> {
  List<Map<String, dynamic>> registeredDrivers = [];
  List<Map<String, dynamic>> assignedDrivers = [];
  List<Map<String, dynamic>> schools = [];
  Map<String, dynamic>? selectedDriver;
  List<String> selectedSchools = [];
  Map<String, List<String>> selectedRoutes = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? schoolData = prefs.getString('schools');
    String? driverData = prefs.getString('assignedDrivers');
    String? registeredData = prefs.getString('registeredDrivers');

    if (schoolData != null) schools = List<Map<String, dynamic>>.from(jsonDecode(schoolData));
    if (driverData != null) assignedDrivers = List<Map<String, dynamic>>.from(jsonDecode(driverData));
    if (registeredData != null) registeredDrivers = List<Map<String, dynamic>>.from(jsonDecode(registeredData));

    setState(() {});
  }

  Future<void> saveAssignedDrivers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('assignedDrivers', jsonEncode(assignedDrivers));
  }

  void assignDriver() {
    if (selectedDriver != null && selectedSchools.isNotEmpty) {
      assignedDrivers.add({
        'driver': selectedDriver,
        'email': selectedDriver!['email'], // <- Added email at top level
        'schools': selectedSchools.map((schoolName) {
          return {
            'name': schoolName,
            'routes': selectedRoutes[schoolName] ?? [],
          };
        }).toList(),
      });
      saveAssignedDrivers();
      setState(() {
        selectedDriver = null;
        selectedSchools.clear();
        selectedRoutes.clear();
      });
    }
  }

  void showDriverDetails(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(driver['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Phone: ${driver['phone']}"),
            Text("Email: ${driver['email']}")
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Close"))],
      ),
    );
  }

  void showAssignmentForm(Map<String, dynamic> driver) {
    setState(() {
      selectedDriver = driver;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Assign Driver"), backgroundColor: Color(0xFF77DDE7)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Registered Drivers", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            DataTable(
              columns: [DataColumn(label: Text('Name')), DataColumn(label: Text('Action'))],
              rows: registeredDrivers.map((driver) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(driver['name']),
                      onTap: () => showDriverDetails(driver),
                    ),
                    DataCell(
                      ElevatedButton(
                        onPressed: () => showAssignmentForm(driver),
                        child: Text("Add"),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            if (selectedDriver != null) ...[
              Divider(),
              Text("Assigning: ${selectedDriver!['name']}", style: TextStyle(fontSize: 16)),
              ...schools.map((school) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      title: Text(school['name']),
                      value: selectedSchools.contains(school['name']),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedSchools.add(school['name']);
                          } else {
                            selectedSchools.remove(school['name']);
                            selectedRoutes.remove(school['name']);
                          }
                        });
                      },
                    ),
                    if (selectedSchools.contains(school['name'])) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (school['routes'] as List).map<Widget>((route) {
                            String routeLabel = "${route['start']} to ${route['end']}, Stops: ${route['stops'].join(', ')}";
                            return CheckboxListTile(
                              title: Text(routeLabel),
                              value: selectedRoutes[school['name']]?.contains(routeLabel) ?? false,
                              onChanged: (val) {
                                setState(() {
                                  selectedRoutes.putIfAbsent(school['name'], () => []);
                                  if (val == true) {
                                    selectedRoutes[school['name']]!.add(routeLabel);
                                  } else {
                                    selectedRoutes[school['name']]!.remove(routeLabel);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      )
                    ]
                  ],
                );
              }).toList(),
              ElevatedButton(
                onPressed: assignDriver,
                child: Text("Assign Driver"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ],
            Divider(),
            Text("Assigned Drivers", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ...assignedDrivers.map((entry) {
              final driver = entry['driver'];
              final schools = entry['schools'];
              return Card(
                child: ListTile(
                  title: Text(driver['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: schools.map<Widget>((s) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("• ${s['name']}"),
                          ...s['routes'].map<Widget>((r) => Text("    - $r")).toList(),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
