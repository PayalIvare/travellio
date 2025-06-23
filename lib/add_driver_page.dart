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

      final driversSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'Driver')
          .get();
      registeredDrivers =
          driversSnapshot.docs.map((doc) => doc.data()).toList();

      final schoolsSnapshot = await firestore.collection('schools').get();
      schools = schoolsSnapshot.docs.map((doc) => doc.data()).toList();

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
    }
  }

  void showDriverDetails(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(driver['name']?.toString() ?? ''),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Phone: ${driver['phone']?.toString() ?? ''}"),
            Text("Email: ${driver['email']?.toString() ?? ''}"),
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
                      Text(driver['name']?.toString() ?? ''),
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
                "Assigning: ${selectedDriver?['name']?.toString() ?? ''}",
                style: TextStyle(fontSize: 16),
              ),
              ...schools.map((school) {
                final schoolName = school['name']?.toString() ?? '';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      title: Text(schoolName),
                      value: selectedSchools.contains(schoolName),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedSchools.add(schoolName);
                          } else {
                            selectedSchools.remove(schoolName);
                            selectedRoutes.remove(schoolName);
                          }
                        });
                      },
                    ),
                    if (selectedSchools.contains(schoolName)) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (school['routes'] as List? ?? [])
                              .map<Widget>((route) {
                            final start = route['start']?['name']?.toString() ?? '';
                            final end = route['end']?['name']?.toString() ?? '';
                            final stops = (route['stops'] as List?)
                                    ?.map((s) => s['name']?.toString() ?? '')
                                    .join(', ') ??
                                '';

                            final routeLabel =
                                "Start: $start → End: $end | Stops: $stops";

                            final routesList = selectedRoutes[schoolName] ?? [];

                            return CheckboxListTile(
                              title: Text(routeLabel),
                              value: routesList.contains(route),
                              onChanged: (val) {
                                setState(() {
                                  selectedRoutes.putIfAbsent(
                                      schoolName, () => []);
                                  if (val == true) {
                                    selectedRoutes[schoolName]!.add(route);
                                  } else {
                                    selectedRoutes[schoolName]!.remove(route);
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
                  title: Text(driver['name']?.toString() ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (schools as List).map<Widget>((s) {
                      final sName = s['name']?.toString() ?? '';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("• $sName"),
                          ...(s['routes'] as List? ?? []).map<Widget>((r) {
                            if (r is Map) {
                              final start =
                                  r['start']?['name']?.toString() ?? '';
                              final end =
                                  r['end']?['name']?.toString() ?? '';
                              final stops = (r['stops'] as List?)
                                      ?.map((s) => s['name']?.toString() ?? '')
                                      .join(', ') ??
                                  '';
                              return Text(
                                  "   - Start: $start → End: $end | Stops: $stops");
                            } else {
                              return Text("   - ${r.toString()}");
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
