import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:empowerher/Pages/Homepage/outgoing_page.dart';
import 'package:empowerher/push_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../user_model.dart';
import 'drawer_page.dart';
import 'incoming_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  late MapController _mapController;
  LatLng _currentPosition = const LatLng(12.329923, 82.299180);
  bool _isLoading = true, isSent = false, isWarning = false;
  String time = DateTime.now().hour.toString();
  late AnimationController _controller;
  late Animation<double> _animation;
  List<Marker> nearbyLocations = [];
  List<Marker> allLocations = [];
  SendNotification notification = SendNotification();
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

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _hideOverlay();
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(_currentPosition, 16);
        }
        _hideOverlay();
      });
    } catch (e) {
      print("Except : $e");
    }
  }

  Future<void> sendSOS(String name) async {
    setState(() {
      isSent = true;
    });
    final relations = await FirebaseFirestore.instance
        .collection('User')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    for (int i in relations.get('relations')) {
      notification.sendNotification(
          i.toString(), "SOS alert !!", "SOS alert from $name from ${_currentPosition.latitude}°N,${_currentPosition.longitude}°E");
    }

    _getCurrentLocation();
    CollectionReference users =
        FirebaseFirestore.instance.collection('Sos_alerts');
    DocumentReference docRef = users.doc();
    String docId = docRef.id;

    await docRef.set({
      "alertTo": relations.get('relations'),
      "contactsNotified": true,
      "falseAlert": false,
      "location":
          GeoPoint(_currentPosition.latitude, _currentPosition.longitude),
      "timeStamp": DateTime.now(),
      "userId": FirebaseAuth.instance.currentUser!.uid,
      "alertId": docId,
    });

    Timer(const Duration(seconds: 5), () {
      setState(() {
        isSent = false;
      });
    });

  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Earth's radius in km
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Stream<List<Marker>> getNearbyLocations() async* {
    yield* FirebaseFirestore.instance
        .collection('Sos_alerts')
        .where('falseAlert', isEqualTo: false)
        .snapshots()
        .asyncMap((snapshot) async {
      setState(() {
        nearbyLocations = [];
        allLocations = [];
      });
      double userLat = _currentPosition.latitude;
      double userLon = _currentPosition.longitude;

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        double placeLat = data['location'].latitude;
        double placeLon = data['location'].longitude;
        double distance =
        _calculateDistance(userLat, userLon, placeLat, placeLon);
        Marker customMarker = Marker(
          width: 40.0,
          height: 40.0,
          point: LatLng(placeLat, placeLon),
          child: const Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Icon(Icons.circle_sharp, color: Colors.red, size: 32),
              ),
              Align(
                alignment: Alignment.center,
                child: Icon(Icons.circle_sharp, color: Colors.white, size: 25),
              ),
              Align(
                alignment: Alignment.center,
                child: Icon(Icons.circle_sharp, color: Colors.red, size: 20),
              ),
            ],
          ),
        );
        allLocations.add(customMarker);
        if (distance <= 1) {
          setState(() {
            nearbyLocations.add(customMarker);
          });
        }
      }
      return allLocations;
    });
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var mqw = MediaQuery.of(context).size.width;
    var mqh = MediaQuery.of(context).size.height;

    Marker marker = Marker(
      width: 40.0,
      height: 40.0,
      point: _currentPosition,
      child: const Stack(
        children: [
          Align(alignment: Alignment.center,child: const Icon(Icons.circle_sharp, color: Colors.blue, size: 32),),
          Align(alignment: Alignment.center,child: const Icon(Icons.circle_sharp, color: Colors.white, size: 25),),
          Align(alignment: Alignment.center,child: const Icon(Icons.circle_sharp, color: Colors.blue, size: 20)),
        ],
      ),
    );

    final userData =
        ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
    ));

    return userData.when(data: (data) {
      if (nearbyLocations.length > 5 && !isWarning){
        notification.sendNotification(data!.phoneNumber.toString(), "⚠️ Alert", "Be careful !! This area has high previous crime rate history");
        setState(() {
          isWarning = true;
        });
      }

      return Scaffold(
        drawer: DrawerScreen(
          userModel: data!,
        ),
        backgroundColor: const Color.fromRGBO(32, 36, 102, 1.0),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  StreamBuilder(stream: getNearbyLocations(), builder: (context, snapshot) {
                    return SizedBox(
                      height: mqh * 0.7,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Colors.white,))
                          : ClipRRect(
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(40.0),
                            bottomRight: Radius.circular(40.0)),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _currentPosition,
                            initialZoom: 16,
                            minZoom: 12,
                            maxZoom: 18,
                            interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.drag |
                                InteractiveFlag.pinchZoom),
                            initialRotation: 0,
                            onMapReady: () {
                              if (_currentPosition != null) {
                                _mapController.move(_currentPosition, 16);
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                              subdomains: ['a', 'b', 'c'],
                            ),
                            MarkerLayer(
                              markers: [
                                marker,
                              ],
                            ),
                            MarkerLayer(markers: snapshot.data ?? [])
                          ],
                        ),
                      ),
                    );
                  }),
                  SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: mqw * 0.9,
                            height: mqh * 0.065,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25.0),
                                color: Colors.white,
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 10,
                                      spreadRadius: 10)
                                ]),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 5.0, top: 5.0, right: 5.0, bottom: 5.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Builder(
                                    builder: (context) => GestureDetector(
                                      onTap: () {
                                        Scaffold.of(context).openDrawer();
                                      },
                                      child: CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          FirebaseAuth
                                              .instance.currentUser?.photoURL ??
                                              "https://cdn-icons-png.flaticon.com/512/5045/5045878.png",
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: mqw * 0.6,
                                    child: Text(
                                      int.parse(time) < 12
                                          ? "Good Morning!"
                                          : int.parse(time) > 15
                                          ? "Good Evening!"
                                          : "Good Afternoon!",
                                      overflow: TextOverflow.fade,
                                      textAlign: TextAlign.right,
                                      maxLines: 1,
                                      style: TextStyle(
                                          fontSize: mqh / mqw * 8.5,
                                          color: Color.fromRGBO(32, 36, 102, 1.0),
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      _showOverlay(context);
                                      _getCurrentLocation();
                                    },
                                    child: Icon(
                                      Icons.share_location_sharp,
                                      size: mqw * 0.07,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      )),
                  Padding(
                    padding: EdgeInsets.only(top: mqh * 0.64, left: mqw * 0.3),
                    child: Container(
                      width: mqw * 0.4,
                      height: mqh * 0.05,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: nearbyLocations.length < 4
                              ? const Color.fromRGBO(10, 163, 10, 1.0)
                              : const Color.fromRGBO(180, 10, 10, 1.0)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.security_sharp,
                            color: Colors.white,
                          ),
                          SizedBox(
                            width: mqw * 0.01,
                          ),
                          Text(
                            nearbyLocations.length < 4
                                ? "You're Safe"
                                : "Be careful !",
                            style: TextStyle(color: Colors.white, fontSize: mqh / mqw * 7),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: mqh * 0.01),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _mapController.move(_currentPosition, 16);
                      },
                      child: Icon(
                        Icons.my_location,
                        size: 25,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(
                      width: mqw * 0.05,
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 0.5);
                          },
                          child: Icon(
                            Icons.add,
                            size: 25,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: mqw * 0.03,),
                        GestureDetector(
                          onTap: () {
                            _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 0.5);
                          },
                          child: Icon(
                            Icons.remove,
                            size: 25,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              maintainState: true,
                              builder: (context) => const OutgoingPage()
                          )
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Colors.white),
                          child: Icon(
                            Icons.arrow_outward_rounded,
                            size: mqw * 0.1,
                            color: const Color.fromRGBO(32, 36, 102, 1),
                          ),
                        ),
                        SizedBox(
                          height: mqh * 0.01,
                        ),
                        Text(
                          "Outgoing",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white, fontSize: mqh / mqw * 6),
                        )
                      ],
                    ),
                  ),
                  Container(
                    height: mqh * 0.2,
                    width: mqw * 0.5,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          for (int i = 0; i < 2; i++)
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return !isSent
                                    ? Container(
                                  width: 100 * (_animation.value + i * 0.3),
                                  height:
                                  100 * (_animation.value + i * 0.3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.withAlpha(
                                        ((0.2 - (i * 0.05)) * 255).toInt()),
                                  ),
                                )
                                    : const SizedBox.shrink();
                              },
                            ),
                          ElevatedButton(
                            onPressed: () {},
                            onLongPress: () {
                              if (data.relations.isNotEmpty) {
                                sendSOS(data.name);
                              }
                              Fluttertoast.showToast(
                                msg: data.relations.isEmpty ? "Please add relation details to send alert to them" : "SOS Alert triggered.. Sending alert",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 1,
                                textColor: Colors.white,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(30),
                              backgroundColor: isSent ? Colors.green : Colors.red,
                            ),
                            child: isSent
                                ? Icon(
                              Icons.check,
                              color: Colors.white,
                              size: mqw * 0.1,
                            )
                                : Text(
                              "SOS",
                              style: TextStyle(
                                fontSize: mqh / mqw * 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              maintainState: true,
                              builder: (context) => IncomingPage(phNo: data.phoneNumber,)
                          )
                      );
                    },
                    child: Column(
                      children: [
                        Transform.rotate(
                          angle: 135,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: Colors.white),
                            child: Icon(
                              Icons.arrow_outward_rounded,
                              size: mqw * 0.1,
                              color: const Color.fromRGBO(32, 36, 102, 1),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: mqh * 0.01,
                        ),
                        Text(
                          "Received",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white, fontSize: mqh / mqw * 6),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      );
    }, error: (error, stackTrace) {
      return const Text("Error");
    }, loading: () {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    });
  }
}
