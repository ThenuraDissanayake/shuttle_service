import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpecialRequestsPage extends StatefulWidget {
  const SpecialRequestsPage({Key? key}) : super(key: key);

  @override
  _SpecialRequestsPageState createState() => _SpecialRequestsPageState();
}

class _SpecialRequestsPageState extends State<SpecialRequestsPage> {
  List<Map<String, dynamic>> pendingRequests = [];
  List<Map<String, dynamic>> acceptedRequests = [];
  Map<String, dynamic>? driverDetails;
  bool isLoading = true;
  int _selectedIndex = 0;
  String? currentDriverId;

  @override
  void initState() {
    super.initState();
    _initializeDriverData();
  }

  // Initialize driver data using Firebase Auth
  Future<void> _initializeDriverData() async {
    try {
      // Get current user from Firebase Auth
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        currentDriverId = currentUser.uid;
        await _fetchDriverDetails();
        await _fetchRequests();
      } else {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No driver logged in')),
          );
        }
      }
    } catch (e) {
      print('Error initializing driver data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch driver details
  Future<void> _fetchDriverDetails() async {
    try {
      DocumentSnapshot driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(currentDriverId)
          .get();

      if (driverDoc.exists) {
        setState(() {
          driverDetails = driverDoc.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print('Error fetching driver details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching driver details: $e')),
        );
      }
    }
  }

  // Fetch both pending and accepted requests
  Future<void> _fetchRequests() async {
    try {
      // Fetch pending requests
      QuerySnapshot pendingSnapshot = await FirebaseFirestore.instance
          .collection('special_shuttle_requests')
          .where('status', isEqualTo: 'pending')
          .get();

      // Fetch requests accepted by this driver
      QuerySnapshot acceptedSnapshot = await FirebaseFirestore.instance
          .collection('special_shuttle_requests')
          .where('status', isEqualTo: 'accepted')
          .where('driver_id', isEqualTo: currentDriverId)
          .get();

      if (mounted) {
        setState(() {
          pendingRequests = pendingSnapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  })
              .toList();

          acceptedRequests = acceptedSnapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  })
              .toList();

          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching requests: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching requests: $e')),
        );
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  // Handle accept/reject with driver details
  Future<void> _handleRequest(String requestId, String status) async {
    if (driverDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver details not available')),
      );
      return;
    }

    try {
      Map<String, dynamic> updateData = {
        'status': status,
      };

      // Add driver details when accepting
      if (status == 'accepted') {
        updateData.addAll({
          'driver_id': currentDriverId,
          'driver_name': driverDetails?['driver_name'],
          'driver_phone': driverDetails?['phone'],
          'shuttle_details': {
            'license_plate': driverDetails?['shuttle']['license_plate'],
            'shuttle_type': driverDetails?['shuttle']['shuttle_type'],
            'capacity': driverDetails?['shuttle']['capacity'],
          }
        });
      }

      await FirebaseFirestore.instance
          .collection('special_shuttle_requests')
          .doc(requestId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $status successfully!')),
        );
      }

      _fetchRequests();
      Navigator.pop(context);
    } catch (e) {
      print('Error updating request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating request: $e')),
        );
      }
    }
  }

  Widget _buildRequestCard(Map<String, dynamic> request, bool isAccepted) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Request Details'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${request['fullName']}'),
                    Text('Email: ${request['email']}'),
                    Text('Contact: ${request['contactNumber']}'),
                    Text('Pickup: ${request['pickupLocation']}'),
                    Text('Drop-off: ${request['dropOffLocation']}'),
                    Text('Passengers: ${request['numPassengers']}'),
                    Text('Reason: ${request['reason']}'),
                    if (request['additionalRequests']?.isNotEmpty ?? false)
                      Text('Additional: ${request['additionalRequests']}'),
                    Text(
                      'Trip Date: ${request['tripDateTime'].toDate()}',
                    ),
                  ],
                ),
              ),
              actions: [
                if (!isAccepted) ...[
                  // TextButton(
                  //   onPressed: () => _handleRequest(request['id'], 'rejected'),
                  //   style: TextButton.styleFrom(foregroundColor: Colors.red),
                  //   child: const Text('Reject'),
                  // ),
                  TextButton(
                    onPressed: () => _handleRequest(request['id'], 'accepted'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                    child: const Text('Accept'),
                  ),
                ],
              ],
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: isAccepted ? Colors.blue : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    request['fullName'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Pickup: ${request['pickupLocation']}',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                'Drop-off: ${request['dropOffLocation']}',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                'Trip Date: ${request['tripDateTime'].toDate().toString().split(" ")[0]}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Special Requests'),
        // backgroundColor: Colors.green,
      ),
      bottomNavigationBar: BottomNavigationBar(
        // backgroundColor: Colors.green,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions),
            label: 'Pending',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Accepted',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedIndex == 0
              ? pendingRequests.isEmpty
                  ? const Center(child: Text('No pending requests.'))
                  : ListView.builder(
                      itemCount: pendingRequests.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) =>
                          _buildRequestCard(pendingRequests[index], false),
                    )
              : acceptedRequests.isEmpty
                  ? const Center(child: Text('No accepted requests.'))
                  : ListView.builder(
                      itemCount: acceptedRequests.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) =>
                          _buildRequestCard(acceptedRequests[index], true),
                    ),
    );
  }
}
