import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shuttle_service/screens/userScreens/my_bookings.dart';
import 'package:shuttle_service/screens/userScreens/passengernotiificationpage.dart';
import 'package:shuttle_service/screens/welcome.dart';
import 'dashboard.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut(); // Firebase logout
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const WelcomeScreen(), // Redirect to WelcomeScreen
        ),
      );
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
            .collection('passengers') // Adjust collection name if needed
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
        // backgroundColor: Colors.green,
        title: const Text('User Profile'),
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
                          icon: Icons.payment,
                          title: 'Paymeent Methords',
                          onTap: () {
                            // Navigate to booking preferences screen
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
        // backgroundColor: const Color.fromARGB(255, 184, 245, 186),
        selectedItemColor: const Color.fromARGB(255, 0, 0, 0),
        unselectedItemColor: const Color.fromARGB(255, 191, 201, 183),
        currentIndex: 3, // Default active tab
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_seat),
            label: 'My Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded),
            label: 'Account',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              );
              break;
            case 1:
              // Navigate to Activities page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyBookingsPage(),
                ),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PassengerNotificationPage(),
                ),
              );
              // Navigate to Notifications page
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfilePage(),
                ),
              );
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
        leading: Icon(icon, color: Colors.green, size: 30),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
