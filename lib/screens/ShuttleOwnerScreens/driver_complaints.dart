import 'dart:io'; // Import necessary for File type
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For file uploads
import 'package:image_picker/image_picker.dart'; // For image picking

class DriverComplaintManagementPage extends StatefulWidget {
  const DriverComplaintManagementPage({Key? key}) : super(key: key);

  @override
  State<DriverComplaintManagementPage> createState() =>
      _DriverComplaintManagementPageState();
}

class _DriverComplaintManagementPageState
    extends State<DriverComplaintManagementPage>
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
        title: const Text('Driver Complaints'),
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
          DriverComplaintSubmissionTab(),
          DriverComplaintHistoryTab(),
        ],
      ),
    );
  }
}

// Driver Complaint Submission Tab
class DriverComplaintSubmissionTab extends StatefulWidget {
  const DriverComplaintSubmissionTab({Key? key}) : super(key: key);

  @override
  State<DriverComplaintSubmissionTab> createState() =>
      _DriverComplaintSubmissionTabState();
}

class _DriverComplaintSubmissionTabState
    extends State<DriverComplaintSubmissionTab> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _complaintTypeController =
      TextEditingController();
  final TextEditingController _vehicleInfoController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _attachment; // Store file picked by user
  bool _isSubmitting = false; // Track submission state

  String? _driverName;
  String? _email;

  @override
  void initState() {
    super.initState();
    _fetchDriverDetails(); // Fetch the driver details on initialization
  }

  Future<void> _fetchDriverDetails() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(currentUser.uid)
            .get();

        if (docSnapshot.exists) {
          setState(() {
            _driverName =
                docSnapshot.data()?['driver_name'] ?? 'Unknown Driver';
            _email = docSnapshot.data()?['email'] ?? 'No Email';
          });
        } else {
          setState(() {
            _driverName = 'Unknown Driver';
            _email = 'No Email';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching driver details: $e');
      setState(() {
        _driverName = 'Unknown Driver';
        _email = 'No Email';
      });
    }
  }

  // Function to pick image or file
  Future<void> _pickAttachment() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _attachment = File(pickedFile.path);
      });
    }
  }

  // Function to upload file to Firebase Storage
  Future<String?> _uploadFile(File file) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
          'complaint_attachments/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _submitComplaint() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      try {
        String? attachmentUrl;
        if (_attachment != null) {
          attachmentUrl = await _uploadFile(_attachment!);
        }

        final complaintData = {
          'driverName': _driverName,
          'email': _email,
          'complaintType': _complaintTypeController.text,
          'vehicleInfo': _vehicleInfoController.text,
          'description': _descriptionController.text,
          'attachment': attachmentUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'Pending',
        };

        await FirebaseFirestore.instance
            .collection('driver_complaints')
            .add(complaintData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Your complaint has been submitted successfully!')),
        );

        // Clear the form
        _complaintTypeController.clear();
        _vehicleInfoController.clear();
        _descriptionController.clear();
        setState(() {
          _attachment = null;
        });
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
    return _driverName == null || _email == null
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
                      'Help us improve by sharing your concerns. We value your feedback as a driver.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    // Driver Name (Auto-filled)
                    TextFormField(
                      enabled: false,
                      initialValue: _driverName,
                      decoration: const InputDecoration(
                        labelText: 'Driver Name',
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
                            value: 'Passenger Issue',
                            child: Text('Passenger Issue')),
                        DropdownMenuItem(
                            value: 'App Issue', child: Text('App Issue')),
                        DropdownMenuItem(
                            value: 'Vehicle Issue',
                            child: Text('Vehicle Issue')),
                        DropdownMenuItem(
                            value: 'Route Issue', child: Text('Route Issue')),
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
                    // Vehicle Information (Optional)
                    TextFormField(
                      controller: _vehicleInfoController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Information (Optional)',
                        hintText: 'e.g., Vehicle ID 12345 or Bus Number 789',
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
                    const SizedBox(height: 16),
                    // Attachment (Optional)
                    ElevatedButton(
                      onPressed: _pickAttachment,
                      child:
                          const Text('Upload Supporting Documents or Images'),
                    ),
                    if (_attachment != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          children: [
                            if (_attachment!.path.endsWith('.jpg') ||
                                _attachment!.path.endsWith('.png'))
                              Image.file(_attachment!,
                                  height: 100, width: 100, fit: BoxFit.cover),
                            Text(
                                'File selected: ${_attachment!.path.split('/').last}'),
                          ],
                        ),
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

// Driver Complaint History Tab
class DriverComplaintHistoryTab extends StatelessWidget {
  const DriverComplaintHistoryTab({Key? key}) : super(key: key);

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
          .collection('driver_complaints')
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
                        if (complaint['vehicleInfo'] != null &&
                            complaint['vehicleInfo'].toString().isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Vehicle Info:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(complaint['vehicleInfo']),
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
