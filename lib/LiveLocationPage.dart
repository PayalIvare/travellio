import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LiveLocationPage extends StatefulWidget {
  const LiveLocationPage({Key? key}) : super(key: key);

  @override
  State<LiveLocationPage> createState() => _LiveLocationPageState();
}

class _LiveLocationPageState extends State<LiveLocationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> schools = [];
  String? selectedSchool;
  List<Map<String, dynamic>> routes = [];
  String? selectedRouteName;
  Map<String, dynamic>? selectedRoute;
  LatLng? start, end, busPosition;
  List<LatLng> stopPoints = [];
  List<LatLng> roadPath = [];

  BitmapDescriptor? startIcon, endIcon, stopIcon, busIcon;
  GoogleMapController? mapController;
  bool iconsLoaded = false;

  StreamSubscription<DocumentSnapshot>? _locationSubscription;
  Map<String, dynamic>? currentDriver;

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _fetchAssignedDrivers();
  }

  Future<void> _loadIcons() async {
    try {
      startIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(18, 18)), 'assets/icons/start.png');
      endIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(18, 18)), 'assets/icons/end.png');
      stopIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(18, 18)), 'assets/icons/stop.png');
      busIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(20, 20)), 'assets/icons/bus.png');

      setState(() {
        iconsLoaded = true;
      });
    } catch (e) {
      debugPrint("Error loading icons: $e");
    }
  }

  Future<Map<String, dynamic>?> _getTravellerSchoolRoute() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('traveller_school').doc(user.uid).get();
      if (!doc.exists) return null;

      return doc.data();
    } catch (e) {
      debugPrint('Error fetching traveller_school info: $e');
      return null;
    }
  }

  Future<void> _fetchAssignedDrivers() async {
    try {
      final travellerData = await _getTravellerSchoolRoute();
      if (travellerData == null) {
        debugPrint('No traveller_school data found.');
        return;
      }

      final userSchool = travellerData['school'];
      final userRouteName = travellerData['route'];

      final snapshot = await _firestore.collection('assignedDrivers').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final List schoolsList = data['schools'] ?? [];

        for (var school in schoolsList) {
          if (school['name'] == userSchool) {
            final routesList = school['routes'] ?? [];

            for (var route in routesList) {
              final startName = route['start']?['name'] ?? '';
              final endName = route['end']?['name'] ?? '';
              final routeName = "$startName → $endName";

              if (routeName == userRouteName) {
                setState(() {
                  selectedSchool = userSchool;
                  selectedRouteName = userRouteName;
                  selectedRoute = route;
                  schools = [Map<String, dynamic>.from(school)];
                  routes = [Map<String, dynamic>.from(route)];
                  currentDriver = data;
                });
                _fetchRouteAndStartTracking();
                return;
              }
            }
          }
        }
      }

      debugPrint('No matching driver found for school: $userSchool and route: $userRouteName');
    } catch (e) {
      debugPrint("Error in _fetchAssignedDrivers: $e");
    }
  }

  Future<void> _fetchRouteAndStartTracking() async {
    if (selectedRoute == null) return;

    final route = selectedRoute!;
    start = end = null;
    stopPoints.clear();
    roadPath.clear();

    if (route['start']?['location'] != null) {
      final startGeo = route['start']['location'];
      start = LatLng(startGeo.latitude, startGeo.longitude);
    }

    if (route['end']?['location'] != null) {
      final endGeo = route['end']['location'];
      end = LatLng(endGeo.latitude, endGeo.longitude);
    }

    if (route['stops'] != null) {
      for (final stop in route['stops']) {
        final loc = stop['location'];
        if (loc != null) {
          stopPoints.add(LatLng(loc.latitude, loc.longitude));
        }
      }
    }

    if (start != null && end != null) {
      await _fetchORSPath([start!, end!]);
    }

    final driverEmail = currentDriver?['driver']?['email'];
    if (driverEmail != null) {
      final uid = await _getDriverUidByEmail(driverEmail);
      if (uid != null) {
        _subscribeToLiveLocation(uid);
      } else {
        debugPrint('No UID found for email: $driverEmail');
      }
    }
  }

  Future<String?> _getDriverUidByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
    } catch (e) {
      debugPrint('Error getting UID by email: $e');
    }
    return null;
  }

  void _subscribeToLiveLocation(String uid) {
    _locationSubscription?.cancel();
    _locationSubscription = _firestore
        .collection('busLocations')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['lat'] != null && data['lng'] != null) {
          setState(() {
            busPosition = LatLng(data['lat'], data['lng']);
          });
        }
      }
    }, onError: (e) {
      debugPrint("Live location stream error: $e");
    });
  }

  Future<void> _fetchORSPath(List<LatLng> points) async {
    if (points.length < 2) return;

    try {
      final coordinates = [
        [points.first.longitude, points.first.latitude],
        [points.last.longitude, points.last.latitude],
      ];

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
        final coords = data['features'][0]['geometry']['coordinates'] as List;
        setState(() {
          roadPath = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
        });
        debugPrint("Fetched ${roadPath.length} polyline points.");
      } else {
        debugPrint("ORS failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("ORS error: $e");
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultLocation = const LatLng(18.5204, 73.8567);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bus Location'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: (!iconsLoaded)
                ? const Center(child: CircularProgressIndicator())
                : (start != null && end != null)
                    ? GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: busPosition ?? start ?? defaultLocation,
                          zoom: 14,
                        ),
                        markers: {
                          if (start != null)
                            Marker(
                              markerId: const MarkerId('start'),
                              position: start!,
                              icon: startIcon ?? BitmapDescriptor.defaultMarker,
                            ),
                          if (end != null)
                            Marker(
                              markerId: const MarkerId('end'),
                              position: end!,
                              icon: endIcon ?? BitmapDescriptor.defaultMarker,
                            ),
                          if (busPosition != null)
                            Marker(
                              markerId: const MarkerId('bus'),
                              position: busPosition!,
                              icon: busIcon ?? BitmapDescriptor.defaultMarker,
                            ),
                          ...stopPoints.map(
                            (s) => Marker(
                              markerId: MarkerId('stop-${s.latitude},${s.longitude}'),
                              position: s,
                              icon: stopIcon ?? BitmapDescriptor.defaultMarker,
                            ),
                          ),
                        },
                        polylines: {
                          if (roadPath.isNotEmpty)
                            Polyline(
                              polylineId: const PolylineId('roadPath'),
                              color: Colors.blueAccent,
                              width: 4,
                              points: roadPath,
                            ),
                        },
                        myLocationEnabled: false,
                        myLocationButtonEnabled: true,
                        onMapCreated: (controller) => mapController = controller,
                      )
                    : const Center(child: Text("Please wait, loading route...")),
          )
        ],
      ),
    );
  }
}
