import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AdminNotificationPage extends StatelessWidget {
  const AdminNotificationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Drivers and Passengers
      child: Scaffold(
        appBar: AppBar(
          title: Text("Admin Notifications"),
          bottom: TabBar(
            tabs: [
              Tab(text: "Drivers"), // Tab for sending notifications to drivers
              Tab(
                  text:
                      "Passengers"), // Tab for sending notifications to passengers
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Send Notifications to Drivers
            _NotificationForm(target: "drivers"),
            // Tab 2: Send Notifications to Passengers
            _NotificationForm(target: "passengers"),
          ],
        ),
      ),
    );
  }
}

// Reusable Notification Form
class _NotificationForm extends StatefulWidget {
  final String target; // "drivers" or "passengers"

  const _NotificationForm({Key? key, required this.target}) : super(key: key);

  @override
  _NotificationFormState createState() => _NotificationFormState();
}

class _NotificationFormState extends State<_NotificationForm> {
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
      // Fetch tokens based on the target audience
      List<String> tokens = [];
      if (widget.target == "drivers") {
        // Fetch driver tokens
        final driverSnapshot =
            await FirebaseFirestore.instance.collection('drivers').get();
        tokens = driverSnapshot.docs
            .map((doc) => doc.data()['fcmToken'] as String)
            .toList();
      } else if (widget.target == "passengers") {
        // Fetch passenger tokens
        final passengerSnapshot =
            await FirebaseFirestore.instance.collection('passengers').get();
        tokens = passengerSnapshot.docs
            .map((doc) => doc.data()['fcmToken'] as String)
            .toList();
      }

      // Send notifications to each token
      for (String token in tokens) {
        await FirebaseMessaging.instance.sendMessage(
          to: token,
          data: {
            'title': title,
            'body': body,
          },
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Notifications sent successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send notifications: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}
