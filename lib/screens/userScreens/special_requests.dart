import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpecialShuttleRequestPage extends StatefulWidget {
  const SpecialShuttleRequestPage({Key? key}) : super(key: key);

  @override
  _SpecialShuttleRequestPageState createState() =>
      _SpecialShuttleRequestPageState();
}

class _SpecialShuttleRequestPageState extends State<SpecialShuttleRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _pickupLocationController =
      TextEditingController(text: "NSBM Green University");
  final TextEditingController _dropOffLocationController =
      TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _additionalRequestsController =
      TextEditingController();

  DateTime? _tripDateTime;
  int _numPassengers = 1;

  // Method to fetch user data from Firebase Firestore
  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Fetch user details from the "passengers" collection using the current user's UID
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('passengers')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          // Autofill the name and email from the fetched document
          setState(() {
            _fullNameController.text = userDoc['name'] ?? '';
            _emailController.text = userDoc['email'] ?? '';
          });
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      try {
        final requestData = {
          'fullName': _fullNameController.text,
          'email': _emailController.text,
          'contactNumber': _contactNumberController.text,
          'tripDateTime': _tripDateTime,
          'pickupLocation': _pickupLocationController.text,
          'dropOffLocation': _dropOffLocationController.text,
          'numPassengers': _numPassengers,
          'reason': _reasonController.text,
          'additionalRequests': _additionalRequestsController.text,
          'status': 'pending', // Set initial status as 'pending'
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('special_shuttle_requests')
            .add(requestData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your special shuttle request has been submitted!'),
          ),
        );
      } catch (e) {
        debugPrint('Error submitting request: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Failed to submit your request. Please try again later.'),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch user data on page load
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Special Shuttle'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need a ride for a special trip? Fill out the details and let us arrange a shuttle for you.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),

                // Full Name (autofilled, not editable)
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  readOnly: true,
                  enabled: false, // Prevent the user from editing this field
                ),
                const SizedBox(height: 16),

                // Email Address (autofilled, not editable)
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  readOnly: true, // Prevent the user from editing this field
                  enabled: false,
                ),
                const SizedBox(height: 16),

                // Contact Number
                TextFormField(
                  controller: _contactNumberController,
                  decoration: InputDecoration(
                    labelText: 'Contact Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your contact number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Trip Date & Time
                GestureDetector(
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2022),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          _tripDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'When do you need the shuttle?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    child: Text(
                      _tripDateTime != null
                          ? '${_tripDateTime!.toLocal()}'.split(' ')[0]
                          : 'Select date and time',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Pickup Location
                TextFormField(
                  controller: _pickupLocationController,
                  decoration: InputDecoration(
                    labelText: 'Pickup Location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Drop-Off Location
                TextFormField(
                  controller: _dropOffLocationController,
                  decoration: InputDecoration(
                    labelText: 'Drop-Off Location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your drop-off location.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'How many passengers?',
                    hintText: '1-50',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly, // Restrict to digits only
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      // Ensure the input is between 1 and 50
                      if (newValue.text.isNotEmpty) {
                        final int? value = int.tryParse(newValue.text);
                        if (value != null && (value < 1 || value > 50)) {
                          return oldValue; // Keep old value if out of range
                        }
                      }
                      return newValue;
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _numPassengers = int.tryParse(value) ?? 1;
                      if (_numPassengers < 1) {
                        _numPassengers = 1; // Ensure minimum value is 1
                      } else if (_numPassengers > 50) {
                        _numPassengers = 50; // Ensure maximum value is 50
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Reason for Request (Optional)
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason for Special Shuttle Request',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Additional Requirements (Optional)
                TextFormField(
                  controller: _additionalRequestsController,
                  decoration: InputDecoration(
                    labelText: 'Do you have any special requests?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Submit Button
                Center(
                  child: ElevatedButton(
                    onPressed: _submitRequest,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Submit Request'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
