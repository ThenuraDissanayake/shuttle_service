import 'dart:io'; // Import necessary for File type
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // For image picking
import 'package:file_picker/file_picker.dart'; // Optional, if you want to pick files other than images

class ComplaintSubmissionPage extends StatefulWidget {
  const ComplaintSubmissionPage({Key? key}) : super(key: key);

  @override
  State<ComplaintSubmissionPage> createState() =>
      _ComplaintSubmissionPageState();
}

class _ComplaintSubmissionPageState extends State<ComplaintSubmissionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _complaintTypeController =
      TextEditingController();
  final TextEditingController _driverInfoController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _attachment; // Store file picked by user

  String? _fullName;
  String? _email;

  @override
  void initState() {
    super.initState();
    _fetchPassengerDetails(); // Fetch the passenger details on initialization
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

  // Function to pick image or file
  Future<void> _pickAttachment() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _attachment = File(pickedFile.path);
      });
    }
    // Optionally, you can use FilePicker for file attachments
    // final result = await FilePicker.platform.pickFiles();
    // if (result != null) {
    //   setState(() {
    //     _attachment = File(result.files.single.path!);
    //   });
    // }
  }

  Future<void> _submitComplaint() async {
    if (_formKey.currentState!.validate()) {
      try {
        final complaintData = {
          'fullName': _fullName,
          'email': _email,
          'complaintType': _complaintTypeController.text,
          'driverInfo': _driverInfoController.text,
          'description': _descriptionController.text,
          'attachment': _attachment != null ? 'Uploaded File Path' : null,
          'createdAt': FieldValue.serverTimestamp(),
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit a Complaint'),
        // backgroundColor: Colors.green,
      ),
      body: _fullName == null || _email == null
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
                              value: 'Driver Issue',
                              child: Text('Driver Issue')),
                          DropdownMenuItem(
                              value: 'App Issue', child: Text('App Issue')),
                          DropdownMenuItem(
                              value: 'Shuttle Service Issue',
                              child: Text('Shuttle Service Issue')),
                          DropdownMenuItem(
                              value: 'Other', child: Text('Other')),
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
                      const SizedBox(height: 16),
                      // Attachment (Optional)
                      ElevatedButton(
                        onPressed: _pickAttachment,
                        child:
                            const Text('Upload Supporting Documents or Images'),
                      ),
                      const SizedBox(height: 32),
                      // Submit Button
                      Center(
                        child: ElevatedButton(
                          onPressed: _submitComplaint,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Submit Complaint'),
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
            ),
    );
  }
}
