import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import "package:http/http.dart" as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'main.dart';


class SendNotification {
  Future<String> getAccessToken() async {
    final jsonString = await rootBundle.loadString(
        'assets/service_account.json');
    final serviceAccount = ServiceAccountCredentials.fromJson(jsonString);

    final scopes = [ 'https://www.googleapis.com/auth/firebase.messaging'];
    final client = await clientViaServiceAccount(serviceAccount, scopes);
    final accessToken = client.credentials.accessToken;
    return accessToken.data;
  }

  Future<void> sendNotification(String phoneNumber, String title,
      String body) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final data = await FirebaseFirestore.instance.collection("User").where(
          'phoneNumber', isEqualTo: int.parse(phoneNumber)).get();
      final targetToken = data.docs.first.get('fcmKey');
      final token = await getAccessToken();

      final url = Uri.parse(
          'https://fcm.googleapis.com/v1/projects/empowerher-f63c9/messages:send');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final payload = json.encode({
        'message': {
          'token': targetToken,
          'notification': {
            'title': title,
            'body': body,
          },
        },
      });

      await http.post(url, headers: headers, body: payload);
    }
  }

  Future<void> showNotification(String title, String msg) async {
    // Define static notification details for each type
    const AndroidNotificationDetails appNotificationDetails =
    AndroidNotificationDetails(
      '3ac378sb',
      'App Notification',
      enableVibration: true,
      channelDescription: 'Notification from EmpowerHer',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('appsound'),
      priority: Priority.high,
      playSound: true,
    );

    const AndroidNotificationDetails sosNotificationDetails =
    AndroidNotificationDetails(
      '4ac378sb',
      'SOS Notification',
      enableVibration: true,
      channelDescription: 'Notification from EmpowerHer',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('sossound'),
      priority: Priority.high,
      playSound: true,
    );

    // Wrap AndroidNotificationDetails in NotificationDetails
    const NotificationDetails appPlatformChannelSpecifics =
    NotificationDetails(android: appNotificationDetails);

    const NotificationDetails sosPlatformChannelSpecifics =
    NotificationDetails(android: sosNotificationDetails); // Corrected

    // Determine the correct sound dynamically
    final bool isSos = msg.toLowerCase().contains("sos");
    final NotificationDetails selectedPlatformChannelSpecifics =
    isSos ? sosPlatformChannelSpecifics : appPlatformChannelSpecifics;

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      msg,
      selectedPlatformChannelSpecifics,
      payload: 'item x',
    );
  }
}