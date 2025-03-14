import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PendingSpecialShuttlePage extends StatelessWidget {
  const PendingSpecialShuttlePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Check if user is logged in
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
              "You need to be logged in to view pending special shuttles."),
        ),
      );
    }

    final userEmail = user.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('pending Special Shuttle'),
        // backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query the special_shuttle_requests collection and filter by status 'pending'
        stream: FirebaseFirestore.instance
            .collection('special_shuttle_requests')
            .where('status', isEqualTo: 'pending') // Filter based on status
            .where('email',
                isEqualTo: userEmail) // Optionally filter by user email
            .snapshots(),
        builder: (context, snapshot) {
          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle errors
          if (snapshot.hasError) {
            return Center(
                child: Text('Something went wrong: ${snapshot.error}'));
          }

          // If no data is found
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No pending special shuttle requests found.'));
          }

          final specialShuttles = snapshot.data!.docs;

          return ListView.builder(
            itemCount: specialShuttles.length,
            itemBuilder: (context, index) {
              final shuttle =
                  specialShuttles[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: ListTile(
                  title: Text(
                    "Passenger Name: ${shuttle['fullName'] ?? 'Unknown_name'}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status: ${shuttle['status'] ?? 'Unknown status'}"),
                      Text(
                          "Pickup Location: ${shuttle['pickupLocation'] ?? 'N/A'}"),
                      Text(
                          "Dropoff Location: ${shuttle['dropOffLocation'] ?? 'N/A'}"),
                      Text(
                          "Date & Time: ${shuttle['tripDateTime']?.toDate().toString() ?? 'N/A'}"),
                      // Text(
                      //     "Num of Passengers: ${shuttle['numPassengers'] ?? 0}"),
                      Text(
                          "Reason: ${shuttle['reason'] ?? 'No reason provided'}"),
                      // Text(
                      //     "Shuttle Type: ${shuttle['shuttle_details']['shuttle_type'] ?? 'N/A'}"),
                      // Text(
                      //     "Capacity: ${shuttle['shuttle_details']['capacity'] ?? 'N/A'}"),
                      // Text(
                      //     "License Plate: ${shuttle['shuttle_details']['license_plate'] ?? 'N/A'}"),
                    ],
                  ),
                  trailing: const Icon(Icons.access_time, color: Colors.orange),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
