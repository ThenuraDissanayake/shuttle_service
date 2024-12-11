import 'package:flutter/material.dart';
import 'reports_and_analytics.dart';
import 'shuttle_approval.dart';
import 'sys_configuration.dart';
import 'user_management.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    AdminDashboardContent(),
    ShuttleApprovalPage(),
    UserManagementPage(),
    ReportsAnalyticsPage(),
    SystemConfigPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Admin'),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.account_circle),
        //     onPressed: () {
        //       // Navigate to profile page or admin settings
        //     },
        //   ),
        // ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue, // Matches the app theme
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[300], // Softer unselected color
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed, // Keeps labels visible
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.approval),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class AdminDashboardContent extends StatelessWidget {
  const AdminDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text('System Overview', style: TextStyle(fontSize: 24)),
          Expanded(
            child: ListView(
              children: [
                _buildDashboardCard('Total Shuttles', '15'),
                _buildDashboardCard('Active Users', '250'),
                _buildDashboardCard('Pending Approvals', '3'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String title, String count) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18)),
            Text(
              count,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
