import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverPaymentDetailsPage extends StatefulWidget {
  const DriverPaymentDetailsPage({super.key});

  @override
  State<DriverPaymentDetailsPage> createState() =>
      _DriverPaymentDetailsPageState();
}

class _DriverPaymentDetailsPageState extends State<DriverPaymentDetailsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  bool _hasPaymentDetails = false;
  String _cardNumber = '';
  String _cardholderName = '';
  String _expiryDate = '';
  String _cvv = '';

  @override
  void initState() {
    super.initState();
    _fetchPaymentDetails();
  }

  Future<void> _fetchPaymentDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      final driverDoc =
          await _firestore.collection('drivers').doc(user.uid).get();
      if (driverDoc.exists && driverDoc.data()?['payment_details'] != null) {
        final paymentData = driverDoc.data()?['payment_details'];
        setState(() {
          _hasPaymentDetails = true;
          _cardNumber = paymentData['card_number'] ?? '';
          _cardholderName = paymentData['cardholder_name'] ?? '';
          _expiryDate = paymentData['expiry_date'] ?? '';
          _cvv = paymentData['cvv'] ?? '';
        });
      }
    }
  }

  Future<void> _savePaymentDetails() async {
    if (_formKey.currentState!.validate()) {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('drivers').doc(user.uid).set({
          'payment_details': {
            'card_number': _cardNumber,
            'cardholder_name': _cardholderName,
            'expiry_date': _expiryDate,
            'cvv': _cvv,
          },
        }, SetOptions(merge: true));

        setState(() {
          _hasPaymentDetails = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _hasPaymentDetails
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cardholder Name: $_cardholderName',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text(
                      'Card Number: **** **** **** ${_cardNumber.substring(_cardNumber.length - 4)}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text('Expiry Date: $_expiryDate',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasPaymentDetails = false;
                      });
                    },
                    child: const Text('Change Bank Details'),
                  ),
                ],
              )
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Cardholder Name'),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter cardholder name' : null,
                      onChanged: (value) => _cardholderName = value,
                    ),
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Card Number'),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter card number' : null,
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _cardNumber = value,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                                labelText: 'Expiry Date (MM/YY)'),
                            validator: (value) =>
                                value!.isEmpty ? 'Enter expiry date' : null,
                            keyboardType: TextInputType.datetime,
                            onChanged: (value) => _expiryDate = value,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'CVV'),
                            validator: (value) =>
                                value!.isEmpty ? 'Enter CVV' : null,
                            keyboardType: TextInputType.number,
                            onChanged: (value) => _cvv = value,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _savePaymentDetails,
                      child: const Text('Save Payment Details'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
