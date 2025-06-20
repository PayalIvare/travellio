import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'login_page.dart';
import 'register_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Fix for duplicate initialization:
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travellio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF77DDE7),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF77DDE7),
          foregroundColor: Colors.black,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 15),
            textStyle: TextStyle(fontSize: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      home: HomePage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/traveller': (context) => TravellerPage(),
        '/driver': (context) => DriverPage(),
        '/operator': (context) => OperatorPage(),
      },
    );
  }
}




class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double buttonWidth = MediaQuery.of(context).size.width > 600 ? 250 : double.infinity;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF77DDE7), Color(0xFF4CC9F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ✅ Add the image here at the top
              // Container(
              //   width: double.infinity,
              //   height: 200,
              //   child: Image.asset(
              //     'assets/bus_image.jpg',
              //     fit: BoxFit.cover,
              //   ),
              // ),

              SizedBox(height: 30),
              Text(
                'Travellio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Travel Anywhere, Anytime',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    SizedBox(
                      width: buttonWidth,
                      child: ElevatedButton(
                        child: Text('Register'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: buttonWidth,
                      child: ElevatedButton(
                        child: Text('Login'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}


class TravellerPage extends StatelessWidget {
  final LatLng busLocation = LatLng(37.42796133580664, -122.085749655962);
  final List<LatLng> stops = [
    LatLng(37.4275, -122.0850),
    LatLng(37.4280, -122.0855),
    LatLng(37.4285, -122.0860),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Traveller Dashboard")),
      body: Column(
        children: [
          // Map (3/4)
          Expanded(
            flex: 3,
            child: FlutterMap(
              options: MapOptions(
                center: busLocation,
                zoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
  width: 40,
  height: 40,
  point: busLocation,
  child: Icon(Icons.directions_bus, color: Colors.red, size: 30),
),
...stops.map((s) => Marker(
  width: 40,
  height: 40,
  point: LatLng(37.427, -122.085),
  child: Icon(Icons.directions_bus, size: 30, color: Colors.red),
)),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [stops.first, ...stops.skip(1)],
                      color: Colors.blue,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bottom line (1/4)
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[200],
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, color: Colors.green),
                      Text("Start"),
                    ],
                  ),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(height: 4, color: Colors.blue),
                        Positioned(
                          left: MediaQuery.of(context).size.width / 4,
                          child: Icon(Icons.directions_bus, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flag, color: Colors.red),
                      Text("End"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DriverPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Driver Dashboard")),
      body: Center(
        child: Text(
          "Driver location tracking & controls will appear here.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class OperatorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Operator Dashboard")),
      body: Center(child: Text("Welcome Operator")),
    );
  }
}
