import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ShuttleTrackingMapPage extends StatefulWidget {
  const ShuttleTrackingMapPage({super.key});

  @override
  _ShuttleTrackingMapPageState createState() => _ShuttleTrackingMapPageState();
}

class _ShuttleTrackingMapPageState extends State<ShuttleTrackingMapPage> {
  late GoogleMapController _mapController;
  final LatLng _nsbmLocation =
      const LatLng(6.8219, 80.0406); // NSBM coordinates
  final Map<MarkerId, Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _addShuttleMarkers();
  }

  void _addShuttleMarkers() {
    // Clear existing markers
    _markers.clear();

    // Example markers for shuttles
    _markers[const MarkerId('shuttle1')] = Marker(
      markerId: const MarkerId('shuttle1'),
      position: const LatLng(6.8225, 80.0410),
      infoWindow: const InfoWindow(
        title: 'Shuttle 1',
        snippet: 'Crowd Level: Moderate',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      onTap: () {
        _showShuttleDetails(
            'Shuttle 1', 'Crowd Level: Moderate', '6.8225, 80.0410');
      },
    );

    _markers[const MarkerId('shuttle2')] = Marker(
      markerId: const MarkerId('shuttle2'),
      position: const LatLng(6.8230, 80.0415),
      infoWindow: const InfoWindow(
        title: 'Shuttle 2',
        snippet: 'Crowd Level: Full',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      onTap: () {
        _showShuttleDetails(
            'Shuttle 2', 'Crowd Level: Full', '6.8230, 80.0415');
      },
    );

    _markers[const MarkerId('shuttle3')] = Marker(
      markerId: const MarkerId('shuttle3'),
      position: const LatLng(6.8215, 80.0400),
      infoWindow: const InfoWindow(
        title: 'Shuttle 3',
        snippet: 'Crowd Level: Empty',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      onTap: () {
        _showShuttleDetails(
            'Shuttle 3', 'Crowd Level: Empty', '6.8215, 80.0400');
      },
    );
  }

  void _showShuttleDetails(
      String shuttleName, String crowdLevel, String location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$shuttleName Details'),
          content: Text('Crowd Level: $crowdLevel\nLocation: $location'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Shuttle Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh or update shuttle locations
              setState(() {
                _addShuttleMarkers();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_bus,
                  color: Colors.green,
                  size: 50,
                ),
                SizedBox(width: 10),
                Text(
                  'Track Shuttles Live',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _nsbmLocation,
                zoom: 15.0,
              ),
              markers: Set<Marker>.of(_markers.values),
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.green),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap on a shuttle marker to view details like location, crowd level, and upcoming stops.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black54,
        currentIndex: 0, // Replace this with a dynamic index if needed
        onTap: (index) {
          // Handle navigation for different pages
          switch (index) {
            case 0:
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ActivitiesPage()));
              break;
            case 1:
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AlertsPage()));
              break;
            case 2:
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()));
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Activities',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Dummy pages for bottom navigation
class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
      ),
      body: const Center(
        child: Text('Activities Page'),
      ),
    );
  }
}

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
      ),
      body: const Center(
        child: Text('Alerts Page'),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: const Center(
        child: Text('Profile Page'),
      ),
    );
  }
}
