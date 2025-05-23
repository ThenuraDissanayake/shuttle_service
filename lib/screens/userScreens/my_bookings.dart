import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shuttle_service/screens/userScreens/track_driver_page.dart';
import 'dart:async';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({Key? key}) : super(key: key);

  @override
  _MyBookingsPageState createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  bool isLoading = true;
  List<Map<String, dynamic>> pendingBookings = [];
  List<Map<String, dynamic>> ongoingBookings = [];
  List<Map<String, dynamic>> pastBookings = [];
  List<Map<String, dynamic>> rejectedBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchBookings();

    // Set up timer to refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchBookings();
    });
  }

  Future<void> _fetchBookings() async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      // First, get the user's name from the passengers collection
      DocumentSnapshot passengerDoc = await FirebaseFirestore.instance
          .collection('passengers')
          .doc(user.uid) // Using the user's UID to fetch their document
          .get();

      if (!passengerDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passenger profile not found')),
        );
        return;
      }

      // Get the name from the passenger document
      String? passengerName = passengerDoc.get('name') as String?;
      if (passengerName == null || passengerName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passenger name not found')),
        );
        return;
      }

      print('Fetched Passenger Name: $passengerName'); // Debugging line

      // Query the 'bookings' collection where 'passengerName' equals the passenger's name
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('passengerName', isEqualTo: passengerName)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No bookings found for this user.');
      } else {
        print('Fetched ${snapshot.docs.length} bookings.');
      }

      // Processing the fetched bookings
      setState(() {
        pendingBookings = snapshot.docs
            .where((doc) => doc['my_booking'] == 'pending') // Filter pending
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
        ongoingBookings = snapshot.docs
            .where((doc) => doc['my_booking'] == 'ongoing') // Filter ongoing
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
        pastBookings = snapshot.docs
            .where((doc) => doc['my_booking'] == 'past') // Filter past
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
        rejectedBookings = snapshot.docs
            .where((doc) => doc['my_booking'] == 'rejected') // Filter rejected
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching bookings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching bookings: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildQRCode(Map<String, dynamic> booking) {
    final qrData = 'Booking ID: ${booking['id']}\n'
        'Passenger: ${booking['passengerName'] ?? 'N/A'}\n'
        'Driver: ${booking['driverName'] ?? 'N/A'}\n'
        'Payment Type: ${booking['paymentMethod'] ?? 'N/A'}\n'
        'Journey: ${booking['journeyType'] ?? 'N/A'}';

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          QrImageView(
            data: qrData,
            size: 200,
            backgroundColor: Colors.white,
            errorStateBuilder: (context, error) {
              return Center(
                child: Text('Error: $error'),
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Booking QR Code',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        // backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'pending'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Past'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendingBookings.length,
                  itemBuilder: (context, index) {
                    final booking = pendingBookings[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Passenger: ${booking['passengerName'] ?? 'N/A'}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text('Driver: ${booking['driverName'] ?? 'N/A'}'),
                            Text(
                                'Journey Type: ${booking['journeyType'] ?? 'N/A'}'),
                            Text(
                                'Payment Method: ${booking['paymentMethod'] ?? 'N/A'}'),
                            Text(
                                'Booking Date / Time: ${booking['bookingDateTime'] != null ? DateFormat('dd MMM yyyy, hh:mm a').format((booking['bookingDateTime'] as Timestamp).toDate()) : 'N/A'}'),
                            Text('Price: LKR ${booking['price'] ?? '0.0'}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Ongoing Bookings Tab
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ongoingBookings.length,
                  itemBuilder: (context, index) {
                    final booking = ongoingBookings[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Passenger: ${booking['passengerName'] ?? 'N/A'}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text('Driver: ${booking['driverName'] ?? 'N/A'}'),
                            Text(
                                'Journey Type: ${booking['journeyType'] ?? 'N/A'}'),
                            Text(
                                'Payment Method: ${booking['paymentMethod'] ?? 'N/A'}'),
                            Text(
                                'Booking Date / Time: ${booking['bookingDateTime'] != null ? DateFormat('dd MMM yyyy, hh:mm a').format((booking['bookingDateTime'] as Timestamp).toDate()) : 'N/A'}'),
                            Text('Price: LKR ${booking['price'] ?? '0.0'}'),
                            const SizedBox(height: 12),
                            Center(
                              child: _buildQRCode(booking),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TrackDriverPage(
                                        driverName: booking['driverName'],
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.location_on),
                                label: const Text('Track my shuttle'),
                                style: ElevatedButton.styleFrom(
                                  alignment: Alignment.center,
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Past Bookings Tab
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pastBookings.length,
                  itemBuilder: (context, index) {
                    final booking = pastBookings[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Passenger: ${booking['passengerName'] ?? 'N/A'}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text('Driver: ${booking['driverName'] ?? 'N/A'}'),
                            Text(
                                'Journey Type: ${booking['journeyType'] ?? 'N/A'}'),
                            Text(
                                'Payment Method: ${booking['paymentMethod'] ?? 'N/A'}'),
                            Text(
                                'Booking Date / Time: ${booking['bookingDateTime'] != null ? DateFormat('dd MMM yyyy, hh:mm a').format((booking['bookingDateTime'] as Timestamp).toDate()) : 'N/A'}'),
                            Text('Price: LKR ${booking['price'] ?? '0.0'}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Rejected Bookings Tab
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rejectedBookings.length,
                  itemBuilder: (context, index) {
                    final booking = rejectedBookings[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Passenger: ${booking['passengerName'] ?? 'N/A'}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text('Driver: ${booking['driverName'] ?? 'N/A'}'),
                            Text(
                                'Journey Type: ${booking['journeyType'] ?? 'N/A'}'),
                            Text(
                                'Payment Method: ${booking['paymentMethod'] ?? 'N/A'}'),
                            Text(
                                'Booking Date / Time: ${booking['bookingDateTime'] != null ? DateFormat('dd MMM yyyy, hh:mm a').format((booking['bookingDateTime'] as Timestamp).toDate()) : 'N/A'}'),
                            Text('Price: LKR ${booking['price'] ?? '0.0'}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        // backgroundColor: const Color.fromARGB(255, 184, 245, 186),
        selectedItemColor: const Color.fromARGB(255, 0, 0, 0),
        unselectedItemColor: const Color.fromARGB(255, 191, 201, 183),
        currentIndex: 1, // Default active tab
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_seat),
            label: 'My Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded),
            label: 'Account',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/passenger-dashboard');
              break;
            case 1:
              Navigator.pushNamed(context, '/my-bookings');
              break;
            case 2:
              Navigator.pushNamed(context, '/passenger-notifications');

              break;
            case 3:
              Navigator.pushNamed(context, '/passenger-profile');
              break;
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }
}
