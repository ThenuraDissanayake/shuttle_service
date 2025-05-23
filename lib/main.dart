import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shuttle_service/routs.dart';
import 'package:shuttle_service/services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(); // Initialize Firebase
    await NotificationService.initialize(); // Initialize notifications
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Error during initialization: $e");
    // Continue without .env if it fails to load
  }
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
      routes: Routes.getRoutes(),
      debugShowCheckedModeBanner: false,
    );
  }
}
