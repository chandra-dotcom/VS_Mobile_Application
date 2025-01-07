
// ignore_for_file: prefer_const_constructors

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:video_streaming/firebase_options.dart';
import 'package:video_streaming/service/firebase_messaging_service.dart';
import 'package:video_streaming/splash_screen.dart';
import 'package:video_streaming/views/home_screen.dart';
import 'package:video_streaming/views/incoming_call_screen.dart';
import 'package:video_streaming/views/play_video_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessagingService messagingService = FirebaseMessagingService();
  await messagingService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Video Streaming',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home_screen': (context) => HomeScreen(),
        '/incoming_call_screen': (context) {
          final videoName = ModalRoute.of(context)?.settings.arguments as String?;
        return IncomingCallScreen(videoName: videoName);
        },
        '/play_video_screen': (context) {
          final videoName = ModalRoute.of(context)?.settings.arguments as String?;
        return PlayVideoScreen(videoName: videoName);
        },
      },
    );
  }
}