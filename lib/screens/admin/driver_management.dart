import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDriverManagement extends StatefulWidget {
  @override
  _AdminDriverManagementState createState() => _AdminDriverManagementState();
}

class _AdminDriverManagementState extends State<AdminDriverManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Management'),
        backgroundColor: Colors.blue[800],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color.fromARGB(
              255, 255, 255, 255), // Color for the selected tab
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: "Pending Approval"),
            Tab(text: "Approved"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDriverList("pending"), // Pending Approval
          _buildDriverList("approved"), // Approved Drivers
        ],
      ),
    );
  }

  Widget _buildDriverList(String approvalStatus) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('drivers')
          .where('admin_approval', isEqualTo: approvalStatus)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No drivers found."));
        }

        var drivers = snapshot.data!.docs;

        return ListView.builder(
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            var driver = drivers[index];
            var data = driver.data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                title: Text(data['driver_name'] ?? "No Name"),
                subtitle: Text(
                    "${data['phone'] ?? 'No Phone'} • ${driver['shuttle']['license_plate'] ?? 'N/A'}"),
                trailing: Text(data['shuttle']['route'] ?? "No Route"),
                onTap: () => _showDriverDetails(driver.id, data),
              ),
            );
          },
        );
      },
    );
  }

  void _showDriverDetails(String driverId, Map<String, dynamic> driver) {
    // Extract shuttle map safely
    Map<String, dynamic>? shuttle = driver['shuttle'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Driver Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("👤 Name: ${driver['driver_name'] ?? 'N/A'}"),
              Text("📞 Phone: ${driver['phone'] ?? 'N/A'}"),
              Text("🚌 Shuttle: ${driver['shuttle']['shuttle_name'] ?? 'N/A'}"),
              Text("🚦 Route: ${driver['shuttle']['route'] ?? 'N/A'}"),
              Text(
                  "🔖 License Plate: ${driver['shuttle']['license_plate'] ?? 'N/A'}"),
              Text("🪑 Capacity: ${shuttle?['capacity'] ?? 'Unknown'} seats"),
              Text(
                  "💰 Full Journey Price: LKR ${shuttle?['full_journey_price'] ?? 'Unknown'}"),
              Text(
                "🕗 Morning Journey: ${driver['morning_journey_time'] != null ? DateFormat('dd MMM yyyy, hh:mm a').format((driver['morning_journey_time'] as Timestamp).toDate()) : 'N/A'}",
              ),
              Text(
                "🌙 Evening Journey: ${driver['evening_journey_time'] != null ? DateFormat('dd MMM yyyy, hh:mm a').format((driver['evening_journey_time'] as Timestamp).toDate()) : 'N/A'}",
              ),
              Text(
                  "📍 Main Stops: ${driver['shuttle']['main_stops'] ?? 'N/A'}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _updateApproval(driverId, "approved"),
              child: Text("✅ Approve", style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () => _updateApproval(driverId, "rejected"),
              child: Text("❌ Reject", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _updateApproval(String driverId, String newStatus) {
    FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .update({'admin_approval': newStatus}).then((_) {
      Navigator.pop(context); // Close the dialog after updating
    }).catchError((error) {
      print("Error updating status: $error");
    });
  }
}
