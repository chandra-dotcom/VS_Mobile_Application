// ignore_for_file: prefer_const_constructors, avoid_print, use_build_context_synchronously, prefer_const_literals_to_create_immutables

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_streaming/main.dart';
import 'package:video_streaming/service/common_service.dart';
import 'package:video_streaming/service/get_serverkey_service.dart';
import 'package:video_streaming/service/notification_service.dart';
import 'package:video_streaming/splash_screen.dart';
import 'package:video_streaming/views/register_user_screen.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  NotificationService notificationService = NotificationService();
  GetServerKey getServerKey = GetServerKey();
  final CommonService commonService = CommonService();

  String? savedVideoName;
  String? deviceToken;
  String? accessToken;
  static const platform = MethodChannel('com.vs.batteryOptimization');
  final storage = FlutterSecureStorage();
  String? token;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  String? registeredMobNo;
  bool isUnsubscribing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getVideoName();
    notificationService.requestNotificationPermission();
    _fetchMobileNumber();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    //this line is commented because without this notiifcation is bypassing the doze mode
    // checkAndRequestBatteryOptimization();
  }

  Future<void> _fetchMobileNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      registeredMobNo = prefs.getString('mobile_number') ?? "Unknown Number";
    });
  }

  Future<void> _getAccessToken() async {
    String token = await getServerKey.getServerKey();
    setState(() {
      accessToken = token;
    });
    print(accessToken);
  }

  //Calls the native mathod from (MainActivity.java file)
  Future<void> checkAndRequestBatteryOptimization() async {
    try {
      bool isExempt = await platform.invokeMethod('isBatteryOptimized') ?? true;

      if (!isExempt) {
        await platform.invokeMethod('requestBatteryOptimization');
      } else {
        print('Battery optimization is already disabled for this app.');
      }
    } catch (e) {
      print("Error checking or requesting battery optimization: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      getVideoName();
    }
  }

  //To get the video from shared-prefrences when app will be resumed
  void getVideoName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    setState(() {
      savedVideoName = prefs.getString('video_name');
      if (savedVideoName != null) {
        navigatorKey.currentState
            ?.pushNamed('/play_video_screen', arguments: savedVideoName);
      }
    });
    print("Your video name is : - $savedVideoName");
  }

  Future<void> unsubscribeUser() async {
    setState(() {
      isUnsubscribing = true;
    });
    final apiEndPoint = Uri.parse("");
    try {
      final response = await http.post(apiEndPoint);
      if (response.statusCode == 200) {
        setState(() {
          isUnsubscribing = false;
        });
        final responseData = json.decode(response.body);
        commonService.showSnackBarMessage(
            context, responseData["message"], Colors.green.shade800);
        var sharedPref = await SharedPreferences.getInstance();
        sharedPref.setBool(SplashScreenState.KEYREGISTER, false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RegisterUserScreen()),
        );
      } else {
        setState(() {
          isUnsubscribing = false;
        });
      }
    } catch (e) {
      setState(() {
        isUnsubscribing = false;
      });
    }
  }
void showConfirmationDialog() {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.7), // Semi-transparent background
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.4), // Slightly transparent white background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // Rounded corners
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        title: Text(
          'Confirmation',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Really want to unsubscribe?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text(
                    'NO',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    unsubscribeUser(); // Perform your functionality
                  },
                  child: Text(
                    'YES',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Icon(
          Icons.live_tv, // Stream icon
          color: Colors.white,
          size: 28.0, // Adjust size as needed
        ),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade500,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeInAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "🎉 Congratulations! 🎉",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "You are successfully subscribed!",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Registered mobile number is:",
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      SizedBox(height: 10),
                      Text(
                        registeredMobNo ?? "",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.blue.shade800,
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () {
                      _getAccessToken();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.android, // Android icon
                          color: Colors.green.shade300,
                          size: 20, // Adjust the icon size as needed
                        ),
                        SizedBox(
                            width: 10), // Add space between the icon and text
                        Text(
                          "Version: 1.0.0",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () {
                      showConfirmationDialog();
                    },
                    child: isUnsubscribing
                        ? SizedBox(
                            width: 18.0, // Adjust size
                            height: 18.0,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.group_remove, // Android icon
                                color: Colors.white,
                                size: 20, // Adjust the icon size as needed
                              ),
                              SizedBox(
                                  width:
                                      10), // Add space between the icon and text
                              Text(
                                "Unsubscribe",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
