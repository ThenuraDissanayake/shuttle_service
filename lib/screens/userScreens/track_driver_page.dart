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

  @override
  void initState() {
    super.initState();
    _startTrackingDriver();
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

          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(driverLocation, 15),
          );
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

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _defaultLocation,
              zoom: 15,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
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
