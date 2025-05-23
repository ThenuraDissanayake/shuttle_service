import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageAdminsPage extends StatefulWidget {
  const ManageAdminsPage({super.key});

  @override
  State<ManageAdminsPage> createState() => _ManageAdminsPageState();
}

class _ManageAdminsPageState extends State<ManageAdminsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to add a new admin
  Future<void> registerAdmin() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Register the new admin in Firebase Authentication
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Prepare Firestore data for the admin
        final adminData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'admin', // Fixed role for all admins
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Save the admin data in Firestore under the "admins" collection
        await _firestore
            .collection('admins')
            .doc(userCredential.user!.uid)
            .set(adminData);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin added successfully!')),
        );

        // Clear the form fields after successful registration
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  // Method to remove an admin
  Future<void> removeAdmin(String adminId, String adminEmail) async {
    try {
      // Prevent deletion of the main admin
      if (adminEmail == 'admin1234@gmail.com') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'The main admin (admin1234@gmail.com) cannot be removed.')),
        );
        return;
      }

      // Delete the admin's document from Firestore
      await _firestore.collection('admins').doc(adminId).delete();

      // Delete the admin's account from Firebase Authentication
      User? user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin ($adminEmail) removed successfully!')),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Admins'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section for adding new admins
            const Text(
              'Add New Admin',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter admin name'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter admin email';
                      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                          .hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter admin password'
                        : null,
                  ),
                  const SizedBox(height: 30),

                  // Add Admin button
                  ElevatedButton(
                    onPressed: registerAdmin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Add Admin',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Section for removing existing admins
            const Text(
              'Remove Existing Admins',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('admins').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No admins found.'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var adminDoc = snapshot.data!.docs[index];
                    var adminData = adminDoc.data() as Map<String, dynamic>;
                    String adminId = adminDoc.id;
                    String adminName = adminData['name'];
                    String adminEmail = adminData['email'];

                    // Disable delete button for the main admin
                    bool isMainAdmin = adminEmail == 'admin1234@gmail.com';

                    return ListTile(
                      title: Text(adminName),
                      subtitle: Text(adminEmail),
                      trailing: isMainAdmin
                          ? const Icon(Icons.block, color: Colors.grey)
                          : IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => removeAdmin(adminId, adminEmail),
                            ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up controllers when the widget is disposed
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
