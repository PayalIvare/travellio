import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Your pages
import 'login_page.dart';
import 'register_page.dart';

// Dashboards
class TravellerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Traveller Dashboard")),
      body: Center(child: Text("Welcome Traveller")),
    );
  }
}

class DriverPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Driver Dashboard")),
      body: Center(child: Text("Welcome Driver")),
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travellio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF77DDE7), // turquoise blue
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF77DDE7),
          foregroundColor: Colors.black,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(fontSize: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      home: const HomePage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/traveller': (context) => TravellerPage(),
        '/driver': (context) => DriverPage(),
        '/operator': (context) => OperatorPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    double buttonWidth =
        MediaQuery.of(context).size.width > 600 ? 250 : double.infinity;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF77DDE7), Color(0xFF4CC9F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top image
              Image.asset(
                'assets/bus_image.jpg', // Make sure your asset is correct
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),

              const SizedBox(height: 20),

              // App Name
              const Text(
                'Travellio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Tagline
              const Text(
                'Travel Anywhere, Anytime',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 40),

              // Buttons directly on background
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    SizedBox(
                      width: buttonWidth,
                      child: ElevatedButton(
                        child: const Text('Register'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: buttonWidth,
                      child: ElevatedButton(
                        child: const Text('Login'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
