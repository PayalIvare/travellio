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
  List<LatLng> stopPoints = [];
  LatLng? start;
  LatLng? end;
  List<LatLng> roadPath = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchDriverRouteAndTrack();
    _timer = Timer.periodic(Duration(seconds: 5), (_) => fetchLiveLocation());
  }

  Future<void> fetchDriverRouteAndTrack() async {
    try {
      var snapshot = await _firestore.collection('assignedDrivers').get();
      if (snapshot.docs.isEmpty) {
        print("No assigned drivers found.");
        return;
      }

      var doc = snapshot.docs.first.data();
      var schoolList = doc['schools'] as List?;
      if (schoolList == null || schoolList.isEmpty) {
        print("No schools found in assigned driver.");
        return;
      }

      var school = schoolList.first;
      var routeList = school['routes'] as List?;
      if (routeList == null || routeList.isEmpty) {
        print("No routes found in school.");
        return;
      }

      var route = routeList.first;

      if (route['start'] != null && route['start']['location'] != null) {
        var startGeo = route['start']['location'];
        start = LatLng(startGeo.latitude, startGeo.longitude);
      }

      if (route['end'] != null && route['end']['location'] != null) {
        var endGeo = route['end']['location'];
        end = LatLng(endGeo.latitude, endGeo.longitude);
      }

      stopPoints.clear();
      if (route['stops'] != null) {
        for (var stop in route['stops']) {
          if (stop['location'] != null) {
            var loc = stop['location'];
            stopPoints.add(LatLng(loc.latitude, loc.longitude));
          }
        }
        print("Fetched ${stopPoints.length} stop(s)");
      }

      if (start != null && end != null) {
        List<LatLng> allPoints = [start!, ...stopPoints, end!];
        await fetchORSPath(allPoints);
      } else {
        print("Start or End is null.");
      }
    } catch (e) {
      print("Error fetching route: $e");
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
        final coords = data['features'][0]['geometry']['coordinates'];
        setState(() {
          roadPath = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
          print("Fetched road path with ${roadPath.length} points");
        });
      } else {
        print("ORS API failed: ${response.body}");
      }
    } catch (e) {
      print("Error fetching ORS path: $e");
    }
  }

  Future<void> fetchLiveLocation() async {
    try {
      var live = await _firestore.collection('liveLocations').get();
      if (live.docs.isNotEmpty) {
        var data = live.docs.first.data();
        setState(() {
          busPosition = LatLng(data['lat'], data['lng']);
        });
      }
    } catch (e) {
      print("Error fetching live location: $e");
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
        title: Text('Live Bus Location'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: start != null && end != null && busPosition != null
          ? FlutterMap(
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
                    Marker(
                      point: start!,
                      width: 30,
                      height: 30,
                      child: Icon(Icons.flag, color: Colors.green),
                    ),
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
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
