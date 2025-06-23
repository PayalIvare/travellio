import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DriverTravellersPage extends StatefulWidget {
  const DriverTravellersPage({Key? key}) : super(key: key); // ✅ const constructor

  @override
  State<DriverTravellersPage> createState() => _DriverTravellersPageState();
}

class _DriverTravellersPageState extends State<DriverTravellersPage> {
  List<Map<String, dynamic>> assignedSchools = [];
  List<Map<String, dynamic>> filteredTravellers = [];
  String? driverEmail;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final email = prefs.getString('loggedInEmail');
    if (email == null || email.isEmpty) return;
    driverEmail = email;

    final assignedData = prefs.getString('assignedDrivers');
    if (assignedData == null || assignedData.isEmpty) return;

    final assignedList = jsonDecode(assignedData) as List<dynamic>;
    for (final entry in assignedList) {
      final entryEmail = entry['driver']?['email'] ?? entry['email'];
      if (entryEmail == driverEmail && entry['schools'] != null) {
        assignedSchools = List<Map<String, dynamic>>.from(entry['schools']);
        break;
      }
    }

    final travellersData = prefs.getString('registeredTravellers');
    if (travellersData == null || travellersData.isEmpty) return;

    final travellersList = jsonDecode(travellersData) as List<dynamic>;

    final schoolNames = assignedSchools
        .map((s) => (s['name'] ?? '').toString().toLowerCase().trim())
        .toList();

    filteredTravellers = travellersList.where((t) {
      final travellerSchool = (t['school'] ?? '').toString().toLowerCase().trim();
      return schoolNames.contains(travellerSchool);
    }).map((t) => Map<String, dynamic>.from(t)).toList();

    setState(() {});
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
              Text('Name: ${traveller['name'] ?? 'N/A'}'),
              Text('Email: ${traveller['email'] ?? 'N/A'}'),
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
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F6FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              traveller['name'] ?? 'Unnamed',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => showTravellerDetails(traveller),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text("Details"),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
