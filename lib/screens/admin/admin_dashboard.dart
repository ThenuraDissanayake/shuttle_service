import 'package:flutter/material.dart';
import 'package:shuttle_service/screens/admin/review_complaints.dart';
import 'reports_and_analytics.dart';
import 'shuttle_management.dart';
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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
        title: const Text('Admin'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[300],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
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
          const Text('System Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildDashboardCard('Total Shuttles', '15'),
                _buildDashboardCard('Active Users', '250'),
                _buildDashboardCard('Pending Approvals', '3'),
                const SizedBox(height: 20),
                _buildNavigationButton(
                  context,
                  'Manage Shuttles',
                  Icons.directions_bus,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ReviewComplaintsPage()),
                  ),
                ),
                _buildNavigationButton(
                  context,
                  'User Management',
                  Icons.people,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UserManagementPage()),
                  ),
                ),
                _buildNavigationButton(
                  context,
                  'Reports & Analytics',
                  Icons.analytics,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ReportsAnalyticsPage()),
                  ),
                ),
                _buildNavigationButton(
                  context,
                  'System Configuration',
                  Icons.settings,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SystemConfigPage()),
                  ),
                ),
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

  Widget _buildNavigationButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
