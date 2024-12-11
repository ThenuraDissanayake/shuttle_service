import 'package:flutter/material.dart';

class BookingRequestsPage extends StatelessWidget {
  const BookingRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for requests
    final List<Map<String, String>> bookingRequests = [
      {
        'booking_id': '001',
        'user_name': 'John Doe',
        'shuttle': 'Shuttle 1',
        'seat': '12',
        'status': 'Pending'
      },
      {
        'booking_id': '002',
        'user_name': 'Jane Smith',
        'shuttle': 'Shuttle 2',
        'seat': '8',
        'status': 'Pending'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Booking Requests'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: bookingRequests.length,
        itemBuilder: (context, index) {
          final request = bookingRequests[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User: ${request['user_name']}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('Shuttle: ${request['shuttle']}'),
                  Text('Seat: ${request['seat']}'),
                  Text('Status: ${request['status']}'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () {
                          // Handle accept logic
                          _handleRequest(
                              context, request['booking_id'], 'Accepted');
                        },
                        child: const Text('Accept'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () {
                          // Handle reject logic
                          _handleRequest(
                              context, request['booking_id'], 'Rejected');
                        },
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleRequest(BuildContext context, String? bookingId, String status) {
    // Handle accept/reject logic here
    // For example, update the booking request status in the database
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request $bookingId has been $status.')),
    );
  }
}
