import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
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
