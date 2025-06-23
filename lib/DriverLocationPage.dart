import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DriverLocationPage extends StatefulWidget {
  const DriverLocationPage({Key? key}) : super(key: key); // ✅ const constructor

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
  Timer? _timer;
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
    startIcon = await _loadIcon('assets/icons/start.png', BitmapDescriptor.hueGreen);
    endIcon = await _loadIcon('assets/icons/end.png', BitmapDescriptor.hueRed);
    stopIcon = await _loadIcon('assets/icons/stop.png', BitmapDescriptor.hueYellow);
    busIcon = await _loadIcon('assets/icons/bus.png', BitmapDescriptor.hueOrange);
  }

  Future<BitmapDescriptor> _loadIcon(String path, double fallbackHue) async {
    try {
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(18, 18)),
        path,
      );
    } catch (_) {
      return BitmapDescriptor.defaultMarkerWithHue(fallbackHue);
    }
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

  Future<void> startTracking() async {
    if (selectedRouteSummary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a school and route first!')),
      );
      return;
    }

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
        infoWindow: const InfoWindow(title: 'Start Point'),
      ));
    }

    final endGeo = fullRoute?['end']?['location'];
    if (endGeo is GeoPoint) {
      end = LatLng(endGeo.latitude, endGeo.longitude);
      markers.add(Marker(
        markerId: const MarkerId('end'),
        position: end!,
        icon: endIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: const InfoWindow(title: 'End Point'),
      ));
    }

    stopPoints.clear();
    for (final stop in fullRoute?['stops'] ?? []) {
      final loc = stop['location'];
      if (loc is GeoPoint) {
        final stopPoint = LatLng(loc.latitude, loc.longitude);
        stopPoints.add({
          'point': stopPoint,
          'name': stop['name'] ?? '',
        });
        markers.add(Marker(
          markerId: MarkerId(stop['name'] ?? ''),
          position: stopPoint,
          icon: stopIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: stop['name'] ?? ''),
        ));
      }
    }

    await drawRoute();

    try {
      final pos = await Geolocator.getCurrentPosition();
      busPosition = LatLng(pos.latitude, pos.longitude);
      markers.add(Marker(
        markerId: const MarkerId('bus'),
        position: busPosition!,
        icon: busIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: const InfoWindow(title: 'Bus Location'),
      ));

      mapController?.animateCamera(CameraUpdate.newLatLngZoom(busPosition!, 15));
    } catch (e) {
      debugPrint('Error getting current position: $e');
    }

    setState(() => rideStarted = true);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final pos = await Geolocator.getCurrentPosition();
        setState(() {
          busPosition = LatLng(pos.latitude, pos.longitude);
          markers.removeWhere((m) => m.markerId.value == 'bus');
          markers.add(Marker(
            markerId: const MarkerId('bus'),
            position: busPosition!,
            icon: busIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: const InfoWindow(title: 'Bus Location'),
          ));
        });

        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('busLocations').doc(user.uid).set({
            'lat': pos.latitude,
            'lng': pos.longitude,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint('Error updating location: $e');
      }
    });
  }

  Future<void> drawRoute() async {
    if (start == null || end == null) return;

    const apiKey = '5b3ce3597851110001cf6248c06c9e12119047b7a3b6369d5bd37ed9';
    final startCoord = '${start!.longitude},${start!.latitude}';
    final endCoord = '${end!.longitude},${end!.latitude}';

    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=$startCoord&end=$endCoord',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['features'][0]['geometry']['coordinates'] as List;
        final points = geometry.map<LatLng>((coord) {
          return LatLng(coord[1], coord[0]);
        }).toList();

        setState(() {
          polylines.clear();
          polylines.add(Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue,
            width: 5,
            points: points,
          ));
        });
      } else {
        debugPrint('OpenRoute error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to draw route: $e');
    }
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;

    setState(() {
      busPosition = null;
      rideStarted = false;
      start = null;
      end = null;
      stopPoints.clear();
      fullRoute = null;
      markers.clear();
      polylines.clear();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Location'),
        backgroundColor: const Color(0xFF77DDE7),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedSchool,
              hint: const Text('Select School'),
              items: schools.map((s) {
                final name = s['name'] ?? 'Unnamed';
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(name),
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
                  markers.clear();
                  polylines.clear();
                });
                prepareRouteSummaries();
              },
            ),
            if (selectedSchool != null)
              DropdownButton<Map<String, dynamic>>(
                value: routeSummaries.contains(selectedRouteSummary)
                    ? selectedRouteSummary
                    : null,
                hint: const Text('Select Route'),
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
                    markers.clear();
                    polylines.clear();
                  });
                },
              ),
            const SizedBox(height: 20),
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
                  onMapCreated: (controller) {
                    mapController = controller;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
