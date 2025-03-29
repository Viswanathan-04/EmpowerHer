import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../Homepage/home_page.dart';

class UserdetailsPage extends StatefulWidget {
  User? user;

  UserdetailsPage({super.key, required this.user});

  @override
  State<UserdetailsPage> createState() => _UserdetailsPageState();
}

class _UserdetailsPageState extends State<UserdetailsPage> {
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

  void _validateUsername(String value) {
    setState(() {
      _isValid = value.isNotEmpty &&
          value.length >= 3 &&
          RegExp(r"^[a-zA-Z]+(([' -][a-zA-Z ])?[a-zA-Z]*)*$").hasMatch(value);
    });
  }

  Future<GeoPoint> getLocation() async {
    Position location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return GeoPoint(location.latitude, location.longitude);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _dateOfBirth.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _signUp() async {
    _showOverlay(context);
    final phData = await FirebaseFirestore.instance.collection('User').where('phoneNumber', isEqualTo: int.parse(_phoneNumber.text)).get();
    if (phData.docs.isEmpty) {
      final locationData = await getLocation();
      try {
        await FirebaseFirestore.instance
            .collection('User')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .update({
          'name': _username.text,
          'dob': _dateOfBirth.text,
          'email': _emailId.text,
          'phoneNumber': int.parse(_phoneNumber.text),
          'relations': [],
          'lastLocation': locationData,
        });
        _hideOverlay();
        Navigator.of(context, rootNavigator: true).pushReplacement(
            MaterialPageRoute(
                maintainState: true, builder: (context) => const HomePage()));
      } catch (e) {
      }
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Phone Number already in use")));
    }
  }

  final TextEditingController _username = TextEditingController();
  final TextEditingController _emailId = TextEditingController();
  final TextEditingController _dateOfBirth = TextEditingController();
  final TextEditingController _phoneNumber = TextEditingController();

  bool _isValid = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    setState(() {
      _emailId.text = widget.user!.email ?? "";
      _username.text = widget.user!.displayName ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    final mqh = MediaQuery.of(context).size.height;
    final mqw = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: mqh * 0.1,
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  height: mqh * 0.2,
                  color: Colors.blue,
                  child: Image.asset(
                    'assets/empowerher_logo.png',
                  ),
                ),
              ),
              SizedBox(
                height: mqh * 0.03,
              ),
              Center(
                child: Text(
                  "Please fill your Details",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: mqh / mqw * 10, fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(
                height: mqh * 0.05,
              ),
              Center(
                child: SizedBox(
                  width: mqw * 0.9,
                  child: TextFormField(
                    controller: _emailId,
                    enabled: false,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Email',
                      suffixIcon:
                      RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                          .hasMatch(_emailId.text)
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: mqh * 0.015,
              ),
              Center(
                child: SizedBox(
                  width: mqw * 0.9,
                  child: TextFormField(
                    controller: _username,
                    onChanged: _validateUsername,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Full Name',
                      suffixIcon: _isValid
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                    ),
                  ),
                ),
              ),
              SizedBox(height: mqh * 0.015),
              Center(
                child: SizedBox(
                  width: mqw * 0.9,
                  child: TextFormField(
                    controller: _phoneNumber,
                    decoration: InputDecoration(
                      suffixIcon:
                      RegExp(r'^(?!([0-9])\1{9,})(\+?\d{1,4}[\s-]?)?(\(?\d{3const }\)?[\s-]?)?[\d\s-]{7,10}$')
                          .hasMatch(_phoneNumber.text)
                          ? const Icon(
                        Icons.check,
                        color: Colors.green,
                      )
                          : const Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                      border: const OutlineInputBorder(),
                      labelText: 'Phone Number',
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: mqh * 0.015,
              ),
              Center(
                child: SizedBox(
                  width: mqw * 0.9,
                  child: TextFormField(
                    controller: _dateOfBirth,
                    decoration: InputDecoration(
                      labelText: 'Select Birth Date',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                    ),
                    readOnly: true,
                  ),
                ),
              ),
              SizedBox(
                height: mqh * 0.05,
              ),
              SizedBox(
                height: 50,
                child: InkWell(
                  onTap: () {
                    if (!RegExp(
                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                        .hasMatch(_emailId.text)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Please enter valid email id")));
                    } else if (!RegExp(
                        r'^(19|20)\d{2}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$')
                        .hasMatch(_dateOfBirth.text)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Please enter valid date of birth")));
                    }
                    if (_username.text != "" &&
                        _emailId.text != "" &&
                        _phoneNumber.text != "" &&
                        _dateOfBirth.text != "") {
                      _signUp();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Please enter all fields")));
                    }
                  },
                  child: Container(
                    width: mqw * 0.9,
                    height: mqh * 0.1,
                    decoration: BoxDecoration(
                        color: const Color.fromRGBO(0, 83, 188, 1),
                        borderRadius: BorderRadius.circular(30)),
                    child: Center(
                      child: Text(
                        "Continue",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: mqh / mqw * 8, fontWeight: FontWeight.w500),
                      ),
                    )
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
