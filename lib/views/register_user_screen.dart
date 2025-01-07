// ignore_for_file: prefer_const_constructors, sort_child_properties_last, use_build_context_synchronously, avoid_print

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_streaming/service/common_service.dart';
import 'package:video_streaming/splash_screen.dart';
import 'package:video_streaming/views/home_screen.dart';
import 'package:http/http.dart' as http;

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {

  final CommonService commonService = CommonService();
  TextEditingController mobileNumberController = TextEditingController();
  String? deviceToken;
  bool isRegistering = false;
  final storage = FlutterSecureStorage();
  
  //called when user taps on Register Button
  void registerUser() async {
    String mobileNumber = mobileNumberController.text.trim();
    if(!RegExp(r'^[0-9]+$').hasMatch(mobileNumber)) {
      commonService.showSnackBarMessage(context, "Please enter only digits", Colors.red.shade900);
    } else if(mobileNumber.length != 10) {
      commonService.showSnackBarMessage(context, "Mobile number should be 10 digits", Colors.red.shade900);
    } else {
      await registerUserAPIcall();
    }
  }

  //API call to generate JWT token
  Future<void> generateToken() async {
    final apiEndPoint = Uri.parse("");
    try{
      final response = await http.post(
        apiEndPoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': "", 'password': ""}),
      );
      if(response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String token = responseData["result"]["token"];
        storage.write(key: "jwt_token", value: token);
      } else {
        //
      }
      
    }catch(e) {
        //
    }
  }

  //API call to register the user
  Future<void> registerUserAPIcall() async {
    setState(() {
      isRegistering = true;
    });
    await _getDevicetoken();
    var sharedPref = await SharedPreferences.getInstance();
    final apiEndPoint = Uri.parse('');
    try {
      final response = await http.post(apiEndPoint);
      if (response.statusCode == 200) {
        await generateToken();
        setState(() {
          isRegistering = false;
        });
      final responseData = json.decode(response.body);
      commonService.showSnackBarMessage(context, responseData['message'], Colors.green.shade800, duration: Duration(seconds: 3));
      sharedPref.setString('mobile_number', mobileNumberController.text);
      sharedPref.setBool(SplashScreenState.KEYREGISTER, true);
      Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
      } else {
        setState(() {
          isRegistering = false;
        });
        print("API calling failed for registerUserAPIcall() ${response.statusCode}");
      }
    } catch (e) {
      isRegistering = false;
      print("Exception caught for registerUserAPIcall():- $e");
    }
  }

  //Function to get Device-Token
  Future<void> _getDevicetoken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      setState(() {
        deviceToken = token;
      });
    } catch (e) {
      //
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Background Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade800, Colors.blue.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.1),
                      // Registration Animation
                      Lottie.asset(
                        "assets/animation_lnyjeiok.json",
                        height: constraints.maxHeight * 0.3,
                        alignment: Alignment.center,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 20),
                      // Title
                      Text(
                        "Welcome to Registration",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Please register yourself to get the video call",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 30),
                      // Mobile Number Field
                      TextFormField(
                        controller: mobileNumberController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Mobile Number',
                          labelStyle: TextStyle(color: Colors.blue.shade900),
                          prefixIcon: Icon(Icons.perm_contact_cal,
                              color: Colors.blue.shade900),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.blue.shade900, width: 2),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Register Button
                      ElevatedButton(
                        onPressed: () {
                          registerUser();
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: isRegistering
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Register",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),                        
                          backgroundColor: Colors.blue.shade900,
                          elevation: 5,
                          shadowColor: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

}
