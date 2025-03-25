import 'package:flutter/material.dart';
import 'package:shuttle_service/screens/ShuttleOwnerScreens/Driver_userProfile.dart';
import 'package:shuttle_service/screens/ShuttleOwnerScreens/booking_requests_management.dart';
import 'package:shuttle_service/screens/ShuttleOwnerScreens/driver_complaints.dart';
import 'package:shuttle_service/screens/ShuttleOwnerScreens/driver_details.dart';
import 'package:shuttle_service/screens/ShuttleOwnerScreens/driver_payment_setup.dart';
import 'package:shuttle_service/screens/ShuttleOwnerScreens/drivernotificationpage.dart';
import 'package:shuttle_service/screens/ShuttleOwnerScreens/qr_scanner.dart';
import 'package:shuttle_service/screens/ShuttleOwnerScreens/shuttleManagement.dart';
import 'package:shuttle_service/screens/ShuttleOwnerScreens/shuttledashboard.dart';
import 'package:shuttle_service/screens/ShuttleOwnerScreens/update_driver_location.dart';
import 'package:shuttle_service/screens/ShuttleOwnerScreens/view_special_requests.dart';
import 'package:shuttle_service/screens/admin/admin_dashboard.dart';
import 'package:shuttle_service/screens/admin/admin_settings.dart';
import 'package:shuttle_service/screens/admin/adminnotificationpage.dart';
import 'package:shuttle_service/screens/admin/driver_complaint_management.dart';
import 'package:shuttle_service/screens/admin/driver_management.dart';
import 'package:shuttle_service/screens/admin/passenger_complaint_management.dart';
import 'package:shuttle_service/screens/admin/passenger_management.dart';
import 'package:shuttle_service/screens/login.dart';
import 'package:shuttle_service/screens/registration.dart';
import 'package:shuttle_service/screens/userScreens/complaints.dart';
import 'package:shuttle_service/screens/userScreens/dashboard.dart';
import 'package:shuttle_service/screens/userScreens/favouritepages.dart';
import 'package:shuttle_service/screens/userScreens/my_bookings.dart';
import 'package:shuttle_service/screens/userScreens/passengernotiificationpage.dart';
import 'package:shuttle_service/screens/userScreens/seatreservation.dart';
import 'package:shuttle_service/screens/userScreens/special_shuttle.dart';
import 'package:shuttle_service/screens/userScreens/userProfile.dart';
import 'package:shuttle_service/screens/welcome.dart';

class Routes {
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/': (context) => const WelcomeScreen(),
      '/login': (context) => const LoginScreen(),
      '/register': (context) => const DynamicRegistrationScreen(),

      //admin
      '/admin-dashboard': (context) => const AdminDashboardScreen(),
      '/admin-settings': (context) => const AdminSettingsPage(),
      '/admin-notifications': (context) => const AdminNotificationPage(),
      '/driver-management': (context) => AdminDriverManagement(),
      '/passenger-complaints': (context) =>
          const PassengerComplaintManagement(),
      '/passenger-management': (context) => const AdminPassengerManagement(),
      '/driver-complaints-admin': (context) =>
          const DriverComplaintManagementAdmin(),

      //passenger
      '/passenger-dashboard': (context) => const DashboardScreen(),
      '/passenger-make-complaints': (context) =>
          const ComplaintManagementPage(),
      '/favorite-shuttles': (context) => const FavoritesPage(),
      '/my-bookings': (context) => const MyBookingsPage(),
      '/passenger-notifications': (context) =>
          const PassengerNotificationPage(),
      '/find-active-shuttles': (context) => const FindActiveShuttlesPage(),
      '/special-shuttle': (context) => const SpecialShuttlePage(),
      '/passenger-profile': (context) => const UserProfilePage(),

      //driver
      '/driver-dashboard': (context) => const OwnerDashboardPage(),
      '/driver-booking-requests': (context) => const BookingRequestsPage(),
      '/driver-payment-setup': (context) => DriverPaymentSetup(),
      '/driver-details': (context) => const DriverDetailsPage(),
      '/driver-profile': (context) => const DUserProfilePage(),
      '/driver-notification': (context) => const DriverNotificationPage(),
      '/qr-scanner': (context) => const DriverScanQRPage(),
      '/shuttle-management': (context) => const ShuttleManagementPage(),
      '/update-driver-location': (context) => const DriverLocationPage(),
      '/view-special-shuttle': (context) => const SpecialRequestsPage(),
      '/driver-complaints': (context) => const DriverComplaintManagementPage(),
    };
  }
}
// Navigator.pushNamed(context, );
