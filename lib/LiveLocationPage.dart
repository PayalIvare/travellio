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

  LatLng? start, end, busPosition;
  List<LatLng> stopPoints = [];
  List<LatLng> roadPath = [];
  Timer? _timer;

  BitmapDescriptor? startIcon, endIcon, stopIcon, busIcon;

  @override
  void initState() {
    super.initState();
    _loadIcons();
    fetchRouteAndStartTracking();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchLiveLocation());
  }

  Future<void> _loadIcons() async {
    startIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(18, 18)), 'assets/icons/start.png');
    endIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(18, 18)), 'assets/icons/end.png');
    stopIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(18, 18)), 'assets/icons/stop.png');
    busIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(20, 20)), 'assets/icons/bus.png');
  }

  Future<void> fetchRouteAndStartTracking() async {
    try {
      final snapshot = await _firestore.collection('assignedDrivers').get();
      if (snapshot.docs.isEmpty) return;

      final doc = snapshot.docs.first.data();
      final schoolList = doc['schools'] as List?;
      if (schoolList == null || schoolList.isEmpty) return;

      final school = schoolList.first;
      final routeList = school['routes'] as List?;
      if (routeList == null || routeList.isEmpty) return;

      final route = routeList.first;

      if (route['start']?['location'] != null) {
        final startGeo = route['start']['location'];
        start = LatLng(startGeo.latitude, startGeo.longitude);
      }

      if (route['end']?['location'] != null) {
        final endGeo = route['end']['location'];
        end = LatLng(endGeo.latitude, endGeo.longitude);
      }

      stopPoints.clear();
      if (route['stops'] != null) {
        for (final stop in route['stops']) {
          final loc = stop['location'];
          if (loc != null) {
            stopPoints.add(LatLng(loc.latitude, loc.longitude));
          }
        }
      }

      if (start != null && end != null) {
        final allPoints = [start!, ...stopPoints, end!];
        await fetchORSPath(allPoints);
      }
    } catch (e) {
      debugPrint("Route fetch error: $e");
    }
  }

  Future<void> fetchORSPath(List<LatLng> points) async {
    try {
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
        final coords = data['features'][0]['geometry']['coordinates'] as List;
        setState(() {
          roadPath = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
        });
      } else {
        debugPrint("ORS failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("ORS error: $e");
    }
  }

  Future<void> fetchLiveLocation() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final doc = await _firestore.collection('busLocations').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['lat'] != null && data['lng'] != null) {
          setState(() {
            busPosition = LatLng(data['lat'], data['lng']);
          });
        }
      }
    } catch (e) {
      debugPrint("Live location error: $e");
    }
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
        title: const Text('Live Bus Location'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: (start != null && end != null && busPosition != null)
          ? GoogleMap(
              initialCameraPosition: CameraPosition(
                target: busPosition!,
                zoom: 15,
              ),
              markers: {
                Marker(markerId: const MarkerId('start'), position: start!, icon: startIcon!),
                Marker(markerId: const MarkerId('end'), position: end!, icon: endIcon!),
                Marker(markerId: const MarkerId('bus'), position: busPosition!, icon: busIcon!),
                ...stopPoints.map(
                  (s) => Marker(
                    markerId: MarkerId('stop-${s.latitude},${s.longitude}'),
                    position: s,
                    icon: stopIcon!,
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
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
