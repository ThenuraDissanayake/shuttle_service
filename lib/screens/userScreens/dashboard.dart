import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shuttle_service/screens/userScreens/complaints.dart';
import 'package:shuttle_service/screens/userScreens/favouritepages.dart';
import 'package:shuttle_service/screens/userScreens/special_requests.dart';
import 'package:shuttle_service/screens/userScreens/my_bookings.dart';
import 'seatreservation.dart';
import 'userProfile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = "User"; // Default name if no data is found

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  // Fetch the user's name from Firestore
  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch from 'passengers' collection
        final userDoc = await FirebaseFirestore.instance
            .collection('passengers')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          // Cast to a Map to access fields
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userName = userData['name'] ?? 'User';
          });
        } else {
          print("No user data found in 'passengers' collection.");
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
                'Welcome',
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
      body: Column(
        children: [
          // UniShuttle logo with bus icon

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_bus,
                  color: Colors.green,
                  size: 50,
                ),
                SizedBox(height: 10), // Adds space between the icon and text
                Text(
                  'UniShuttle',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Buttons for various actions
          // Expanded(
          //   child: GridView.count(
          //     crossAxisCount: 2,
          //     padding: const EdgeInsets.all(20.0),
          //     crossAxisSpacing: 5.0,
          //     mainAxisSpacing: 5.0,
          //     children: [
          //       _buildDashboardButton(context, Icons.event_seat, 'Book a Seat',
          //           () {
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //             builder: (context) => const SeatReservationPage(),
          //           ),
          //         );
          //       }),
          //       _buildDashboardButton(context, Icons.map, 'Track Shuttle', () {
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //             builder: (context) => const ShuttleTrackingMapPage(),
          //           ),
          //         );
          //       }),
          //       _buildDashboardButton(
          //           context, Icons.notifications, 'Notifications', () {
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //             builder: (context) => const NotificationsPage(),
          //           ),
          //         );
          //       }),
          //       _buildDashboardButton(context, Icons.history, 'My Bookings',
          //           () {
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //             builder: (context) => const BookingHistoryPage(),
          //           ),
          //         );
          //       }),
          //       _buildDashboardButton(context, Icons.feedback, 'Feedback', () {
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(
          //             builder: (context) => const FeedbackPage(),
          //           ),
          //         );
          //       }),
          //       _buildDashboardButton(
          //           context, Icons.settings, 'Profile Settings', () {}),
          //     ],
          //   ),
          // ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                _DashCard01(
                  icon: Icons.event_seat,
                  title: 'Reserve a Shuttle',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FindActiveShuttlesPage(),
                      ),
                    );
                    // Navigate to shuttle reservation page
                  },
                ),
                _DashCard(
                  icon: Icons.bookmark,
                  title: 'My Shuttle List',
                  onTap: () {
                    // Navigate to my shuttle list page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoritesPage(),
                      ),
                    );
                  },
                ),
                _DashCard(
                  icon: Icons.emoji_people,
                  title: 'Request for Special Shuttle',
                  onTap: () {
                    // Navigate to special shuttle request page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SpecialShuttleRequestPage(),
                      ),
                    );
                  },
                ),
                _DashCard(
                  icon: Icons.report,
                  title: 'Make a complaint',
                  onTap: () {
                    // Navigate to complaint page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PassengerComplaintPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const Spacer(),

          // Search bar at the bottom
          // Padding(
          //   padding: const EdgeInsets.all(20.0),
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: TextField(
          //           decoration: InputDecoration(
          //             hintText: 'Search for shuttle',
          //             border: OutlineInputBorder(
          //               borderRadius: BorderRadius.circular(20),
          //             ),
          //             filled: true,
          //             fillColor: Colors.white,
          //           ),
          //         ),
          //       ),
          //       const SizedBox(width: 10),
          //       IconButton(
          //         icon: const Icon(Icons.search),
          //         onPressed: () {
          //           // Handle search action
          //         },
          //       ),
          //     ],
          //   ),
          // ),
        ],
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              );
              break;
            case 1:
              // Navigate to Activities page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyBookingsPage(),
                ),
              );
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
      ),
    );
  }

  // Widget _buildDashboardButton(
  //     BuildContext context, IconData icon, String label, VoidCallback onTap) {
  //   return ElevatedButton(
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: Colors.white, // Button color
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(20),
  //       ),
  //     ),
  //     onPressed: onTap,
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Icon(icon, size: 50, color: Colors.black),
  //         const SizedBox(height: 10),
  //         Text(
  //           label,
  //           style: const TextStyle(color: Colors.black, fontSize: 16),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _DashCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 100, // Adjust the height
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

Widget _DashCard01({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return SizedBox(
    height: 120,
    child: Card(
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.green.shade100, // Soft green
                Colors.white, // Light white gradient
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // color: const Color.fromARGB(255, 255, 255, 255), // Soft circle background
                ),
                child: Icon(
                  icon,
                  color: const Color.fromARGB(
                      255, 0, 0, 0), // Slightly darker green icon
                  size: 40,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(
                      255, 0, 0, 0), // Matching soft green text
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
