import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PassengerNotificationPage extends StatelessWidget {
  const PassengerNotificationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the currently logged-in user's UID
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Notifications"),
        ),
        body: Center(
          child: Text("User not logged in!"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('passengers')
            .doc(uid)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No notifications yet."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var notification = snapshot.data!.docs[index];
              return ListTile(
                title: Text(notification['title']),
                subtitle: Text(notification['body']),
                trailing: Text(
                  DateTime.fromMillisecondsSinceEpoch(notification['timestamp'])
                      .toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          NotificationDetailsPage(notification: notification),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationDetailsPage extends StatelessWidget {
  final dynamic notification;

  const NotificationDetailsPage({Key? key, required this.notification})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notification Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['title'],
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(notification['body']),
            SizedBox(height: 16),
            Text(
              "Received on: ${DateTime.fromMillisecondsSinceEpoch(notification['timestamp']).toString()}",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
