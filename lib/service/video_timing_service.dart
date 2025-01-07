// ignore_for_file: avoid_print, unused_element, unused_import, prefer_const_constructors

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:video_streaming/service/common_service.dart';

class VideoTimingService {

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final storage = FlutterSecureStorage();

  static Future<void> handleVideoCompletion(String? answerTime, int videoTime, String? disposition,
      String? videoName, String? masterUserId, String? jobName, String? campaignName, String? retryNumber) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    String? registeredMobNo = prefs.getString('mobile_number');
    final apiEndPoint = Uri.parse("");
    String? jwtToken = await storage.read(key: 'jwt_token');
    String? masterUserId = await storage.read(key: 'masterUserId');
    String? jobName = await storage.read(key: 'jobName');
    String? campaignName = await storage.read(key: 'campaignName');
    String? retryNumber = await storage.read(key: 'retryNumber');

    print("handleVideoCompletion() is called");

    try {
      final response = await http.post(
        apiEndPoint,
        headers: {
          'Authorization': 'winw $jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'answerTime': answerTime,
          'billableSeconds': videoTime,
          'disposition': disposition,
          'lastData': videoName,
          'targetNo': registeredMobNo,
          'masterUserId' : masterUserId,
          'jobName' : jobName,
          'campaignName' : campaignName,
          'retryNo' : retryNumber,
          'src' : "videoCall",
        }),
      );
      if (response.statusCode == 200){
        await prefs.reload();
        prefs.remove('video_name');
        String? videoNaME = prefs.getString('video_name');
        print("After removing ur video Name is : - $videoNaME");
        SystemNavigator.pop();
      } else {
        await prefs.reload();
        prefs.remove('video_name');
        SystemNavigator.pop();
      }
    } catch (e) {
      await prefs.reload();
      prefs.remove('video_name');
      SystemNavigator.pop();
    }
  }

  static Future<void> logToFireStore(String? answerTime, int videoTime, String? disposition, String? videoName, String? registeredMobNo, String jwtToken) async {
    try {
  await _firestore.collection("CDR").add({
    "answerTime" : answerTime,
    "videoTime" : videoTime,
    "disposition" : disposition,
    "videoName" : videoName,
    "jwtToken" : jwtToken,
  });
} on Exception catch (e) {
  print('Error logging to Firestore: $e');
}
  }

  static Future<void> logMasterUserDetails(String? userName,String? password, String jwtToken) async {
    try {
  await _firestore.collection("MasterUserInfo").add({
    "userName" : userName,
    "password" : password,
    "jwtToken" : jwtToken
  });
} on Exception catch (e) {
  print('Error logging to Firestore: $e');
}
  }

  static Future<void> logMasterUserDetailsAndResponseCode(String? userName,String? password, dynamic responseCode, String jwtToken) async {
    try {
  await _firestore.collection("MasterUserInfoError").add({
    "userName" : userName,
    "password" : password,
    "responseCode" : responseCode,
    "jwtToken" : jwtToken
  });
} on Exception catch (e) {
  print('Error logging to Firestore: $e');
}
  }
}
