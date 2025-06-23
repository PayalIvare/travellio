import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ViewTravellersPage extends StatefulWidget {
  @override
  _ViewTravellersPageState createState() => _ViewTravellersPageState();
}

class _ViewTravellersPageState extends State<ViewTravellersPage> {
  List<Map<String, dynamic>> travellers = [];

  @override
  void initState() {
    super.initState();
    loadTravellers();
  }

  /// Load travellers from SharedPreferences (JSON list)
  Future<void> loadTravellers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('registeredTravellers');
    if (data != null && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          setState(() {
            travellers = List<Map<String, dynamic>>.from(decoded);
          });
        }
      } catch (e) {
        debugPrint('Error decoding travellers: $e');
      }
    }
  }

  /// Show detailed info of a single traveller
  void showTravellerDetails(Map<String, dynamic> traveller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(traveller['name'] ?? 'No Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${traveller['email'] ?? "N/A"}'),
            Text('Phone: ${traveller['phone'] ?? "N/A"}'),
            Text('School: ${traveller['school'] ?? "N/A"}'),
            Text('Route: ${traveller['route'] ?? "N/A"}'),
            Text('Pickup: ${traveller['pickup'] ?? "N/A"}'),
            Text('Drop: ${traveller['drop'] ?? "N/A"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Travellers'),
        backgroundColor: const Color(0xFF77DDE7),
      ),
      body: travellers.isEmpty
          ? const Center(child: Text('No travellers found.'))
          : ListView.builder(
              itemCount: travellers.length,
              itemBuilder: (context, index) {
                final traveller = travellers[index];
                final name = traveller['name']?.toString().trim().isEmpty == false
                    ? traveller['name']
                    : 'Unnamed';
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  child: ListTile(
                    title: Text(name),
                    trailing: ElevatedButton(
                      onPressed: () => showTravellerDetails(traveller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Details'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
