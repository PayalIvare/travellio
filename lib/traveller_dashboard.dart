import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'main.dart'; // 👈 Redirecting to HomePage after logout
import 'SelectSchool.dart';
import 'HolidayCalendarPage.dart';
import 'LiveLocationPage.dart';

class TravellerDashboard extends StatefulWidget {
  final String travellerName;

  const TravellerDashboard({Key? key, required this.travellerName}) : super(key: key);

  @override
  State<TravellerDashboard> createState() => _TravellerDashboardState();
}

class _TravellerDashboardState extends State<TravellerDashboard> {
  static const Color turquoise = Color(0xFF77DDE7);
  static const Color black = Colors.black;
  static const Color white = Colors.white;

  List<dynamic> schoolData = [];

  @override
  void initState() {
    super.initState();
    loadSchoolData();
  }

  Future<void> loadSchoolData() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('schools').get();

    setState(() {
      schoolData = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with menu and logout
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 30),
              decoration: const BoxDecoration(
                color: turquoise,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      const Text('Hello,', style: TextStyle(color: white, fontSize: 20)),
                      Text(
                        widget.travellerName.toLowerCase(),
                        style: const TextStyle(
                          color: white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Your Transport Solution',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.menu, color: white),
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

            const SizedBox(height: 20),

            // Grid Buttons
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    buildDashboardButton(
                      icon: Icons.school,
                      label: 'Select School',
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectSchool(
                              initialSchoolData: schoolData,
                              travellerName: widget.travellerName,
                            ),
                          ),
                        );
                        if (result != null) {
                          debugPrint('Selected school: $result');
                        }
                      },
                    ),
                    buildDashboardButton(
                      icon: Icons.business,
                      label: 'Select Operator',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Select Operator tapped')),
                        );
                      },
                    ),
                    buildDashboardButton(
                      icon: Icons.location_on,
                      label: 'Live Location',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LiveLocationPage()),
                        );
                      },
                    ),
                    buildDashboardButton(
                      icon: Icons.calendar_today,
                      label: 'Calendar',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HolidayCalendarPage()),
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
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              spreadRadius: 2,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: turquoise),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
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
