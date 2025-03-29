import 'package:flutter/material.dart';

class Aboutus extends StatefulWidget {
  Aboutus({super.key});

  @override
  State<Aboutus> createState() => _AboutusState();
}

class _AboutusState extends State<Aboutus> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
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
          "About EmpowerHer",
          style: TextStyle(
            fontSize: width * 0.05,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "About this Application",
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  "EmpowerHer is a security-oriented navigation app that ensures safe travel for women using real-time crime information, traffic, and user reports. In contrast to standard navigation apps that emphasize speed, EmpowerHer ensures safer route options, steering clear of crime hotspots derived from police reports and crowd-sourced information. The app offers real- time notifications about unsafe points and suspicious behavior so that users can plan their trips in advance. An integrated SOS emergency feature provides one-tap alerts to close friends and emergency services, along with live location sharing for urgent help. Travelers can make their communities safer by reporting, making data more accurate. The app also provides time-based safety information, which assists travelers in selecting the safest times to travel. It features public transport safety ratings, analyzing buses, trains, and stations for safe transport. Driven by Al, crime forecasting models, and APIs like Google Maps and Twilio, EmpowerHer facilitates a proactive women's safety measure. Empowering women with confidence to travel safely at any time and any place, the app leverages real-time information and crowd-sourced intelligence.",
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w200,
                  ),
                ),
                // SizedBox(
                //   height: 10,
                // ),
                // Text(
                //   "Developers",
                //   textAlign: TextAlign.justify,
                //   style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                // ),
                // SizedBox(
                //   height: 10,
                // ),
                // Text(
                //   "Viswanathan Krishnan\nVaibhav Charan\nVigneshwaran R",
                //   textAlign: TextAlign.justify,
                //   style: TextStyle(
                //     fontSize: 16.5,
                //     fontWeight: FontWeight.w200,
                //   ),
                // ),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
