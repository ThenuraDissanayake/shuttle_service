import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpecialShuttlePage extends StatefulWidget {
  const SpecialShuttlePage({Key? key}) : super(key: key);

  @override
  _SpecialShuttlePageState createState() => _SpecialShuttlePageState();
}

class _SpecialShuttlePageState extends State<SpecialShuttlePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Special Shuttle'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Request'),
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SpecialShuttleRequestTab(),
          PendingSpecialShuttleTab(),
          AcceptedSpecialShuttleTab(),
        ],
      ),
    );
  }
}

// Request Tab (former SpecialShuttleRequestPage)
class SpecialShuttleRequestTab extends StatefulWidget {
  const SpecialShuttleRequestTab({Key? key}) : super(key: key);

  @override
  _SpecialShuttleRequestTabState createState() =>
      _SpecialShuttleRequestTabState();
}

class _SpecialShuttleRequestTabState extends State<SpecialShuttleRequestTab> {
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
    return Padding(
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
    );
  }
}

// Pending Tab (former PendingSpecialShuttlePage)
class PendingSpecialShuttleTab extends StatelessWidget {
  const PendingSpecialShuttleTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Check if user is logged in
    if (user == null) {
      return const Center(
        child:
            Text("You need to be logged in to view pending special shuttles."),
      );
    }

    final userEmail = user.email;

    return StreamBuilder<QuerySnapshot>(
      // Query the special_shuttle_requests collection and filter by status 'pending'
      stream: FirebaseFirestore.instance
          .collection('special_shuttle_requests')
          .where('status', isEqualTo: 'pending') // Filter based on status
          .where('email',
              isEqualTo: userEmail) // Optionally filter by user email
          .snapshots(),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle errors
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong: ${snapshot.error}'));
        }

        // If no data is found
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No pending special shuttle requests found.'));
        }

        final specialShuttles = snapshot.data!.docs;

        return ListView.builder(
          itemCount: specialShuttles.length,
          itemBuilder: (context, index) {
            final shuttle =
                specialShuttles[index].data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: ListTile(
                title: Text(
                  "Passenger Name: ${shuttle['fullName'] ?? 'Unknown_name'}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Status: ${shuttle['status'] ?? 'Unknown status'}"),
                    Text(
                        "Pickup Location: ${shuttle['pickupLocation'] ?? 'N/A'}"),
                    Text(
                        "Dropoff Location: ${shuttle['dropOffLocation'] ?? 'N/A'}"),
                    Text(
                        "Date & Time: ${shuttle['tripDateTime']?.toDate().toString() ?? 'N/A'}"),
                    Text(
                        "Reason: ${shuttle['reason'] ?? 'No reason provided'}"),
                  ],
                ),
                trailing: const Icon(Icons.access_time, color: Colors.orange),
              ),
            );
          },
        );
      },
    );
  }
}

// Accepted Tab (former AcceptedSpecialShuttlePage)
class AcceptedSpecialShuttleTab extends StatelessWidget {
  const AcceptedSpecialShuttleTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Check if user is logged in
    if (user == null) {
      return const Center(
        child:
            Text("You need to be logged in to view accepted special shuttles."),
      );
    }

    final userEmail = user.email;

    return StreamBuilder<QuerySnapshot>(
      // Query the special_shuttle_requests collection and filter by status 'accepted'
      stream: FirebaseFirestore.instance
          .collection('special_shuttle_requests')
          .where('status', isEqualTo: 'accepted') // Filter based on status
          .where('email',
              isEqualTo: userEmail) // Optionally filter by user email
          .snapshots(),
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle errors
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong: ${snapshot.error}'));
        }

        // If no data is found
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No accepted special shuttles found.'));
        }

        final specialShuttles = snapshot.data!.docs;

        return ListView.builder(
          itemCount: specialShuttles.length,
          itemBuilder: (context, index) {
            final shuttle =
                specialShuttles[index].data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: ListTile(
                title: Text(
                  "Accepted by: ${shuttle['driver_name'] ?? 'Unknown Driver'}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "Driver Phone: ${shuttle['driver_phone'] ?? 'No phone number'}"),
                    Text(
                        "Pickup Location: ${shuttle['pickupLocation'] ?? 'N/A'}"),
                    Text(
                        "Date & Time: ${shuttle['tripDateTime']?.toDate().toString() ?? 'N/A'}"),
                    Text(
                        "Shuttle Type: ${shuttle['shuttle_details']['shuttle_type'] ?? 'N/A'}"),
                    Text(
                        "Capacity: ${shuttle['shuttle_details']['capacity'] ?? 'N/A'}"),
                    Text(
                        "License Plate: ${shuttle['shuttle_details']['license_plate'] ?? 'N/A'}"),
                  ],
                ),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            );
          },
        );
      },
    );
  }
}
