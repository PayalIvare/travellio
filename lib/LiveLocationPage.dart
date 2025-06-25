import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LiveLocationPage extends StatefulWidget {
  const LiveLocationPage({Key? key}) : super(key: key);

  @override
  State<LiveLocationPage> createState() => _LiveLocationPageState();
}

class _LiveLocationPageState extends State<LiveLocationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LatLng? busPosition;
  LatLng? start;
  LatLng? end;
  List<LatLng> stopPoints = [];
  List<LatLng> roadPath = [];
  Timer? _timer;
  bool isRideActive = true;

  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  BitmapDescriptor? startIcon;
  BitmapDescriptor? endIcon;
  BitmapDescriptor? stopIcon;
  BitmapDescriptor? busIcon;

  @override
  void initState() {
    super.initState();
    loadCustomIcons();
    fetchDriverRouteAndTrack();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchLiveLocation());
  }

  Future<void> loadCustomIcons() async {
    startIcon = await _loadIcon('assets/icons/start.png', BitmapDescriptor.hueGreen);
    endIcon = await _loadIcon('assets/icons/end.png', BitmapDescriptor.hueRed);
    stopIcon = await _loadIcon('assets/icons/stop.png', BitmapDescriptor.hueYellow);
    busIcon = await _loadIcon('assets/icons/bus.png', BitmapDescriptor.hueOrange);
  }

  Future<BitmapDescriptor> _loadIcon(String path, double fallbackHue) async {
    try {
      return await BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(18, 18)), path);
    } catch (_) {
      return BitmapDescriptor.defaultMarkerWithHue(fallbackHue);
    }
  }

  Future<void> fetchDriverRouteAndTrack() async {
    try {
      final snapshot = await _firestore.collection('assignedDrivers').get();
      if (snapshot.docs.isEmpty) return;

      final doc = snapshot.docs.first.data();
      final school = (doc['schools'] as List).first;
      final route = (school['routes'] as List).first;

      final startGeo = route['start']?['location'] as GeoPoint?;
      if (startGeo != null) {
        start = LatLng(startGeo.latitude, startGeo.longitude);
        markers.add(Marker(markerId: const MarkerId('start'), position: start!, icon: startIcon ?? BitmapDescriptor.defaultMarker));
      }

      final endGeo = route['end']?['location'] as GeoPoint?;
      if (endGeo != null) {
        end = LatLng(endGeo.latitude, endGeo.longitude);
        markers.add(Marker(markerId: const MarkerId('end'), position: end!, icon: endIcon ?? BitmapDescriptor.defaultMarker));
      }

      for (final stop in route['stops'] ?? []) {
        final loc = stop['location'] as GeoPoint?;
        if (loc != null) {
          final point = LatLng(loc.latitude, loc.longitude);
          stopPoints.add(point);
          markers.add(Marker(markerId: MarkerId(stop['name']), position: point, icon: stopIcon ?? BitmapDescriptor.defaultMarker));
        }
      }

      final points = [start!, ...stopPoints, end!];
      await fetchORSPath(points);
    } catch (e) {
      debugPrint("Error: $e");
    }
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
      final coords = data['features'][0]['geometry']['coordinates'] as List;
      setState(() {
        roadPath = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
        polylines.add(Polyline(
          polylineId: const PolylineId("route"),
          color: Colors.blueAccent,
          width: 4,
          points: roadPath,
        ));
      });
    }
  }

  Future<void> fetchLiveLocation() async {
    final snapshot = await _firestore.collection('busLocations').get();
    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      final active = data['active'] ?? false;

      if (!active) {
        setState(() => isRideActive = false);
        _timer?.cancel();
        return;
      }

      final lat = data['lat'];
      final lng = data['lng'];
      if (lat != null && lng != null) {
        final updatedPosition = LatLng(lat, lng);
        setState(() {
          busPosition = updatedPosition;
          markers.removeWhere((m) => m.markerId.value == 'bus');
          markers.add(Marker(
            markerId: const MarkerId('bus'),
            position: updatedPosition,
            icon: busIcon ?? BitmapDescriptor.defaultMarker,
          ));
        });

        mapController?.animateCamera(CameraUpdate.newLatLng(updatedPosition));
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Bus Location"),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: (!isRideActive)
          ? const Center(child: Text("Ride has ended."))
          : (start != null && end != null && busPosition != null)
              ? GoogleMap(
                  initialCameraPosition: CameraPosition(target: busPosition!, zoom: 15),
                  markers: markers,
                  polylines: polylines,
                  onMapCreated: (controller) => mapController = controller,
                  myLocationEnabled: true,
                )
              : const Center(child: CircularProgressIndicator()),
    );
  }
}
