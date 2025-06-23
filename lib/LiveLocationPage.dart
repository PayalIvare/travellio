import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class LiveLocationPage extends StatefulWidget {
  const LiveLocationPage({Key? key}) : super(key: key); // ✅ const constructor

  @override
  State<LiveLocationPage> createState() => _LiveLocationPageState();
}

class _LiveLocationPageState extends State<LiveLocationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LatLng? busPosition;
  List<LatLng> stopPoints = [];
  LatLng? start;
  LatLng? end;
  List<LatLng> roadPath = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchDriverRouteAndTrack();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchLiveLocation());
  }

  Future<void> fetchDriverRouteAndTrack() async {
    try {
      final snapshot = await _firestore.collection('assignedDrivers').get();
      if (snapshot.docs.isEmpty) {
        debugPrint("No assigned drivers found.");
        return;
      }

      final doc = snapshot.docs.first.data();
      final schoolList = doc['schools'] as List?;
      if (schoolList == null || schoolList.isEmpty) {
        debugPrint("No schools found in assigned driver.");
        return;
      }

      final school = schoolList.first;
      final routeList = school['routes'] as List?;
      if (routeList == null || routeList.isEmpty) {
        debugPrint("No routes found in school.");
        return;
      }

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
        debugPrint("Fetched ${stopPoints.length} stop(s)");
      }

      if (start != null && end != null) {
        final allPoints = [start!, ...stopPoints, end!];
        await fetchORSPath(allPoints);
      } else {
        debugPrint("Start or End is null.");
      }
    } catch (e) {
      debugPrint("Error fetching route: $e");
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
          debugPrint("Fetched road path with ${roadPath.length} points");
        });
      } else {
        debugPrint("ORS API failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching ORS path: $e");
    }
  }

  Future<void> fetchLiveLocation() async {
    try {
      final live = await _firestore.collection('liveLocations').get();
      if (live.docs.isNotEmpty) {
        final data = live.docs.first.data();
        setState(() {
          busPosition = LatLng(data['lat'], data['lng']);
        });
      }
    } catch (e) {
      debugPrint("Error fetching live location: $e");
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
          ? FlutterMap(
              options: MapOptions(
                center: busPosition,
                zoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: start!,
                      width: 30,
                      height: 30,
                      child: const Icon(Icons.flag, color: Colors.green),
                    ),
                    Marker(
                      point: end!,
                      width: 30,
                      height: 30,
                      child: const Icon(Icons.flag, color: Colors.red),
                    ),
                    ...stopPoints.map(
                      (s) => Marker(
                        point: s,
                        width: 20,
                        height: 20,
                        child: const Icon(Icons.location_on, size: 20, color: Colors.yellow),
                      ),
                    ),
                    Marker(
                      point: busPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.directions_bus, color: Colors.orange, size: 30),
                    ),
                  ],
                ),
                if (roadPath.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: roadPath,
                        strokeWidth: 4.0,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
