// ignore_for_file: prefer_const_constructors, avoid_print

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:video_streaming/firebase_options.dart';
import 'package:video_streaming/main.dart';
import 'package:video_streaming/service/video_timing_service.dart';

class FirebaseMessagingService {
  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final storage = FlutterSecureStorage();

  Future<void> init() async {

    // await _firebaseMessaging.requestPermission(); //notification permission in iOS and macOS devices.

    //Handel background message
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    //Handel foreground message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      String videoName = message.data['videoFileName'];
      await storage.write(key: 'masterUserId', value: message.data['masterUserId']);
      await storage.write(key: 'jobName', value: message.data['jobName']);   
      await storage.write(key: 'campaignName', value: message.data['campaignName']);
      await storage.write(key: 'retryNumber', value: message.data['retryNumber']);
      navigatorKey.currentState
          ?.pushNamed('/incoming_call_screen', arguments: videoName);
    });

    //Handel when app is opened from a background state/terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      String videoName = message.data['videoFileName'];
      String masterUserId = message.data['masterUserId'];
      String jobName = message.data['jobName'];
      String campaignName = message.data['campaignName'];
      String retryNumber = message.data['retryNumber'];
      await storage.write(key: 'masterUserId', value: message.data['masterUserId']);
      await storage.write(key: 'jobName', value: message.data['jobName']);
      await storage.write(key: 'campaignName', value: message.data['campaignName']);
      await storage.write(key: 'retryNumber', value: message.data['retryNumber']);
      _handleIncomingNotification(videoName, masterUserId, jobName, campaignName, retryNumber);
    });
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    String videoName = message.data['videoFileName'];
    String masterUserId = message.data['masterUserId'];
    String jobName = message.data['jobName'];
    String campaignName = message.data['campaignName'];
    String retryNumber = message.data['retryNumber'];
    await storage.write(key: 'masterUserId', value: message.data['masterUserId']);
    await storage.write(key: 'jobName', value: message.data['jobName']);
    await storage.write(key: 'campaignName', value: message.data['campaignName']);
    await storage.write(key: 'retryNumber', value: message.data['retryNumber']);
    _handleIncomingNotification(videoName, masterUserId, jobName, campaignName, retryNumber);
  }

  static void _handleIncomingNotification(String videoName, String masterUserId, String jobName, String campaignName, String retryNumber) {
    //call the function to show the Incoming call UI
    showIncomingCall(videoName, masterUserId, jobName, campaignName, retryNumber);
  }

  static Future<void> showIncomingCall(String videoName, String masterUserId, String jobName, String campaignName, String retryNumber) async {
    final Uuid uuid = Uuid();
    final String currentUuid = uuid.v4(); // Generate unique UUID for the call
    CallKitParams callKitParams = CallKitParams(
      id: currentUuid,
      nameCaller: 'John Snow',
      appName: 'Callkit',
      avatar: 'https://i.pravatar.cc/100',
      handle: '+917050657182',
      type: 1,
      textAccept: 'Accept',
      textDecline: 'Decline',
      duration: 30000,
      extra: <String, dynamic>{'videoName': videoName},
    );

    //show the Incoming Call UI
    await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);

    //Listen for the CallKit events
    FlutterCallkitIncoming.onEvent.listen((event) async {
      switch (event?.event) {
        case Event.actionCallAccept:
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('video_name', videoName);
          break;
        case Event.actionCallDecline:
          VideoTimingService.handleVideoCompletion(null, 0, "BUSY", videoName, masterUserId, jobName, campaignName, retryNumber);
          break;
        case Event.actionCallTimeout:
          VideoTimingService.handleVideoCompletion(null, 0, "NO ANSWER", videoName, masterUserId, jobName, campaignName, retryNumber);
          break;
        case Event.actionCallCallback:
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('video_name', videoName);
          break;
        default:
          break;
      }
    });
  }
}
