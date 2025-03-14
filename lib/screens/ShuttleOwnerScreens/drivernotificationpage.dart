import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class DriverNotificationPage extends StatefulWidget {
  const DriverNotificationPage({Key? key}) : super(key: key);

  @override
  _DriverNotificationPageState createState() => _DriverNotificationPageState();
}

class _DriverNotificationPageState extends State<DriverNotificationPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  Future<void> _sendNotification() async {
    String title = _titleController.text;
    String body = _bodyController.text;

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    try {
      // Get the currently logged-in user's UID
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not logged in!")),
        );
        return;
      }

      // Fetch driver details from Firestore
      final driverSnapshot =
          await FirebaseFirestore.instance.collection('drivers').doc(uid).get();

      if (!driverSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Driver not found!")),
        );
        return;
      }

      List<dynamic> mainStops = driverSnapshot.data()?['main_stops'] ?? [];

      // Fetch passengers who match the driver's stops
      final passengerSnapshot = await FirebaseFirestore.instance
          .collection('passengers')
          .where('role', isEqualTo: 'Passenger')
          .get();

      List<String> passengerTokens = [];
      for (var passengerDoc in passengerSnapshot.docs) {
        Map<String, dynamic>? passengerData = passengerDoc.data();
        String? token = passengerData['fcmToken'];
        if (token != null) {
          passengerTokens.add(token);
        }
      }

      // Send notifications to each token
      for (String token in passengerTokens) {
        await FirebaseMessaging.instance.sendMessage(
          to: token,
          data: {
            'title': title,
            'body': body,
          },
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Notification sent successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send notification: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Send Notification"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Title"),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(labelText: "Message"),
              maxLines: 5,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendNotification,
              child: Text("Send Notification"),
            ),
          ],
        ),
      ),
    );
  }
}
