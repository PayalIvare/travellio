import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'SelectSchool.dart';
import 'HolidayCalendarPage.dart';
import 'LiveLocationPage.dart';
import 'package:intl/intl.dart';

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
  List<Map<String, dynamic>> notifications = [];
  bool hasNewNotifications = false;

  @override
  void initState() {
    super.initState();
    loadSchoolData();
    fetchNotifications();
  }

  Future<void> loadSchoolData() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('schools').get();
    setState(() {
      schoolData = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> fetchNotifications() async {
    final userDoc = FirebaseAuth.instance.currentUser;
    if (userDoc == null) return;

    final notifRef = FirebaseFirestore.instance
        .collection('notifications')
        .doc(widget.travellerName)
        .collection('messages');

    final snapshot = await notifRef.orderBy('timestamp', descending: true).get();
    final fetched = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    setState(() {
      notifications = fetched;
      hasNewNotifications = fetched.isNotEmpty;
    });
  }

  Future<void> dismissNotifications() async {
    final notifRef = FirebaseFirestore.instance
        .collection('notifications')
        .doc(widget.travellerName)
        .collection('messages');

    final snapshot = await notifRef.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    setState(() {
      notifications.clear();
      hasNewNotifications = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
        child: Column(
          children: [
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
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
                        const Text('Your Transport Solution', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 48,
                    child: Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications, color: white),
                          onPressed: () async {
                            await showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (context) {
                                if (notifications.isEmpty) {
                                  return SizedBox(
                                    height: 150,
                                    child: Center(
                                      child: Text('No notifications', style: TextStyle(color: turquoise)),
                                    ),
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (var notif in notifications)
                                        Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0F8FF),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: turquoise),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                DateFormat('dd MMM yyyy, hh:mm a').format(
                                                  (notif['timestamp'] as Timestamp).toDate(),
                                                ),
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                notif['message'] ?? '',
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ),
                                      TextButton(
                                        onPressed: () async {
                                          await dismissNotifications();
                                          Navigator.of(context).pop(); // Close bottom sheet
                                          setState(() {
                                            hasNewNotifications = false;
                                          });
                                        },
                                        style: TextButton.styleFrom(foregroundColor: turquoise),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        if (hasNewNotifications)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
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
