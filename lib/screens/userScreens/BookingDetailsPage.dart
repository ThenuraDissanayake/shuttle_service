import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'package:uuid/uuid.dart';

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

  Future<void> _processPayment() async {
    try {
      // Get driver's merchant details
      final driverSnapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .where('driver_name', isEqualTo: widget.driverName)
          .limit(1)
          .get();

      if (driverSnapshot.docs.isEmpty) {
        throw Exception('Driver merchant details not found');
      }

      final driverData = driverSnapshot.docs.first.data();
      final merchantId = driverData['merchantId'];
      final int capacity = driverData['shuttle']['capacity'] ?? 0;

      // Check capacity before proceeding with payment
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

      // Check capacity limits
      if (widget.journeyType == 'Morning Journey' &&
          bookingsForMorning >= capacity) {
        throw Exception('Morning journey is fully booked.');
      } else if (widget.journeyType == 'Evening Journey' &&
          bookingsForEvening >= capacity) {
        throw Exception('Evening journey is fully booked.');
      }

      if (merchantId == null) {
        throw Exception('Driver has not configured payment details');
      }

      final orderId = const Uuid().v4();

      Map paymentObject = {
        "sandbox": true,
        "merchant_id": merchantId,
        "merchant_secret": driverData['merchantSecret'],
        "notify_url": "http://sample.com/notify",
        "order_id": orderId,
        "items": "${widget.journeyType} Shuttle Service",
        "amount": widget.price,
        "currency": "LKR",
        "first_name": passengerName,
        "last_name": "",
        "email": FirebaseAuth.instance.currentUser?.email ?? "",
        "phone": widget.phone,
        "address": "",
        "city": "",
        "country": "Sri Lanka",
      };

      PayHere.startPayment(
        paymentObject,
        (paymentId) async {
          try {
            // Update booking count after successful payment
            await bookingRef.update({
              'bookings_for_morning': widget.journeyType == 'Morning Journey'
                  ? bookingsForMorning + 1
                  : bookingsForMorning,
              'bookings_for_evening': widget.journeyType == 'Evening Journey'
                  ? bookingsForEvening + 1
                  : bookingsForEvening,
            });

            await _completeBooking(orderId, paymentId);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Payment successful & booking confirmed!')),
              );
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating booking: $e')),
              );
            }
          }
        },
        (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment failed: $error')),
            );
          }
        },
        () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment cancelled')),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _completeBooking(String orderId, String paymentId) async {
    // Set status and booking state based on payment method
    final String bookingStatus =
        _selectedPaymentMethod == 'Cash' ? 'Pending' : 'Accepted';
    final String myBooking =
        _selectedPaymentMethod == 'Cash' ? 'pending' : 'ongoing';

    await FirebaseFirestore.instance.collection('bookings').add({
      'journeyType': widget.journeyType,
      'price': widget.price,
      'paymentMethod': _selectedPaymentMethod,
      'status': bookingStatus,
      'passengerName': passengerName,
      'driverName': widget.driverName,
      'orderId': orderId,
      'paymentId': paymentId,
      'my_booking': myBooking,
      'bookingDateTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _requestBooking() async {
    setState(() => isLoading = true);

    try {
      if (_selectedPaymentMethod == 'Card Payment') {
        await _processPayment();
      } else {
        // Existing cash payment logic
        await _completeBooking('cash-${const Uuid().v4()}', 'cash');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Booking request submitted successfully. Awaiting driver confirmation.')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process booking: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        // backgroundColor: Colors.green,
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
                        '👤 Passenger Name: $passengerName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '🚍 Journey: ${widget.journeyType}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '💲 Price: LKR ${widget.price}',
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '👨‍✈️ Driver Name: ${widget.driverName}',
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '📞 Phone: ${widget.phone}',
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
                        items: ['Card Payment', 'Cash']
                            .map<DropdownMenuItem<String>>(
                          (String value) {
                            String icon;

                            // Assign appropriate emojis based on the value
                            switch (value) {
                              case 'Card Payment':
                                icon = '💳'; // Card payment emoji
                                break;
                              case 'Cash':
                                icon = '💵'; // Cash emoji
                                break;
                              default:
                                icon = '❓'; // Default emoji (if needed)
                            }

                            return DropdownMenuItem<String>(
                              value: value,
                              child: Row(
                                children: [
                                  Text(icon), // Display emoji
                                  SizedBox(
                                      width: 10), // Space between icon and text
                                  Text(value),
                                ],
                              ),
                            );
                          },
                        ).toList(),
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
                          ' Reserve ',
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
