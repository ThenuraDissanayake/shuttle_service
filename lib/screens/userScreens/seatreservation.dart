import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shuttle_service/screens/userScreens/shuttledetails.dart';

class FindActiveShuttlesPage extends StatefulWidget {
  const FindActiveShuttlesPage({Key? key}) : super(key: key);

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
          .collection('drivers') // Replace with your collection name
          .where('shuttle.status', isEqualTo: 'Active')
          .get();

      // Convert querySnapshot to list of shuttles
      final activeShuttles = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return {
          'shuttle_id': doc.id,
          'route': data['shuttle']['route'] ?? 'Unknown Route',
          'driver_name': data['driver_name'] ?? 'Unknown Driver',
          'license_plate': data['shuttle']['license_plate'] ?? 'Unknown Plate',
          'morning_journey_time': data['morning_journey_time'] ??
              Timestamp.fromDate(DateTime.now()),
          'evening_journey_time': data['evening_journey_time'] ??
              Timestamp.fromDate(DateTime.now().add(const Duration(hours: 12))),
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
      final route = (shuttle['route'] as String).toLowerCase();
      final searchQuery = query.toLowerCase();
      return route.contains(searchQuery);
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
                suffixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(
                height: 16), // Add space between search bar and results

            // Show active shuttles or a loading indicator
            _filteredShuttles.isEmpty
                ? const Expanded(
                    child: Center(child: Text('No active shuttles found.')),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: _filteredShuttles.length,
                      itemBuilder: (context, index) {
                        final shuttle = _filteredShuttles[index];
                        final morningJourneyTime =
                            shuttle['morning_journey_time'] as Timestamp;
                        final eveningJourneyTime =
                            shuttle['evening_journey_time'] as Timestamp;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(
                              shuttle['route'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Driver: ${shuttle['driver_name']}'),
                                Text(
                                    'License Plate: ${shuttle['license_plate']}'),
                                Text(
                                    'Morning Journey: ${_formatTimestamp(morningJourneyTime, context)}'),
                                Text(
                                    'Evening Journey: ${_formatTimestamp(eveningJourneyTime, context)}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.ads_click),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShuttleDetailsPage(
                                      shuttleId: shuttle['shuttle_id'],
                                    ),
                                  ),
                                );
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

  String _formatTimestamp(Timestamp timestamp, BuildContext context) {
    try {
      final date = timestamp.toDate();
      return TimeOfDay.fromDateTime(date).format(context);
    } catch (e) {
      return 'Invalid Time';
    }
  }
}
