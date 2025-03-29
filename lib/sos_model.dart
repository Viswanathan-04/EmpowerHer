import 'package:cloud_firestore/cloud_firestore.dart';

class SosModel {
  String alertId;
  List<dynamic> alertTo;
  bool contactsNotified;
  bool falseAlert;
  double latitude;
  double longitude;
  Timestamp timeStamp;
  String userId;

  SosModel({
    required this.alertId,
    required this.alertTo,
    required this.contactsNotified,
    required this.falseAlert,
    required this.latitude,
    required this.longitude,
    required this.timeStamp,
    required this.userId,
  });

  factory SosModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SosModel(alertId: data["alertId"],
        alertTo: data["alertTo"],
        contactsNotified: data["contactsNotified"],
        falseAlert: data["falseAlert"],
        latitude: data["location"].latitude,
        longitude: data["location"].longitude,
        timeStamp: data["timeStamp"],
        userId: data["userId"]);
  }

  Map<String, dynamic> toMap() {
    return {
      'alertId': alertId,
      'alertTo': alertTo,
      'contactsNotified': contactsNotified,
      'latitude': latitude,
      'longitude': longitude,
      'timeStamp': timeStamp,
      'userId': userId,
    };
  }
}