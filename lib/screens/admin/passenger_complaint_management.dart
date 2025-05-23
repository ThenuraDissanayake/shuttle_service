import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PassengerComplaintManagement extends StatefulWidget {
  const PassengerComplaintManagement({super.key});

  @override
  State<PassengerComplaintManagement> createState() =>
      _ComplaintManagementPageState();
}

class _ComplaintManagementPageState extends State<PassengerComplaintManagement>
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
        title: const Text('Complaint Management'),
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
          ComplaintListTab(status: 'Pending'),
          ComplaintListTab(status: 'In Progress'),
          ComplaintListTab(status: 'Resolved'),
        ],
      ),
    );
  }
}

class ComplaintListTab extends StatelessWidget {
  final String status;

  const ComplaintListTab({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For the initial tab, show all complaints if status is not yet set
    final Query query = status == 'Pending'
        ? FirebaseFirestore.instance
            .collection('complaints')
            .where('status', isEqualTo: status)
        : FirebaseFirestore.instance
            .collection('complaints')
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
          return Center(child: Text('No $status complaints found.'));
        }

        final complaints = snapshot.data!.docs;

        // Sort manually by createdAt if available
        try {
          complaints.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            // Try to get createdAt values
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
          // Continue with unsorted data
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
                title: Text(data['fullName'] ?? 'Unknown'),
                subtitle: Text(data['complaintType'] ?? 'No type'),
                trailing: Text(data['status'] ?? 'Pending'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminComplaintDetailsPage(
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

class AdminComplaintDetailsPage extends StatefulWidget {
  final String complaintId;
  const AdminComplaintDetailsPage({Key? key, required this.complaintId})
      : super(key: key);
  @override
  State<AdminComplaintDetailsPage> createState() =>
      _AdminComplaintDetailsPageState();
}

class _AdminComplaintDetailsPageState extends State<AdminComplaintDetailsPage> {
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
          .collection('complaints')
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
          .collection('complaints')
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
        title: const Text('Complaint Details'),
        backgroundColor: Colors.blue[800],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('complaints')
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
                Text("Name: ${complaintData['fullName']}"),
                Text("Email: ${complaintData['email']}"),
                Text("Type: ${complaintData['complaintType']}"),
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
