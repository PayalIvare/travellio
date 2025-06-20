import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  Map<String, List<Map<String, dynamic>>> selectedRoutes = {};

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Fetch drivers
      final driversSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'Driver')
          .get();
      registeredDrivers =
          driversSnapshot.docs.map((doc) => doc.data()).toList();

      // Fetch schools
      final schoolsSnapshot = await firestore.collection('schools').get();
      schools = schoolsSnapshot.docs.map((doc) => doc.data()).toList();

      // Fetch assigned drivers
      final assignedSnapshot =
          await firestore.collection('assignedDrivers').get();
      assignedDrivers =
          assignedSnapshot.docs.map((doc) => doc.data()).toList();

      setState(() {});
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> assignDriver() async {
    if (selectedDriver != null && selectedSchools.isNotEmpty) {
      final entry = {
        'driver': selectedDriver,
        'email': selectedDriver?['email'] ?? '',
        'schools': selectedSchools.map((schoolName) {
          return {
            'name': schoolName,
            'routes': selectedRoutes[schoolName] ?? [],
          };
        }).toList(),
      };

      await FirebaseFirestore.instance.collection('assignedDrivers').add(entry);

      assignedDrivers.add(entry);

      setState(() {
        selectedDriver = null;
        selectedSchools.clear();
        selectedRoutes.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a driver and at least one school.')),
      );
    }
  }

  void showDriverDetails(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(driver['name'] ?? ''),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Phone: ${driver['phone'] ?? ''}"),
            Text("Email: ${driver['email'] ?? ''}"),
          ],
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

  void showAssignmentForm(Map<String, dynamic> driver) {
    setState(() {
      selectedDriver = driver;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Assign Driver"),
        backgroundColor: Color(0xFF77DDE7),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Registered Drivers",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            DataTable(
              columns: [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Action')),
              ],
              rows: registeredDrivers.map((driver) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(driver['name'] ?? ''),
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
              Text(
                "Assigning: ${selectedDriver?['name'] ?? ''}",
                style: TextStyle(fontSize: 16),
              ),
              ...schools.map((school) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ School name checkbox
                    CheckboxListTile(
                      title: Text(school['name'] ?? ''),
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

                    // ✅ Routes — only show start/end/stops NAMES
                    if (selectedSchools.contains(school['name'])) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (school['routes'] as List)
                              .map<Widget>((route) {
                            final start = route['start']?['name'] ?? '';
                            final end = route['end']?['name'] ?? '';
                            final stops = (route['stops'] as List?)
                                    ?.map((s) => s['name'])
                                    .join(', ') ??
                                '';

                            final routeLabel =
                                "Start: $start → End: $end | Stops: $stops";

                            return CheckboxListTile(
                              title: Text(routeLabel),
                              value: selectedRoutes[school['name']]?.contains(route) ?? false,
                              onChanged: (val) {
                                setState(() {
                                  selectedRoutes.putIfAbsent(
                                      school['name'], () => []);
                                  if (val == true) {
                                    if (!selectedRoutes[school['name']]!.contains(route)) {
                                      selectedRoutes[school['name']]!.add(route);
                                    }
                                  } else {
                                    selectedRoutes[school['name']]!.remove(route);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
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
            Text(
              "Assigned Drivers",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            ...assignedDrivers.map((entry) {
              final driver = entry['driver'] ?? {};
              final schools = entry['schools'] ?? [];
              if (driver.isEmpty) return SizedBox();
              return Card(
                child: ListTile(
                  title: Text(driver['name'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (schools as List).map<Widget>((s) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("• ${s['name'] ?? ''}"),
                          ...(s['routes'] as List).map<Widget>((r) {
                            if (r is Map) {
                              final start = r['start']?['name'] ?? '';
                              final end = r['end']?['name'] ?? '';
                              final stops = (r['stops'] as List?)
                                      ?.map((s) => s['name'])
                                      .join(', ') ??
                                  '';
                              return Text(
                                  "   - Start: $start → End: $end | Stops: $stops");
                            } else {
                              return Text("   - $r");
                            }
                          }).toList(),
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
