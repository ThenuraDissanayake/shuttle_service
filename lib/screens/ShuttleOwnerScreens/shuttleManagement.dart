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

  // Weekday selection (Monday to Sunday)
  List<bool> _workingDays = List.generate(7, (_) => false);
  final List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  // Is today a working day?
  bool get _isTodayWorkingDay {
    // Get today's weekday (1 = Monday, 7 = Sunday in DateTime)
    // Adjust to our 0-based index (0 = Monday, 6 = Sunday)
    final todayIndex = DateTime.now().weekday - 1;
    return _workingDays[todayIndex];
  }

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

          // Fetch working days if available
          if (driverData['working_days'] != null) {
            List<dynamic> workingDays = driverData['working_days'];
            for (int i = 0; i < 7 && i < workingDays.length; i++) {
              _workingDays[i] = workingDays[i];
            }
          }

          // Auto-adjust active status based on today
          if (!_isTodayWorkingDay) {
            _isActive = false;
          }
        });
      }
    }
  }

  // Update shuttle status and journey times in Firestore
  Future<void> _updateShuttleDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      // If trying to activate on a non-working day, show warning
      if (_isActive && !_isTodayWorkingDay) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot activate shuttle on a non-working day!'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isActive = false;
        });
        return;
      }

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
        'working_days': _workingDays,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isActive
              ? 'Shuttle activated and settings updated!'
              : 'Shuttle deactivated and settings updated!'),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Working Days Selection
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Working Days',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select days when the shuttle will operate:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: List.generate(7, (index) {
                          return FilterChip(
                            label: Text(_weekdays[index]),
                            selected: _workingDays[index],
                            onSelected: (bool selected) {
                              setState(() {
                                _workingDays[index] = selected;

                                // If today's day is deselected, automatically turn off active status
                                if (!_isTodayWorkingDay) {
                                  _isActive = false;
                                }
                              });
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              // Shuttle Active/Inactive Toggle Switch
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: SwitchListTile(
                  title: const Text('Shuttle Active Status'),
                  subtitle: Text(_isTodayWorkingDay
                      ? 'Toggle shuttle status (Active/Inactive)'
                      : 'Cannot activate on non-working days'),
                  value: _isActive,
                  onChanged: _isTodayWorkingDay
                      ? (value) {
                          setState(() {
                            _isActive = value; // Toggle status
                          });
                        }
                      : null, // Disable toggle if today is not a working day
                ),
              ),

              // Morning Journey Time Picker
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: const Text('Morning Journey Time (24-Hour Format)'),
                  subtitle: Text("${_morningJourneyTime.format(context)}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => _pickMorningJourneyTime(context),
                  ),
                ),
              ),

              // Evening Journey Time Picker
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: const Text('Evening Journey Time (24-Hour Format)'),
                  subtitle: Text("${_eveningJourneyTime.format(context)}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => _pickEveningJourneyTime(context),
                  ),
                ),
              ),

              // Save Button to update details
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _updateShuttleDetails,
                  child: const Text('Save Shuttle Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
