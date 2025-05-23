import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
// import '../models/driver.dart';

class DriverPaymentSetup extends StatefulWidget {
  @override
  _DriverPaymentSetupState createState() => _DriverPaymentSetupState();
}

class _DriverPaymentSetupState extends State<DriverPaymentSetup> {
  final _formKey = GlobalKey<FormState>();
  final _merchantIdController = TextEditingController();
  final _merchantSecretController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isLoading = false;
  bool _hasExistingDetails = false;

  @override
  void initState() {
    super.initState();
    _checkExistingDetails();
  }

  Future<void> _checkExistingDetails() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists && docSnapshot.data()?['merchantId'] != null) {
          setState(() => _hasExistingDetails = true);

          // Pre-fill the form with existing data
          _merchantIdController.text = docSnapshot.data()?['merchantId'] ?? '';
          _nameController.text = docSnapshot.data()?['name'] ?? '';
          _emailController.text = docSnapshot.data()?['email'] ?? '';
          _phoneController.text = docSnapshot.data()?['phone'] ?? '';
          _addressController.text = docSnapshot.data()?['address'] ?? '';
          _cityController.text = docSnapshot.data()?['city'] ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading existing details: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _hashSecret(String secret) {
    final bytes = utf8.encode(secret);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<void> _saveDriverDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user found');

      // Hash the merchant secret before storing
      final hashedSecret = _hashSecret(_merchantSecretController.text);

      final driverData = {
        // 'name': _nameController.text,
        'merchantId': _merchantIdController.text,
        'merchantSecret': hashedSecret, // Store hashed secret
        // 'email': _emailController.text,
        // 'phone': _phoneController.text,
        // 'address': _addressController.text,
        // 'city': _cityController.text,
        'country': 'Sri Lanka',
        // 'createdAt': FieldValue.serverTimestamp(),
        // 'updatedAt': FieldValue.serverTimestamp(),
      };

      // Store in Firestore
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .set(driverData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment details saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Setup Payment Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Setup Payment Details'),
        actions: [
          if (_hasExistingDetails)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _hasExistingDetails = false),
              tooltip: 'Edit Details',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: _hasExistingDetails
            ? Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Details Already Configured',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 16),
                      Text('Merchant ID: ${_merchantIdController.text}'),
                      // Text('Name: ${_nameController.text}'),
                      // Text('Email: ${_emailController.text}'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            setState(() => _hasExistingDetails = false),
                        child: Text('Update Details'),
                      ),
                    ],
                  ),
                ),
              )
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _merchantIdController,
                      decoration: InputDecoration(
                        labelText: 'PayHere Merchant ID',
                        hintText: 'Enter your PayHere merchant ID',
                      ),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Merchant ID is required'
                          : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _merchantSecretController,
                      decoration: InputDecoration(
                        labelText: 'Merchant Secret',
                        hintText: 'Enter your PayHere merchant secret',
                      ),
                      obscureText: true,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Merchant secret is required'
                          : null,
                    ),
                    // Add other fields...
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveDriverDetails,
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Save Payment Details'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _merchantIdController.dispose();
    _merchantSecretController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}
