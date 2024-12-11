// reservations_overview_page.dart
import 'package:flutter/material.dart';

class ReservationsOverviewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Reservations Overview'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('View and Manage Reservations',
                style: TextStyle(fontSize: 24)),
            // Reservation cards
            Expanded(
              child: ListView(
                children: [
                  _buildReservationCard(
                      'Shuttle 1', '10:00 AM', '15 seats reserved'),
                  _buildReservationCard(
                      'Shuttle 2', '11:00 AM', 'No seats left'),
                ],
              ),
            ),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Time: $time', style: TextStyle(fontSize: 16)),
            Text(seats, style: TextStyle(fontSize: 16)),
            ElevatedButton(
              onPressed: () {
                // View reservation details
              },
              child: const Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }
}
