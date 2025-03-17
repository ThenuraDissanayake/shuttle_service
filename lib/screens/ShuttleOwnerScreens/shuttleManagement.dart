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
  TimeOfDay _morningJourneyTime =
      TimeOfDay(hour: 8, minute: 0); // Default 8:00 AM
  TimeOfDay _eveningJourneyTime =
      TimeOfDay(hour: 16, minute: 0); // Default 4:00 PM

  @override
  void initState() {
    super.initState();
    _fetchShuttleDetails();
  }

  // Fetch shuttle details and sync with Firestore
  Future<void> _fetchShuttleDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      final driverDoc =
          await _firestore.collection('drivers').doc(user.uid).get();
      if (driverDoc.exists) {
        final driverData = driverDoc.data() as Map<String, dynamic>;
        setState(() {
          _isActive = driverData['shuttle']['status'] == 'Active';
          // Fetch the saved journey times from Firestore, if they exist
          if (driverData['morning_journey_time'] != null) {
            _morningJourneyTime = TimeOfDay.fromDateTime(
                (driverData['morning_journey_time'] as Timestamp).toDate());
          }
          if (driverData['evening_journey_time'] != null) {
            _eveningJourneyTime = TimeOfDay.fromDateTime(
                (driverData['evening_journey_time'] as Timestamp).toDate());
          }
        });
      }
    }
  }

  // Update shuttle status and journey times in Firestore
  Future<void> _updateShuttleDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('drivers').doc(user.uid).update({
        'shuttle.status': _isActive ? 'Active' : 'Inactive',
        'morning_journey_time': Timestamp.fromDate(DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            _morningJourneyTime.hour,
            _morningJourneyTime.minute)),
        'evening_journey_time': Timestamp.fromDate(DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            _eveningJourneyTime.hour,
            _eveningJourneyTime.minute)),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isActive
              ? 'Shuttle activated and times updated!'
              : 'Shuttle deactivated and times updated!'),
        ),
      );
    }
  }

  // Function to show time picker for morning journey
  Future<void> _pickMorningJourneyTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _morningJourneyTime,
    );
    if (pickedTime != null && pickedTime != _morningJourneyTime) {
      setState(() {
        _morningJourneyTime = pickedTime;
      });
    }
  }

  // Function to show time picker for evening journey
  Future<void> _pickEveningJourneyTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _eveningJourneyTime,
    );
    if (pickedTime != null && pickedTime != _eveningJourneyTime) {
      setState(() {
        _eveningJourneyTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shuttle Management'),
        // backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shuttle Active/Inactive Toggle Switch
            SwitchListTile(
              title: const Text('Shuttle Active Status'),
              subtitle: const Text('Toggle shuttle status (Active/Inactive)'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value; // Toggle status
                });
                _updateShuttleDetails();
              },
            ),
            const SizedBox(height: 20),

            // Morning Journey Time Picker
            ListTile(
              title: const Text('Morning Journey Time (24-Hour Format)'),
              subtitle: Text("${_morningJourneyTime.format(context)}"),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () => _pickMorningJourneyTime(context),
              ),
            ),
            const SizedBox(height: 20),

            // Evening Journey Time Picker
            ListTile(
              title: const Text('Evening Journey Time (24-Hour Format)'),
              subtitle: Text("${_eveningJourneyTime.format(context)}"),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () => _pickEveningJourneyTime(context),
              ),
            ),
            const SizedBox(height: 20),

            // Save Button to update details
            ElevatedButton(
              onPressed: _updateShuttleDetails,
              child: const Text('Save Shuttle Details'),
            ),
          ],
        ),
      ),
    );
  }
}
