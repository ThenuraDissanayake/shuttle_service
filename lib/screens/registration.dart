import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart'; // Import your login screen
import 'userScreens/dashboard.dart'; // Passenger dashboard
import 'ShuttleOwnerScreens/shuttledashboard.dart'; // Shuttle owner dashboard

class DynamicRegistrationScreen extends StatefulWidget {
  const DynamicRegistrationScreen({super.key});

  @override
  State<DynamicRegistrationScreen> createState() =>
      _DynamicRegistrationScreenState();
}

class _DynamicRegistrationScreenState extends State<DynamicRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _selectedRole;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> _getNextShuttleNumber() async {
    // Reference to a special document that will track the last shuttle number
    DocumentReference counterRef =
        _firestore.collection('counters').doc('shuttle_number');

    // Use a transaction to ensure atomic increment
    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot counterSnap = await transaction.get(counterRef);

      if (!counterSnap.exists) {
        // If the counter doesn't exist, create it and start from 1
        transaction.set(counterRef, {'last_shuttle_number': 0});
        return 'Shuttle No1';
      }

      // Get the last shuttle number and increment
      int lastNumber = counterSnap['last_shuttle_number'] + 1;

      // Update the counter
      transaction.update(counterRef, {'last_shuttle_number': lastNumber});

      // Return the new shuttle number
      return 'Shuttle No$lastNumber';
    });
  }

  Future<void> registerUser() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a role.')),
        );
        return;
      }

      try {
        // Register user in Firebase Authentication
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // For drivers (owners), generate a shuttle number
        String shuttleNumber =
            _selectedRole == 'Driver' ? await _getNextShuttleNumber() : '';

        // Prepare Firestore data
        final userData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole == 'Driver'
              ? 'Owner'
              : _selectedRole, // Store as 'Owner' in Firestore if 'Driver' is selected
          'createdAt': FieldValue.serverTimestamp(),
          // Add Shuttle Number for Drivers
          if (_selectedRole == 'Driver') 'Shuttle_No': shuttleNumber,
        };

        // Save data in Firestore
        final String collection =
            _selectedRole == 'Passenger' ? 'passengers' : 'owners';
        await _firestore
            .collection(collection)
            .doc(userCredential.user!.uid)
            .set(userData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: _selectedRole == 'Driver'
                ? Text(
                    'Registration successful! Your Shuttle Number is: $shuttleNumber')
                : const Text('Registration successful!'),
          ),
        );

        // Navigate to the appropriate dashboard
        if (_selectedRole == 'Passenger') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else if (_selectedRole == 'Driver') {
          // Here, 'Driver' will map to 'Owner'
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OwnerDashboardPage()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: Center(
        // Center the body content
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // Ensure the column takes minimum space
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_bus,
                      color: Colors.green,
                      size: 50,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'UniShuttle',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),

                // Role Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: ['Passenger', 'Driver'] // Show Driver instead of Owner
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedRole = value),
                  decoration: InputDecoration(
                    labelText: 'Select Role',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  validator: (value) =>
                      value == null ? 'Please select a role' : null,
                ),
                const SizedBox(height: 20),

                // Name field
                TextFormField(
                  controller: _nameController,
                  enabled: _selectedRole != null,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 20),

                // Email field
                TextFormField(
                  controller: _emailController,
                  enabled: _selectedRole != null,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your email';
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
                  enabled: _selectedRole != null,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter your password'
                      : null,
                ),
                const SizedBox(height: 20),

                // Confirm Password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  enabled: _selectedRole != null,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                  validator: (value) => value != _passwordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: 30),

                // Register button
                ElevatedButton(
                  onPressed: registerUser,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
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
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
