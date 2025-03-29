// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:empowerher/push_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../user_model.dart';

class ManageAccess extends ConsumerStatefulWidget {
  final int phNo;

  ManageAccess({super.key, required this.phNo});

  @override
  ConsumerState<ManageAccess> createState() => _ManageAccessState();
}

class _ManageAccessState extends ConsumerState<ManageAccess> {
  final TextEditingController _phoneConn = TextEditingController();
  final TextEditingController _otpConn = TextEditingController();

  void _showDialog() {
    bool invalidNum = false;
    int otpNum = 100000 + Random().nextInt(900000); // Ensures a 6-digit number

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Add Relation'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _phoneConn,
                      keyboardType: TextInputType.phone,
                      // Ensures numeric keyboard
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Phone Number',
                        suffixIcon: IconButton(
                          onPressed: () {
                            int? phoneNumber = int.tryParse(_phoneConn.text);
                            if (phoneNumber != null &&
                                phoneNumber != widget.phNo) {
                              _fetchPhoneDetails(_phoneConn.text, otpNum);
                            } else {
                              setState(() {
                                invalidNum = true;
                              });

                              Timer(const Duration(seconds: 3), () {
                                setState(() {
                                  invalidNum = false;
                                });
                              });
                            }
                          },
                          icon: Icon(
                            invalidNum ? Icons.cancel_outlined : Icons.send,
                            color: invalidNum ? Colors.red : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _otpConn,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'OTP',
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    _addrelation(otpNum);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addrelation(int otpNum) async {
    // ignore: unrelated_type_equality_checks
    if (_otpConn.text == otpNum.toString()) {
      String phonetoCheck = _phoneConn.text;
      var usersCollection = FirebaseFirestore.instance.collection("User");
      var querySnapshot = await usersCollection
          .where('phoneNumber', isEqualTo: widget.phNo)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          "relations": FieldValue.arrayUnion([int.parse(phonetoCheck)])
        });

        Navigator.of(context, rootNavigator: true).pop();
      }
    } else if (int.parse(_phoneConn.text) == widget.phNo) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a different number")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPhoneDetails(
      String phoneNumber, int otpNum) async {
    List<Map<String, dynamic>> relationDetails = [];
    var userDoc = await FirebaseFirestore.instance
        .collection('User')
        .where('phoneNumber', isEqualTo: int.parse(phoneNumber))
        .get();
    if (userDoc.docs.isNotEmpty) {
      final data = userDoc.docs.first.data()['phoneNumber'];
      SendNotification notification = SendNotification();
      notification.sendNotification(data.toString(), "OTP Verification",
          "Your OTP is ${otpNum.toString()}");
    } else {}
    return relationDetails;
  }

  Stream<List<Map<String, dynamic>>> _fetchRelationDetails(String phNo) {
    return FirebaseFirestore.instance
        .collection('User')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .asyncMap((documentSnapshot) async {
      if (documentSnapshot.exists) {
        var data = documentSnapshot.data();
        if (data != null && data['relations'] is List) {
          List relations = data['relations'];

          List<Map<String, dynamic>> relatedUsers = [];

          for (var phoneNumber in relations) {
            var querySnapshot = await FirebaseFirestore.instance
                .collection("User")
                .where('phoneNumber', isEqualTo: phoneNumber)
                .get();
            for (var doc in querySnapshot.docs) {
              relatedUsers.add(doc.data());
            }
          }
          return relatedUsers;
        }
      }
      return [];
    });
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
        backgroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        title: Align(
          alignment: Alignment.center,
          child: Text(
            "Manage Access",
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              _showDialog();
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 20),
              child: Icon(
                Icons.add,
                color: Colors.black,
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              userData.when(
                data: (data) {
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _fetchRelationDetails(widget.phNo.toString()),
                    builder: (context, snapshot) {
                      print(snapshot.data);
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(
                          color: Color.fromRGBO(32, 36, 102, 1.0),
                        );
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }
                      var details = snapshot.data!;
                      return Column(
                        children: [
                          SizedBox(
                            height: height * 0.75,
                            child: ListView.builder(
                              itemCount: details.length,
                              itemBuilder: (context, index) {
                                final relationDetail = details[index];
                                return Container(
                                  padding: const EdgeInsets.only(
                                      left: 10.0, top: 10.0, bottom: 10.0),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 15.0,
                                    vertical: 5.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.white,
                                        radius: width * 0.05,
                                        backgroundImage: NetworkImage(
                                          relationDetail['imageUrl'] ??
                                              "https://cdn-icons-png.flaticon.com/512/5045/5045878.png",
                                        ),
                                      ),
                                      SizedBox(
                                        width: width * 0.05,
                                      ),
                                      SizedBox(
                                        width: width * 0.65,
                                        child: Text(
                                          relationDetail['name'],
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: width * 0.02,
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final data = await FirebaseFirestore
                                              .instance
                                              .collection('User')
                                              .where('phoneNumber',
                                                  isEqualTo: widget.phNo)
                                              .get();
                                          data.docs.first.reference.update({
                                            'relations': FieldValue.arrayRemove(
                                                [relationDetail['phoneNumber']])
                                          });
                                        },
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                error: (error, stackTrace) {
                  return Center(child: Text("Error: $error"));
                },
                loading: () {
                  return const CircularProgressIndicator(
                    color: Color.fromRGBO(32, 36, 102, 1.0),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
