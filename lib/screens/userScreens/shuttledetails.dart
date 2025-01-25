import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShuttleDetailsPage extends StatelessWidget {
  final String shuttleId;

  const ShuttleDetailsPage({Key? key, required this.shuttleId})
      : super(key: key);

  Future<Map<String, dynamic>?> _fetchShuttleDetails() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('drivers') // Ensure this matches your Firestore structure
          .doc(shuttleId)
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
    } catch (e) {
      debugPrint('Error fetching shuttle details: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shuttle Details'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchShuttleDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Shuttle not found.'),
            );
          } else {
            final shuttle = snapshot.data!;
            final driverName = shuttle['driver_name'] ?? 'Unknown Driver';
            final licensePlate =
                shuttle['shuttle']?['license_plate'] ?? 'Unknown License Plate';
            final shuttleType =
                shuttle['shuttle']?['shuttle_type'] ?? 'Unknown Type';
            final route = shuttle['shuttle']?['route'] ?? 'Unknown Route';
            final capacity = shuttle['shuttle']?['capacity'] ?? 0;
            final List<String> mainStops =
                List<String>.from(shuttle['shuttle']?['main_stops'] ?? []);
            final price =
                shuttle['shuttle']?['full_journey_price']?.toString() ?? 'N/A';
            final morningJourneyTime = shuttle['morning_journey_time'];
            final eveningJourneyTime = shuttle['evening_journey_time'];

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildSectionTitle('Driver Details'),
                      Text('Driver Name: $driverName'),
                      const SizedBox(height: 8),
                      Text('Phone: ${shuttle['phone'] ?? 'Unknown'}'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Shuttle Details'),
                      Text('Shuttle Type: $shuttleType'),
                      Text('License Plate: $licensePlate'),
                      Text('Capacity: $capacity'),
                      Text('Route: $route'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Price'),
                      Text('LKR: $price'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Main Stops'),
                      mainStops.isEmpty
                          ? const Text('No stops available.')
                          : Column(
                              children: mainStops.map((stop) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.place, size: 20),
                                      const SizedBox(width: 8),
                                      Text(stop),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Journey Times'),
                      const SizedBox(height: 24),
                      if (morningJourneyTime != null)
                        Text(
                          'Morning Journey: ${_formatTimestamp(morningJourneyTime, context)}',
                        ),

                      // Book Now Button
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Implement booking logic
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Reserve Now',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (eveningJourneyTime != null)
                        Text(
                          'Evening Journey: ${_formatTimestamp(eveningJourneyTime, context)}',
                        ),
                      // const SizedBox(height: 24),
                      // Book Now Button
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Implement booking logic
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Reserve Now',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp, BuildContext context) {
    try {
      final date = (timestamp as Timestamp).toDate();
      return TimeOfDay.fromDateTime(date).format(context);
    } catch (e) {
      return 'Invalid Time';
    }
  }
}
