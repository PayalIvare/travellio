import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class LiveLocationPage extends StatefulWidget {
  @override
  _LiveLocationPageState createState() => _LiveLocationPageState();
}

class _LiveLocationPageState extends State<LiveLocationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LatLng? busPosition;
  LatLng? start;
  LatLng? end;
  List<LatLng> stopPoints = [];
  List<LatLng> roadPath = [];

  Timer? _timer;

  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await fetchDriverRouteAndTrack();
      await fetchLiveLocation();
      _timer = Timer.periodic(Duration(seconds: 5), (_) => fetchLiveLocation());
    } catch (e) {
      print("Initialization error: $e");
      setState(() => hasError = true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchDriverRouteAndTrack() async {
    var snapshot = await _firestore.collection('assignedDrivers').get();
    if (snapshot.docs.isEmpty) {
      throw Exception("No assigned drivers found.");
    }

    var doc = snapshot.docs.first.data();
    var schoolList = doc['schools'] as List?;
    if (schoolList == null || schoolList.isEmpty) {
      throw Exception("No schools in driver data.");
    }

    var school = schoolList.first;
    var routeList = school['routes'] as List?;
    if (routeList == null || routeList.isEmpty) {
      throw Exception("No routes in school.");
    }

    var route = routeList.first;

    start = _geoToLatLng(route['start']?['location']);
    end = _geoToLatLng(route['end']?['location']);

    stopPoints = [];
    if (route['stops'] != null) {
      for (var stop in route['stops']) {
        var loc = _geoToLatLng(stop['location']);
        if (loc != null) stopPoints.add(loc);
      }
    }

    if (start == null || end == null) {
      throw Exception("Start or End point is null.");
    }

    List<LatLng> allPoints = [start!, ...stopPoints, end!];
    await fetchORSPath(allPoints);
  }

  LatLng? _geoToLatLng(dynamic geo) {
    if (geo == null) return null;
    return LatLng(geo.latitude, geo.longitude);
  }

  Future<void> fetchORSPath(List<LatLng> points) async {
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
      throw Exception("ORS failed: ${response.body}");
    }
  }

  Future<void> fetchLiveLocation() async {
    var live = await _firestore.collection('liveLocations').get();
    if (live.docs.isNotEmpty) {
      var data = live.docs.first.data();
      setState(() {
        busPosition = LatLng(data['lat'], data['lng']);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildStatus("Loading...");
    if (hasError) return _buildStatus("Error loading data.");

    if (start == null || end == null || busPosition == null) {
      return _buildStatus("Incomplete map data.");
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Bus Location'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: FlutterMap(
        options: MapOptions(
          center: busPosition,
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
              ...stopPoints.map((s) => Marker(
                    point: s,
                    width: 20,
                    height: 20,
                    child: Icon(Icons.location_on, size: 20, color: Colors.yellow),
                  )),
              if (busPosition != null)
                Marker(
                  point: busPosition!,
                  width: 40,
                  height: 40,
                  child: Icon(Icons.directions_bus, color: Colors.orange, size: 30),
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
      ),
    );
  }

  Widget _buildStatus(String text) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Bus Location'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Center(child: Text(text)),
    );
  }
}
