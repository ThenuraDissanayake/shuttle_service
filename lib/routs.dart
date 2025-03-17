import 'package:flutter/material.dart';
import 'package:shuttle_service/screens/ShuttleOwnerScreens/shuttledashboard.dart';
import 'package:shuttle_service/screens/admin/admin_dashboard.dart';
import 'package:shuttle_service/screens/login.dart';
import 'package:shuttle_service/screens/registration.dart';
import 'package:shuttle_service/screens/userScreens/dashboard.dart';
// Import other screen files here

class Routes {
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/login': (context) => const LoginScreen(),
      '/register': (context) => const DynamicRegistrationScreen(),
      '/admin-dashboard': (context) => const AdminDashboardScreen(),
      '/passenger-dashboard': (context) => const DashboardScreen(),
      '/driver-dashboard': (context) => const OwnerDashboardPage(),
      // '/admin-settings': (context) => const AdminSettingsScreen(),
      // '/admin-notifications': (context) => const AdminNotificationScreen(),
      // '/driver-management': (context) => const DriverManagementScreen(),
      // '/passenger-management': (context) => const PassengerManagementScreen(),
      // '/review-complaints': (context) => const ReviewComplaintsScreen(),

      // Add other routes here
    };
  }
}
