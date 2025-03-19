import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut(); // Firebase logout
      Navigator.pushNamed(context, '/');
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log out. Please try again.')),
      );
    }
  }

  Future<Map<String, String>> _getUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser; // Get current user
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('admins') // Adjust collection name if needed
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          return {
            'name': data['name'] ?? 'Unknown', // Fetch name
            'email': data['email'] ?? 'No email', // Fetch email
          };
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return {
      'name': 'Guest User',
      'email': 'guest@example.com',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        title: const Text('Admin Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading user data.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No user data found.'));
          } else {
            final userData = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Column(
                      children: [
                        // const CircleAvatar(
                        //   radius: 60,
                        //   backgroundImage: AssetImage(
                        //       'assets/profile_placeholder.png'), // Placeholder image
                        // ),
                        // const SizedBox(height: 10),
                        Text(
                          userData['name'] ??
                              'Unknown User', // Display user name
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          userData['email'] ?? 'No Email', // Display user email
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
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
                          title: 'Add or Remove Admins',
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
                          icon: Icons.logout,
                          title: 'Logout',
                          onTap: () => _logout(context), // Handle logout
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue[800],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
        currentIndex: 3,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_bus), label: 'Drivers'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people), label: 'Passengers'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/admin-dashboard');
              break;
            case 1:
              Navigator.pushNamed(context, '/driver-management');
              break;
            case 2:
              Navigator.pushNamed(context, '/passenger-management');
              break;
            case 3:
              Navigator.pushNamed(context, '/admin-settings');
              break;
          }
        },
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
        leading: Icon(icon, color: Colors.blue[800], size: 30),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
