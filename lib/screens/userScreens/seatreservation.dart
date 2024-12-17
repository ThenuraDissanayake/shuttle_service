import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FindActiveShuttlesPage extends StatefulWidget {
  const FindActiveShuttlesPage({super.key});

  @override
  State<FindActiveShuttlesPage> createState() => _FindActiveShuttlesPageState();
}

class _FindActiveShuttlesPageState extends State<FindActiveShuttlesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _activeShuttles = [];
  List<Map<String, dynamic>> _filteredShuttles = [];

  @override
  void initState() {
    super.initState();
    _fetchActiveShuttles();

    // Listen to search input changes and filter results
    _searchController.addListener(() {
      _filterShuttles(_searchController.text);
    });
  }

  // Fetch active shuttles from Firestore
  Future<void> _fetchActiveShuttles() async {
    try {
      final querySnapshot = await _firestore
          .collection('drivers')
          .where('shuttle.status',
              isEqualTo: 'Active') // Filter for active shuttles
          .get();

      // Convert querySnapshot to list of shuttles
      final activeShuttles = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        final route = data['shuttle']['route'];
        String routeDisplay = '';
        if (route is List) {
          routeDisplay = List<String>.from(route).join(" -> ");
        } else if (route is String) {
          routeDisplay = route;
        }

        return {
          'shuttle_id': doc.id,
          'route': routeDisplay,
          'driver_name': data['driver_name'] ?? 'Unknown Driver',
          'license_plate': data['shuttle']['license_plate'] ?? 'Unknown Plate',
          'morning_journey_time': data['morning_journey_time'] ??
              Timestamp.fromDate(DateTime.now()),
          'evening_journey_time': data['evening_journey_time'] ??
              Timestamp.fromDate(DateTime.now().add(Duration(hours: 12))),
        };
      }).toList();

      setState(() {
        _activeShuttles = activeShuttles;
        _filteredShuttles = activeShuttles; // Initially, display all shuttles
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching active shuttles: $e')),
      );
    }
  }

  // Filter shuttles by route name
  void _filterShuttles(String query) {
    final filtered = _activeShuttles.where((shuttle) {
      final route = shuttle['route'].toLowerCase();
      final searchQuery = query.toLowerCase();
      return route.contains(
          searchQuery); // Check if the route contains the search query
    }).toList();

    setState(() {
      _filteredShuttles = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Active Shuttles'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Route',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(
                height: 16), // Add space between search bar and results

            // Show active shuttles or a loading indicator
            _filteredShuttles.isEmpty
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()))
                : Expanded(
                    child: ListView.builder(
                      itemCount: _filteredShuttles.length,
                      itemBuilder: (context, index) {
                        final shuttle = _filteredShuttles[index];
                        final morningJourneyTime =
                            shuttle['morning_journey_time'];
                        final eveningJourneyTime =
                            shuttle['evening_journey_time'];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(
                              shuttle['route'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Driver: ${shuttle['driver_name']}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'License Plate: ${shuttle['license_plate']}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                    'Morning Journey: ${TimeOfDay.fromDateTime(morningJourneyTime.toDate()).format(context)}'),
                                Text(
                                    'Evening Journey: ${TimeOfDay.fromDateTime(eveningJourneyTime.toDate()).format(context)}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.directions_bus),
                              onPressed: () {
                                // Add your logic to handle shuttle booking or details
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
