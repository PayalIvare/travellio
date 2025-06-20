import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SelectSchool extends StatefulWidget {
  @override
  _SelectSchoolState createState() => _SelectSchoolState();
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedSchools = prefs.getString('schools');
    if (savedSchools != null) {
      List<dynamic> decoded = jsonDecode(savedSchools);
      setState(() {
        fullSchoolData = decoded;
        schools = decoded.map<String>((school) => school['name'].toString()).toList();
      });
    }
  }

  void loadRoutesForSelectedSchool() {
    if (selectedSchool != null) {
      var school = fullSchoolData.firstWhere((s) => s['name'] == selectedSchool);
      List<dynamic> routeList = school['routes'];
      setState(() {
        routes = routeList.map<String>((route) => "${route['start']} → ${route['end']}").toList();
        selectedRoute = null;
        stops = [];
        selectedPickup = null;
        selectedDrop = null;
      });
    }
  }

  void loadStopsForSelectedRoute() {
    if (selectedSchool != null && selectedRoute != null) {
      var school = fullSchoolData.firstWhere((s) => s['name'] == selectedSchool);
      List<dynamic> routeList = school['routes'];

      for (var route in routeList) {
        String routeName = "${route['start']} → ${route['end']}";
        if (routeName == selectedRoute) {
          List<dynamic> stopList = route['stops'];
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

  Future<void> saveSelections() async {
    if (selectedSchool != null &&
        selectedRoute != null &&
        selectedPickup != null &&
        selectedDrop != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString('selectedSchool', selectedSchool!);
      await prefs.setString('selectedRoute', selectedRoute!);
      await prefs.setInt('selectedRouteIndex', routes.indexOf(selectedRoute!));
      await prefs.setString('pickup_point', selectedPickup!);
      await prefs.setString('drop_point', selectedDrop!);

      try {
        String? loggedInEmail = prefs.getString('loggedInEmail');
        if (loggedInEmail != null) {
          String? data = prefs.getString('registeredTravellers');

          if (data != null) {
            List<dynamic> travellers = jsonDecode(data);

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
              print("✅ Traveller updated successfully.");
            } else {
              print("⚠️ No matching traveller found.");
            }
          } else {
            print("❌ registeredTravellers is null");
          }
        } else {
          print("❌ loggedInEmail is null");
        }
      } catch (e) {
        print("🚨 Error updating traveller: $e");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selections saved successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select all fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select School & Route'),
        backgroundColor: Color(0xFF77DDE7),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Select School'),
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
              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Select Route'),
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
              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Select Pickup Point'),
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
              SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Select Drop Point'),
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
              SizedBox(height: 32),

              ElevatedButton(
                onPressed: saveSelections,
                child: Text('Confirm & Save'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              ),
              SizedBox(height: 16),

              ElevatedButton(
                onPressed: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  String? school = prefs.getString('selectedSchool');
                  String? route = prefs.getString('selectedRoute');
                  String? pickup = prefs.getString('pickup_point');
                  String? drop = prefs.getString('drop_point');

                  if (school != null && route != null && pickup != null && drop != null) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Your Selections'),
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
                              child: Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No selections found!')),
                    );
                  }
                },
                child: Text('View Details'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
