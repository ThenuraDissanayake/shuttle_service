import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DriverNotificationPage extends StatefulWidget {
  const DriverNotificationPage({super.key});

  @override
  _DriverNotificationPageState createState() => _DriverNotificationPageState();
}

class _DriverNotificationPageState extends State<DriverNotificationPage>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Notifications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReceivedNotificationsTab(),
          _buildSentNotificationsTab(),
        ],
      ),
    );
  }

  late TabController _tabController;
  List<Map<String, dynamic>> receivedNotifications = [];
  List<Map<String, dynamic>> sentNotifications = [];
  List<Map<String, dynamic>> bookingPassengers = [];
  bool isLoading = true;
  int _unreadCount = 0;
  StreamSubscription? _notificationSubscription;
  Timer? _refreshTimer;
  bool _isIndexError = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadNotifications();
    loadBookingPassengers();

    // Set timer to refresh every 30 seconds
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      refreshNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationSubscription?.cancel();
    _refreshTimer?.cancel();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void loadNotifications() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print('No driver logged in');
      setState(() {
        isLoading = false;
      });
      return;
    }

    _notificationSubscription?.cancel();

    // Load received notifications
    try {
      _notificationSubscription = FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientToken', isEqualTo: uid)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          // Sort locally instead of in the query
          var docs = snapshot.docs.toList()
            ..sort((a, b) {
              var aTime = a.data()['timestamp'] as Timestamp?;
              var bTime = b.data()['timestamp'] as Timestamp?;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime); // Descending order
            });

          receivedNotifications = docs.map((doc) {
            return {
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            };
          }).toList();

          _unreadCount =
              receivedNotifications.where((n) => n['read'] == false).length;
        });

        // Load sent notifications
        FirebaseFirestore.instance
            .collection('notifications')
            .where('senderId', isEqualTo: uid)
            .get()
            .then((sentSnapshot) {
          if (mounted) {
            setState(() {
              var sentDocs = sentSnapshot.docs.toList()
                ..sort((a, b) {
                  var aTime = a.data()['timestamp'] as Timestamp?;
                  var bTime = b.data()['timestamp'] as Timestamp?;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime); // Descending order
                });

              sentNotifications = sentDocs.map((doc) {
                return {
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                };
              }).toList();

              isLoading = false;
              _isIndexError = false;
            });
          }
        }).catchError((e) {
          print('Error loading sent notifications: $e');
          setState(() {
            isLoading = false;
          });
        });
      }, onError: (e) {
        print('Error loading received notifications: $e');
        setState(() {
          isLoading = false;
          _isIndexError = true;
        });
        _loadNotificationsSimple(uid);
      });
    } catch (e) {
      print('Exception in loadNotifications: $e');
      _loadNotificationsSimple(uid);
    }
  }

  void _loadNotificationsSimple(String uid) {
    // Fallback method for loading notifications
    FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientToken', isEqualTo: uid)
        .get()
        .then((snapshot) {
      if (mounted) {
        setState(() {
          var docs = snapshot.docs.toList()
            ..sort((a, b) {
              var aTime = a.data()['timestamp'] as Timestamp?;
              var bTime = b.data()['timestamp'] as Timestamp?;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

          receivedNotifications = docs.map((doc) {
            return {
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            };
          }).toList();

          _unreadCount =
              receivedNotifications.where((n) => n['read'] == false).length;
        });
      }

      // Load sent notifications
      FirebaseFirestore.instance
          .collection('notifications')
          .where('senderId', isEqualTo: uid)
          .get()
          .then((sentSnapshot) {
        if (mounted) {
          setState(() {
            sentNotifications = sentSnapshot.docs.map((doc) {
              return {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              };
            }).toList();
            isLoading = false;
          });
        }
      });
    }).catchError((e) {
      print('Error in simple notifications query: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          receivedNotifications = [];
          sentNotifications = [];
        });
      }
    });
  }

  Future<void> loadBookingPassengers() async {
    try {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // First, get the driver's name with correct field name
      DocumentSnapshot driverDoc =
          await FirebaseFirestore.instance.collection('drivers').doc(uid).get();

      if (!driverDoc.exists) {
        print('Driver profile not found');
        return;
      }

      String? driverName = driverDoc.get('driver_name')
          as String?; // Changed from 'name' to 'driver_name'
      if (driverName == null || driverName.isEmpty) {
        print('Driver name not found');
        return;
      }

      // Get all bookings for this driver where status is pending or ongoing
      QuerySnapshot bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('driverName',
              isEqualTo:
                  driverName) // This matches the bookings collection field
          .where('my_booking', whereIn: ['pending', 'ongoing']).get();

      setState(() {
        bookingPassengers = bookingsSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
      });
    } catch (e) {
      print('Error loading booking passengers: $e');
    }
  }

  void refreshNotifications() {
    print('Refreshing notifications...');
    setState(() {
      isLoading = true;
    });

    loadNotifications();
    loadBookingPassengers();

    // Short delay to show loading indicator
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as read: $e')),
      );
    }
  }

  Future<void> markAllAsRead() async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var notification in receivedNotifications) {
        if (notification['read'] == false) {
          DocumentReference docRef = FirebaseFirestore.instance
              .collection('notifications')
              .doc(notification['id']);
          batch.update(docRef, {'read': true});
        }
      }
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (e) {
      print('Error marking all as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark all as read: $e')),
      );
    }
  }

  Future<void> sendNotification(String passengerName) async {
    String title = _titleController.text.trim();
    String message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both title and message')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Find the passenger's UID from their name
      QuerySnapshot passengerSnapshot = await FirebaseFirestore.instance
          .collection('passengers')
          .where('name', isEqualTo: passengerName)
          .get();

      if (passengerSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passenger not found')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      String passengerUid = passengerSnapshot.docs.first.id;

      // Create the notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'body': message,
        'recipientToken': passengerUid,
        'senderId': FirebaseAuth.instance.currentUser?.uid ?? '',
        'senderRole': 'Driver',
        'recipientRole': 'Passenger',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification sent to $passengerName')),
      );

      _titleController.clear();
      _messageController.clear();

      // Refresh the sent notifications list
      loadNotifications();
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

  void _showSendNotificationDialog(String passengerName) {
    _titleController.clear();
    _messageController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Notification to $passengerName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              sendNotification(passengerName);
            },
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedNotificationsTab() {
    if (receivedNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'You\'ll receive updates from admins here',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        refreshNotifications();
        await Future.delayed(Duration(milliseconds: 800));
      },
      child: ListView.builder(
        itemCount: receivedNotifications.length,
        itemBuilder: (context, index) {
          var notification = receivedNotifications[index];
          bool isRead = notification['read'] ?? false;
          DateTime? timestamp;
          if (notification['timestamp'] != null) {
            timestamp = (notification['timestamp'] as Timestamp).toDate();
          }

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: isRead ? 1 : 3,
            color: isRead ? null : Colors.blue[50],
            child: ListTile(
              contentPadding: EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: isRead ? Colors.grey : Colors.blue,
                child: Icon(
                  Icons.notifications,
                  color: Colors.white,
                ),
              ),
              title: Text(
                notification['title'] ?? 'No Title',
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(notification['body'] ?? 'No Message'),
                  SizedBox(height: 8),
                  Text(
                    timestamp != null
                        ? '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
                        : 'Just now',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              trailing: !isRead
                  ? IconButton(
                      icon: Icon(Icons.done, color: Colors.blue),
                      onPressed: () => markAsRead(notification['id']),
                    )
                  : null,
              onTap: () {
                if (!isRead) {
                  markAsRead(notification['id']);
                }
                // Show notification details
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(notification['title'] ?? 'No Title'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification['body'] ?? 'No Message',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'From: ${notification['senderRole'] ?? 'Unknown'}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (timestamp != null)
                          Text(
                            'Sent: ${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSentNotificationsTab() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Current Passengers Section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Current Passengers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: bookingPassengers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No active bookings',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: bookingPassengers.length,
                        itemBuilder: (context, index) {
                          final booking = bookingPassengers[index];
                          final passengerName =
                              booking['passengerName'] ?? 'Unknown';
                          final journeyType =
                              booking['journeyType'] ?? 'Not specified';
                          final bookingDateTime =
                              booking['bookingDateTime'] != null
                                  ? (booking['bookingDateTime'] as Timestamp)
                                      .toDate()
                                  : null;

                          return Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(passengerName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Journey: $journeyType'),
                                  if (bookingDateTime != null)
                                    Text(
                                      'Booked: ${DateFormat('dd MMM yyyy, hh:mm a').format(bookingDateTime)}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.message, color: Colors.blue),
                                onPressed: () =>
                                    _showSendNotificationDialog(passengerName),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),

        // Sent Notifications History
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sent Notifications History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: sentNotifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No sent notifications',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: sentNotifications.length,
                        itemBuilder: (context, index) {
                          var notification = sentNotifications[index];
                          DateTime? timestamp;
                          if (notification['timestamp'] != null) {
                            timestamp = (notification['timestamp'] as Timestamp)
                                .toDate();
                          }

                          return Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text(notification['title'] ?? 'No Title'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(notification['body'] ?? 'No Message'),
                                  SizedBox(height: 4),
                                  Text(
                                    'To: ${notification['recipientRole'] ?? 'Unknown'}',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  if (timestamp != null)
                                    Text(
                                      'Sent: ${DateFormat('dd MMM yyyy, hh:mm a').format(timestamp)}',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
