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

  Future<void> loadTravellers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('registeredTravellers');
    if (data != null) {
      setState(() {
        travellers = List<Map<String, dynamic>>.from(jsonDecode(data));
      });
    }
  }

  void showTravellerDetails(Map<String, dynamic> traveller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(traveller['name'] ?? 'No Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${traveller['email'] ?? "Not provided"}'),
            Text('Phone: ${traveller['phone'] ?? "Not provided"}'),
            Text('School: ${traveller['school'] ?? "N/A"}'),
            Text('Bus Stop: ${traveller['busStop'] ?? "N/A"}'),
            Text('Pickup: ${traveller['pickup'] ?? "N/A"}'),
            Text('Drop: ${traveller['drop'] ?? "N/A"}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Travellers'),
        backgroundColor: Color(0xFF77DDE7),
      ),
      body: ListView.builder(
        itemCount: travellers.length,
        itemBuilder: (context, index) {
          final traveller = travellers[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: ListTile(
              title: Text(traveller['name'] ?? 'Unnamed'),
              trailing: ElevatedButton(
                onPressed: () => showTravellerDetails(traveller),
                child: Text('Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
