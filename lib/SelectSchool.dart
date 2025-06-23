import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SelectSchool extends StatefulWidget {
  const SelectSchool({Key? key}) : super(key: key);

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

  Future<void> loadSchools() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSchools = prefs.getString('schools');
    if (savedSchools != null) {
      final decoded = jsonDecode(savedSchools);
      setState(() {
        fullSchoolData = decoded;
        schools = decoded.map<String>((school) => school['name'].toString()).toList();
      });
    }
  }

  void loadRoutesForSelectedSchool() {
    if (selectedSchool != null) {
      final school = fullSchoolData.firstWhere(
        (s) => s['name'] == selectedSchool,
        orElse: () => null,
      );
      if (school != null) {
        final List<dynamic> routeList = school['routes'];
        setState(() {
          routes = routeList.map<String>((route) => "${route['start']} → ${route['end']}").toList();
          selectedRoute = null;
          stops = [];
          selectedPickup = null;
          selectedDrop = null;
        });
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
        final List<dynamic> routeList = school['routes'];
        for (var route in routeList) {
          final routeName = "${route['start']} → ${route['end']}";
          if (routeName == selectedRoute) {
            final stopList = route['stops'];
            setState(() {
              stops = List<String>.from(stopList);
              selectedPickup = null;
              selectedDrop = null;
            });
            break;
          }
        }
      }
    }
  }

  Future<void> saveSelections() async {
    if (selectedSchool != null &&
        selectedRoute != null &&
        selectedPickup != null &&
        selectedDrop != null) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('selectedSchool', selectedSchool!);
      await prefs.setString('selectedRoute', selectedRoute!);
      await prefs.setInt('selectedRouteIndex', routes.indexOf(selectedRoute!));
      await prefs.setString('pickup_point', selectedPickup!);
      await prefs.setString('drop_point', selectedDrop!);

      try {
        final loggedInEmail = prefs.getString('loggedInEmail');
        if (loggedInEmail != null) {
          final data = prefs.getString('registeredTravellers');

          if (data != null) {
            final travellers = jsonDecode(data);

            bool updated = false;
            for (var traveller in travellers) {
              if (traveller is Map<String, dynamic> &&
                  traveller['email'] == loggedInEmail) {
                traveller['school'] = selectedSchool;
                traveller['route'] = selectedRoute;
                traveller['pickup'] = selectedPickup;
                traveller['drop'] = selectedDrop;
                updated = true;
                break;
              }
            }

            if (updated) {
              await prefs.setString('registeredTravellers', jsonEncode(travellers));
              debugPrint("✅ Traveller updated successfully.");
            } else {
              debugPrint("⚠️ No matching traveller found.");
            }
          } else {
            debugPrint("❌ registeredTravellers is null");
          }
        } else {
          debugPrint("❌ loggedInEmail is null");
        }
      } catch (e) {
        debugPrint("🚨 Error updating traveller: $e");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selections saved successfully!')),
      );
      Navigator.pop(context);
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
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select School'),
                value: selectedSchool,
                items: schools
                    .map((school) => DropdownMenuItem<String>(
                          value: school,
                          child: Text(school),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSchool = value;
                  });
                  loadRoutesForSelectedSchool();
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Route'),
                value: selectedRoute,
                items: routes
                    .map((route) => DropdownMenuItem<String>(
                          value: route,
                          child: Text(route),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRoute = value;
                  });
                  loadStopsForSelectedRoute();
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Pickup Point'),
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
                decoration: const InputDecoration(labelText: 'Select Drop Point'),
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
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: saveSelections,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Confirm & Save'),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final school = prefs.getString('selectedSchool');
                  final route = prefs.getString('selectedRoute');
                  final pickup = prefs.getString('pickup_point');
                  final drop = prefs.getString('drop_point');

                  if (school != null && route != null && pickup != null && drop != null) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Your Selections'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('School: $school'),
                              Text('Route: $route'),
                              Text('Pickup Point: $pickup'),
                              Text('Drop Point: $drop'),
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
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No selections found!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('View Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
