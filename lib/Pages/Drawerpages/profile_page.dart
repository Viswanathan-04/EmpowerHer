import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:empowerher/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../Signin_page/signin_page.dart';

class Profilepage extends ConsumerStatefulWidget {
  const Profilepage({super.key});

  @override
  ConsumerState<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends ConsumerState<Profilepage> {
  bool isEdit = false;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _mailController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _birthdayController = TextEditingController();

  DateTime? _selectedDate;

  Future<String> getLocation() async {
    Position location = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    );

    Placemark place = placemarks[0];
    return place.locality ?? 'Unknown location';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _birthdayController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> getData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      try {
        final data = await FirebaseFirestore.instance
            .collection("User")
            .doc(userId)
            .get();
        if (data.exists) {
          var data1 = data.data();
          setState(() {
            _nameController.text = data1!['name'] ?? "";
            _mailController.text = data1['email'] ?? "";
            _phoneController.text = data1['phoneNumber'].toString() ?? '';
            _birthdayController.text = data1['dob'] ?? '';
          });
        } else {}
      } catch (e) {}
    } else {}
  }

  Future<void> changeDetails() async {
    final phData = await FirebaseFirestore.instance
        .collection('User')
        .where('phoneNumber', isEqualTo: int.parse(_phoneController.text))
        .get();
    if (isEdit) {
      if (!RegExp(r'^(19|20)\d{2}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$')
          .hasMatch(_birthdayController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please enter valid date of birth")));
      }
      if (phData.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Phone Number already exists. Please check")));
      } else {
        FirebaseFirestore.instance
            .collection("User")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({
          "name": _nameController.text,
          "phoneNumber": int.parse(_phoneController.text),
          "dob": _birthdayController.text,
        });
        setState(() {
          isEdit = !isEdit;
        });
        getData();
      }
    }
  }

  Future<void> deleteAccount() async {
    try {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
      ));
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
                child: CircularProgressIndicator(
              color: Color.fromRGBO(32, 36, 102, 1),
            ))),
      );

      await FirebaseFirestore.instance
          .collection('User')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .delete();

      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect();
        await googleSignIn.signOut();
      }
      await FirebaseAuth.instance.currentUser!.delete();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SigninPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print("Error deleting account: $e");
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final userData =
        ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.only(left: 0),
          child: GestureDetector(
            onTap: () async {
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: const Icon(Icons.arrow_back),
          ),
        ),
        title: const Text("Edit Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: userData.when(
            data: (data) {
              List<dynamic> relations;
              if (data != null) {
                relations = data.relations;
              }
              return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: SizedBox(
                    height: height,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: width * 0.2,
                          backgroundColor: Colors.white,
                          backgroundImage: NetworkImage(
                            FirebaseAuth.instance.currentUser?.photoURL ??
                                "https://cdn-icons-png.flaticon.com/512/5045/5045878.png",
                          ),
                        ),
                        SizedBox(
                          height: height * 0.02,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Name",
                              style: TextStyle(
                                  color: Colors.grey, fontSize: width * 0.04),
                            ),
                            SizedBox(
                              width: width,
                              height: isEdit ? 50 : 40,
                              child: isEdit
                                  ? TextFormField(
                                      controller: _nameController,
                                      decoration: InputDecoration(
                                        hintText: data!.name,
                                      ),
                                    )
                                  : Text(
                                      data!.name,
                                      textAlign: TextAlign.left,
                                      style: TextStyle(fontSize: width * 0.05),
                                    ),
                            )
                          ],
                        ),
                        SizedBox(
                          height: height * 0.01,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Email Address",
                              style: TextStyle(
                                  color: Colors.grey, fontSize: width * 0.04),
                            ),
                            SizedBox(
                              width: width,
                              height: isEdit ? 50 : 40,
                              child: isEdit
                                  ? TextFormField(
                                      controller: _mailController,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        hintText: data.email,
                                      ),
                                    )
                                  : Text(
                                      data.email,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: width * 0.05,
                                          color: Colors.black),
                                    ),
                            )
                          ],
                        ),
                        SizedBox(
                          height: height * 0.01,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Phone Number",
                              style: TextStyle(
                                  color: Colors.grey, fontSize: width * 0.04),
                            ),
                            SizedBox(
                              width: width,
                              height: isEdit ? 50 : 40,
                              child: isEdit
                                  ? TextFormField(
                                      controller: _phoneController,
                                      decoration: InputDecoration(
                                        hintText: data.phoneNumber.toString(),
                                      ),
                                    )
                                  : Text(
                                      data.phoneNumber.toString(),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          fontSize: width * 0.05,
                                          color: Colors.black),
                                    ),
                            )
                          ],
                        ),
                        SizedBox(
                          height: height * 0.01,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Birthday",
                              style: TextStyle(
                                  color: Colors.grey, fontSize: width * 0.04),
                            ),
                            SizedBox(
                              width: width,
                              height: isEdit ? 50 : 40,
                              child: isEdit
                                  ? TextFormField(
                                      controller: _birthdayController,
                                      decoration: InputDecoration(
                                        suffixIcon: IconButton(
                                          icon:
                                              const Icon(Icons.calendar_today),
                                          onPressed: () => _selectDate(context),
                                        ),
                                      ),
                                      readOnly: true,
                                    )
                                  : Text(
                                      data.dob,
                                      textAlign: TextAlign.left,
                                      style: TextStyle(fontSize: width * 0.05),
                                    ),
                            )
                          ],
                        ),
                        SizedBox(
                          height: height * 0.05,
                        ),
                        Center(
                            child: Container(
                          width: width * 0.4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: const Color.fromRGBO(32, 36, 102, 1.0),
                          ),
                          child: TextButton(
                            onPressed: () {
                              if (isEdit) {
                                changeDetails();
                              } else {
                                setState(() {
                                  isEdit = !isEdit;
                                });
                              }
                            },
                            child: !isEdit
                                ? Text(
                                    'Edit',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: width * 0.05),
                                  )
                                : Text(
                                    'Save details',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: width * 0.05),
                                  ),
                          ),
                        )),
                        SizedBox(
                          height: height * 0.02,
                        ),
                        Center(
                            child: Container(
                                width: width * 0.5,
                                height: height * 0.05,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  color: Color.fromRGBO(175, 0, 0, 1),
                                ),
                                child: GestureDetector(
                                    onTap: () {
                                      deleteAccount();
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 10,),
                                        Text(
                                          "Delete Account",
                                          style: TextStyle(
                                              fontSize: height / width * 7,
                                            color: Colors.white
                                          ),
                                        ),
                                      ],
                                    )
                                )
                            )
                        ),
                      ],
                    ),
                  ));
            },
            error: (error, StackTrace) {
              return const Text("Error");
            },
            loading: () {
              return const CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}
