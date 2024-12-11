import 'package:flutter/material.dart';

class OngoingActivitiesPage extends StatelessWidget {
  const OngoingActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Ongoing Activities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh page content if necessary
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Ongoing Reservation Section
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Ongoing Reservations',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: 3, // Example: 3 ongoing activities
              itemBuilder: (context, index) {
                return _buildReservationCard(
                  shuttleName: 'Shuttle ${index + 1}',
                  route: 'NSBM -> Colombo',
                  seatNumber: index + 1,
                  time: '2:30 PM',
                  onModify: () {
                    // Handle modification of the booking
                  },
                  onCancel: () {
                    // Handle cancellation of the booking
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard({
    required String shuttleName,
    required String route,
    required int seatNumber,
    required String time,
    required VoidCallback onModify,
    required VoidCallback onCancel,
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
            Icon(
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
                    'Seat: $seatNumber',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Time: $time',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: onModify,
                  child: const Text('Modify'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
