import 'package:flutter/material.dart';

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

  void filterTravellers() {
    final schoolNames = widget.assignedSchools
        .map((s) => (s['name'] ?? '').toString().toLowerCase().trim())
        .toList();

    filteredTravellers = widget.allTravellers.where((t) {
      final travellerSchool = (t['school'] ?? '').toString().toLowerCase().trim();
      return schoolNames.contains(travellerSchool);
    }).toList();
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
