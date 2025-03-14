import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ComplaintHistoryPage extends StatelessWidget {
  const ComplaintHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Check if user is logged in
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("You need to be logged in to view complaints."),
        ),
      );
    }

    final userEmail = user.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query the complaints collection and filter by email
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .where('email',
                isEqualTo:
                    userEmail) // Filter based on the current user's email
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
            return const Center(child: Text('No complaints found.'));
          }

          final complaints = snapshot.data!.docs;

          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint =
                  complaints[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: ListTile(
                  title: Text(
                    complaint['complaintType'] ?? 'Unknown Type',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Description: ${complaint['description'] ?? 'No description'}"),
                      Text(
                          "Admin Reply: ${complaint['adminReply'] ?? 'No reply yet'}"),
                      Text("Status: ${complaint['status'] ?? 'Pending'}"),
                    ],
                  ),
                  trailing: Icon(
                    complaint['status'] == 'Resolved'
                        ? Icons.check_circle
                        : Icons.hourglass_empty,
                    color: complaint['status'] == 'Resolved'
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
