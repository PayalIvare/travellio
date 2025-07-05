import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewTravellersPage extends StatefulWidget {
  const ViewTravellersPage({Key? key}) : super(key: key);

  @override
  _ViewTravellersPageState createState() => _ViewTravellersPageState();
}

class _ViewTravellersPageState extends State<ViewTravellersPage> {
  List<Map<String, dynamic>> travellers = [];

  @override
  void initState() {
    super.initState();
    fetchTravellers();
  }

  Future<void> fetchTravellers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('traveller_school')
          .get();

      List<Map<String, dynamic>> fetched = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['uid'] = doc.id; // Save UID for reference
        fetched.add(data);
      }

      setState(() {
        travellers = fetched;
      });
    } catch (e) {
      print('Error fetching travellers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading travellers')),
      );
    }
  }

  void showTravellerDetails(Map<String, dynamic> traveller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(traveller['traveller'] ?? 'No Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        backgroundColor: const Color(0xFF77DDE7),
        title: const Text('View Travellers'),
      ),
      body: travellers.isEmpty
          ? const Center(child: Text('No travellers found.'))
          : ListView.builder(
              itemCount: travellers.length,
              itemBuilder: (context, index) {
                final traveller = travellers[index];
                final name = traveller['traveller'] ?? 'Unnamed';
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
                          name,
                          style: const TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.black),
                          tooltip: 'Details',
                          onPressed: () => showTravellerDetails(traveller),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
