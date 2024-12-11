import 'package:flutter/material.dart';
import 'seatreservation.dart';
import 'ShuttleTracking.dart';
import 'notification.dart';
import 'feedback.dart';
import 'myBooking.dart';
import 'userProfile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Hi User, Welcome to UniShuttle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // Navigate to the User Profile screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const UserProfilePage(), // Navigating to UserProfilePage
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_bus,
                  color: Colors.green,
                  size: 50,
                ),
                SizedBox(width: 10),
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

          // Buttons for various actions
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(20.0),
              crossAxisSpacing: 20.0,
              mainAxisSpacing: 20.0,
              children: [
                _buildDashboardButton(context, Icons.event_seat, 'Book a Seat',
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SeatReservationPage(),
                    ),
                  );
                }),
                _buildDashboardButton(context, Icons.map, 'Track Shuttle', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ShuttleTrackingMapPage(),
                    ),
                  );
                }),
                _buildDashboardButton(
                    context, Icons.notifications, 'Notifications', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                }),
                _buildDashboardButton(context, Icons.history, 'My Bookings',
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BookingHistoryPage(),
                    ),
                  );
                }),
                _buildDashboardButton(context, Icons.feedback, 'Feedback', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FeedbackPage(),
                    ),
                  );
                }),
                _buildDashboardButton(
                    context, Icons.settings, 'Profile Settings', () {}),
              ],
            ),
          ),

          // Search bar at the bottom
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for shuttle',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // Handle search action
                  },
                ),
              ],
            ),
          ),

          // Bottom navigation bar
          BottomNavigationBar(
            backgroundColor: Colors.green,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: 'Activities',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications),
                label: 'Alerts',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardButton(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, // Button color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: Colors.black),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.black, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
