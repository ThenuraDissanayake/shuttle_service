import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shuttle_service/screens/userScreens/BookingDetailsPage.dart';

class ShuttleDetailsPage extends StatefulWidget {
  final String shuttleId;

  const ShuttleDetailsPage({Key? key, required this.shuttleId})
      : super(key: key);

  @override
  _ShuttleDetailsPageState createState() => _ShuttleDetailsPageState();
}

class _ShuttleDetailsPageState extends State<ShuttleDetailsPage> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favoriteDoc = await FirebaseFirestore.instance
        .collection('user_favorites')
        .doc(user.uid)
        .collection('shuttles')
        .doc(widget.shuttleId)
        .get();

    setState(() {
      _isFavorite = favoriteDoc.exists;
    });
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add favorites')),
      );
      return;
    }

    final favoriteRef = FirebaseFirestore.instance
        .collection('user_favorites')
        .doc(user.uid)
        .collection('shuttles')
        .doc(widget.shuttleId);

    try {
      if (_isFavorite) {
        // Remove from favorites
        await favoriteRef.delete();
        setState(() {
          _isFavorite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites')),
        );
      } else {
        // Add to favorites
        await favoriteRef.set({
          'shuttleId': widget.shuttleId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        setState(() {
          _isFavorite = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to favorites')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<Map<String, dynamic>?> _fetchShuttleDetails() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(widget.shuttleId)
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
    } catch (e) {
      debugPrint('Error fetching shuttle details: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchDriverBookings(String driverName) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('driver_bookings')
          .where('driver_name', isEqualTo: driverName)
          .limit(1)
          .get();

      if (docSnapshot.docs.isNotEmpty) {
        return docSnapshot.docs.first.data();
      }
    } catch (e) {
      debugPrint('Error fetching driver bookings: $e');
    }
    return null;
  }

  // Function to check if booking should be allowed based on journey time
  bool _isReservationAllowed(Timestamp? journeyTime) {
    if (journeyTime == null) return false;

    final now = DateTime.now();
    final journeyDateTime = journeyTime.toDate();

    // Create DateTime for today with the same time as the journey
    final todayJourneyTime = DateTime(now.year, now.month, now.day,
        journeyDateTime.hour, journeyDateTime.minute);

    // Calculate the cutoff time (2 hours before journey)
    final cutoffTime = todayJourneyTime.subtract(const Duration(hours: 2));

    // Get current hour for 8 PM check
    final currentHour = now.hour;

    // After 8 PM (20:00), allow reservations for next day
    if (currentHour >= 20) {
      return true;
    }

    // Check if current time is before the cutoff time
    return now.isBefore(cutoffTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shuttle Details'),
        // backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
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

            // Check if reservations are allowed for morning and evening journeys
            final morningReservationAllowed =
                _isReservationAllowed(morningJourneyTime);
            final eveningReservationAllowed =
                _isReservationAllowed(eveningJourneyTime);

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildSectionTitle('Driver Details'),
                      Text('👤 Driver Name: $driverName'),
                      const SizedBox(height: 8),
                      Text('📞 Phone: ${shuttle['phone'] ?? 'Unknown'}'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Shuttle Details'),
                      Text('🚌 Shuttle Type: $shuttleType'),
                      Text('🔖 License Plate: $licensePlate'),
                      Text('🪑 Capacity: $capacity'),
                      Text('🚦 Route: $route'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('💲 Price'),
                      Text('LKR: $price'),
                      const SizedBox(height: 16),
                      _buildSectionTitle('📍 Main Stops'),
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
                          '🕗 Morning Journey: ${_formatTimestamp(morningJourneyTime, context)}',
                        ),

                      // Fetch bookings and show number of bookings for morning and evening journeys
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _fetchDriverBookings(driverName),
                        builder: (context, bookingSnapshot) {
                          if (bookingSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (bookingSnapshot.hasError) {
                            return Text(
                                'Error fetching bookings: ${bookingSnapshot.error}');
                          } else if (!bookingSnapshot.hasData ||
                              bookingSnapshot.data == null) {
                            return const Text('No bookings data available.');
                          } else {
                            final bookings = bookingSnapshot.data!;
                            final morningBookings =
                                bookings['bookings_for_morning'] ?? 0;
                            final eveningBookings =
                                bookings['bookings_for_evening'] ?? 0;

                            return Column(
                              children: [
                                Text('Bookings: $morningBookings / $capacity'),
                              ],
                            );
                          }
                        },
                      ),

                      // Morning Journey Reserve Now Button with Unique ID
                      ElevatedButton(
                        onPressed: morningReservationAllowed
                            ? () {
                                final uniqueId =
                                    'reserve_${widget.shuttleId}_morning';
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookingDetailsPage(
                                      journeyType: 'Morning Journey',
                                      price: price,
                                      driverName: driverName,
                                      phone: shuttle['phone'] ?? 'Unknown',
                                    ),
                                  ),
                                );
                              }
                            : null, // Disable button if not allowed
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          // Button will be greyed out automatically when onPressed is null
                        ),
                        child: const Text(
                          'Reserve Now',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (eveningJourneyTime != null)
                        Text(
                          '🕗 Evening Journey: ${_formatTimestamp(eveningJourneyTime, context)}',
                        ),

                      // Fetch bookings and show number of bookings for evening journeys
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _fetchDriverBookings(driverName),
                        builder: (context, bookingSnapshot) {
                          if (bookingSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (bookingSnapshot.hasError) {
                            return Text(
                                'Error fetching bookings: ${bookingSnapshot.error}');
                          } else if (!bookingSnapshot.hasData ||
                              bookingSnapshot.data == null) {
                            return const Text('No bookings data available.');
                          } else {
                            final bookings = bookingSnapshot.data!;
                            final eveningBookings =
                                bookings['bookings_for_evening'] ?? 0;

                            return Column(
                              children: [
                                Text(' Bookings: $eveningBookings / $capacity'),
                              ],
                            );
                          }
                        },
                      ),

                      // Evening Journey Reserve Now Button with Unique ID
                      ElevatedButton(
                        onPressed: eveningReservationAllowed
                            ? () {
                                final uniqueId =
                                    'reserve_${widget.shuttleId}_evening';
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookingDetailsPage(
                                      journeyType: 'Evening Journey',
                                      price: price,
                                      driverName: driverName,
                                      phone: shuttle['phone'] ?? 'Unknown',
                                    ),
                                  ),
                                );
                              }
                            : null, // Disable button if not allowed
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          // Button will be greyed out automatically when onPressed is null
                        ),
                        child: const Text(
                          'Reserve Now ',
                          style: TextStyle(fontSize: 12, color: Colors.white),
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
