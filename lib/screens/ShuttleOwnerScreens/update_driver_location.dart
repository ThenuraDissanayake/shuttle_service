import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class DriverLocationPage extends StatefulWidget {
  const DriverLocationPage({Key? key}) : super(key: key);

  @override
  _DriverLocationPageState createState() => _DriverLocationPageState();
}

class _DriverLocationPageState extends State<DriverLocationPage> {
  bool isLocationOn = false;
  StreamSubscription<Position>? _locationSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkInitialLocationStatus();
  }

  Future<void> _checkInitialLocationStatus() async {
    if (currentUser != null) {
      final driverDoc =
          await _firestore.collection('drivers').doc(currentUser!.uid).get();

      if (driverDoc.exists) {
        setState(() {
          isLocationOn = driverDoc.data()?['isLocationOn'] ?? false;
        });

        if (isLocationOn) {
          _startLocationUpdates();
        }
      }
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location services are disabled. Please enable them.'),
        ),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are denied.'),
          ),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied.'),
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _toggleLocation() async {
    if (!isLocationOn) {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return;
    }

    setState(() {
      isLocationOn = !isLocationOn;
    });

    if (currentUser != null) {
      await _firestore.collection('drivers').doc(currentUser!.uid).update({
        'isLocationOn': isLocationOn,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (isLocationOn) {
        _startLocationUpdates();
      } else {
        _stopLocationUpdates();
      }
    }
  }

  void _startLocationUpdates() {
    if (_locationSubscription != null)
      return; // Prevent overlapping subscriptions

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) async {
      if (currentUser != null) {
        print('Updating location for driver: ${currentUser!.uid}');
        print(
            'Latitude: ${position.latitude}, Longitude: ${position.longitude}');

        await _firestore.collection('drivers').doc(currentUser!.uid).update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'lastUpdated': FieldValue.serverTimestamp(),
          'isLocationOn': true,
        });
      }
    });
  }

  void _stopLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = null; // Reset the subscription
    if (currentUser != null) {
      _firestore.collection('drivers').doc(currentUser!.uid).update({
        'isLocationOn': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Sharing'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLocationOn ? Icons.location_on : Icons.location_off,
              size: 80,
              color: isLocationOn ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              isLocationOn
                  ? 'Location Sharing is ON'
                  : 'Location Sharing is OFF',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _toggleLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLocationOn ? Colors.red : Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                isLocationOn ? 'Turn Off Location' : 'Turn On Location',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
