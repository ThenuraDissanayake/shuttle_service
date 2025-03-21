import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  _OwnerDashboardPageState createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  String _userName = "User"; // Default value if no name is found
  bool _isDriverDetailsComplete = true;
  String _greeting = "";

  get pendingRequests => null; // Flag to check if details are complete

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _checkDriverDetails(); // Check if driver details are submitted
    _updateGreeting();
  }

  void _updateGreeting() {
    var hour = DateTime.now().hour;
    setState(() {
      if (hour < 12) {
        _greeting = 'Good Morning';
      } else if (hour < 17) {
        _greeting = 'Good Afternoon';
      } else {
        _greeting = 'Good Evening';
      }
    });
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
          .collection('bookings')
          .where('driverName', isEqualTo: driverName)
          .where('status', isEqualTo: 'Pending')
          .get();

      int morningCount = 0;
      int eveningCount = 0;

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

  Future<void> _checkDriverDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .get();

      if (driverDoc.exists) {
        final driverData = driverDoc.data() as Map<String, dynamic>;
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
                  Navigator.pushNamed(context, '/driver-details');
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
    if (!_isDriverDetailsComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showIncompleteDriverDetailsAlert();
      });
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $_userName',
                style: const TextStyle(fontSize: 15),
              ),
              Text(
                '$_greeting!',
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, '/driver-profile');
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.white.withOpacity(0.9),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 5),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Shuttle Overview',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: [
                      FutureBuilder<String?>(
                        future: _getDriverName(),
                        builder: (context, driverSnapshot) {
                          if (driverSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (!driverSnapshot.hasData ||
                              driverSnapshot.data == null) {
                            return const Text('Driver not found');
                          }

                          return FutureBuilder<Map<String, dynamic>?>(
                            future: _fetchDriverBookings(driverSnapshot.data!),
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
                                return const Text(
                                    'No bookings data available.');
                              }

                              final bookings = bookingSnapshot.data!;
                              final morningBookings =
                                  bookings['bookings_for_morning'] ?? 0;
                              final eveningBookings =
                                  bookings['bookings_for_evening'] ?? 0;

                              return Column(
                                children: [
                                  FutureBuilder<Map<String, int>>(
                                    future: _fetchPendingRequests(),
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
                                        '$morningRequests',
                                      );
                                    },
                                  ),
                                  FutureBuilder<Map<String, int>>(
                                    future: _fetchPendingRequests(),
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
                                        '$eveningRequests',
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
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Transport Service Requests',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        _DashCard(
                          icon: Icons.event_seat,
                          title: 'Pending Cash Bookings',
                          onTap: () {
                            Navigator.pushNamed(
                                context, '/driver-booking-requests');
                          },
                        ),
                        _DashCard(
                          icon: Icons.emoji_people,
                          title: 'Special Shuttle Requests',
                          onTap: () {
                            Navigator.pushNamed(
                                context, '/view-special-shuttle');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Shuttle Operations',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        _DashCard(
                          icon: Icons.bus_alert,
                          title: 'Shuttle status / Times',
                          onTap: () {
                            Navigator.pushNamed(context, '/shuttle-management');
                          },
                        ),
                        _DashCard(
                          icon: Icons.location_on,
                          title: 'Share live Location',
                          onTap: () {
                            Navigator.pushNamed(
                                context, '/update-driver-location');
                          },
                        ),
                        const SizedBox(height: 20),
                        _DashCard(
                          icon: Icons.report,
                          title: 'Make a Complaint',
                          onTap: () {
                            Navigator.pushNamed(context, '/driver-complaints');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 0, 0, 0),
        unselectedItemColor: const Color.fromARGB(255, 191, 201, 183),
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'ShuttlePassScan',
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
              Navigator.pushNamed(context, '/driver-dashboard');
              break;
            case 1:
              Navigator.pushNamed(context, '/qr-scanner');
              break;
            case 2:
              Navigator.pushNamed(context, '/driver-notification');
              break;
            case 3:
              Navigator.pushNamed(context, '/driver-profile');
              break;
          }
        },
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildReservationCard(
      String shuttleName, String seats, String pendingRequests) {
    return Container(
      width: 300,
      height: 110,
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
              const SizedBox(height: 5),
              Text(
                seats,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 5),
              Text(
                'Cash Booking Requests: $pendingRequests',
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
      height: 80,
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: const Color.fromARGB(255, 68, 72, 68), size: 30),
              const SizedBox(width: 10),
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
