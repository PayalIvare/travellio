import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'SelectSchool.dart';
import 'HolidayCalendarPage.dart';

class TravellerDashboard extends StatefulWidget {
  @override
  _TravellerDashboardState createState() => _TravellerDashboardState();
}

class _TravellerDashboardState extends State<TravellerDashboard> {
  final Color turquoise = Color(0xFF77DDE7);
  final Color black = Colors.black;
  final Color white = Colors.white;

  String travellerName = "Traveller";

  @override
  void initState() {
    super.initState();
    loadTravellerName();
  }

  Future<void> loadTravellerName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      travellerName = prefs.getString('travellerName') ?? "Traveller";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: Column(
        children: [
          // ✅ Top bar at very top with no extra padding
          Container(
            color: turquoise,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top), // safe area only
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: white),
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton(
                  icon: Icon(Icons.menu, color: white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Menu tapped')),
                    );
                  },
                ),
              ],
            ),
          ),

          // ✅ Hello block with rounded bottom corners
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: turquoise,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello,',
                    style: TextStyle(color: white, fontSize: 24)),
                Text(travellerName,
                    style: TextStyle(
                        color: white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text('Your Transport Solution',
                    style: TextStyle(color: white, fontSize: 20)),
                // Text('Transport Solution',
                //     style: TextStyle(color: white, fontSize: 20)),
              ],
            ),
          ),

          // ✅ Buttons Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  buildDashboardButton(
                    context,
                    icon: Icons.school,
                    label: 'Select School',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectSchool(),
                        ),
                      );
                    },
                  ),
                  buildDashboardButton(
                    context,
                    icon: Icons.business,
                    label: 'Select Operator',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Select Operator tapped')),
                      );
                    },
                  ),
                  buildDashboardButton(
                    context,
                    icon: Icons.location_on,
                    label: 'Live Location',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Live Location tapped')),
                      );
                    },
                  ),
                  buildDashboardButton(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Calendar',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HolidayCalendarPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDashboardButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: black, // ✅ black background
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
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
              Icon(icon, size: 40, color: turquoise), // ✅ icon turquoise
              SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: turquoise, // ✅ text turquoise
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
