import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotifierPage extends StatefulWidget {
  final String driverEmail;
  final List<Map<String, dynamic>> assignedSchools;
  final List<Map<String, dynamic>> allTravellers;

  const NotifierPage({
    Key? key,
    required this.driverEmail,
    required this.assignedSchools,
    required this.allTravellers,
  }) : super(key: key);

  @override
  State<NotifierPage> createState() => _NotifierPageState();
}

class _NotifierPageState extends State<NotifierPage> {
  List<Map<String, dynamic>> filteredTravellers = [];
  List<String> selectedTravellerIds = [];
  bool selectAll = false;

  @override
  void initState() {
    super.initState();
    filterTravellers();
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
          final routeString = "$start → $end".toLowerCase();
          schoolRoutePairs.add({
            'school': schoolName,
            'route': routeString,
          });
        }
      }
    }

    setState(() {
      filteredTravellers = widget.allTravellers.where((t) {
        final travellerSchool = (t['school'] ?? '').toString().trim().toLowerCase();
        final travellerRoute = (t['route'] ?? '').toString().trim().toLowerCase();

        return schoolRoutePairs.any((pair) =>
            pair['school'] == travellerSchool &&
            (pair['route'] == travellerRoute ||
                travellerRoute.contains(pair['route']!) ||
                pair['route']!.contains(travellerRoute)));
      }).toList();
    });
  }

  void toggleSelectAll(bool? value) {
    setState(() {
      selectAll = value ?? false;
      selectedTravellerIds = selectAll
          ? filteredTravellers.map((t) => t['id'] as String).toList()
          : [];
    });
  }

  void toggleTraveller(String id, bool? value) {
    setState(() {
      if (value == true) {
        selectedTravellerIds.add(id);
      } else {
        selectedTravellerIds.remove(id);
      }
    });
  }

  Future<void> sendNotification(String type) async {
    final now = DateTime.now();
    final date = "${now.day}/${now.month}/${now.year}";
    final time = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    for (final id in selectedTravellerIds) {
      final traveller = filteredTravellers.firstWhere((t) => t['id'] == id);

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(id)
          .collection('messages')
          .add({
        'type': type,
        'message':
            "${traveller['traveller'] ?? 'Traveller'} has been ${type == 'Pickup' ? 'picked up' : 'dropped'}",
        'timestamp': FieldValue.serverTimestamp(),
        'date': date,
        'time': time,
        'driverEmail': widget.driverEmail,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$type notification sent.")),
    );

    setState(() {
      selectedTravellerIds.clear();
      selectAll = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifier"),
        backgroundColor: const Color(0xFF77DDE7),
        leading: const BackButton(color: Colors.black),
      ),
      body: filteredTravellers.isEmpty
          ? const Center(child: Text("No travellers found."))
          : Column(
              children: [
                CheckboxListTile(
                  title: const Text("Select All"),
                  value: selectAll,
                  onChanged: toggleSelectAll,
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredTravellers.length,
                    itemBuilder: (context, index) {
                      final traveller = filteredTravellers[index];
                      final name = traveller['traveller'] ?? 'Unnamed';

                      return CheckboxListTile(
                        title: Text(name),
                        value: selectedTravellerIds.contains(traveller['id']),
                        onChanged: (val) =>
                            toggleTraveller(traveller['id'], val),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: selectedTravellerIds.isEmpty
                          ? null
                          : () => sendNotification("Pickup"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("Pickup"),
                    ),
                    ElevatedButton(
                      onPressed: selectedTravellerIds.isEmpty
                          ? null
                          : () => sendNotification("Drop"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("Drop"),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
