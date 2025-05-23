import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({super.key});

  @override
  _AdminNotificationPageState createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String targetRole = 'Passengers';
  List<Map<String, dynamic>> sentNotifications = [];
  bool isLoading = true;
  late TabController _tabController;
  bool _isIndexError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadSentNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void loadSentNotifications() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print('No admin logged in');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Use a simpler query to avoid index issues
      FirebaseFirestore.instance
          .collection('notifications')
          .where('senderId', isEqualTo: uid)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          // Sort the documents locally instead of in the query
          var docs = snapshot.docs.toList()
            ..sort((a, b) {
              var aTime = a.data()['timestamp'] as Timestamp?;
              var bTime = b.data()['timestamp'] as Timestamp?;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime); // Descending order
            });

          sentNotifications = docs.map((doc) {
            return {
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            };
          }).toList();
          isLoading = false;
          _isIndexError = false;
        });
      }, onError: (e) {
        print('Error loading sent notifications: $e');
        setState(() {
          isLoading = false;
          _isIndexError = true;
          sentNotifications = []; // Empty list as fallback
        });

        // Try again with a simpler query
        _loadNotificationsSimple(uid);
      });
    } catch (e) {
      print('Exception in loadSentNotifications: $e');
      _loadNotificationsSimple(uid);
    }
  }

  void _loadNotificationsSimple(String uid) {
    // Fallback method with absolute minimum query requirements
    FirebaseFirestore.instance
        .collection('notifications')
        .where('senderId', isEqualTo: uid)
        .get()
        .then((snapshot) {
      if (mounted) {
        setState(() {
          // Sort locally
          var docs = snapshot.docs.toList()
            ..sort((a, b) {
              var aTime = a.data()['timestamp'] as Timestamp?;
              var bTime = b.data()['timestamp'] as Timestamp?;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime); // Descending order
            });

          sentNotifications = docs.map((doc) {
            return {
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            };
          }).toList();
          isLoading = false;
        });
      }
    }).catchError((e) {
      print('Error in simple notifications query: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          sentNotifications = [];
        });
      }
    });
  }

  Future<void> sendNotification(String role) async {
    String title = _titleController.text.trim();
    String body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Title and Message')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      List<String> recipientUids = await getRecipientUidsForRole(role);
      if (recipientUids.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No users found for $role')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Create a batch to send multiple notifications efficiently
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (String uid in recipientUids) {
        DocumentReference docRef =
            FirebaseFirestore.instance.collection('notifications').doc();
        batch.set(docRef, {
          'title': title,
          'body': body,
          'recipientToken': uid,
          'senderId': FirebaseAuth.instance.currentUser?.uid ?? '',
          'senderRole': 'Admin',
          'recipientRole': role,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Notification sent to ${recipientUids.length} $role')),
      );
      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send notification: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<String>> getRecipientUidsForRole(String role) async {
    if (role == 'All Users') {
      List<String> passengerUids = await _fetchUidsFromCollection('passengers');
      List<String> driverUids = await _fetchUidsFromCollection('drivers');
      return [...passengerUids, ...driverUids];
    } else if (role == 'Passengers') {
      return await _fetchUidsFromCollection('passengers');
    } else if (role == 'Drivers') {
      return await _fetchUidsFromCollection('drivers');
    }
    return [];
  }

  Future<List<String>> _fetchUidsFromCollection(String collection) async {
    try {
      var snapshot =
          await FirebaseFirestore.instance.collection(collection).get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error fetching UIDs from $collection: $e');
      return [];
    }
  }

  Widget _buildNotificationStats() {
    Map<String, int> stats = {
      'Passengers': 0,
      'Drivers': 0,
      'All Users': 0,
    };

    for (var notification in sentNotifications) {
      String recipientRole = notification['recipientRole'] ?? 'Unknown';
      if (recipientRole == 'Passengers') {
        stats['Passengers'] = (stats['Passengers'] ?? 0) + 1;
      } else if (recipientRole == 'Drivers') {
        stats['Drivers'] = (stats['Drivers'] ?? 0) + 1;
      } else if (recipientRole == 'All Users') {
        stats['All Users'] = (stats['All Users'] ?? 0) + 1;
      }
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('Passengers', stats['Passengers'] ?? 0, Colors.blue),
                _statItem('Drivers', stats['Drivers'] ?? 0, Colors.green),
                _statItem('All Users', stats['All Users'] ?? 0, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        SizedBox(height: 5),
        Text(label),
      ],
    );
  }

  Widget _buildTabContent(String role) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isIndexError)
            Container(
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Firestore index issue detected. The list may not be fully sorted.',
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Notification Title',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _bodyController,
            decoration: InputDecoration(
              labelText: 'Notification Message',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => sendNotification(role),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    'Send to $role',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: _buildSentNotificationsList(role),
          ),
        ],
      ),
    );
  }

  Widget _buildSentNotificationsList(String role) {
    // Filter notifications based on role
    List<Map<String, dynamic>> filteredNotifications = [];

    if (role == 'All Users') {
      filteredNotifications = sentNotifications;
    } else {
      filteredNotifications = sentNotifications
          .where((notification) => notification['recipientRole'] == role)
          .toList();
    }

    if (filteredNotifications.isEmpty) {
      return Center(
        child: Text('No notifications sent to $role yet'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        loadSentNotifications();
        await Future.delayed(Duration(milliseconds: 500));
      },
      child: ListView.builder(
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          var notification = filteredNotifications[index];
          DateTime? timestamp;
          if (notification['timestamp'] != null) {
            timestamp = (notification['timestamp'] as Timestamp).toDate();
          }

          return Card(
            margin: EdgeInsets.symmetric(vertical: 5),
            child: ListTile(
              title: Text(notification['title'] ?? 'No Title'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification['body'] ?? 'No Message'),
                  SizedBox(height: 5),
                  Text(
                    timestamp != null
                        ? 'Sent: ${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
                        : 'Sending...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(notification['id'])
                        .delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Notification deleted')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete: $e')),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Notification Center'),
        backgroundColor: Colors.blue[800],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Passengers'),
            Tab(text: 'Drivers'),
            Tab(text: 'All Users'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildNotificationStats(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTabContent('Passengers'),
                      _buildTabContent('Drivers'),
                      _buildTabContent('All Users'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
