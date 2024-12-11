import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Handle logout action if needed
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                  // CircleAvatar(
                  //   radius: 60,
                  //   backgroundImage: AssetImage(
                  //       'assets/profile_placeholder.png'), // Placeholder image
                  // ),
                  SizedBox(height: 10),
                  Text(
                    'John Doe', // Replace with dynamic data
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'johndoe@example.com', // Replace with dynamic data
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _buildProfileOption(
                    icon: Icons.person,
                    title: 'Edit Personal Details',
                    onTap: () {
                      // Navigate to edit personal details screen
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.lock,
                    title: 'Change Password',
                    onTap: () {
                      // Navigate to change password screen
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.settings,
                    title: 'Booking Preferences',
                    onTap: () {
                      // Navigate to booking preferences screen
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () {
                      // Handle logout logic here
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Colors.green, size: 30),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
