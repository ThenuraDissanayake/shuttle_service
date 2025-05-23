import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = "User"; // Default name if no data is found
  String _greeting = "";

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _updateGreeting();
  }

  void _updateGreeting() {
    var hour = DateTime.now().hour;
    setState(() {
      if (hour < 12) {
        _greeting = 'Good Morning';
      } else if (hour < 17) {
        _greeting = 'Good Afternoon';
      } else {
        _greeting = 'Good Evening';
      }
    });
  }

  // Fetch the user's name from Firestore
  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch from 'passengers' collection
        final userDoc = await FirebaseFirestore.instance
            .collection('passengers')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          // Cast to a Map to access fields
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userName = userData['name'] ?? 'User';
          });
        } else {
          print("No user data found in 'passengers' collection.");
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Return false to disable back button
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          // backgroundColor: Colors.green,
          title: Align(
            alignment: Alignment.centerLeft, // Align title to the left
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align text to the left
              children: [
                Text(
                  'Hi, $_userName',
                  style: const TextStyle(
                      // color: Colors.white,
                      fontSize: 15), // Set text color to white
                ),
                // const Text(
                //   'Welcome',
                //   style: TextStyle(
                //       // color: Colors.white,
                //       fontSize: 18), // Set text color to white
                // ),
                Text(
                  '$_greeting!',
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () {
                // Navigate to User Profile screen
                Navigator.pushNamed(context, '/passenger-profile');
              },
            ),
          ],
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
            child: ListView(
              // Using ListView to make the content scrollable
              padding: const EdgeInsets.all(16.0),
              children: [
                // UniShuttle logo with bus icon
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/bus_icon.png',
                        width: 50,
                        height: 50,
                      ),
                      const SizedBox(
                          height: 10), // Adds space between the icon and text
                      const Text(
                        'UniShuttle',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const Align(
                  alignment: Alignment.center, // Aligns the text to the left
                  child: Text(
                    '“Seat reservations for tomorrow \n will be available from 8.00 PM”',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),

                // Buttons for various actions
                Column(
                  children: [
                    _DashCard01(
                      icon: Icons.event_seat,
                      title: '      Reserve a Shuttle',
                      onTap: () {
                        Navigator.pushNamed(context, '/find-active-shuttles');
                        // Navigate to shuttle reservation page
                      },
                    ),
                    _DashCard(
                      icon: Icons.bookmark,
                      title: 'My Shuttle List',
                      onTap: () {
                        // Navigate to my shuttle list page
                        Navigator.pushNamed(context, '/favorite-shuttles');
                      },
                    ),
                    _DashCard(
                      icon: Icons.emoji_people,
                      title: 'Request for Special Shuttle',
                      onTap: () {
                        // Navigate to special shuttle request page
                        Navigator.pushNamed(context, '/special-shuttle');
                      },
                    ),
                    _DashCard(
                      icon: Icons.report,
                      title: 'Make a complaint',
                      onTap: () {
                        // Navigate to complaint page
                        Navigator.pushNamed(
                            context, '/passenger-make-complaints');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          // backgroundColor: const Color.fromARGB(255, 184, 245, 186),
          selectedItemColor: const Color.fromARGB(255, 0, 0, 0),
          unselectedItemColor: const Color.fromARGB(255, 191, 201, 183),
          currentIndex: 0, // Default active tab
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
                Navigator.pushNamed(context, '/passenger-dashboard');
                break;
              case 1:
                Navigator.pushNamed(context, '/my-bookings');
                break;
              case 2:
                Navigator.pushNamed(context, '/passenger-notifications');

                break;
              case 3:
                Navigator.pushNamed(context, '/passenger-profile');
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _DashCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 100, // Adjust the height
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center, // Centers content horizontally
            children: [
              Icon(icon,
                  color: const Color.fromARGB(255, 68, 72, 68), size: 30),
              const SizedBox(width: 10), // Spacing between icon and text
              Text(
                title,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _DashCard01({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return SizedBox(
    height: 120,
    child: Card(
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.green.shade100, // Soft green
                Colors.white, // Light white gradient
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 20), // Add spacing from the left
              Icon(
                icon,
                size: 40,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
