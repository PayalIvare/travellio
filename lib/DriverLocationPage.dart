import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DriverLocationPage extends StatefulWidget {
  const DriverLocationPage({Key? key}) : super(key: key);

  @override
  State<DriverLocationPage> createState() => _DriverLocationPageState();
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
  StreamSubscription<Position>? _positionStream;
  bool rideStarted = false;

  LatLng? start;
  LatLng? end;
  List<Map<String, dynamic>> stopPoints = [];
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  GoogleMapController? mapController;

  BitmapDescriptor? startIcon;
  BitmapDescriptor? endIcon;
  BitmapDescriptor? stopIcon;
  BitmapDescriptor? busIcon;

  @override
  void initState() {
    super.initState();
    loadCustomIcons();
    fetchAssignedSchools();
  }

  Future<void> loadCustomIcons() async {
    startIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(18, 18)), 'assets/icons/start.png');
    endIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(18, 18)), 'assets/icons/end.png');
    stopIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(18, 18)), 'assets/icons/stop.png');
    busIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(20, 20)), 'assets/icons/bus.png');
  }

  Future<void> fetchAssignedSchools() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('assignedDrivers')
          .where('email', isEqualTo: user.email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first.data();
        setState(() {
          schools = List<Map<String, dynamic>>.from(doc['schools'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetching assigned schools: $e');
    }
  }

  void prepareRouteSummaries() {
    if (selectedSchool == null) {
      setState(() => routeSummaries = []);
      return;
    }

    final foundRoutes = schools.firstWhere(
      (s) => s['name'] == selectedSchool,
      orElse: () => {},
    )['routes'] ?? [];

    setState(() {
      routeSummaries = foundRoutes.whereType<Map>().map<Map<String, dynamic>>((r) {
        return {
          'name': r['name'] ?? 'Route',
          'start': r['start']?['name'] ?? '',
          'end': r['end']?['name'] ?? '',
          'full': r,
        };
      }).toList();
    });
  }

  Future<void> drawRouteWithORS(List<LatLng> waypoints) async {
    final coordinates = waypoints.map((p) => [p.longitude, p.latitude]).toList();

    try {
      final response = await http.post(
        Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car/geojson'),
        headers: {
          'Authorization': '5b3ce3597851110001cf6248c06c9e12119047b7a3b6369d5bd37ed9',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'coordinates': coordinates}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coords = data['features'][0]['geometry']['coordinates'] as List;
        final points = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();

        setState(() {
          polylines.clear();
          polylines.add(Polyline(
            polylineId: const PolylineId('ors_route'),
            color: Colors.blueAccent,
            width: 5,
            points: points,
          ));
        });
      } else {
        debugPrint('ORS error: ${response.body}');
      }
    } catch (e) {
      debugPrint('Failed to draw route: $e');
    }
  }

  Future<void> startTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied');
        return;
      }
    }

    if (selectedRouteSummary == null) return;
    fullRoute = selectedRouteSummary!['full'];
    markers.clear();
    polylines.clear();

    final startGeo = fullRoute?['start']?['location'];
    if (startGeo is GeoPoint) {
      start = LatLng(startGeo.latitude, startGeo.longitude);
      markers.add(Marker(
        markerId: const MarkerId('start'),
        position: start!,
        icon: startIcon ?? BitmapDescriptor.defaultMarker,
      ));
    }

    final endGeo = fullRoute?['end']?['location'];
    if (endGeo is GeoPoint) {
      end = LatLng(endGeo.latitude, endGeo.longitude);
      markers.add(Marker(
        markerId: const MarkerId('end'),
        position: end!,
        icon: endIcon ?? BitmapDescriptor.defaultMarker,
      ));
    }

    stopPoints.clear();
    List<LatLng> routePoints = [];
    if (start != null) routePoints.add(start!);

    for (final stop in fullRoute?['stops'] ?? []) {
      final loc = stop['location'];
      if (loc is GeoPoint) {
        final stopPoint = LatLng(loc.latitude, loc.longitude);
        stopPoints.add({'point': stopPoint});
        routePoints.add(stopPoint);
        markers.add(Marker(
          markerId: MarkerId(stop['name'] ?? ''),
          position: stopPoint,
          icon: stopIcon ?? BitmapDescriptor.defaultMarker,
        ));
      }
    }

    if (end != null) routePoints.add(end!);
    await drawRouteWithORS(routePoints);

    final user = _auth.currentUser;
    if (user != null) {
      final docRef = _firestore.collection('busLocations').doc(user.uid);
      final exists = (await docRef.get()).exists;

      final pos = await Geolocator.getCurrentPosition();
      busPosition = LatLng(pos.latitude, pos.longitude);
      markers.add(Marker(
        markerId: const MarkerId('bus'),
        position: busPosition!,
        icon: busIcon ?? BitmapDescriptor.defaultMarker,
      ));

      mapController?.animateCamera(CameraUpdate.newLatLngZoom(busPosition!, 15));

      final busData = {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'active': true,
      };

      if (!exists) {
        await docRef.set(busData);
      } else {
        await docRef.update(busData);
      }
    }

    setState(() => rideStarted = true);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((Position pos) async {
      final newPosition = LatLng(pos.latitude, pos.longitude);
      setState(() {
        busPosition = newPosition;
        markers.removeWhere((m) => m.markerId.value == 'bus');
        markers.add(Marker(
          markerId: const MarkerId('bus'),
          position: busPosition!,
          icon: busIcon ?? BitmapDescriptor.defaultMarker,
        ));
      });

      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('busLocations').doc(user.uid).update({
          'lat': pos.latitude,
          'lng': pos.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  void stopTracking() async {
    _positionStream?.cancel();
    _positionStream = null;

    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('busLocations').doc(user.uid).update({
        'active': false,
      });
    }

    setState(() {
      rideStarted = false;
      start = null;
      end = null;
      stopPoints.clear();
      markers.clear();
      polylines.clear();
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Location')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedSchool,
              hint: const Text('Select School'),
              items: schools.map((s) {
                return DropdownMenuItem<String>(
                  value: s['name'],
                  child: Text(s['name']),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedSchool = val;
                  selectedRouteSummary = null;
                  prepareRouteSummaries();
                });
              },
            ),
            if (selectedSchool != null)
              DropdownButton<Map<String, dynamic>>(
                value: selectedRouteSummary,
                hint: const Text('Select Route'),
                items: routeSummaries.map((summary) {
                  return DropdownMenuItem(
                    value: summary,
                    child: Text('${summary['start']} → ${summary['end']}'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedRouteSummary = val),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: startTracking,
              child: const Text('Start Ride'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: stopTracking,
              child: const Text('Stop Ride'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
            const SizedBox(height: 20),
            if (rideStarted && busPosition != null)
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: busPosition!,
                    zoom: 15,
                  ),
                  markers: markers,
                  polylines: polylines,
                  onMapCreated: (controller) => mapController = controller,
                  myLocationEnabled: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}