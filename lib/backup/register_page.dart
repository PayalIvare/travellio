import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  String? _verificationId; // for mobile
  ConfirmationResult? _webConfirmationResult; // for web

  RecaptchaVerifier? _recaptchaVerifier; // ✅ make nullable for clarity

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _recaptchaVerifier = RecaptchaVerifier(
        auth: FirebaseAuthPlatform.instance, // ✅ CORRECT fix!
        container: 'recaptcha',
        size: RecaptchaVerifierSize.normal,
        theme: RecaptchaVerifierTheme.light,
      );
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendOTP() async {
    String phone = _phoneController.text.trim();

    if (!phone.startsWith('+')) {
      _showSnack('Phone must include country code, e.g. +91...');
      return;
    }

    try {
      if (kIsWeb) {
        _webConfirmationResult = await _auth.signInWithPhoneNumber(
          phone,
          _recaptchaVerifier,
        );
        setState(() => _otpSent = true);
        _showSnack('OTP sent to $phone');
      } else {
        await _auth.verifyPhoneNumber(
          phoneNumber: phone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _auth.signInWithCredential(credential);
            _showSnack('Phone automatically verified!');
          },
          verificationFailed: (FirebaseAuthException e) {
            _showSnack('Verification failed: ${e.message}');
          },
          codeSent: (String verificationId, int? resendToken) {
            setState(() {
              _verificationId = verificationId;
              _otpSent = true;
            });
            _showSnack('OTP sent to $phone');
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
        );
      }
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  Future<void> _verifyOTPAndRegister() async {
    String otp = _otpController.text.trim();
    String name = _nameController.text.trim();

    try {
      if (kIsWeb) {
        await _webConfirmationResult!.confirm(otp);
      } else {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: otp,
        );
        await _auth.signInWithCredential(credential);
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('travellerName', name);

      _showSnack('Registered & Phone Verified!');
      Navigator.pop(context);
    } catch (e) {
      _showSnack('Invalid OTP: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Color turquoise = const Color(0xFF77DDE7);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: turquoise,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner Image
            Container(
              width: double.infinity,
              height: 200,
              child: Image.asset('assets/bus_image.jpg', fit: BoxFit.cover),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: turquoise,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 10),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone (+countrycode)',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter phone number' : null,
                    ),

                    const SizedBox(height: 10),

                    // OTP field if sent
                    if (_otpSent)
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Enter OTP',
                          prefixIcon: Icon(Icons.verified),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Button
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (_otpSent) {
                            _verifyOTPAndRegister();
                          } else {
                            _sendOTP();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_otpSent ? 'Verify OTP' : 'Send OTP'),
                    ),

                    // 🟢 Required for web reCAPTCHA
                    if (kIsWeb) const SizedBox(height: 20),
                    if (kIsWeb)
                      Container(
                        alignment: Alignment.center,
                        child: const Text('Below: reCAPTCHA'),
                      ),
                    if (kIsWeb)
                      Container(
                        width: double.infinity,
                        height: 100,
                        child: const HtmlElementView(viewType: 'recaptcha'),
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
