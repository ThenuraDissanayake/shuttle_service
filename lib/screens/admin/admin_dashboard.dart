import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  int totalPassengers = 0;
  int totalDrivers = 0;
  int pendingApprovals = 0;
  int totalComplaints = 0;

  @override
  void initState() {
    super.initState();
    _fetchData(); // Initial data fetch
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchData(); // Auto-refresh every 5 seconds
    });
  }

  Future<void> _fetchData() async {
    try {
      // Fetch total number of drivers
      QuerySnapshot driverSnapshot =
          await FirebaseFirestore.instance.collection('drivers').get();

      // Fetch pending driver approvals
      QuerySnapshot pendingSnapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .where('admin_approval', isEqualTo: 'pending')
          .get();

      // Fetch total complaints (assuming "complaints" collection exists)
      // QuerySnapshot complaintsSnapshot = await FirebaseFirestore.instance
      //     .collection('complaints')
      //     .where('status', isEqualTo: 'Pending') // Filter by status
      //     .get();

      QuerySnapshot complaintsSnapshot = await FirebaseFirestore.instance
          .collection('complaints')
          .where('status', isEqualTo: 'Pending')
          .get();

      QuerySnapshot driverComplaintsSnapshot = await FirebaseFirestore.instance
          .collection('driver_complaints')
          .where('status', isEqualTo: 'Pending')
          .get();

      QuerySnapshot passengerSnapshot =
          await FirebaseFirestore.instance.collection('passengers').get();

      setState(() {
        totalDrivers = driverSnapshot.size;
        pendingApprovals = pendingSnapshot.size;
        totalComplaints =
            complaintsSnapshot.size + driverComplaintsSnapshot.size;
        totalPassengers = passengerSnapshot.size;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue[800],
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.white.withOpacity(0.9),
          child: RefreshIndicator(
            onRefresh: () async {
              _fetchData(); // Manual refresh on pull-down
            },
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                children: [
                  // Overview Cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _overviewCard('Total Drivers', Icons.directions_bus,
                          Colors.red, totalDrivers),
                      _overviewCard('Pending Driver Approvals', Icons.pending,
                          Colors.orange, pendingApprovals),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _overviewCard('Total Complaints', Icons.report,
                          Colors.purple, totalComplaints),
                      _overviewCard('Total Passengers', Icons.people,
                          Colors.blue, totalPassengers),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _dashboardButton(
                      context, Icons.notification_add, 'Send Messages', () {
                    Navigator.pushNamed(context, '/admin-notifications');
                  }),
                  _dashboardButton(
                      context, Icons.report_problem, ' Passenger Complaints',
                      () {
                    Navigator.pushNamed(context, '/passenger-complaints');
                  }),
                  _dashboardButton(
                      context, Icons.report_problem, ' Driver Complaints', () {
                    Navigator.pushNamed(context, '/driver-complaints-admin');
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue[800],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
        currentIndex: _selectedIndex,
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

  Widget _overviewCard(String title, IconData icon, Color color, int count) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 10),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                count.toString(),
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardButton(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return SizedBox(
      height: 100,
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 12.0),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black, size: 30),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
