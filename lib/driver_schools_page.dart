import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverSchoolsPage extends StatefulWidget {
  const DriverSchoolsPage({Key? key}) : super(key: key);

  @override
  _DriverSchoolsPageState createState() => _DriverSchoolsPageState();
}

class _DriverSchoolsPageState extends State<DriverSchoolsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> assignedSchools = [];
  String? driverEmail;

  @override
  void initState() {
    super.initState();
    fetchDriverSchools();
  }

  Future<void> fetchDriverSchools() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        debugPrint('No user logged in!');
        return;
      }
      driverEmail = user.email ?? '';
      debugPrint('Logged in driver email: $driverEmail');

      final QuerySnapshot snapshot = await _firestore
          .collection('assignedDrivers')
          .where('email', isEqualTo: driverEmail)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docData = snapshot.docs.first.data() as Map<String, dynamic>? ?? {};
        setState(() {
          assignedSchools = List<Map<String, dynamic>>.from(docData['schools'] ?? []);
        });
        debugPrint('Fetched assigned schools: $assignedSchools');
      } else {
        debugPrint('No assigned schools found for this driver.');
      }
    } catch (e) {
      debugPrint('Error fetching schools: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Assigned Schools"),
        backgroundColor: const Color(0xFF77DDE7),
      ),
      body: assignedSchools.isEmpty
          ? const Center(child: Text("No schools assigned yet."))
          : ListView.builder(
              itemCount: assignedSchools.length,
              itemBuilder: (context, index) {
                final school = assignedSchools[index];
                final schoolName = school['name'] ?? 'Unnamed School';
                final routes = school['routes'] is List ? List.from(school['routes']) : [];

                return Card(
                  margin: const EdgeInsets.all(12),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "🏫 $schoolName",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...routes.map<Widget>((route) {
                          final start = route['start']?['name'] ?? 'Unknown';
                          final end = route['end']?['name'] ?? 'Unknown';
                          final stops = route['stops'] ?? [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "🚍 Route:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text("• Start: $start"),
                              Text("• End: $end"),
                              const SizedBox(height: 4),
                              const Text("• Stops:"),
                              ...stops.map<Widget>((stop) {
                                final stopName = stop['name'] ?? 'Unnamed Stop';
                                return Padding(
                                  padding: const EdgeInsets.only(left: 12.0, top: 2),
                                  child: Text("  - $stopName"),
                                );
                              }).toList(),
                              const Divider(height: 24, color: Colors.grey),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
