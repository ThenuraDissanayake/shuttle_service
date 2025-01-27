import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({Key? key}) : super(key: key);

  @override
  _MyBookingsPageState createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  List<Map<String, dynamic>> ongoingBookings = [];
  List<Map<String, dynamic>> pastBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      // Fetch bookings
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('passengerName',
              isEqualTo: user.displayName) // Match passenger
          .get();

      setState(() {
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
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ongoing'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
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
                            Text(
                                'Journey Type: ${booking['journeyType'] ?? 'N/A'}'),
                            Text(
                                'Payment Method: ${booking['paymentMethod'] ?? 'N/A'}'),
                            Text('Price: LKR ${booking['price'] ?? '0.0'}'),
                            const SizedBox(height: 12),
                            Center(
                              child: _buildQRCode(booking),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () => (),
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
                            Text(
                                'Journey Type: ${booking['journeyType'] ?? 'N/A'}'),
                            Text(
                                'Payment Method: ${booking['paymentMethod'] ?? 'N/A'}'),
                            Text('Price: LKR ${booking['price'] ?? '0.0'}'),
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
