# 🚍 Shuttle Service System

A **Digital Shuttle Booking and Management System** for NSBM Green University, enabling students and staff to book seats, track shuttles, and manage shuttle services efficiently.

---

## 📌 Features

- **User Roles**: Passengers, Shuttle Drivers, Admin
- **Real-time Shuttle Tracking**: Driver’s live location
- **Seat Booking & Reservations**
- **Secure Online Payments**: Integrated with PayHere Payment Gateway
- **Admin Dashboard**: Manage complaints, schedules, and user data
- **Push Notifications**: Updates and alerts for users

---

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend & Database**: Firebase (Firestore, Authentication, Storage)
- **Payment Integration**: PayHere
- **Location Services**: Google Maps API

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (version 3.5.4 or higher)
- Dart SDK
- Firebase Project with necessary configurations
- PayHere account for payment integration

### Installation

1. Extract the ZIP file to your desired location.
2. Open the project in your preferred IDE (e.g., Visual Studio Code or Android Studio).
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Set up Firebase:
   - Add `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) to their respective directories.
5. Run the app:
   ```bash
   flutter run
   ```

---

## 📂 Project Structure

- **`lib/screens`**: Contains all UI screens for user and admin functionalities.
- **`assets/`**: Static assets like images, terms, and conditions.
- **`ios/` and `android/`**: Platform-specific configurations.
- **`pubspec.yaml`**: Dependency management.

---

## 📝 Test User Credentials

Use the following credentials to test the application:

- **Passenger**

  - Email: `test1@gmail.com`
  - Password: `123456`

- **Driver**

  - Email: `test2@gmail.com`
  - Password: `123456`

- **Admin**
  - Email: `admin1234@gmail.com`
  - Password: `admin1234`

---

## 📝 Terms and Conditions

Refer to the [assets/terms.txt](assets/terms.txt) file for the full terms and conditions of the app.

---

## 📧 Contact

For any inquiries or support, please contact the development team at **10898450@students.plymouth.ac.uk**.

---
