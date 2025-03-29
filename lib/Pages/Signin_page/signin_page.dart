import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:empowerher/Pages/Homepage/home_page.dart';
import 'package:empowerher/Pages/Signin_page/userdetails_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  OverlayEntry? _overlayEntry;

  void _showOverlay(BuildContext context) {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Container(
          color: Colors.black45,
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<GeoPoint> getLocation() async {
    Position location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return GeoPoint(location.latitude, location.longitude);
  }

  signInWithGoogle(BuildContext context) async {
    _showOverlay(context);
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();
    final GoogleSignInAuthentication? googleSignInAuthentication =
        await googleSignInAccount?.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleSignInAuthentication?.idToken,
      accessToken: googleSignInAuthentication?.accessToken,
    );
    UserCredential result = await firebaseAuth.signInWithCredential(credential);

    User? userDetails = result.user;
    final currTime = DateTime.now();
    final lastLogin =
        "${currTime.year.toString().padLeft(2, '0')}-${currTime.month.toString().padLeft(2, '0')}-${currTime.day.toString().padLeft(2, '0')} ${currTime.hour.toString().padLeft(2, '0')}:${currTime.minute.toString().padLeft(2, '0')}";

    if (userDetails != null) {
      try {
        await FirebaseFirestore.instance
            .collection("User")
            .doc(userDetails.uid)
            .update({
              "lastLogin": lastLogin,
              "lastLocation" : await getLocation(),
              "fcmKey": await FirebaseMessaging.instance.getToken(),
            });
        _hideOverlay();
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(
            maintainState: true,
            builder: (context) => const HomePage(),
          ),
        );
      } on Exception {
        await FirebaseFirestore.instance
            .collection("User")
            .doc(userDetails.uid)
            .set({
              "email": userDetails.email,
              "name": userDetails.displayName,
              "id": userDetails.uid,
              "imageUrl" : userDetails.photoURL ?? "https://cdn-icons-png.flaticon.com/512/5045/5045878.png",
              "lastLogin": lastLogin,
              "lastLocation" : await getLocation(),
              "phoneNumber": 0,
              "fcmKey": await FirebaseMessaging.instance.getToken(),
            });
        _hideOverlay();
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(
            maintainState: true,
            builder: (context) => UserdetailsPage(user: userDetails),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark
    ));
    var mqh = MediaQuery.of(context).size.height;
    var mqw = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    height: mqh * 0.18,
                    color: const Color.fromRGBO(32, 36, 102, 1.0),
                    child: Image.asset('assets/empowerher_logo.png'),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'EmpowerHer',
                  style: TextStyle(fontSize: mqh / mqw * 12, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: mqh * 0.3),
                Text(
                  'Sign in with your Google account to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: mqh / mqw * 7, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: mqw * 0.7,
                  height: mqh * 0.075,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      signInWithGoogle(context);
                    },
                    icon: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
                      height: 24,
                    ),
                    label: Text(
                      'Sign in with Google',
                      style: TextStyle(fontSize: mqh / mqw * 7, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(32, 36, 102, 1.0),
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
