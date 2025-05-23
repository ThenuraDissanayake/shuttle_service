import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  // Send a notification to specific tokens
  static Future<void> sendNotification({
    required String title,
    required String body,
    required List<String> tokens,
    String? senderId,
    String? senderRole,
  }) async {
    try {
      for (String token in tokens) {
        // Send via FCM (this requires server-side for production, but works locally for testing)
        print('Sending to token: $token - Title: $title, Body: $body');

        // Store in Firestore for history
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': title,
          'body': body,
          'recipientToken': token,
          'senderId': senderId ?? '',
          'senderRole': senderRole ?? '',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Fetch tokens for a specific role
  static Future<List<String>> getTokensForRole(String role) async {
    String collection = role == 'Passenger'
        ? 'passengers'
        : role == 'Driver'
            ? 'drivers'
            : 'admins';
    var snapshot =
        await FirebaseFirestore.instance.collection(collection).get();
    return snapshot.docs
        .map((doc) => doc['fcmToken'] as String?)
        .where((token) => token != null)
        .cast<String>()
        .toList();
  }

  // Fetch token for a specific user
  static Future<String?> getTokenForUser(String uid, String role) async {
    String collection = role == 'Passenger'
        ? 'passengers'
        : role == 'Driver'
            ? 'drivers'
            : 'admins';
    var doc =
        await FirebaseFirestore.instance.collection(collection).doc(uid).get();
    return doc.exists ? doc['fcmToken'] as String? : null;
  }

  // Initialize FCM and register token
  static Future<void> initialize() async {
    // Request permission (iOS requires this)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    // Get and store the FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _updateToken(token);
    }

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen(_updateToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.data}');
      // Show in-app notification if needed
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _updateToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String role = await _determineUserRole(user.uid);
      String collection = role == 'Passenger'
          ? 'passengers'
          : role == 'Driver'
              ? 'drivers'
              : 'admins';
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(user.uid)
          .update({
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<String> _determineUserRole(String uid) async {
    var passengerDoc = await FirebaseFirestore.instance
        .collection('passengers')
        .doc(uid)
        .get();
    if (passengerDoc.exists) return 'Passenger';
    var driverDoc =
        await FirebaseFirestore.instance.collection('drivers').doc(uid).get();
    if (driverDoc.exists) return 'Driver';
    var adminDoc =
        await FirebaseFirestore.instance.collection('admins').doc(uid).get();
    if (adminDoc.exists) return 'Admin';
    return 'Unknown';
  }
}

// Background message handler (must be top-level)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.data}');
}
