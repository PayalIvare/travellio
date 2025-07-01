import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travellio/home_page.dart' hide HomePage;

import 'driver_schools_page.dart';
import 'DriverTravellersPage.dart';
import 'DriverLocationPage.dart';
import 'main.dart';

class DriverDashboard extends StatefulWidget {
  final String driverEmail;

  const DriverDashboard({Key? key, required this.driverEmail}) : super(key: key);

  @override
  _DriverDashboardState createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  String driverName = '';
  final Color turquoise = const Color(0xFF77DDE7);
  final Color black = Colors.black;

  @override
  void initState() {
    super.initState();
    fetchDriverName();
  }

  Future<void> fetchDriverName() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.driverEmail)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          driverName = snapshot.docs.first['name'] ?? 'Driver';
        });
      }
    } catch (e) {
      print('Error fetching driver name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with menu icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 30),
              decoration: BoxDecoration(
                color: turquoise,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Stack(
                children: [
                  // Greeting text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      const Text(
                        'Hello,',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      Text(
                        driverName.isNotEmpty ? driverName.toLowerCase() : 'loading...',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Your Transport Solution',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),

                  // Menu icon with Logout option
                  Positioned(
                    right: 0,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onSelected: (value) async {
                        if (value == 'logout') {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => HomePage()),
                            (route) => false,
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'logout',
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: const Text(
                            'Logout',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Grid buttons
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    buildDashboardCard(
                      icon: Icons.school,
                      label: 'Schools',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DriverSchoolsPage()),
                        );
                      },
                    ),
                    buildDashboardCard(
                      icon: Icons.group,
                      label: 'Travellers',
                      onTap: () async {
                        try {
                          // Step 1: Fetch assigned schools
                          final assignedSnapshot = await FirebaseFirestore.instance
                              .collection('assignedDrivers')
                              .where('email', isEqualTo: widget.driverEmail)
                              .get();

                          List<Map<String, dynamic>> assignedSchools = [];

                          if (assignedSnapshot.docs.isNotEmpty) {
                            final data = assignedSnapshot.docs.first.data();
                            assignedSchools = List<Map<String, dynamic>>.from(data['schools'] ?? []);
                          }

                          print("Logged in driver email: ${widget.driverEmail}");
                          print("Fetched assigned schools: $assignedSchools");

                          // Step 2: Fetch all travellers
                          final travellerSnapshot = await FirebaseFirestore.instance
                              .collection('traveller_school')
                              .get();

                          List<Map<String, dynamic>> allTravellers = travellerSnapshot.docs
                              .map((doc) => doc.data())
                              .toList();

                          // Step 3: Navigate to page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DriverTravellersPage(
                                driverEmail: widget.driverEmail,
                                assignedSchools: assignedSchools,
                                allTravellers: allTravellers,
                              ),
                            ),
                          );
                        } catch (e) {
                          print('Error fetching data: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to load traveller data')),
                          );
                        }
                      },
                    ),
                    buildDashboardCard(
                      icon: Icons.notifications,
                      label: 'Notifier',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notifier tapped')),
                        );
                      },
                    ),
                    buildDashboardCard(
                      icon: Icons.location_on,
                      label: 'Location',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DriverLocationPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDashboardCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: turquoise),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: turquoise,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
