import 'package:empowerher/Pages/Drawerpages/about_page.dart';
import 'package:empowerher/Pages/Drawerpages/profile_page.dart';
import 'package:empowerher/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../Drawerpages/manage_access_page.dart';
import '../Signin_page/signin_page.dart';

class DrawerScreen extends StatefulWidget {
  final UserModel userModel;

  DrawerScreen({super.key, required this.userModel});

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(
            maintainState: true, builder: (context) => const SigninPage()),
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mqw = MediaQuery.of(context).size.width;
    final mqh = MediaQuery.of(context).size.height;
    return Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: const ListTile(
                      leading: Icon(
                        Icons.arrow_back,
                        color: Color.fromRGBO(32, 36, 102, 1.0),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        left: mqh * 0.025, top: mqh * 0.02, bottom: mqh * 0.01),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.userModel.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: mqh / mqw * 11,
                          color: const Color.fromRGBO(32, 36, 102, 1.0),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.only(left: mqh * 0.025, bottom: mqh * 0.04),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Last Login : ${widget.userModel.lastLogin}",
                        style: TextStyle(
                            fontSize: mqh / mqw * 6,
                            color: const Color.fromRGBO(0, 0, 0, 0.5)),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              maintainState: true,
                              builder: (context) => const Profilepage()));
                    },
                    child: ListTile(
                      leading: Icon(
                        Icons.info_outline,
                        color: Color.fromRGBO(32, 36, 102, 1.0),
                      ),
                      title: Text(
                        "Profile",
                        style: TextStyle(
                            color: Color.fromRGBO(0, 0, 0, 0.5),
                            fontSize: mqh / mqw * 8),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true)
                          .push(MaterialPageRoute(
                              maintainState: true,
                              builder: (context) => ManageAccess(
                                    phNo: widget.userModel.phoneNumber,
                                  )));
                    },
                    child: ListTile(
                      leading: Icon(
                        Icons.supervisor_account,
                        color: Color.fromRGBO(32, 36, 102, 1.0),
                      ),
                      title: Text(
                        "Manage Relations",
                        style: TextStyle(
                            color: Color.fromRGBO(0, 0, 0, 0.5),
                            fontSize: mqh / mqw * 8),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              maintainState: true,
                              builder: (context) => Aboutus()));
                    },
                    child: ListTile(
                      leading: Icon(
                        Icons.info_outline,
                        color: Color.fromRGBO(32, 36, 102, 1.0),
                      ),
                      title: Text(
                        "About this App",
                        style: TextStyle(
                            color: Color.fromRGBO(0, 0, 0, 0.5),
                            fontSize: mqh / mqw * 8),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    child: ListTile(
                      leading: Icon(
                        Icons.warning,
                        color: Color.fromRGBO(32, 36, 102, 1.0),
                      ),
                      title: Text(
                        "Report an issue",
                        style: TextStyle(
                            color: Color.fromRGBO(0, 0, 0, 0.5),
                            fontSize: mqh / mqw * 8),
                      ),
                    ),
                  ),
                  // Spacer(),
                  InkWell(
                    onTap: () async {
                      signOut();
                    },
                    child: ListTile(
                      leading: Icon(
                        Icons.logout,
                        color: Color.fromRGBO(32, 36, 102, 1.0),
                      ),
                      title: Text(
                        "Sign Out",
                        style: TextStyle(
                            color: Color.fromRGBO(0, 0, 0, 0.5),
                            fontSize: mqh / mqw * 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
