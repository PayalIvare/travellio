import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverTravellersPage extends StatefulWidget {
  final String driverEmail;
  final List<Map<String, dynamic>> assignedSchools;
  final List<Map<String, dynamic>> allTravellers;

  const DriverTravellersPage({
    Key? key,
    required this.driverEmail,
    required this.assignedSchools,
    required this.allTravellers,
  }) : super(key: key);

  @override
  State<DriverTravellersPage> createState() => _DriverTravellersPageState();
}

class _DriverTravellersPageState extends State<DriverTravellersPage> {
  List<Map<String, dynamic>> filteredTravellers = [];

  @override
  void initState() {
    super.initState();
    filterTravellers();
  }

  String normalizeRoute(String route) {
    return route.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  }

  void filterTravellers() {
    List<Map<String, String>> schoolRoutePairs = [];

    for (var school in widget.assignedSchools) {
      final schoolName = (school['name'] ?? '').toString().trim().toLowerCase();
      final routes = school['routes'] as List? ?? [];

      for (var route in routes) {
        final start = route['start']?['name']?.toString().trim();
        final end = route['end']?['name']?.toString().trim();
        if (start != null && end != null) {
          final routeString = "$start → $end";
          schoolRoutePairs.add({
            'school': schoolName,
            'route': routeString,
          });
        }
      }
    }

    setState(() {
      filteredTravellers = widget.allTravellers
          .where((t) {
            final travellerSchool = (t['school'] ?? '').toString().trim().toLowerCase();
            final travellerRoute = (t['route'] ?? '').toString().trim().toLowerCase();

            return schoolRoutePairs.any((pair) =>
                pair['school'] == travellerSchool &&
                normalizeRoute(pair['route']!) == normalizeRoute(travellerRoute));
          })
          .map((t) {
            final uid = t['uid'] ?? '';
            return {
              ...t,
              'id': uid,
            };
          })
          .toList();
    });

    print("Filtered travellers count: ${filteredTravellers.length}");
  }

  void showTravellerDetails(Map<String, dynamic> traveller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Traveller Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${traveller['traveller'] ?? 'N/A'}'),
              Text('School: ${traveller['school'] ?? 'N/A'}'),
              Text('Route: ${traveller['route'] ?? 'N/A'}'),
              Text('Pickup: ${traveller['pickup'] ?? 'N/A'}'),
              Text('Drop: ${traveller['drop'] ?? 'N/A'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Travellers"),
        backgroundColor: const Color(0xFF77DDE7),
        leading: const BackButton(color: Colors.black),
      ),
      body: filteredTravellers.isEmpty
          ? const Center(child: Text("No travellers found."))
          : ListView.builder(
              itemCount: filteredTravellers.length,
              itemBuilder: (context, index) {
                final traveller = filteredTravellers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F6FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          traveller['traveller'] ?? 'Unnamed',
                          style: const TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.black),
                          tooltip: 'Details',
                          onPressed: () => showTravellerDetails(traveller),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
