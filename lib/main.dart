import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:empowerher/Pages/Signin_page/signin_page.dart';
import 'package:empowerher/Pages/Signin_page/userdetails_page.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:permission_handler/permission_handler.dart';

import './push_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'Pages/Homepage/home_page.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    SendNotification sendNotification = SendNotification();
    sendNotification.showNotification(message.notification?.title ?? "", message.notification?.body ?? "");
  });
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark
  ));
  runApp(const ProviderScope(child: MyApp(debugShowCheckedModeBanner: false)));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required bool debugShowCheckedModeBanner});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.notification,
    ].request();

    if (statuses[Permission.location]?.isGranted ?? false) {
      print("Location permission granted");
    } else {
      print("Location permission denied");
    }

    if (statuses[Permission.notification]?.isGranted ?? false) {
      print("Notification permission granted");
    } else {
      print("Notification permission denied");
    }
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<Widget> getInitialScreen(User user) async {
    final data = await FirebaseFirestore.instance.collection('User').doc(user.uid).get();
    final phoneNumber = data.data()?['phoneNumber'];
    if (phoneNumber == 0 || phoneNumber == null) {
      return UserdetailsPage(user: user);
    } else {
      return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EmpowerHer',
      color: Colors.white,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasData) {
            return FutureBuilder<Widget>(
              future: getInitialScreen(snapshot.data!),
              builder: (context, futureSnapshot) {
                if (futureSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (futureSnapshot.hasData) {
                  return futureSnapshot.data!;
                } else {
                  return const Scaffold(
                    body: Center(
                      child: Text("Error loading data"),
                    ),
                  );
                }
              },
            );
          } else {
            return const SigninPage();
          }
        },
      ),
    );
  }
}