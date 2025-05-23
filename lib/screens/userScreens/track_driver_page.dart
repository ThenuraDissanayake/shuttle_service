import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

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
  BitmapDescriptor? _busIcon;
  String _eta = 'Calculating...';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadBusIcon();
    // Delay tracking until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTrackingDriver();
      // Start auto-refresh timer
      _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          _startTrackingDriver();
        }
      });
    });
  }

  Future<void> _loadBusIcon() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/bus_icon.png');
      final Uint8List bytes = data.buffer.asUint8List();

      // Create custom sized icon
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 80, // Reduce size to 80px
        targetHeight: 80, // Maintain aspect ratio
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ByteData? resizedData =
          await fi.image.toByteData(format: ui.ImageByteFormat.png);

      if (resizedData != null) {
        final Uint8List resizedBytes = resizedData.buffer.asUint8List();
        final BitmapDescriptor customIcon =
            BitmapDescriptor.fromBytes(resizedBytes);

        setState(() {
          _busIcon = customIcon;
        });
      } else {
        // Fallback to default marker with custom color if resize fails
        setState(() {
          _busIcon =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
        });
      }
    } catch (e) {
      print('Error loading bus icon: $e');
      setState(() {
        _busIcon =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      });
    }
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
                  markerId: const MarkerId('driver'),
                  position: driverLocation,
                  icon: _busIcon ?? BitmapDescriptor.defaultMarker,
                  infoWindow: InfoWindow(
                    title: '${widget.driverName}\'s Shuttle',
                    snippet: 'ETA: $_eta',
                  ),
                ),
              );
              _calculateETA(driverLocation);
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

  Future<void> _calculateETA(LatLng driverLocation) async {
    // This is a simple distance-based calculation
    // For more accurate results, consider using Google Maps Distance Matrix API
    const double averageSpeed = 40.0; // km/h
    double distanceInKm = _calculateDistance(driverLocation, _defaultLocation);
    double timeInHours = distanceInKm / averageSpeed;
    int minutes = (timeInHours * 60).round();

    setState(() {
      _eta = minutes <= 0 ? 'Arriving' : '$minutes mins';
    });
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    // Simple distance calculation using Euclidean distance
    // For more accurate results, consider using Haversine formula
    var p = 0.017453292519943295; // Math.PI / 180
    var c = cos;
    var a = 0.5 -
        c((point2.latitude - point1.latitude) * p) / 2 +
        c(point1.latitude * p) *
            c(point2.latitude * p) *
            (1 - c((point2.longitude - point1.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        title: const Text(
          // 'Track ${widget.driverName}'
          'Shuttle Tracking',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('drivers')
                .where('driver_name', isEqualTo: widget.driverName)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState('Error: ${snapshot.error}');
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildErrorState('Driver not found');
              }

              final driverData =
                  snapshot.data!.docs.first.data() as Map<String, dynamic>;
              final isLocationOn = driverData['isLocationOn'] ?? false;

              if (!isLocationOn) {
                return _buildLocationOffState();
              }

              // If location is on and we have coordinates, set as initial position
              if (driverData['latitude'] != null &&
                  driverData['longitude'] != null) {
                _defaultLocation = LatLng(
                  driverData['latitude'],
                  driverData['longitude'],
                );
              }

              return Stack(
                children: [
                  GoogleMap(
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
                    myLocationButtonEnabled: false, // We'll add a custom button
                    mapType: MapType.normal,
                    zoomControlsEnabled: true,
                    zoomGesturesEnabled: true,
                  ),
                  Positioned(
                    right: 16,
                    bottom: 200,
                    child: FloatingActionButton(
                      backgroundColor: Colors.white,
                      child:
                          const Icon(Icons.my_location, color: Colors.black87),
                      onPressed: () => _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_defaultLocation, 15),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // ETA Card at top
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            const Icon(Icons.access_time, color: Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Estimated Time of Arrival',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _eta,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom Sheet with Driver Details
          DraggableScrollableSheet(
            initialChildSize: 0.25,
            minChildSize: 0.15,
            maxChildSize: 0.4,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildDriverInfoRow(Icons.person_outline,
                                widget.driverName, 'Driver'),
                            // const Divider(),
                            // _buildDriverInfoRow(
                            //     Icons.route, 'Live Tracking', 'Active'),
                            const Divider(),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('drivers')
                                  .where('driver_name',
                                      isEqualTo: widget.driverName)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return _buildDriverInfoRow(
                                      Icons.directions_bus,
                                      'License Plate',
                                      'N/A');
                                }
                                final driverData = snapshot.data!.docs.first
                                    .data() as Map<String, dynamic>;
                                return _buildDriverInfoRow(
                                    Icons.directions_bus,
                                    'License Plate',
                                    driverData['shuttle']?['license_plate'] ??
                                        'N/A');
                              },
                            ),
                            // Add more driver details here
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationOffState() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              'Location Sharing is Off',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'The driver has temporarily disabled location sharing',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfoRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    _refreshTimer?.cancel(); // Cancel the timer when disposing
    super.dispose();
  }
}
