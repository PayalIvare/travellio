import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DriverSchoolsPage extends StatefulWidget {
  @override
  _DriverSchoolsPageState createState() => _DriverSchoolsPageState();
}

class _DriverSchoolsPageState extends State<DriverSchoolsPage> {
  List<Map<String, dynamic>> assignedSchools = [];
  String driverEmail = '';

  @override
  void initState() {
    super.initState();
    fetchDriverSchools();
  }

  Future<void> fetchDriverSchools() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? email = prefs.getString('loggedInEmail');
    if (email == null) return;

    driverEmail = email;
    print('Logged in driver email: $driverEmail');

    String? assignedData = prefs.getString('assignedDrivers');
    if (assignedData == null) return;

    List<dynamic> assignedList = jsonDecode(assignedData);
    print('Assigned Drivers List: $assignedList');

    for (var entry in assignedList) {
      final email = entry['driver']?['email'] ?? entry['email'];
      print('Checking entry: ${entry['driver']}, email: $email');

      if (email == driverEmail) {
        print('Match found. Schools: ${entry['schools']}');
        setState(() {
          assignedSchools = List<Map<String, dynamic>>.from(entry['schools']);
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Assigned Schools"),
        backgroundColor: Color(0xFF77DDE7),
      ),
      body: assignedSchools.isEmpty
          ? Center(child: Text("No schools assigned yet."))
          : ListView.builder(
              itemCount: assignedSchools.length,
              itemBuilder: (context, index) {
                final school = assignedSchools[index];
                return Card(
                  margin: EdgeInsets.all(12),
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          school['name'] ?? 'Unnamed School',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        if (school['routes'] is List &&
                            (school['routes'] as List).isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                (school['routes'] as List).map<Widget>((route) {
                              return Text("- $route");
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
