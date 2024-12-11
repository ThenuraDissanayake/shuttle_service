import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/welcome.dart'; // Import the Welcome screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniShuttle',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const WelcomeScreen(), // Start with the Welcome screen
      debugShowCheckedModeBanner: false,
    );
  }
}
