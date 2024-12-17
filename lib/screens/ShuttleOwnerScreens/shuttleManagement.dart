import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShuttleManagementPage extends StatefulWidget {
  const ShuttleManagementPage({super.key});

  @override
  State<ShuttleManagementPage> createState() => _ShuttleManagementPageState();
}

class _ShuttleManagementPageState extends State<ShuttleManagementPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isActive = false; // Shuttle active/inactive status
  Map<DateTime, bool> _activeDays = {}; // Active days with toggle states

  @override
  void initState() {
    super.initState();
    _initializeActiveDays();
    _fetchShuttleDetails();
  }

  // Initialize active days (today + next 2 days)
  void _initializeActiveDays() {
    final today = DateTime.now();
    for (int i = 0; i < 3; i++) {
      final date = DateTime(today.year, today.month, today.day + i);
      _activeDays[date] = false; // Default to "off"
    }
  }

  // Fetch shuttle details and sync with Firestore
  Future<void> _fetchShuttleDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      final driverDoc =
          await _firestore.collection('drivers').doc(user.uid).get();
      if (driverDoc.exists) {
        final driverData = driverDoc.data() as Map<String, dynamic>;

        // Update active status and active days from Firestore
        setState(() {
          _isActive = driverData['shuttle']['status'] == 'Active';

          if (driverData['shuttle']['active_days'] != null) {
            final firestoreDays =
                List.from(driverData['shuttle']['active_days']);
            for (var timestamp in firestoreDays) {
              final date = (timestamp as Timestamp).toDate();
              _activeDays[date] = true; // Mark as active
            }
          }
        });
      }
    }
  }

  // Update shuttle status in Firestore
  Future<void> _updateShuttleStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('drivers').doc(user.uid).update({
        'shuttle.status': _isActive ? 'Active' : 'Inactive',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_isActive ? 'Shuttle activated!' : 'Shuttle deactivated!'),
        ),
      );
    }
  }

  // Update active days in Firestore
  Future<void> _updateActiveDaysInFirestore() async {
    final user = _auth.currentUser;
    if (user != null) {
      final activeDaysTimestamps = _activeDays.entries
          .where((entry) => entry.value) // Filter for active days
          .map((entry) => Timestamp.fromDate(entry.key))
          .toList();

      await _firestore.collection('drivers').doc(user.uid).update({
        'shuttle.active_days': activeDaysTimestamps,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Active days updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shuttle Management'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shuttle Active/Inactive Toggle
              SwitchListTile(
                title: const Text('Shuttle Active Status'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                  _updateShuttleStatus();
                },
              ),
              const SizedBox(height: 20),

              // Active Days Toggles
              const Text('Active Days for Bookings',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Column(
                children: _activeDays.entries.map((entry) {
                  final date = entry.key;
                  final isActive = entry.value;
                  return SwitchListTile(
                    title: Text(
                      "${date.day}/${date.month}/${date.year}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    value: isActive,
                    onChanged: (value) {
                      setState(() {
                        _activeDays[date] = value;
                      });
                      _updateActiveDaysInFirestore();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Additional Features Placeholder
              const Text('Additional Features', style: TextStyle(fontSize: 18)),
              const Text(
                'Include any additional sections here such as booking requests.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
