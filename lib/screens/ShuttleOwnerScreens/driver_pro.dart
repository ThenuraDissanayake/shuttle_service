import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverDetailsPage extends StatefulWidget {
  const DriverDetailsPage({super.key});

  @override
  State<DriverDetailsPage> createState() => _DriverDetailsPageState();
}

class _DriverDetailsPageState extends State<DriverDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _shuttleNameController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _shuttleTypeController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _mainStopController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isEditing = false;
  bool _isSubmitted = false;
  Map<String, dynamic>? _driverData;
  String _driverName = "Unknown";
  String _shuttleNo = "";

  // List to store multiple main stops
  List<String> _mainStops = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchDriverData();
  }

  Future<void> _fetchDriverData() async {
    final user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot ownerDoc =
          await _firestore.collection('owners').doc(user.uid).get();
      if (ownerDoc.exists) {
        final userData = ownerDoc.data() as Map<String, dynamic>;
        setState(() {
          _driverName = userData['name'] ?? 'Unknown';
          _shuttleNo = userData['Shuttle_No'] ?? '';
          _shuttleNameController.text = _driverName;
        });
      }

      final driverDoc =
          await _firestore.collection('drivers').doc(user.uid).get();
      if (driverDoc.exists) {
        setState(() {
          _driverData = driverDoc.data() as Map<String, dynamic>;
          _shuttleNameController.text =
              _driverData?['shuttle']['shuttle_name'] ?? _driverName;
          _licensePlateController.text =
              _driverData?['shuttle']['license_plate'] ?? '';
          _shuttleTypeController.text =
              _driverData?['shuttle']['shuttle_type'] ?? '';
          _capacityController.text =
              _driverData?['shuttle']['capacity']?.toString() ?? '';

          // Fetch route and main stops
          _routeController.text = _driverData?['shuttle']['route'] ?? '';

          dynamic mainStopsData = _driverData?['shuttle']['main_stops'];
          if (mainStopsData is List) {
            _mainStops = List<String>.from(mainStopsData);
          }

          _phoneController.text = _driverData?['phone'] ?? '';
          _isSubmitted = true;
        });
      }
    }
  }

  // Method to add a new main stop
  void _addMainStop() {
    String newMainStop = _mainStopController.text.trim();
    if (newMainStop.isNotEmpty && !_mainStops.contains(newMainStop)) {
      setState(() {
        _mainStops.add(newMainStop);
        _mainStopController.clear(); // Clear the input after adding
      });
    }
  }

  // Method to remove a main stop
  void _removeMainStop(String mainStop) {
    setState(() {
      _mainStops.remove(mainStop);
    });
  }

  Future<void> saveDriverDetails() async {
    if (_formKey.currentState!.validate() && _mainStops.isNotEmpty) {
      try {
        final user = _auth.currentUser;
        if (user != null) {
          final driverData = {
            'driver_name': _driverName,
            'phone': _phoneController.text.trim(),
            'shuttle': {
              'shuttle_name': _shuttleNameController.text.trim(),
              'license_plate': _licensePlateController.text.trim(),
              'shuttle_type': _shuttleTypeController.text.trim(),
              'capacity': int.parse(_capacityController.text.trim()),
              'route': _routeController.text.trim(), // Single route
              'main_stops': _mainStops, // List of main stops
              'status': 'Active',
            },
          };

          await _firestore.collection('drivers').doc(user.uid).set(driverData);

          setState(() {
            _isSubmitted = true;
            _isEditing = false;
            _driverData = driverData;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Driver details saved successfully!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving driver details: $e')),
        );
      }
    }
  }

  Future<void> updateDriverDetails() async {
    try {
      final user = _auth.currentUser;
      if (user != null && _driverData != null) {
        final updatedData = {
          'phone': _phoneController.text.trim(),
          'shuttle': {
            'shuttle_name': _shuttleNameController.text.trim(),
            'license_plate': _licensePlateController.text.trim(),
            'shuttle_type': _shuttleTypeController.text.trim(),
            'capacity': int.parse(_capacityController.text.trim()),
            'route': _routeController.text.trim(), // Single route
            'main_stops': _mainStops, // List of main stops
            'status': 'Active',
          },
        };

        await _firestore
            .collection('drivers')
            .doc(user.uid)
            .update(updatedData);

        setState(() {
          _isEditing = false;
          _driverData = updatedData;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver details updated successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating driver details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_shuttleNo '),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isSubmitted && !_isEditing
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Driver Name: $_driverName',
                      style: const TextStyle(fontSize: 22),
                    ),
                    Text(
                      'Shuttle Number: $_shuttleNo',
                      style: const TextStyle(fontSize: 22),
                    ),
                    Text(
                      'Shuttle Name: ${_driverData?['shuttle']['shuttle_name'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 22),
                    ),
                    Text(
                      'License Plate: ${_driverData?['shuttle']['license_plate'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 22),
                    ),
                    Text(
                      'Shuttle Type: ${_driverData?['shuttle']['shuttle_type'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 22),
                    ),
                    Text(
                      'Capacity: ${_driverData?['shuttle']['capacity'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 22),
                    ),
                    // Display route
                    Text(
                      'Route: ${_driverData?['shuttle']['route'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 22),
                    ),
                    // Display main stops
                    Text(
                      'Main Stops: ${_mainStops.isNotEmpty ? _mainStops.join(", ") : 'N/A'}',
                      style: const TextStyle(fontSize: 22),
                    ),
                    Text(
                      'Phone: ${_driverData?['phone'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      child: const Text('Edit Profile'),
                    ),
                  ],
                ),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _shuttleNameController,
                      decoration:
                          const InputDecoration(labelText: 'Driver Name'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter shuttle name'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _licensePlateController,
                      decoration:
                          const InputDecoration(labelText: 'License Plate'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter license plate'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _shuttleTypeController,
                      decoration:
                          const InputDecoration(labelText: 'Shuttle Type'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter shuttle type'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _capacityController,
                      decoration: const InputDecoration(labelText: 'Capacity'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter capacity'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    // Route input
                    TextFormField(
                      controller: _routeController,
                      decoration: const InputDecoration(
                          labelText: 'Route (e.g., NSBM - Colombo)'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter route' : null,
                    ),
                    const SizedBox(height: 20),
                    // Main stops input with add button
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _mainStopController,
                            decoration: const InputDecoration(
                                labelText: 'Add Main Stop'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: _addMainStop,
                        ),
                      ],
                    ),
                    // Display added main stops
                    if (_mainStops.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          const Text(
                            'Current Main Stops:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Wrap(
                            spacing: 8.0,
                            children: _mainStops.map((mainStop) {
                              return Chip(
                                label: Text(mainStop),
                                onDeleted: () => _removeMainStop(mainStop),
                                deleteIcon: const Icon(Icons.cancel),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter phone number'
                          : null,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _mainStops.isNotEmpty
                          ? (_isSubmitted
                              ? updateDriverDetails
                              : saveDriverDetails)
                          : null, // Disable if no main stops
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        _isSubmitted ? 'Update Details' : 'Save Driver Details',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up controllers
    _shuttleNameController.dispose();
    _licensePlateController.dispose();
    _shuttleTypeController.dispose();
    _capacityController.dispose();
    _routeController.dispose();
    _mainStopController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
