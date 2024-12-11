import 'package:flutter/material.dart';
import 'reservations_overview_page.dart';
import 'shuttleManagement.dart';
import 'booking_requests_management.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Shuttle Owner Dashboard'),
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

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OwnerDashboardPage(),
  ));
}
