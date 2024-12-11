import 'package:flutter/material.dart';

class BookingHistoryPage extends StatelessWidget {
  const BookingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // Navigate to profile screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Page Title
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  color: Colors.green,
                  size: 50,
                ),
                SizedBox(width: 10),
                Text(
                  'Booking History',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Booking List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: 6, // Example: 6 bookings
              itemBuilder: (context, index) {
                bool isUpcoming = index % 2 == 0; // Example condition
                return _buildBookingCard(
                  bookingDate: '12 Dec 2024',
                  shuttleName: 'Shuttle ${index + 1}',
                  route: 'NSBM -> Colombo',
                  status: isUpcoming ? 'Upcoming' : 'Completed',
                  isUpcoming: isUpcoming,
                  onCancel: () {
                    // Handle cancel action
                  },
                  onViewDetails: () {
                    // Handle view details action
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black54,
        currentIndex: 2, // Highlight the current tab
        onTap: (index) {
          // Handle navigation for other tabs
          if (index == 0) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ActivitiesPage()));
          } else if (index == 1) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AlertsPage()));
          } else if (index == 2) {
            // Stay on the current page
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Activities',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Bookings',
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard({
    required String bookingDate,
    required String shuttleName,
    required String route,
    required String status,
    required bool isUpcoming,
    required VoidCallback onCancel,
    required VoidCallback onViewDetails,
  }) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 20.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shuttleName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text('Route: $route', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            Text('Booking Date: $bookingDate',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            Text(
              'Status: $status',
              style: TextStyle(
                fontSize: 16,
                color: isUpcoming ? Colors.orange : Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isUpcoming)
                  ElevatedButton(
                    onPressed: onCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onViewDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Dummy pages for bottom navigation
class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
      ),
      body: const Center(
        child: Text('Activities Page'),
      ),
    );
  }
}

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
      ),
      body: const Center(
        child: Text('Alerts Page'),
      ),
    );
  }
}
