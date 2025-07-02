import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'login_page.dart';
import 'register_page.dart';
import 'firebase_options.dart';
import 'LiveLocationPage.dart'; // live location screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        '/live-location': (context) => LiveLocationPage(),
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
              const SizedBox(height: 80),
              Image.asset(
                'assets/logo.png', // ✅ Make sure this path is correct and declared in pubspec.yaml
                height: 200,
              ),
              const SizedBox(height: 8),
              const Text(
                'Travel Anywhere, Anytime',
                style: TextStyle(
                  color: Color.fromARGB(179, 5, 3, 150),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
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
