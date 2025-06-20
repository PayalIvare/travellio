import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double buttonWidth = MediaQuery.of(context).size.width > 600 ? 300 : double.infinity;

    return Scaffold(
      appBar: AppBar(title: Text('Welcome to Travel App')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton(
                  child: Text('Login'),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
                  },
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: buttonWidth,
                child: ElevatedButton(
                  child: Text('Register'),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterPage()));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
