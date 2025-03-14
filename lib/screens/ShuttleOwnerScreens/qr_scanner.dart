import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';

class DriverScanQRPage extends StatefulWidget {
  const DriverScanQRPage({Key? key}) : super(key: key);

  @override
  _DriverScanQRPageState createState() => _DriverScanQRPageState();
}

class _DriverScanQRPageState extends State<DriverScanQRPage> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _hasScanned = false;
  String _scanResult = '';
  bool _isProcessing = false;
  String _processStatus = '';
  bool _isSuccess = false;
  bool _isTorchOn = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _processQRCode(String qrData) async {
    // Prevent multiple scans while processing
    if (_isProcessing) return;

    setState(() {
      _hasScanned = true;
      _scanResult = qrData;
      _isProcessing = true;
      _processStatus = 'Processing booking...';
      _isSuccess = false;
    });

    try {
      // Extract booking ID from QR code
      RegExp regExp = RegExp(r'Booking ID: ([\w-]+)');
      Match? match = regExp.firstMatch(qrData);

      if (match == null || match.groupCount < 1) {
        setState(() {
          _processStatus = 'Invalid QR code format';
          _isProcessing = false;
        });
        return;
      }

      String bookingId = match.group(1)!;

      // Get current driver information
      User? currentDriver = FirebaseAuth.instance.currentUser;
      if (currentDriver == null) {
        setState(() {
          _processStatus = 'Driver not authenticated';
          _isProcessing = false;
        });
        return;
      }

      // Get the driver's doc to verify identity
      DocumentSnapshot driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(currentDriver.uid)
          .get();

      if (!driverDoc.exists) {
        setState(() {
          _processStatus = 'Driver profile not found';
          _isProcessing = false;
        });
        return;
      }

      String driverName = driverDoc.get('name') as String;

      // Fetch the booking document
      DocumentSnapshot bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!bookingDoc.exists) {
        setState(() {
          _processStatus = 'Booking not found';
          _isProcessing = false;
        });
        return;
      }

      // Verify this is the correct driver for this booking
      String assignedDriverName = bookingDoc.get('driverName') as String;
      if (assignedDriverName != driverName) {
        setState(() {
          _processStatus = 'You are not assigned to this booking';
          _isProcessing = false;
        });
        return;
      }

      // Check if booking is in 'ongoing' status
      String bookingStatus = bookingDoc.get('my_booking') as String;
      if (bookingStatus != 'ongoing') {
        setState(() {
          _processStatus = 'This booking is not in ongoing status';
          _isProcessing = false;
        });
        return;
      }

      // Update booking status to 'past'
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'my_booking': 'past',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Vibrate to indicate success
      HapticFeedback.heavyImpact();

      setState(() {
        _processStatus = 'Booking marked as completed!';
        _isProcessing = false;
        _isSuccess = true;
      });

      // Return to scan mode after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _hasScanned = false;
            _scanResult = '';
          });
        }
      });
    } catch (e) {
      setState(() {
        _processStatus = 'Error: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Booking QR Code'),
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              await cameraController.toggleTorch();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _hasScanned ? _buildResultView() : _buildScannerView(),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: const Text(
                'Position the QR code within the frame to scan and complete the ride',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        // Scanner
        MobileScanner(
          controller: cameraController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && !_hasScanned) {
              final String code = barcodes.first.rawValue ?? '';
              if (code.isNotEmpty) {
                _processQRCode(code);
              }
            }
          },
        ),
        // Simple scan indicator
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 3.0,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSuccess ? Icons.check_circle : Icons.info,
            size: 80,
            color: _isSuccess ? Colors.green : Colors.blue,
          ),
          const SizedBox(height: 20),
          Text(
            _processStatus,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_isProcessing)
            const CircularProgressIndicator()
          else if (_isSuccess)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasScanned = false;
                  _scanResult = '';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('Scan Another'),
            )
          else
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasScanned = false;
                  _scanResult = '';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('Try Again'),
            ),
        ],
      ),
    );
  }
}
