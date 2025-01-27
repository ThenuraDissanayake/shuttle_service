import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingRequestsPage extends StatefulWidget {
  const BookingRequestsPage({Key? key}) : super(key: key);

  @override
  _BookingRequestsPageState createState() => _BookingRequestsPageState();
}

class _BookingRequestsPageState extends State<BookingRequestsPage> {
  List<Map<String, dynamic>> bookingRequests = [];
  bool isLoading = true;
  String? driverName;

  // Fetch the current driver's name based on their user ID
  Future<void> _fetchDriverName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      // Retrieve driver details from the 'drivers' collection
      DocumentSnapshot driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .get();

      if (driverDoc.exists) {
        setState(() {
          driverName = driverDoc['driver_name']; // Assuming driver_name exists
        });
        _fetchBookingRequests(); // Fetch bookings after getting the driver's name
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver information not found')),
        );
        setState(() {
          isLoading = false; // Stop loading if the driver is not found
        });
      }
    } catch (e) {
      print('Error fetching driver name: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching driver name: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch booking requests for the current driver
  Future<void> _fetchBookingRequests() async {
    if (driverName == null) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('driverName', isEqualTo: driverName) // Filter by driver name
          .where('status', isEqualTo: 'Pending') // Only fetch pending requests
          .get();

      setState(() {
        bookingRequests = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
        isLoading = false; // Stop loading once data is fetched
      });
    } catch (e) {
      print('Error fetching booking requests: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching bookings: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

// Handle the booking request (Accept or Reject)
  Future<void> _handleBooking(String bookingId, String status) async {
    try {
      // If the status is "Accepted", also update the 'my_booking' field to 'ongoing'
      Map<String, dynamic> updateData = {'status': status};

      if (status == 'Accepted') {
        updateData['my_booking'] = 'ongoing'; // Set 'my_booking' to 'ongoing'
      }

      // Update the booking document
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking $status successfully!')),
      );

      // Refresh the booking requests after handling
      _fetchBookingRequests();
    } catch (e) {
      print('Error updating booking status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating booking status: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDriverName(); // Fetch the driver's name when the screen loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Booking Requests'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookingRequests.isEmpty
              ? const Center(child: Text('No booking requests available.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookingRequests.length,
                  itemBuilder: (context, index) {
                    final request = bookingRequests[index];

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Passenger: ${request['passengerName']}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text('Journey Type: ${request['journeyType']}'),
                            // Text('Price: LKR ${request['price']}'),
                            Text('Payment Method: ${request['paymentMethod']}'),
                            // Text('Phone: ${request['phone']}'),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () =>
                                      _handleBooking(request['id'], 'Accepted'),
                                  child: const Text('Accept'),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _handleBooking(request['id'], 'Rejected'),
                                  child: const Text('Reject'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
