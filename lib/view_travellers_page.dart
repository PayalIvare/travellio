import 'package:flutter/material.dart';

class ViewTravellersPage extends StatefulWidget {
  final List<Map<String, dynamic>> travellers;

  const ViewTravellersPage({Key? key, required this.travellers}) : super(key: key);

  @override
  _ViewTravellersPageState createState() => _ViewTravellersPageState();
}

class _ViewTravellersPageState extends State<ViewTravellersPage> {
  late final List<Map<String, dynamic>> travellers;

  @override
  void initState() {
    super.initState();
    travellers = widget.travellers;
  }

  /// Show details of a traveller
  void showTravellerDetails(Map<String, dynamic> traveller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(traveller['name']?.toString().trim().isNotEmpty == true
            ? traveller['name']
            : 'No Name'),
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
                final name = traveller['name']?.toString().trim().isNotEmpty == true
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
