import 'package:flutter/material.dart';
import 'driver_schools_page.dart';
import 'DriverTravellersPage.dart';
import 'DriverLocationPage.dart';

class DriverDashboard extends StatelessWidget {
  final Color turquoise = const Color(0xFF77DDE7);
  final Color black = Colors.black;

  const DriverDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ Example dummy data — replace this with your real data source
    final String driverEmail = 'driver@example.com';
    final List<Map<String, dynamic>> assignedSchools = [
      {'name': 'ABC School'},
      {'name': 'XYZ School'},
    ];
    final List<Map<String, dynamic>> allTravellers = [
      {
        'name': 'John Doe',
        'email': 'john@example.com',
        'school': 'ABC School',
        'route': 'Route 1',
        'pickup': 'Stop A',
        'drop': 'Stop B',
      },
      {
        'name': 'Jane Smith',
        'email': 'jane@example.com',
        'school': 'XYZ School',
        'route': 'Route 2',
        'pickup': 'Stop X',
        'drop': 'Stop Y',
      },
      {
        'name': 'Mark Lee',
        'email': 'mark@example.com',
        'school': 'LMN School',
        'route': 'Route 3',
        'pickup': 'Stop M',
        'drop': 'Stop N',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
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
                        MaterialPageRoute(
                          builder: (_) => DriverTravellersPage(
                            driverEmail: driverEmail,
                            assignedSchools: assignedSchools,
                            allTravellers: allTravellers,
                          ),
                        ),
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
                          builder: (_) => DriverSchoolsPage(),
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
                        const SnackBar(content: Text('Routes tapped')),
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
                        MaterialPageRoute(
                          builder: (_) => DriverLocationPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: turquoise,
                  foregroundColor: black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDashboardButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
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
              const SizedBox(height: 10),
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
