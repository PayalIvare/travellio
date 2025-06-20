<<<<<<< HEAD
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DriverLocationPage extends StatefulWidget {
  @override
  _DriverLocationPageState createState() => _DriverLocationPageState();
}

class _DriverLocationPageState extends State<DriverLocationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> schools = [];
  String? selectedSchool;
  List<Map<String, dynamic>> routeSummaries = [];
  Map<String, dynamic>? selectedRouteSummary;
  Map<String, dynamic>? fullRoute;

  LatLng? busPosition;
  LatLng? start;
  LatLng? end;
  List<Map<String, dynamic>> stopPoints = [];
  List<LatLng> roadPath = [];

  StreamSubscription<Position>? positionStream;
  bool rideStarted = false;
  DateTime? lastUpdateTime;

<<<<<<< HEAD:lib/DriverLocationPage.dart
  final String orsApiKey = '5b3ce3597851110001cf6248c06c9e12119047b7a3b6369d5bd37ed9';
=======
  final String orsApiKey = 'YOUR_ORS_API_KEY'; // <-- Replace with your key!
>>>>>>> 8e100314efa14c92d6a9ed3c3a99fee0d5de8228:lib/DriverLocationPage

  @override
  void initState() {
    super.initState();
    fetchAssignedSchools();
  }

  Future<void> fetchAssignedSchools() async {
    User? user = _auth.currentUser;
    if (user == null) return;

<<<<<<< HEAD:lib/DriverLocationPage.dart
    final snapshot = await _firestore
=======
    var snapshot = await _firestore
>>>>>>> 8e100314efa14c92d6a9ed3c3a99fee0d5de8228:lib/DriverLocationPage
        .collection('assignedDrivers')
        .where('email', isEqualTo: user.email)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first.data();
      if (doc['schools'] != null) {
        setState(() {
          schools = List<Map<String, dynamic>>.from(doc['schools']);
        });
      }
    }
  }

  void prepareRouteSummaries() {
    if (selectedSchool == null) {
      setState(() {
        routeSummaries = [];
      });
      return;
    }
<<<<<<< HEAD:lib/DriverLocationPage.dart
    final routes = schools
        .firstWhere((s) => s['name'] == selectedSchool, orElse: () => {})
        .putIfAbsent('routes', () => []);

    if (routes is List) {
      setState(() {
        routeSummaries = routes.whereType<Map<String, dynamic>>().map((r) {
          return {
            'name': r['name'] ?? 'Route',
            'start': r['start']?['name'] ?? '',
            'end': r['end']?['name'] ?? '',
            'full': r,
          };
        }).toList();
      });
    }
=======
    var foundRoutes = schools
        .firstWhere((s) => s['name'] == selectedSchool)['routes'] ?? [];
    setState(() {
      routeSummaries = foundRoutes.where((r) => r is Map).map<Map<String, dynamic>>((r) {
        return {
          'name': r['name'] ?? 'Route',
          'start': r['start']?['name'] ?? '',
          'end': r['end']?['name'] ?? '',
          'full': r,
        };
      }).toList();
    });
>>>>>>> 8e100314efa14c92d6a9ed3c3a99fee0d5de8228:lib/DriverLocationPage
  }

  Future<void> fetchRouteFromORS(List<LatLng> points) async {
    final coordinates = points.map((p) => [p.longitude, p.latitude]).toList();
    final url = Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car/geojson');

    final response = await http.post(
      url,
      headers: {
        'Authorization': '5b3ce3597851110001cf6248c06c9e12119047b7a3b6369d5bd37ed9',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'coordinates': coordinates}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coords = data['features'][0]['geometry']['coordinates'];
      setState(() {
        roadPath = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
      });
    } else {
      print('ORS API error: ${response.body}');
    }
  }

  Future<void> startTracking() async {
    if (selectedRouteSummary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a school and route first!')),
      );
      return;
    }

    fullRoute = selectedRouteSummary!['full'];

<<<<<<< HEAD:lib/DriverLocationPage.dart
    // Extract start & end points
    final startGeo = fullRoute?['start']?['location'];
    final endGeo = fullRoute?['end']?['location'];

    if (startGeo is GeoPoint) {
      start = LatLng(startGeo.latitude, startGeo.longitude);
    }
    if (endGeo is GeoPoint) {
      end = LatLng(endGeo.latitude, endGeo.longitude);
=======
    // Extract start & end
    if (fullRoute!['start'] != null) {
      var startGeo = fullRoute!['start']['location'];
      if (startGeo is GeoPoint) {
        start = LatLng(startGeo.latitude, startGeo.longitude);
      }
    }

    if (fullRoute!['end'] != null) {
      var endGeo = fullRoute!['end']['location'];
      if (endGeo is GeoPoint) {
        end = LatLng(endGeo.latitude, endGeo.longitude);
      }
>>>>>>> 8e100314efa14c92d6a9ed3c3a99fee0d5de8228:lib/DriverLocationPage
    }

    // Extract stops
    stopPoints.clear();
    final stops = fullRoute?['stops'] ?? [];
    for (var stop in stops) {
      final loc = stop['location'];
      if (loc is GeoPoint) {
        stopPoints.add({
          'point': LatLng(loc.latitude, loc.longitude),
          'name': stop['name'] ?? '',
        });
      }
    }

<<<<<<< HEAD:lib/DriverLocationPage.dart
    // Fetch path from ORS
=======
    // Prepare path
>>>>>>> 8e100314efa14c92d6a9ed3c3a99fee0d5de8228:lib/DriverLocationPage
    List<LatLng> routePoints = [
      if (start != null) start!,
      ...stopPoints.map((s) => s['point'] as LatLng),
      if (end != null) end!,
    ];
    await fetchRouteFromORS(routePoints);

<<<<<<< HEAD:lib/DriverLocationPage.dart
    // Start position tracking
    final pos = await Geolocator.getCurrentPosition();
=======
    // Get initial position
    Position pos = await Geolocator.getCurrentPosition();
>>>>>>> 8e100314efa14c92d6a9ed3c3a99fee0d5de8228:lib/DriverLocationPage
    setState(() {
      busPosition = LatLng(pos.latitude, pos.longitude);
    });

    lastUpdateTime = DateTime.now();
    positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      setState(() {
        busPosition = LatLng(position.latitude, position.longitude);
      });

      final now = DateTime.now();
      if (lastUpdateTime == null || now.difference(lastUpdateTime!).inSeconds >= 5) {
        lastUpdateTime = now;
        final uid = _auth.currentUser?.uid;
        if (uid != null) {
          _firestore.collection('liveLocations').doc(uid).set({
            'lat': position.latitude,
            'lng': position.longitude,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    });

    setState(() {
      rideStarted = true;
    });
  }

  void stopTracking() {
    positionStream?.cancel();
    setState(() {
      busPosition = null;
      rideStarted = false;
      start = null;
      end = null;
      stopPoints.clear();
      fullRoute = null;
      roadPath.clear();
    });
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Location'),
        backgroundColor: Color(0xFF77DDE7),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedSchool,
              hint: Text('Select School'),
              items: schools.map((school) {
                return DropdownMenuItem<String>(
                  value: school['name'],
                  child: Text(school['name'] ?? ''),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedSchool = val;
                  selectedRouteSummary = null;
                  fullRoute = null;
                  start = null;
                  end = null;
                  stopPoints.clear();
                  roadPath.clear();
                  busPosition = null;
                });
                prepareRouteSummaries();
              },
            ),
            if (selectedSchool != null)
              DropdownButton<Map<String, dynamic>>(
                value: routeSummaries.contains(selectedRouteSummary)
                    ? selectedRouteSummary
                    : null,
                hint: Text('Select Route'),
                items: routeSummaries.map((summary) {
                  return DropdownMenuItem(
                    value: summary,
                    child: Text('${summary['start']} → ${summary['end']}'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedRouteSummary = val;
                    fullRoute = null;
                    start = null;
                    end = null;
                    stopPoints.clear();
                    roadPath.clear();
                    busPosition = null;
                  });
                },
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: startTracking,
              child: Text("Start Ride"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: stopTracking,
              child: Text("Stop Ride"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
            SizedBox(height: 20),
            if (rideStarted && fullRoute != null)
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    center: busPosition ?? start ?? LatLng(18.5204, 73.8567),
                    zoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        if (start != null)
                          Marker(
                            point: start!,
                            width: 30,
                            height: 30,
                            child: Icon(Icons.flag, color: Colors.green),
                          ),
                        if (end != null)
                          Marker(
                            point: end!,
                            width: 30,
                            height: 30,
                            child: Icon(Icons.flag, color: Colors.red),
                          ),
                        if (busPosition != null)
                          Marker(
                            point: busPosition!,
                            width: 40,
                            height: 40,
                            child: Icon(Icons.directions_bus, color: Colors.orange),
                          ),
<<<<<<< HEAD:lib/DriverLocationPage.dart
                        ...stopPoints.map((stop) => Marker(
                              point: stop['point'],
                              width: 20,
                              height: 20,
                              child: Icon(Icons.location_on, color: Colors.yellow),
                            )),
=======
                        ...stopPoints
                            .where((stop) => stop['point'] != null)
                            .map((stop) => Marker(
                                  point: stop['point'],
                                  width: 20,
                                  height: 20,
                                  child: Icon(Icons.location_on, color: Colors.yellow),
                                )),
>>>>>>> 8e100314efa14c92d6a9ed3c3a99fee0d5de8228:lib/DriverLocationPage
                      ],
                    ),
                    if (roadPath.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: roadPath,
                            color: Colors.blueAccent,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
=======
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DriverLocationPage extends StatefulWidget {
  @override
  _DriverLocationPageState createState() => _DriverLocationPageState();
}

class _DriverLocationPageState extends State<DriverLocationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> schools = [];
  String? selectedSchool;
  List<Map<String, dynamic>> routeSummaries = [];
  Map<String, dynamic>? selectedRouteSummary;
  Map<String, dynamic>? fullRoute;

  LatLng? busPosition;
  LatLng? start;
  LatLng? end;
  List<Map<String, dynamic>> stopPoints = [];
  List<LatLng> roadPath = [];

  StreamSubscription<Position>? positionStream;
  bool rideStarted = false;
  DateTime? lastUpdateTime;

  final String orsApiKey = '5b3ce3597851110001cf6248c06c9e12119047b7a3b6369d5bd37ed9';

  @override
  void initState() {
    super.initState();
    fetchAssignedSchools();
  }

  Future<void> fetchAssignedSchools() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('assignedDrivers')
        .where('email', isEqualTo: user.email)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first.data();
      if (doc['schools'] != null) {
        setState(() {
          schools = List<Map<String, dynamic>>.from(doc['schools']);
        });
      }
    }
  }

  void prepareRouteSummaries() {
    if (selectedSchool == null) {
      setState(() {
        routeSummaries = [];
      });
      return;
    }
    final routes = schools
        .firstWhere((s) => s['name'] == selectedSchool, orElse: () => {})
        .putIfAbsent('routes', () => []);

    if (routes is List) {
      setState(() {
        routeSummaries = routes.whereType<Map<String, dynamic>>().map((r) {
          return {
            'name': r['name'] ?? 'Route',
            'start': r['start']?['name'] ?? '',
            'end': r['end']?['name'] ?? '',
            'full': r,
          };
        }).toList();
      });
    }
  }

  Future<void> fetchRouteFromORS(List<LatLng> points) async {
    final coordinates = points.map((p) => [p.longitude, p.latitude]).toList();
    final url = Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car/geojson');

    final response = await http.post(
      url,
      headers: {
        'Authorization': orsApiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'coordinates': coordinates}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coords = data['features'][0]['geometry']['coordinates'];
      setState(() {
        roadPath = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
      });
    } else {
      print('ORS API error: ${response.body}');
    }
  }

  Future<void> startTracking() async {
    if (selectedRouteSummary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a school and route first!')),
      );
      return;
    }

    fullRoute = selectedRouteSummary!['full'];

    // Extract start & end points
    final startGeo = fullRoute?['start']?['location'];
    final endGeo = fullRoute?['end']?['location'];

    if (startGeo is GeoPoint) {
      start = LatLng(startGeo.latitude, startGeo.longitude);
    }
    if (endGeo is GeoPoint) {
      end = LatLng(endGeo.latitude, endGeo.longitude);
    }

    // Extract stops
    stopPoints.clear();
    final stops = fullRoute?['stops'] ?? [];
    for (var stop in stops) {
      final loc = stop['location'];
      if (loc is GeoPoint) {
        stopPoints.add({
          'point': LatLng(loc.latitude, loc.longitude),
          'name': stop['name'] ?? '',
        });
      }
    }

    // Fetch path from ORS
    List<LatLng> routePoints = [
      if (start != null) start!,
      ...stopPoints.map((s) => s['point'] as LatLng),
      if (end != null) end!,
    ];
    await fetchRouteFromORS(routePoints);

    // Start position tracking
    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      busPosition = LatLng(pos.latitude, pos.longitude);
    });

    lastUpdateTime = DateTime.now();
    positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      setState(() {
        busPosition = LatLng(position.latitude, position.longitude);
      });

      final now = DateTime.now();
      if (lastUpdateTime == null || now.difference(lastUpdateTime!).inSeconds >= 5) {
        lastUpdateTime = now;
        final uid = _auth.currentUser?.uid;
        if (uid != null) {
          _firestore.collection('liveLocations').doc(uid).set({
            'lat': position.latitude,
            'lng': position.longitude,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    });

    setState(() {
      rideStarted = true;
    });
  }

  void stopTracking() {
    positionStream?.cancel();
    setState(() {
      busPosition = null;
      rideStarted = false;
      start = null;
      end = null;
      stopPoints.clear();
      fullRoute = null;
      roadPath.clear();
    });
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Location'),
        backgroundColor: Color(0xFF77DDE7),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedSchool,
              hint: Text('Select School'),
              items: schools.map((school) {
                return DropdownMenuItem<String>(
                  value: school['name'],
                  child: Text(school['name'] ?? ''),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedSchool = val;
                  selectedRouteSummary = null;
                  fullRoute = null;
                  start = null;
                  end = null;
                  stopPoints.clear();
                  roadPath.clear();
                  busPosition = null;
                });
                prepareRouteSummaries();
              },
            ),
            if (selectedSchool != null)
              DropdownButton<Map<String, dynamic>>(
                value: routeSummaries.contains(selectedRouteSummary)
                    ? selectedRouteSummary
                    : null,
                hint: Text('Select Route'),
                items: routeSummaries.map((summary) {
                  return DropdownMenuItem(
                    value: summary,
                    child: Text('${summary['start']} → ${summary['end']}'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedRouteSummary = val;
                    fullRoute = null;
                    start = null;
                    end = null;
                    stopPoints.clear();
                    roadPath.clear();
                    busPosition = null;
                  });
                },
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: startTracking,
              child: Text("Start Ride"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: stopTracking,
              child: Text("Stop Ride"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
            SizedBox(height: 20),
            if (rideStarted && fullRoute != null)
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    center: busPosition ?? start ?? LatLng(18.5204, 73.8567),
                    zoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        if (start != null)
                          Marker(
                            point: start!,
                            width: 30,
                            height: 30,
                            child: Icon(Icons.flag, color: Colors.green),
                          ),
                        if (end != null)
                          Marker(
                            point: end!,
                            width: 30,
                            height: 30,
                            child: Icon(Icons.flag, color: Colors.red),
                          ),
                        if (busPosition != null)
                          Marker(
                            point: busPosition!,
                            width: 40,
                            height: 40,
                            child: Icon(Icons.directions_bus, color: Colors.orange),
                          ),
                        ...stopPoints.map((stop) => Marker(
                              point: stop['point'],
                              width: 20,
                              height: 20,
                              child: Icon(Icons.location_on, color: Colors.yellow),
                            )),
                      ],
                    ),
                    if (roadPath.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: roadPath,
                            color: Colors.blueAccent,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
>>>>>>> b543c71 (Update lib folder with latest changes)
