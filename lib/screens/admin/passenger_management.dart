import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPassengerManagement extends StatefulWidget {
  const AdminPassengerManagement({super.key});

  @override
  _AdminPassengerManagementState createState() =>
      _AdminPassengerManagementState();
}

class _AdminPassengerManagementState extends State<AdminPassengerManagement> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passenger Management'),
        backgroundColor: Colors.blue[800],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.white.withOpacity(0.9),
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('passengers').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No passengers found."));
              }

              var passengers = snapshot.data!.docs;

              return ListView.builder(
                itemCount: passengers.length,
                itemBuilder: (context, index) {
                  var passenger = passengers[index];
                  var data = passenger.data() as Map<String, dynamic>;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text(data['name'] ?? "No Name"),
                      subtitle: Text(data['email'] ?? 'No Email'),
                      trailing:
                          Text(data['isBanned'] == true ? 'Banned' : 'Active'),
                      onTap: () => _showPassengerDetails(passenger.id, data),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPassengerDetails(
      String passengerId, Map<String, dynamic> passenger) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Passenger Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("👤 Name: ${passenger['name'] ?? 'N/A'}"),
              Text("📧 Email: ${passenger['email'] ?? 'N/A'}"),
              Text("📞 Phone: ${passenger['phone'] ?? 'N/A'}"),
              // Text("🎫 Bookings: ${passenger['bookingCount'] ?? '0'}"),
              Text(
                  "🚫 Status: ${passenger['isBanned'] == true ? 'Banned' : 'Active'}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _updatePassengerStatus(
                  passengerId, passenger['isBanned'] != true),
              child: Text(
                passenger['isBanned'] == true ? "✅ Unban" : "❌ Ban",
                style: TextStyle(
                    color: passenger['isBanned'] == true
                        ? Colors.green
                        : Colors.red),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _updatePassengerStatus(String passengerId, bool banStatus) async {
    try {
      // Update the passenger's ban status in Firestore
      await FirebaseFirestore.instance
          .collection('passengers')
          .doc(passengerId)
          .update({'isBanned': banStatus});

      Navigator.pop(context); // Close the dialog
    } catch (error) {
      print("Error updating status: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $error')),
      );
    }
  }
}
