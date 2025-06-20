import 'package:flutter/material.dart';
import 'driver_schools_page.dart'; 
import 'DriverTravellersPage.dart';
import 'DriverLocationPage';

class DriverDashboard extends StatelessWidget {
  final Color turquoise = Color(0xFF77DDE7);
  final Color black = Colors.black;
  final Color white = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Dashboard'),
        backgroundColor: turquoise,
      ),
      backgroundColor: black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  buildDashboardButton(
                    context,
                    icon: Icons.group,
                    label: 'Travellers',
                    color: turquoise,
                    onTap: () {
                     Navigator.push(
                       context,
                      MaterialPageRoute(builder: (_) => DriverTravellersPage()),
                     );

                    },
                  ),
                  buildDashboardButton(
                    context,
                    icon: Icons.school,
                    label: 'Schools',
                    color: turquoise,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DriverSchoolsPage(),
                        ),
                      );
                    },
                  ),
                  buildDashboardButton(
                    context,
                    icon: Icons.alt_route,
                    label: 'Routes',
                    color: turquoise,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Routes tapped')),
                      );
                    },
                  ),
                  buildDashboardButton(
                    context,
                    icon: Icons.notifications,
                    label: 'Notifier',
                    color: turquoise,
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back),
                label: Text('Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: turquoise,
                  foregroundColor: black,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDashboardButton(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: black),
              SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: black,
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
