import 'package:flutter/material.dart';
import 'login.dart'; // Import the LoginScreen
import 'registration.dart'; // Import the DynamicRegistrationScreen

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_bus,
                    color: Colors.green,
                    size: 50,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'UniShuttle',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Welcome to UniShuttle!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Please Login or Register to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              // Login button
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to Login Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.login, color: Colors.black),
                label: const Text(
                  'Login',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[400],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Register button
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to the Dynamic Registration Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const DynamicRegistrationScreen()),
                  );
                },
                icon: const Icon(Icons.app_registration, color: Colors.white),
                label: const Text(
                  'Register',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
