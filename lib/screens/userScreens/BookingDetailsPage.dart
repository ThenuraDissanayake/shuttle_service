import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingDetailsPage extends StatefulWidget {
  final String journeyType; // Morning or Evening
  final String price;
  final String driverName;
  final String phone;

  const BookingDetailsPage({
    Key? key,
    required this.journeyType,
    required this.price,
    required this.driverName,
    required this.phone,
  }) : super(key: key);

  @override
  _BookingDetailsPageState createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  String _selectedPaymentMethod = 'Card Payment';
  String passengerName = 'User';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPassengerName();
  }

  Future<void> _fetchPassengerName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('passengers')
            .doc(user.uid)
            .get();

        if (snapshot.exists) {
          setState(() {
            passengerName = snapshot['name'] ?? 'User';
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passenger record not found.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch passenger name: $e')),
      );
    }
  }

  Future<void> _requestBooking() async {
    setState(() {
      isLoading = true;
    });

    try {
      final driverSnapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .where('driver_name', isEqualTo: widget.driverName)
          .limit(1)
          .get();

      if (driverSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver not found.')),
        );
        return;
      }

      final driverData = driverSnapshot.docs.first.data();
      final int capacity = driverData['shuttle']['capacity'] ?? 0;

      final bookingRef = FirebaseFirestore.instance
          .collection('driver_bookings')
          .doc(widget.driverName);

      final bookingSnapshot = await bookingRef.get();

      if (!bookingSnapshot.exists) {
        await bookingRef.set({
          'driver_name': widget.driverName,
          'bookings_for_morning': 0,
          'bookings_for_evening': 0,
        });
      }

      final bookingData = (await bookingRef.get()).data()!;
      int bookingsForMorning = bookingData['bookings_for_morning'] ?? 0;
      int bookingsForEvening = bookingData['bookings_for_evening'] ?? 0;

      if (widget.journeyType == 'Morning Journey' &&
          bookingsForMorning >= capacity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Morning journey is fully booked.')),
        );
      } else if (widget.journeyType == 'Evening Journey' &&
          bookingsForEvening >= capacity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evening journey is fully booked.')),
        );
      } else {
        await bookingRef.update({
          'bookings_for_morning': widget.journeyType == 'Morning Journey'
              ? bookingsForMorning + 1
              : bookingsForMorning,
          'bookings_for_evening': widget.journeyType == 'Evening Journey'
              ? bookingsForEvening + 1
              : bookingsForEvening,
        });

        await FirebaseFirestore.instance.collection('bookings').add({
          'journeyType': widget.journeyType,
          'price': widget.price,
          'paymentMethod': _selectedPaymentMethod,
          'status': 'Pending',
          'passengerName': passengerName,
          'driverName': widget.driverName,
          'phone': widget.phone,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request sent successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to request booking: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Passenger Name: $passengerName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Journey: ${widget.journeyType}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Price: LKR ${widget.price}',
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Driver Name: ${widget.driverName}',
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Phone: ${widget.phone}',
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select Payment Method:',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: _selectedPaymentMethod,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedPaymentMethod = newValue!;
                          });
                        },
                        items: ['Card Payment', 'Bank Transfer', 'Cash']
                            .map<DropdownMenuItem<String>>(
                              (String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _requestBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Green
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Request Booking',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
