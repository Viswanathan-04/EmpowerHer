import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:empowerher/sos_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class IncomingPage extends StatefulWidget {
  final int phNo;

  const IncomingPage({super.key, required this.phNo});

  @override
  State<IncomingPage> createState() => _IncomingPageState();
}

class _IncomingPageState extends State<IncomingPage> {
  Stream<List<SosModel>> getAlertSent() {
    final data = FirebaseFirestore.instance
        .collection('Sos_alerts')
        .where('alertTo', arrayContains: widget.phNo)
        .snapshots()
        .map((querySnapshot) {
      var dataList =
          querySnapshot.docs.map((doc) => SosModel.fromFirestore(doc)).toList();
      dataList.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
      return dataList;
    });
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final mqw = MediaQuery.of(context).size.width;
    final mqh = MediaQuery.of(context).size.height;
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: Color.fromRGBO(32, 36, 102, 1),
        systemNavigationBarIconBrightness: Brightness.dark
    ));

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
        title: Text(
          "Incoming Alerts",
          style: TextStyle(
            fontSize: mqh / mqw * 10,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: StreamBuilder<List<SosModel>>(
        stream: getAlertSent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(32, 36, 102, 1),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No SOS alerts found."),
            );
          }
          List<SosModel> alerts = snapshot.data!;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: mqw * 0.02),
            child: ListView.builder(
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                DateTime date = alert.timeStamp.toDate();
                String formattedTime =
                    DateFormat('dd-MM-yyyy HH:mm').format(date);
                return Card(
                  color: alert.falseAlert
                      ? const Color.fromRGBO(50, 50, 50, 1.0)
                      : const Color.fromRGBO(32, 36, 102, 1),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            alert.falseAlert ? const Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ) : const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            SizedBox(width: mqw * 0.02,),
                            Text(
                              formattedTime.substring(0, 10),
                              style: TextStyle(
                                  fontSize: mqh / mqw * 8,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(255, 165, 0, 1.0)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text("Location: ${alert.latitude}, ${alert.longitude}",
                            style: TextStyle(
                                fontSize: mqh / mqw * 7,
                                fontWeight: FontWeight.w500,
                                color: Color.fromRGBO(255, 255, 255, 0.8))),
                        const SizedBox(height: 6),
                        Text(
                            "Sent at: ${formattedTime.substring(
                              11,
                            )}",
                            style: TextStyle(
                                fontSize: mqh / mqw * 6,
                                color: Color.fromRGBO(255, 255, 255, 0.6))),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final Uri url = Uri.parse(
                                    'https://maps.google.com/?q=${alert.latitude},${alert.longitude}');
                                if (!await launchUrl(url)) {
                                  throw Exception('Could not launch $url');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(74, 144, 226, 1.0),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                "View on Map",
                                style: TextStyle(color: Colors.white, fontSize: mqh / mqw * 6),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final falseAlert = await FirebaseFirestore
                                    .instance
                                    .collection('Sos_alerts')
                                    .doc(alert.alertId)
                                    .get();
                                bool isFalse = falseAlert['falseAlert'];
                                await FirebaseFirestore.instance
                                    .collection('Sos_alerts')
                                    .doc(alert.alertId)
                                    .update({'falseAlert': !isFalse});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(74, 144, 226, 1.0),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                !alert.falseAlert
                                    ? "Report Invalid"
                                    : "Report Valid",
                                style: TextStyle(color: Colors.white, fontSize: mqh / mqw * 6),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
