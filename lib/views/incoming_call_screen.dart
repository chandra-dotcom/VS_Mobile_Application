// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, avoid_print, use_key_in_widget_constructors, unnecessary_import, deprecated_member_use, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:video_streaming/main.dart';
import 'package:video_streaming/service/video_timing_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final String? videoName;

  IncomingCallScreen({super.key, this.videoName});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        VideoTimingService.handleVideoCompletion(null, 0, "BUSY", widget.videoName, null, null, null, null); //Exited from the app when user press android /app back-button in android
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade900],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Incoming Call Text
              Padding(
                padding: const EdgeInsets.only(top: 130.0),
                child: Text(
                  'Incoming Call...',
                  style: TextStyle(fontSize: 30, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              // Lottie Animation
              Expanded(
                child: Lottie.asset(
                  'assets/calling.json',
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Circular "Pick" button
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.green,
                    child: IconButton(
                      icon: Icon(Icons.call, color: Colors.white, size: 28),
                      onPressed: () async {
                        navigatorKey.currentState?.pushReplacementNamed(
                            '/play_video_screen',
                            arguments: widget.videoName);
                      },
                    ),
                  ),
                  // Circular "Cut" button
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.red,
                    child: IconButton(
                      icon: Icon(Icons.call_end, color: Colors.white, size: 28),
                      onPressed: () async {
                        VideoTimingService.handleVideoCompletion(null, 0, "BUSY", widget.videoName, null, null, null, null);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
