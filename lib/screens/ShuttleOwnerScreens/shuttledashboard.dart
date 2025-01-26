import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shuttleManagement.dart';
import 'reservations_overview_page.dart';
import 'booking_requests_management.dart';
import 'driver_pro.dart';
import 'Driver_userProfile.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  _OwnerDashboardPageState createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  String _userName = "User"; // Default value if no name is found
  bool _isDriverDetailsComplete = true;

  get pendingRequests => null; // Flag to check if details are complete

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _checkDriverDetails(); // Check if driver details are submitted
  }

  Future<Map<String, int>> _fetchPendingRequests() async {
    try {
      final driverName = await _getDriverName(); // Fetch the driver's name

      if (driverName == null) {
        return {
          'morning': 0,
          'evening': 0
        }; // No driver found, return 0 for both
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection(
              'bookings') // Assuming your collection is named "bookings"
          .where('driverName', isEqualTo: driverName)
          .where('status', isEqualTo: 'Pending')
          .get();

      int morningCount = 0;
      int eveningCount = 0;

      // Loop through the documents and count morning and evening bookings
      querySnapshot.docs.forEach((doc) {
        final journeyType = doc['journeyType'];
        if (journeyType == 'Morning Journey') {
          morningCount++;
        } else if (journeyType == 'Evening Journey') {
          eveningCount++;
        }
      });

      return {'morning': morningCount, 'evening': eveningCount};
    } catch (e) {
      print("Error fetching pending requests: $e");
      return {'morning': 0, 'evening': 0};
    }
  }

  // Fetch the user's name from Firestore
  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('owners')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userName = userData['name'] ?? 'User';
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<Map<String, dynamic>?> _fetchDriverBookings(String driverName) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection(
              'driver_bookings') // Assuming your collection is named "driver_bookings"
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

  Future<String?> _getDriverName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot driverDoc = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(user.uid)
            .get();

        if (driverDoc.exists) {
          return driverDoc.get('driver_name');
        }
      } catch (e) {
        debugPrint('Error fetching driver name: $e');
      }
    }
    return null;
  }

  // Check if the driver details are submitted
  Future<void> _checkDriverDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .get();

      if (driverDoc.exists) {
        final driverData = driverDoc.data() as Map<String, dynamic>;

        // Check if the required fields are filled
        if (driverData['shuttle'] == null ||
            driverData['shuttle']['license_plate'] == null ||
            driverData['shuttle']['capacity'] == null ||
            driverData['shuttle']['route'] == null ||
            driverData['phone'] == null) {
          setState(() {
            _isDriverDetailsComplete = false;
          });
        } else {
          setState(() {
            _isDriverDetailsComplete = true;
          });
        }
      } else {
        setState(() {
          _isDriverDetailsComplete = false;
        });
      }
    }
  }

  // Show a dialog if driver details are not complete
  void _showIncompleteDriverDetailsAlert() {
    if (!_isDriverDetailsComplete) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Driver Details Required'),
            content: const Text(
                'It looks like you haven\'t submitted your driver details. Please fill in your information.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DriverDetailsPage()),
                  );
                },
                child: const Text('Go to Driver Details'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show the alert only if driver details are incomplete
    if (!_isDriverDetailsComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showIncompleteDriverDetailsAlert();
      });
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green,
        title: Align(
          alignment: Alignment.centerLeft, // Align title to the left
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align text to the left
            children: [
              Text(
                'Hi, $_userName',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15), // Set text color to white
              ),
              const Text(
                'Welcome to UniShuttle',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18), // Set text color to white
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // Navigate to User Profile screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfilePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // const Padding(
              //   padding: EdgeInsets.symmetric(vertical: 20.0),
              //   child: Column(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Icon(
              //         Icons.directions_bus,
              //         color: Colors.green,
              //         size: 50,
              //       ),
              //       SizedBox(
              //           height: 10), // Adds space between the icon and text
              //       Text(
              //         'UniShuttle',
              //         style: TextStyle(
              //           fontSize: 32,
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 5),
              // const Align(
              //   alignment: Alignment.centerLeft, // Aligns the text to the left
              //   child: Text(
              //     'Morning Journey',
              //     style: TextStyle(fontSize: 24),
              //   ),
              // ),
              const Align(
                alignment: Alignment.centerLeft, // Aligns the text to the left
                child: Text(
                  'Shuttle Overview',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              // ListView(
              //   physics:
              //       const NeverScrollableScrollPhysics(), // Prevent nested scroll
              //   shrinkWrap: true, // Adjust to fit the content
              //   children: [
              //     _buildReservationCard(
              //       'Morning Journey',
              //       '',
              //       '20 seats reserved',
              //     ),
              //   ],
              // ),

              // const SizedBox(height: 10),

              // // const Text('Evening Journey', style: TextStyle(fontSize: 24)),
              // ListView(
              //   physics:
              //       const NeverScrollableScrollPhysics(), // Prevent nested scroll
              //   shrinkWrap: true, // Adjust to fit the content
              //   children: [
              //     _buildReservationCard(
              //         'Evening Journey', '', '20 seats reserved'),
              //   ],
              // ),

              // ListView(
              //   physics:
              //       const NeverScrollableScrollPhysics(), // Prevent nested scroll
              //   shrinkWrap: true, // Adjust to fit the content
              //   children: [
              //     FutureBuilder<String?>(
              //       future: _getDriverName(), // Fetch the driver name
              //       builder: (context, driverSnapshot) {
              //         if (driverSnapshot.connectionState ==
              //             ConnectionState.waiting) {
              //           return const Center(child: CircularProgressIndicator());
              //         }

              //         if (!driverSnapshot.hasData ||
              //             driverSnapshot.data == null) {
              //           return const Text('Driver not found');
              //         }

              //         return FutureBuilder<Map<String, dynamic>?>(
              //           future: _fetchDriverBookings(
              //               driverSnapshot.data!), // Fetch bookings
              //           builder: (context, bookingSnapshot) {
              //             if (bookingSnapshot.connectionState ==
              //                 ConnectionState.waiting) {
              //               return const Center(
              //                   child: CircularProgressIndicator());
              //             }

              //             if (bookingSnapshot.hasError) {
              //               return Text(
              //                   'Error fetching bookings: ${bookingSnapshot.error}');
              //             }

              //             if (!bookingSnapshot.hasData ||
              //                 bookingSnapshot.data == null) {
              //               return const Text('No bookings data available.');
              //             }

              //             // Extract morning and evening booking counts
              //             final bookings = bookingSnapshot.data!;
              //             final morningBookings =
              //                 bookings['bookings_for_morning'] ?? 0;
              //             final eveningBookings =
              //                 bookings['bookings_for_evening'] ?? 0;

              //             return Column(
              //               children: [
              //                 _buildReservationCard(
              //                   'Morning Journey',
              //                   'Journey details for the morning',
              //                   '$morningBookings seats reserved',
              //                 ),
              //                 _buildReservationCard(
              //                   'Evening Journey',
              //                   'Journey details for the evening',
              //                   '$eveningBookings seats reserved',
              //                 ),
              //               ],
              //             );
              //           },
              //         );
              //       },
              //     ),
              //   ],
              // ),

              ListView(
                physics:
                    const NeverScrollableScrollPhysics(), // Prevent nested scroll
                shrinkWrap: true, // Adjust to fit the content
                children: [
                  FutureBuilder<String?>(
                    future: _getDriverName(), // Fetch the driver name
                    builder: (context, driverSnapshot) {
                      if (driverSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!driverSnapshot.hasData ||
                          driverSnapshot.data == null) {
                        return const Text('Driver not found');
                      }

                      return FutureBuilder<Map<String, dynamic>?>(
                        future: _fetchDriverBookings(
                            driverSnapshot.data!), // Fetch bookings
                        builder: (context, bookingSnapshot) {
                          if (bookingSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (bookingSnapshot.hasError) {
                            return Text(
                                'Error fetching bookings: ${bookingSnapshot.error}');
                          }

                          if (!bookingSnapshot.hasData ||
                              bookingSnapshot.data == null) {
                            return const Text('No bookings data available.');
                          }

                          // Extract morning and evening booking counts
                          final bookings = bookingSnapshot.data!;
                          final morningBookings =
                              bookings['bookings_for_morning'] ?? 0;
                          final eveningBookings =
                              bookings['bookings_for_evening'] ?? 0;

                          return Column(
                            children: [
                              // Morning Journey Card with Pending Requests
                              FutureBuilder<Map<String, int>>(
                                future:
                                    _fetchPendingRequests(), // Fetch the pending requests
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }

                                  if (snapshot.hasError) {
                                    return Text(
                                        'Error fetching pending requests: ${snapshot.error}');
                                  }

                                  if (!snapshot.hasData) {
                                    return const Text(
                                        'No pending requests data available.');
                                  }

                                  final morningRequests =
                                      snapshot.data!['morning'] ?? 0;

                                  return _buildReservationCard(
                                    'Morning Journey',
                                    '$morningBookings seats reserved',
                                    '$morningRequests', // Pass pending requests here
                                  );
                                },
                              ),

                              // Evening Journey Card with Pending Requests
                              FutureBuilder<Map<String, int>>(
                                future:
                                    _fetchPendingRequests(), // Fetch the pending requests
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }

                                  if (snapshot.hasError) {
                                    return Text(
                                        'Error fetching pending requests: ${snapshot.error}');
                                  }

                                  if (!snapshot.hasData) {
                                    return const Text(
                                        'No pending requests data available.');
                                  }

                                  final eveningRequests =
                                      snapshot.data!['evening'] ?? 0;

                                  return _buildReservationCard(
                                    'Evening Journey',
                                    '$eveningBookings seats reserved',
                                    '$eveningRequests', // Pass pending requests here
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Align(
                alignment: Alignment.centerLeft, // Aligns the text to the left
                child: Text(
                  'Shuttle Oprations',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    _DashCard(
                      icon: Icons.bus_alert,
                      title: 'Shuttle status',
                      onTap: () {
                        // Navigate to shuttle reservation page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ShuttleManagementPage(), // Replace with your destination page
                          ),
                        );
                      },
                    ),
                    _DashCard(
                      icon: Icons.emoji_people,
                      title: 'Requests',
                      onTap: () {
                        // Navigate to special shuttle request page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const BookingRequestsPage(), // Replace with your destination page
                          ),
                        );
                      },
                    ),
                    _DashCard(
                      icon: Icons.event_seat,
                      title: 'Reservation Overview',
                      onTap: () {
                        // Navigate to my shuttle list page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ReservationsOverviewPage(), // Replace with your destination page
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // FutureBuilder<String?>(
              //   future: _getDriverName(),
              //   builder: (context, driverSnapshot) {
              //     if (driverSnapshot.connectionState ==
              //         ConnectionState.waiting) {
              //       return const CircularProgressIndicator();
              //     }

              //     if (!driverSnapshot.hasData || driverSnapshot.data == null) {
              //       return const Text('Driver not found');
              //     }

              //     return FutureBuilder<Map<String, dynamic>?>(
              //       future: _fetchDriverBookings(driverSnapshot.data!),
              //       builder: (context, bookingSnapshot) {
              //         if (bookingSnapshot.connectionState ==
              //             ConnectionState.waiting) {
              //           return const CircularProgressIndicator();
              //         }

              //         if (bookingSnapshot.hasError) {
              //           return Text(
              //               'Error fetching bookings: ${bookingSnapshot.error}');
              //         }

              //         if (!bookingSnapshot.hasData ||
              //             bookingSnapshot.data == null) {
              //           return const Text('No bookings data available.');
              //         }

              //         final bookings = bookingSnapshot.data!;
              //         final morningBookings =
              //             bookings['bookings_for_morning'] ?? 0;
              //         final eveningBookings =
              //             bookings['bookings_for_evening'] ?? 0;

              //         return Column(
              //           children: [
              //             Text('Driver: ${driverSnapshot.data}'),
              //             Text('Morning Bookings: $morningBookings'),
              //             Text('Evening Bookings: $eveningBookings'),
              //           ],
              //         );
              //       },
              //     );
              //   },
              // ),

              // Fetch bookings and show number of bookings for morning and evening journeys

              // GestureDetector(
              //   onTap: () {
              //     // Navigator.push(
              //     //   context,
              //     //   MaterialPageRoute(
              //     //     builder: (context) =>
              //     //         const ShuttleStatusPage(), // Replace with your destination page
              //     //   ),
              //     // );
              //   },
              //   child: const Text(
              //     'Shuttle Status Overview',
              //     style: TextStyle(fontSize: 24),
              //   ),
              // ),
              // Row(
              //   children: [
              //     _buildStatusCard('Shuttle 1', 'Available'),
              //   ],
              // ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      // Bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.green,
        selectedItemColor: const Color.fromARGB(255, 0, 0, 0),
        unselectedItemColor: const Color.fromARGB(255, 255, 255, 255),
        currentIndex: 0, // Default active tab
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize),
            label: 'Shuttle Operations',
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OwnerDashboardPage(),
                ),
              );
              break;
            case 1:
              // Navigate to Activities page
              break;
            case 2:
              // Navigate to Notifications page
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfilePage(),
                ),
              );
              break;
          }
        },
        selectedLabelStyle: TextStyle(fontSize: 12), // Adjust font size
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
    );
  }

  // Widget _buildStatusCard(String shuttleName, String status) {
  //   return Card(
  //     elevation: 5,
  //     margin: const EdgeInsets.all(8),
  //     child: Padding(
  //       padding: const EdgeInsets.all(10),
  //       child: Column(
  //         children: [
  //           Text(shuttleName,
  //               style:
  //                   const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  //           Text(status, style: const TextStyle(fontSize: 16)),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildReservationCard(String shuttleName, String time, String seats) {
  //   return Card(
  //     elevation: 5,
  //     margin: const EdgeInsets.all(8),
  //     child: Padding(
  //       padding: const EdgeInsets.all(10),
  //       child: Column(
  //         children: [
  //           Text(shuttleName,
  //               style:
  //                   const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  //           Text('Pending Requests: $pendingRequests',
  //               style: const TextStyle(fontSize: 16)),
  //           Text(seats, style: const TextStyle(fontSize: 16)),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildReservationCard(
      String shuttleName, String seats, String pendingRequests) {
    return Container(
      width: 300, // Set a specific width
      height: 110, // Adjusted height to fit both lines of text
      margin: const EdgeInsets.all(8),
      child: Card(
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                shuttleName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                  height: 1), // Adds space between shuttle name and details
              Text(
                seats,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(
                  height: 1), // Adds space between seats and pending requests
              Text(
                'Pending Requests: $pendingRequests',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _DashCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 80, // Adjust the height
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center, // Centers content horizontally
            children: [
              Icon(icon,
                  color: const Color.fromARGB(255, 68, 72, 68), size: 30),
              const SizedBox(width: 10), // Spacing between icon and text
              Text(
                title,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
