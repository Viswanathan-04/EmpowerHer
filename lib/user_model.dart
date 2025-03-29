import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserModel {
  String dob;
  String email;
  String name;
  String fcmKey;
  String imageUrl;
  String lastLogin;
  double latitude;
  double longitude;
  List<dynamic> relations;
  int phoneNumber;

  UserModel({
    required this.dob,
    required this.email,
    required this.name,
    required this.imageUrl,
    required this.fcmKey,
    required this.lastLogin,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    required this.relations,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
        dob: data['dob'] ?? '',
        email: data['email'] ?? '',
        name: data['name'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        fcmKey: data['fcmKey'] ?? '',
        lastLogin: data['lastLogin'] ?? '',
        latitude: data['lastLocation'].latitude ?? 0.1,
        longitude: data['lastLocation'].longitude ?? 0.1,
        phoneNumber: data['phoneNumber'] ?? 0,
        relations: data['relations'] ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dob': dob,
      'email': email,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'phone_number': phoneNumber,
      'relations': relations,
    };
  }
}

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Stream<UserModel?> streamCurrentUser(String userId) {
    return auth.authStateChanges().switchMap((user) {
      if (user == null) {
        return Stream.value(null); // User signed out
      } else {
        return db.collection('User').doc(userId).snapshots().map((doc) {
          if (doc.exists) {
            return UserModel.fromFirestore(doc);
          } else {
            return null;
          }
        });
      }
    });
  }
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final userModelProvider = StreamProvider.family<UserModel?, String>((ref, userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamCurrentUser(userId).handleError((error) {
    print('Error streaming user data: $error');
    return null;
  });
});