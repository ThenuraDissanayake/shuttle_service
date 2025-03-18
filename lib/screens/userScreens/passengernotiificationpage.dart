import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shuttle_service/screens/userScreens/dashboard.dart';
import 'package:shuttle_service/screens/userScreens/my_bookings.dart';
import 'package:shuttle_service/screens/userScreens/userProfile.dart';

class PassengerNotificationPage extends StatefulWidget {
  const PassengerNotificationPage({super.key});

  @override
  _PassengerNotificationPageState createState() =>
      _PassengerNotificationPageState();
}

class _PassengerNotificationPageState extends State<PassengerNotificationPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  StreamSubscription? _notificationSubscription;
  Timer? _refreshTimer;
  int _unreadCount = 0;
  bool _isIndexError = false;
  String? _indexUrl;

  @override
  void initState() {
    super.initState();
    loadNotifications();

    // Set timer to refresh every 5 seconds
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      refreshNotifications();
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void loadNotifications() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      print('No user logged in');
      setState(() {
        isLoading = false;
      });
      return;
    }

    _notificationSubscription?.cancel();

    try {
      // First, try to fetch without ordering to avoid index issues if they occur
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

          notifications = docs.map((doc) {
            return {
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            };
          }).toList();

          _unreadCount = notifications.where((n) => n['read'] == false).length;
          isLoading = false;
          _isIndexError = false;
        });
      }, onError: (e) {
        print('Error loading notifications: $e');

        // Extract index URL if that's the error
        String errorMsg = e.toString();
        if (errorMsg.contains('index')) {
          _indexUrl = _extractIndexUrl(errorMsg);
          _isIndexError = true;
        }

        // Fallback to simple query with no ordering
        _loadNotificationsWithoutOrdering(uid);
      });
    } catch (e) {
      print('Exception in loadNotifications: $e');
      _loadNotificationsWithoutOrdering(uid);
    }
  }

  String? _extractIndexUrl(String errorMessage) {
    // Extract URL from the error message
    RegExp urlRegex = RegExp(r'https://console\.firebase\.google\.com[^\s]+');
    final match = urlRegex.firstMatch(errorMessage);
    return match?.group(0);
  }

  void _loadNotificationsWithoutOrdering(String uid) {
    // Fallback method that doesn't use ordering in the query
    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientToken', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        // Sort locally
        var sortedDocs = snapshot.docs.toList();
        sortedDocs.sort((a, b) {
          var aTime = a.data()['timestamp'] as Timestamp?;
          var bTime = b.data()['timestamp'] as Timestamp?;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // Descending order
        });

        notifications = sortedDocs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          };
        }).toList();

        _unreadCount = notifications.where((n) => n['read'] == false).length;
        isLoading = false;
      });
    }, onError: (e) {
      print('Error in fallback notification loading: $e');
      setState(() {
        isLoading = false;
        notifications = [];
      });
    });
  }

  void refreshNotifications() {
    print('Refreshing notifications...');
    // Just show a visual indicator that refresh is happening
    setState(() {
      isLoading = true;
    });

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
      for (var notification in notifications) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('My Notifications'),
            SizedBox(width: 10),
            if (_unreadCount > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
        // backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: refreshNotifications,
            tooltip: 'Refresh Notifications',
          ),
          if (_unreadCount > 0)
            IconButton(
              icon: Icon(Icons.done_all),
              onPressed: markAllAsRead,
              tooltip: 'Mark All as Read',
            ),
        ],
      ),
      body: Stack(
        children: [
          if (isLoading)
            LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          if (_isIndexError)
            Container(
              color: Colors.yellow[100],
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Firestore index needed. Please create the required index.',
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: _isIndexError ? 40 : 0),
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'You\'ll receive updates here',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      refreshNotifications();
                      // Simulate network delay for refresh indicator
                      await Future.delayed(Duration(milliseconds: 800));
                    },
                    child: ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        var notification = notifications[index];
                        bool isRead = notification['read'] ?? false;
                        DateTime? timestamp;
                        if (notification['timestamp'] != null) {
                          timestamp =
                              (notification['timestamp'] as Timestamp).toDate();
                        }

                        return Card(
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          elevation: isRead ? 1 : 3,
                          color: isRead ? null : Colors.green[50],
                          child: ListTile(
                            contentPadding: EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundColor:
                                  isRead ? Colors.grey : Colors.green,
                              child: Icon(
                                Icons.notifications,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              notification['title'] ?? 'No Title',
                              style: TextStyle(
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
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
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: !isRead
                                ? IconButton(
                                    icon: Icon(Icons.done, color: Colors.blue),
                                    onPressed: () =>
                                        markAsRead(notification['id']),
                                  )
                                : null,
                            onTap: () {
                              if (!isRead) {
                                markAsRead(notification['id']);
                              }
                              // Show notification details if needed
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                      notification['title'] ?? 'Notification'),
                                  content: Text(notification['body'] ?? ''),
                                  actions: [
                                    TextButton(
                                      child: Text('Close'),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        // backgroundColor: const Color.fromARGB(255, 184, 245, 186),
        selectedItemColor: const Color.fromARGB(255, 0, 0, 0),
        unselectedItemColor: const Color.fromARGB(255, 191, 201, 183),
        currentIndex: 2, // Default active tab
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_seat),
            label: 'My Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded),
            label: 'Account',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              );
              break;
            case 1:
              // Navigate to Activities page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyBookingsPage(),
                ),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PassengerNotificationPage(),
                ),
              );
              // Navigate to Notifications page
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfilePage(),
                ),
              );
              break;
          }
        },
      ),
    );
  }
}
