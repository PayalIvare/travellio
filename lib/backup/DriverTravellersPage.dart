import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DriverTravellersPage extends StatefulWidget {
  @override
  _DriverTravellersPageState createState() => _DriverTravellersPageState();
}

class _DriverTravellersPageState extends State<DriverTravellersPage> {
  List<Map<String, dynamic>> assignedSchools = [];
  List<Map<String, dynamic>> filteredTravellers = [];
  String driverEmail = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? email = prefs.getString('loggedInEmail');
    if (email == null) return;
    driverEmail = email;

    String? assignedData = prefs.getString('assignedDrivers');
    if (assignedData == null) return;

    List<dynamic> assignedList = jsonDecode(assignedData);
    for (var entry in assignedList) {
      final entryEmail = entry['driver']?['email'] ?? entry['email'];
      if (entryEmail == driverEmail && entry['schools'] != null) {
        assignedSchools = List<Map<String, dynamic>>.from(entry['schools']);
        break;
      }
    }

    String? travellersData = prefs.getString('registeredTravellers');
    if (travellersData == null) return;

    List<dynamic> travellersList = jsonDecode(travellersData);

    List<String> schoolNames = assignedSchools
        .map((school) => (school['name'] ?? '').toString().toLowerCase().trim())
        .toList();

    filteredTravellers = travellersList.where((traveller) {
      String travellerSchool =
          (traveller['school'] ?? '').toString().toLowerCase().trim();
      return schoolNames.contains(travellerSchool);
    }).map((t) => Map<String, dynamic>.from(t)).toList();

    setState(() {});
  }

  void showTravellerDetails(Map<String, dynamic> traveller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Traveller Details'),
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
              child: Text('Close'),
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
        title: Text("View Travellers"),
        backgroundColor: Color(0xFF77DDE7),
        leading: BackButton(color: Colors.black),
      ),
      body: filteredTravellers.isEmpty
          ? Center(child: Text("No travellers found."))
          : ListView.builder(
              itemCount: filteredTravellers.length,
              itemBuilder: (context, index) {
                final traveller = filteredTravellers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF9F6FC),
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
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => showTravellerDetails(traveller),
                            child: Text("Details"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
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
