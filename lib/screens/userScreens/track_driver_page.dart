import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrackDriverPage extends StatefulWidget {
  final String driverName;

  const TrackDriverPage({
    Key? key,
    required this.driverName,
  }) : super(key: key);

  @override
  _TrackDriverPageState createState() => _TrackDriverPageState();
}

class _TrackDriverPageState extends State<TrackDriverPage> {
  GoogleMapController? _mapController;
  StreamSubscription<QuerySnapshot>? _locationSubscription;
  final Set<Marker> _markers = {};
  LatLng _defaultLocation = const LatLng(6.9271, 79.8612);
  bool _isMapCreated = false;

  @override
  void initState() {
    super.initState();
    // Delay tracking until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTrackingDriver();
    });
  }

  void _startTrackingDriver() {
    _locationSubscription = FirebaseFirestore.instance
        .collection('drivers')
        .where('driver_name', isEqualTo: widget.driverName)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final driverData = snapshot.docs.first.data();
        // Debug log to confirm data received
        print("Received driver data: $driverData");

        if (driverData['isLocationOn'] == true &&
            driverData['latitude'] != null &&
            driverData['longitude'] != null) {
          final LatLng driverLocation = LatLng(
            driverData['latitude'],
            driverData['longitude'],
          );

          if (mounted) {
            setState(() {
              _markers.clear();
              _markers.add(
                Marker(
                  markerId: const MarkerId('driverLocation'),
                  position: driverLocation,
                  infoWindow: InfoWindow(title: widget.driverName),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen),
                ),
              );
            });

            // Only move camera if map controller is initialized
            if (_isMapCreated && _mapController != null) {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(driverLocation, 15),
              );
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track ${widget.driverName}'),
        // backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .where('driver_name', isEqualTo: widget.driverName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Driver not found'));
          }

          final driverData =
              snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final isLocationOn = driverData['isLocationOn'] ?? false;

          if (!isLocationOn) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Driver\'s location sharing is currently turned off',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // If location is on and we have coordinates, set as initial position
          if (driverData['latitude'] != null &&
              driverData['longitude'] != null) {
            _defaultLocation = LatLng(
              driverData['latitude'],
              driverData['longitude'],
            );
          }

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _defaultLocation,
              zoom: 15,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
              _isMapCreated = true;

              // If markers already exist when map is created, move camera
              if (_markers.isNotEmpty) {
                final firstMarker = _markers.first;
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(firstMarker.position, 15),
                );
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}
