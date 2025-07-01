import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_driver_page.dart';
import 'add_school_page.dart';
import 'add_vehicle.dart';
import 'view_travellers_page.dart';
import 'main.dart'; // For HomePage after logout

class OperatorDashboard extends StatefulWidget {
  const OperatorDashboard({super.key});

  @override
  State<OperatorDashboard> createState() => _OperatorDashboardState();
}

class _OperatorDashboardState extends State<OperatorDashboard> {
  final Color turquoise = const Color(0xFF77DDE7);
  final Color black = Colors.black;

  final List<Map<String, String>> vehicleList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                  // Text section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SizedBox(height: 5),
                      Text('Hello,', style: TextStyle(fontSize: 20, color: Colors.white)),
                      Text(
                        'Operator',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Your Control Panel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  // Menu icon with logout
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
                        const PopupMenuItem<String>(
                          value: 'logout',
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Text('Logout', style: TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Grid Buttons
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    buildDashboardButton(
                      icon: Icons.person_add,
                      label: 'Add Driver',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddDriverPage()),
                      ),
                    ),
                    buildDashboardButton(
                      icon: Icons.group,
                      label: 'View Travellers',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ViewTravellersPage()),
                      ),
                    ),
                    buildDashboardButton(
                      icon: Icons.school,
                      label: 'Add School',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddSchoolPage()),
                      ),
                    ),
                    buildDashboardButton(
                      icon: Icons.directions_bus,
                      label: 'Add Vehicle',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddVehiclePage(initialVehicles: vehicleList),
                          ),
                        );
                        setState(() {});
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

  Widget buildDashboardButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: black,
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
