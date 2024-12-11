import 'package:flutter/material.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('User Management'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 10, // Example: 10 users
        itemBuilder: (context, index) {
          return Card(
            elevation: 5,
            margin: const EdgeInsets.only(bottom: 16.0),
            child: ListTile(
              title: Text('User ${index + 1}'),
              subtitle: const Text('Role: Student'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  // Handle actions
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'Edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'Delete', child: Text('Delete')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
