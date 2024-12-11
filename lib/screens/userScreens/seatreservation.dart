import 'package:flutter/material.dart';

class SeatReservationPage extends StatefulWidget {
  const SeatReservationPage({super.key});

  @override
  _SeatReservationPageState createState() => _SeatReservationPageState();
}

class _SeatReservationPageState extends State<SeatReservationPage> {
  int _selectedIndex = 0; // For bottom navigation tracking

  // Placeholder pages for bottom navigation
  final List<Widget> _pages = [
    const Placeholder(), // Activities Page
    const Placeholder(), // Alerts Page
    const Placeholder(), // Profile Page
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Seat Reservation'),
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
                  Icons.event_seat,
                  color: Colors.green,
                  size: 50,
                ),
                SizedBox(width: 10),
                Text(
                  'Reserve Your Seat',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Shuttle List with Availability
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: 5, // Example: 5 shuttles
              itemBuilder: (context, index) {
                return _buildShuttleCard(
                  shuttleName: 'Shuttle ${index + 1}',
                  route: 'Route ${index + 1}: NSBM -> Colombo',
                  availableSeats: 40 - (index * 8), // Example seat data
                  onReserve: () {
                    // Handle reservation
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
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildShuttleCard({
    required String shuttleName,
    required String route,
    required int availableSeats,
    required VoidCallback onReserve,
  }) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 20.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(
              Icons.directions_bus,
              size: 50,
              color: Colors.green,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shuttleName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    route,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Available Seats: $availableSeats',
                    style: TextStyle(
                      fontSize: 16,
                      color: availableSeats > 0 ? Colors.black : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: availableSeats > 0 ? onReserve : null,
              child: const Text('Reserve'),
            ),
          ],
        ),
      ),
    );
  }
}
