import 'package:flutter/material.dart';
import 'add_driver_page.dart';
import 'add_school_page.dart';
import 'add_vehicle.dart';
import 'view_travellers_page.dart';

class OperatorDashboard extends StatelessWidget {
  final Color turquoise = const Color(0xFF77DDE7);
  final Color black = Colors.black;

  @override
  Widget build(BuildContext context) {
    double iconSize = 40;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operator Dashboard'),
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
                    icon: Icons.person_add,
                    label: 'Add Driver',
                    color: turquoise,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddDriverPage()),
                    ),
                  ),
                  buildDashboardButton(
                    context,
                    icon: Icons.group,
                    label: 'View Travellers',
                    color: turquoise,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ViewTravellersPage()),
                    ),
                  ),
                  buildDashboardButton(
                    context,
                    icon: Icons.school,
                    label: 'Add School',
                    color: turquoise,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddSchoolPage()),
                    ),
                  ),
                  buildDashboardButton(
                    context,
                    icon: Icons.directions_bus,
                    label: 'Add Vehicle',
                    color: turquoise,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddVehiclePage()),
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
