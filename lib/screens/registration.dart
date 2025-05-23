import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  bool _agreedToTerms = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> _getNextShuttleNumber() async {
    DocumentReference counterRef =
        _firestore.collection('counters').doc('shuttle_number');

    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot counterSnap = await transaction.get(counterRef);

      if (!counterSnap.exists) {
        transaction.set(counterRef, {'last_shuttle_number': 0});
        return 'Shuttle No1';
      }

      int lastNumber = counterSnap['last_shuttle_number'] + 1;
      transaction.update(counterRef, {'last_shuttle_number': lastNumber});
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

      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please agree to the terms & conditions.')),
        );
        return;
      }

      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        String shuttleNumber =
            _selectedRole == 'Driver' ? await _getNextShuttleNumber() : '';

        final userData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole == 'Driver' ? 'Owner' : _selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
          if (_selectedRole == 'Driver') 'Shuttle_No': shuttleNumber,
        };

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

        if (_selectedRole == 'Passenger') {
          Navigator.pushNamed(context, '/passenger-dashboard');
        } else if (_selectedRole == 'Driver') {
          Navigator.pushNamed(context, '/driver-dashboard');
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
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/bus_icon.png',
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(width: 10),
                    const Text(
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
                  items: ['Passenger', 'Driver']
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

                // Name
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

                // Email
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

                // Password
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

                // Confirm Password
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
                const SizedBox(height: 20),

                // Terms & Conditions
                CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _agreedToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreedToTerms = value ?? false;
                    });
                  },
                  title: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        const TextSpan(text: '  I agree to the '),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              // Load terms from assets/terms.txt
                              String termsContent = 'Loading terms...';
                              try {
                                termsContent =
                                    await DefaultAssetBundle.of(context)
                                        .loadString('assets/terms.txt');
                              } catch (e) {
                                termsContent =
                                    'Failed to load terms. Please try again later.';
                              }
                              // Show terms and conditions in a dialog
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Terms & Conditions'),
                                  content: SingleChildScrollView(
                                    child: Text(
                                        termsContent), // Dynamically loaded terms
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Register Button
                ElevatedButton(
                  onPressed: _agreedToTerms ? registerUser : null,
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
                const SizedBox(height: 20),

                // Already have an account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
