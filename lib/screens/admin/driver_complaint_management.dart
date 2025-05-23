import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverComplaintManagementAdmin extends StatefulWidget {
  const DriverComplaintManagementAdmin({Key? key}) : super(key: key);

  @override
  State<DriverComplaintManagementAdmin> createState() =>
      _DriverComplaintManagementAdminState();
}

class _DriverComplaintManagementAdminState
    extends State<DriverComplaintManagementAdmin>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Driver Complaints Management'),
        backgroundColor: Colors.blue[800],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DriverComplaintListTab(status: 'Pending'),
          DriverComplaintListTab(status: 'In Progress'),
          DriverComplaintListTab(status: 'Resolved'),
        ],
      ),
    );
  }
}

class DriverComplaintListTab extends StatelessWidget {
  final String status;

  const DriverComplaintListTab({Key? key, required this.status})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Query query = FirebaseFirestore.instance
        .collection('driver_complaints')
        .where('status', isEqualTo: status);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No $status driver complaints found.'));
        }

        final complaints = snapshot.data!.docs;

        // Sort manually by createdAt if available
        try {
          complaints.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aDate = aData['createdAt'];
            final bDate = bData['createdAt'];

            if (aDate != null && bDate != null) {
              return bDate
                  .toString()
                  .compareTo(aDate.toString()); // Descending order
            }
            return 0;
          });
        } catch (e) {
          print('Error sorting: $e');
        }

        return ListView.builder(
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final complaint = complaints[index];
            final complaintId = complaint.id;
            final data = complaint.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(data['driverName'] ?? 'Unknown Driver'),
                subtitle: Text(data['complaintType'] ?? 'No type'),
                trailing: Text(data['status'] ?? 'Pending'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminDriverComplaintDetailsPage(
                        complaintId: complaintId,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class AdminDriverComplaintDetailsPage extends StatefulWidget {
  final String complaintId;
  const AdminDriverComplaintDetailsPage({Key? key, required this.complaintId})
      : super(key: key);

  @override
  State<AdminDriverComplaintDetailsPage> createState() =>
      _AdminDriverComplaintDetailsPageState();
}

class _AdminDriverComplaintDetailsPageState
    extends State<AdminDriverComplaintDetailsPage> {
  final TextEditingController _replyController = TextEditingController();
  String _status = "Pending";

  @override
  void initState() {
    super.initState();
    _loadCurrentStatus();
  }

  Future<void> _loadCurrentStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('driver_complaints')
          .doc(widget.complaintId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _status = data['status'] ?? 'Pending';
        });
      }
    } catch (e) {
      print('Error loading status: $e');
    }
  }

  Future<void> _submitReply() async {
    if (_replyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reply')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('driver_complaints')
          .doc(widget.complaintId)
          .update({
        'adminReply': _replyController.text,
        'status': _status,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply submitted successfully')),
      );

      Navigator.pop(context); // Go back to the complaints list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting reply: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Complaint Details'),
        backgroundColor: Colors.blue[800],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('driver_complaints')
            .doc(widget.complaintId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Complaint not found.'));
          }

          final complaintData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Driver Name: ${complaintData['driverName']}"),
                Text("Email: ${complaintData['email']}"),
                Text("Type: ${complaintData['complaintType']}"),
                Text("Vehicle Info: ${complaintData['vehicleInfo'] ?? 'N/A'}"),
                Text("Description: ${complaintData['description']}"),
                Text("Status: ${complaintData['status'] ?? 'Pending'}"),
                const SizedBox(height: 16),
                TextField(
                  controller: _replyController,
                  decoration: const InputDecoration(
                    labelText: "Admin Reply",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(
                        value: 'In Progress', child: Text('In Progress')),
                    DropdownMenuItem(
                        value: 'Resolved', child: Text('Resolved')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _status = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitReply,
                  child: const Text('Submit Reply'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
