import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shuttleManagement.dart';
import 'reservations_overview_page.dart';
import 'booking_requests_management.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  _OwnerDashboardPageState createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  String _userName = "User"; // Default value if no name is found

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
        // Attempt to get the user data from both 'passengers' and 'owners' collections
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('passengers')
            .doc(user.uid)
            .get();

        // If no user data found in 'passengers', try 'owners'
        if (!userDoc.exists) {
          userDoc = await FirebaseFirestore.instance
              .collection('owners')
              .doc(user.uid)
              .get();
        }

        if (userDoc.exists) {
          // Cast userDoc.data() as Map<String, dynamic> and retrieve the name
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userName = userData['name'] ?? 'User';
          });
        } else {
          print("No user data found in Firestore.");
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
        backgroundColor: Colors.green,
        title: Text('Hi, $_userName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // Navigate to profile screen or any other screen
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Shuttle Status Overview',
                style: TextStyle(fontSize: 24)),
            Row(
              children: [
                _buildStatusCard('Shuttle 1', 'Available'),
                _buildStatusCard('Shuttle 2', 'Full'),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Latest Reservations', style: TextStyle(fontSize: 24)),
            Expanded(
              child: ListView(
                children: [
                  _buildReservationCard(
                      'Shuttle 1', '10:00 AM', '20 seats reserved'),
                  _buildReservationCard(
                      'Shuttle 2', '11:00 AM', 'No seats left'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Feedback from Users', style: TextStyle(fontSize: 24)),
            Expanded(
              child: ListView(
                children: [
                  _buildFeedbackCard('Great service!', 'User 1'),
                  _buildFeedbackCard('On-time and comfortable.', 'User 2'),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.green,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 0, // Default active tab
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Activities',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'Shuttle Management',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Reservations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Booking Requests',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Navigate to Activities page
              break;
            case 1:
              // Navigate to Notifications page
              break;
            case 2:
              // Navigate to Shuttle Management page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShuttleManagementPage(),
                ),
              );
              break;
            case 3:
              // Navigate to Reservations page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReservationsOverviewPage(),
                ),
              );
              break;
            case 4:
              // Navigate to Booking Requests page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookingRequestsPage(),
                ),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _buildStatusCard(String shuttleName, String status) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(shuttleName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(status, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationCard(String shuttleName, String time, String seats) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(shuttleName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Time: $time', style: const TextStyle(fontSize: 16)),
            Text(seats, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(String feedback, String user) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(feedback, style: const TextStyle(fontSize: 16)),
            Text('- $user',
                style:
                    const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
