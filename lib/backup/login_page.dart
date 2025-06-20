import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'operator_dashboard.dart';
import 'traveller_dashboard.dart';
import 'driver_dashboard.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedUserType = 'Traveller'; // default

  @override
  Widget build(BuildContext context) {
    Color turquoise = Color(0xFF77DDE7);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Login'),
        backgroundColor: turquoise,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 200,
              child: Image.asset(
                'assets/bus_image.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: turquoise,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter email' : null,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter password' : null,
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedUserType,
                      decoration: InputDecoration(
                        labelText: 'Select User Type',
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: ['Traveller', 'Driver', 'Operator']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUserType = value!;
                        });
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          String email = _emailController.text.trim();
                          String password = _passwordController.text.trim();
                          String userType = _selectedUserType;

                          // ✅ Save email to SharedPreferences
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('loggedInEmail', email);

                          if (userType == 'Operator' &&
                              email == 'operator@gmail.com' &&
                              password == '123456') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => OperatorDashboard()),
                            );
                          } else if (userType == 'Traveller') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => TravellerDashboard()),
                            );
                          } else if (userType == 'Driver') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => DriverDashboard()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Invalid credentials or user type.')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Login'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
