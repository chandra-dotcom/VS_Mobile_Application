
// ignore_for_file: prefer_const_constructors, avoid_print

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class CommonService {
  static final storage = FlutterSecureStorage();
  static String jwtToken = "";
  //To show the Snackbar Message
  void showSnackBarMessage(BuildContext context, String message, Color color,
      {Duration duration = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: duration,
        behavior: SnackBarBehavior.fixed,
        backgroundColor: color,
      ),
    );
  }

  String getCurrentDateTime() {
    final DateTime now = DateTime.now();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
  }

  static Future<String> getJwtToken() async {

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
        jwtToken = token;
        return token;
      } else {
        //
      }
      
    }catch(e) {
        //
    }
    return "";
  }
}