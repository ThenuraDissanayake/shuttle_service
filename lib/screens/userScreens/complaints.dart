import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ComplaintManagementPage extends StatefulWidget {
  const ComplaintManagementPage({Key? key}) : super(key: key);

  @override
  State<ComplaintManagementPage> createState() =>
      _ComplaintManagementPageState();
}

class _ComplaintManagementPageState extends State<ComplaintManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Complaints'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Submit Complaint', icon: Icon(Icons.create)),
            Tab(text: 'Complaint History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ComplaintSubmissionTab(),
          ComplaintHistoryTab(),
        ],
      ),
    );
  }
}

// Complaint Submission Tab
class ComplaintSubmissionTab extends StatefulWidget {
  const ComplaintSubmissionTab({Key? key}) : super(key: key);

  @override
  State<ComplaintSubmissionTab> createState() => _ComplaintSubmissionTabState();
}

class _ComplaintSubmissionTabState extends State<ComplaintSubmissionTab> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _complaintTypeController =
      TextEditingController();
  final TextEditingController _driverInfoController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  String? _fullName;
  String? _email;

  @override
  void initState() {
    super.initState();
    _fetchPassengerDetails();
  }

  @override
  void dispose() {
    _complaintTypeController.dispose();
    _driverInfoController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchPassengerDetails() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('passengers')
            .doc(currentUser.uid)
            .get();

        if (docSnapshot.exists) {
          setState(() {
            _fullName = docSnapshot.data()?['name'] ?? '';
            _email = docSnapshot.data()?['email'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching passenger details: $e');
    }
  }

  Future<void> _submitComplaint() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final complaintData = {
          'fullName': _fullName,
          'email': _email,
          'complaintType': _complaintTypeController.text,
          'driverInfo': _driverInfoController.text,
          'description': _descriptionController.text,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'Pending',
        };

        await FirebaseFirestore.instance
            .collection('complaints')
            .add(complaintData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Your complaint has been submitted successfully!')),
        );

        // Clear the form
        _complaintTypeController.clear();
        _driverInfoController.clear();
        _descriptionController.clear();
      } catch (e) {
        debugPrint('Error submitting complaint: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Failed to submit your complaint. Please try again later.')),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _fullName == null || _email == null
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Help us improve by sharing your concerns. We value your feedback.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    // Full Name (Auto-filled)
                    TextFormField(
                      enabled: false,
                      initialValue: _fullName,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Email (Auto-filled)
                    TextFormField(
                      enabled: false,
                      initialValue: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Complaint Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _complaintTypeController.text.isEmpty
                          ? null
                          : _complaintTypeController.text,
                      items: const [
                        DropdownMenuItem(
                            value: 'Driver Issue', child: Text('Driver Issue')),
                        DropdownMenuItem(
                            value: 'App Issue', child: Text('App Issue')),
                        DropdownMenuItem(
                            value: 'Shuttle Service Issue',
                            child: Text('Shuttle Service Issue')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _complaintTypeController.text = value!;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Complaint Type',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null
                          ? 'Please select a complaint type'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Driver/Vehicle Information (Optional)
                    TextFormField(
                      controller: _driverInfoController,
                      decoration: const InputDecoration(
                        labelText: 'Driver/Vehicle Information (Optional)',
                        hintText: 'e.g., Driver John or Shuttle ID 12345',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Description of Complaint
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Describe your complaint in detail',
                        hintText: 'Write about what happened...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide a description of your complaint.';
                        } else if (value.length < 50) {
                          return 'Your description must be at least 50 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // Submit Button
                    Center(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitComplaint,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          backgroundColor: Colors.green,
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Submit Complaint'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Footer Note
                    const Center(
                      child: Text(
                        'Your complaint will be reviewed by the admin within 24-48 hours. '
                        'You may be contacted for further details if needed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}

// Complaint History Tab with improved sorting and display
class ComplaintHistoryTab extends StatelessWidget {
  const ComplaintHistoryTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Check if user is logged in
    if (user == null) {
      return const Center(
        child: Text("You need to be logged in to view complaints."),
      );
    }
    final userEmail = user.email;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('email', isEqualTo: userEmail)
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
          return const Center(child: Text('No complaints found.'));
        }

        // Get all complaints
        final List<DocumentSnapshot> complaints = snapshot.data!.docs;

        // Sort the complaints by createdAt manually (client-side)
        complaints.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTimestamp = aData['createdAt'] as Timestamp?;
          final bTimestamp = bData['createdAt'] as Timestamp?;

          // Handle null timestamps - put them at the end
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;

          // Sort in descending order (newest first)
          return bTimestamp.compareTo(aTimestamp);
        });

        return ListView.builder(
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final complaint = complaints[index].data() as Map<String, dynamic>;
            // Format timestamp if available
            String formattedDate = 'Date not available';
            if (complaint['createdAt'] != null) {
              final timestamp = complaint['createdAt'] as Timestamp;
              final date = timestamp.toDate();
              formattedDate = '${date.day}/${date.month}/${date.year}';
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: ExpansionTile(
                title: Text(
                  complaint['complaintType'] ?? 'Unknown Type',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Status: ${complaint['status'] ?? 'Pending'} • $formattedDate",
                  style: TextStyle(
                    color: _getStatusColor(complaint['status']),
                  ),
                ),
                trailing: Icon(
                  _getStatusIcon(complaint['status']),
                  color: _getStatusColor(complaint['status']),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Description:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(complaint['description'] ?? 'No description'),
                        const SizedBox(height: 8),
                        if (complaint['driverInfo'] != null &&
                            complaint['driverInfo'].toString().isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Driver/Vehicle Info:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(complaint['driverInfo']),
                              const SizedBox(height: 8),
                            ],
                          ),
                        const Text(
                          "Admin Reply:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(complaint['adminReply'] ?? 'No reply yet'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Resolved':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      case 'Rejected':
        return Colors.red;
      case 'Pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'Resolved':
        return Icons.check_circle;
      case 'In Progress':
        return Icons.autorenew;
      case 'Rejected':
        return Icons.cancel;
      case 'Pending':
      default:
        return Icons.hourglass_empty;
    }
  }
}
