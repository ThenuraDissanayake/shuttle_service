import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // Dummy data
  String paymentMethod = 'Credit Card';
  double seatPrice = 50.0; // Example price for one reservation
  double subscriptionPrice = 150.0; // Example price for monthly subscription

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Payment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // Navigate to profile screen
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Page Title
            const Text(
              'Complete Your Payment',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Payment Method Dropdown
            DropdownButton<String>(
              value: paymentMethod,
              items: <String>['Credit Card', 'PayPal', 'Google Pay']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  paymentMethod = newValue!;
                });
              },
              hint: const Text('Select Payment Method'),
            ),

            const SizedBox(height: 20),

            // Payment Amount (Seat or Subscription)
            Text(
              'Amount: \$${paymentMethod == 'Credit Card' ? seatPrice : subscriptionPrice}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Payment Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                // Implement payment gateway integration here
                _processPayment();
              },
              child: const Text('Pay Now'),
            ),

            const SizedBox(height: 20),

            // Payment History Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                // Navigate to payment history page
                _viewPaymentHistory();
              },
              child: const Text('View Payment History'),
            ),
          ],
        ),
      ),
    );
  }

  // Dummy Payment Processing Function
  void _processPayment() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Successful'),
          content: const Text('Your payment has been processed successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Dummy Payment History Function
  void _viewPaymentHistory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment History'),
          content: const Text('You have made 2 payments in the last month.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
