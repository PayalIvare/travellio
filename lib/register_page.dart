import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedUserType = 'Traveller';

  @override
  Widget build(BuildContext context) {
    Color turquoise = Color(0xFF77DDE7);
    Color white = Colors.white;

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: Text('Register'),
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
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Please enter name' : null,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter mobile number';
                        } else if (value.length != 10) {
                          return 'Mobile number must be 10 digits';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Please enter email' : null,
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
                          value == null || value.isEmpty ? 'Please enter password' : null,
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedUserType,
                      decoration: InputDecoration(
                        labelText: 'Select User Type',
                        prefixIcon: Icon(Icons.account_circle),
                      ),
                      items: ['Traveller', 'Driver', 'Operator'].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
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
                          String name = _nameController.text.trim();
                          String mobile = _mobileController.text.trim();
                          String email = _emailController.text.trim();
                          String password = _passwordController.text.trim();
                          String userType = _selectedUserType;

                          try {
                            // ✅ Create user in Firebase Auth
                            UserCredential userCredential =
                                await FirebaseAuth.instance
                                    .createUserWithEmailAndPassword(
                              email: email,
                              password: password,
                            );

                            String uid = userCredential.user!.uid;

                            // ✅ Save additional data in Firestore
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .set({
                              'name': name,
                              'email': email,
                              'phone': mobile,
                              'role': userType,
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Registered Successfully')),
                            );

                            Navigator.pop(context);
                          } on FirebaseAuthException catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Registration failed: ${e.message}')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Register'),
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
