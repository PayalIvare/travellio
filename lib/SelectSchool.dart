import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectSchool extends StatefulWidget {
  final List<dynamic> initialSchoolData;
  final String travellerName;

  const SelectSchool({
    Key? key,
    required this.initialSchoolData,
    required this.travellerName,
  }) : super(key: key);

  @override
  State<SelectSchool> createState() => _SelectSchoolState();
}


class _SelectSchoolState extends State<SelectSchool> {
  List<String> schools = [];
  String? selectedSchool;

  List<String> routes = [];
  String? selectedRoute;

  List<String> stops = [];
  String? selectedPickup;
  String? selectedDrop;

  List<dynamic> fullSchoolData = [];

  @override
  void initState() {
    super.initState();
    loadSchools();
  }

  void loadSchools() {
    fullSchoolData = widget.initialSchoolData;
    schools = fullSchoolData
        .map<String>((school) => school['name'].toString())
        .toList();
    setState(() {});
  }

  void loadRoutesForSelectedSchool() {
    if (selectedSchool != null) {
      final school = fullSchoolData.firstWhere(
        (s) => s['name'] == selectedSchool,
        orElse: () => null,
      );
      if (school != null) {
        final routeList = school['routes'] ?? [];
        routes = routeList.map<String>((route) {
          final start = route['start']?['name'] ?? '';
          final end = route['end']?['name'] ?? '';
          return "$start → $end";
        }).toList();
        selectedRoute = null;
        stops = [];
        selectedPickup = null;
        selectedDrop = null;
        setState(() {});
      }
    }
  }

  void loadStopsForSelectedRoute() {
    if (selectedSchool != null && selectedRoute != null) {
      final school = fullSchoolData.firstWhere(
        (s) => s['name'] == selectedSchool,
        orElse: () => null,
      );
      if (school != null) {
        final routeList = school['routes'] ?? [];
        for (var route in routeList) {
          final start = route['start']?['name'] ?? '';
          final end = route['end']?['name'] ?? '';
          final routeName = "$start → $end";
          if (routeName == selectedRoute) {
            final stopsList = route['stops'] ?? [];
            stops = stopsList
                .map<String>((stop) => stop['name'].toString())
                .toList();
            selectedPickup = null;
            selectedDrop = null;
            setState(() {});
            break;
          }
        }
      }
    }
  }

  Future<void> saveToFirestore() async {
    try {
      await FirebaseFirestore.instance
          .collection('traveller_school')
          .doc(widget.travellerName)
          .set({
        'traveller': widget.travellerName,
        'school': selectedSchool,
        'route': selectedRoute,
        'pickup': selectedPickup,
        'drop': selectedDrop,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to Firestore successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    }
  }

  void confirmAndReturn() {
    if (selectedSchool != null &&
        selectedRoute != null &&
        selectedPickup != null &&
        selectedDrop != null) {
      saveToFirestore();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const turquoise = Color(0xFF77DDE7);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select School & Route'),
        backgroundColor: turquoise,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration:
                          const InputDecoration(labelText: 'Select School'),
                      value: selectedSchool,
                      items: schools
                          .map((school) => DropdownMenuItem<String>(
                                value: school,
                                child: Text(school),
                              ))
                          .toList(),
                      onChanged: (value) {
                        selectedSchool = value;
                        loadRoutesForSelectedSchool();
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration:
                          const InputDecoration(labelText: 'Select Route'),
                      value: selectedRoute,
                      items: routes
                          .map((route) => DropdownMenuItem<String>(
                                value: route,
                                child: Text(route),
                              ))
                          .toList(),
                      onChanged: (value) {
                        selectedRoute = value;
                        loadStopsForSelectedRoute();
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                          labelText: 'Select Pickup Point'),
                      value: selectedPickup,
                      items: stops
                          .map((stop) => DropdownMenuItem<String>(
                                value: stop,
                                child: Text(stop),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPickup = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration:
                          const InputDecoration(labelText: 'Select Drop Point'),
                      value: selectedDrop,
                      items: stops
                          .map((stop) => DropdownMenuItem<String>(
                                value: stop,
                                child: Text(stop),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDrop = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: confirmAndReturn,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Confirm & Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
