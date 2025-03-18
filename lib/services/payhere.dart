// import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';

// class PayhereService {
//   static Future<void> startPayment({
//     required double amount,
//     required String orderId,
//     required String itemDesc,
//     required String customerName,
//     required String customerEmail,
//     required String customerPhone,
//   }) async {
//     Map paymentObject = {
//       "sandbox": true, // Set to false in production
//       "merchant_id": "1211149", // Replace with your Merchant ID
//       "merchant_secret": "xyz", // Replace with your Merchant Secret
//       "notify_url": "http://sample.com/notify",
//       "order_id": orderId,
//       "items": itemDesc,
//       "amount": amount.toString(),
//       "currency": "LKR",
//       "first_name": customerName,
//       "last_name": "",
//       "email": customerEmail,
//       "phone": customerPhone,
//       "address": "No.1, Galle Road",
//       "city": "Colombo",
//       "country": "Sri Lanka",
//       "delivery_address": "",
//       "delivery_city": "",
//       "delivery_country": "",
//       "custom_1": "",
//       "custom_2": ""
//     };

//     try {
//       PayHere.startPayment(paymentObject, (paymentId) {
//         print("Payment Success. Payment Id: $paymentId");
//       }, (error) {
//         print("Payment Failed. Error: $error");
//         throw Exception(error);
//       }, () {
//         print("Payment Dismissed");
//         throw Exception("Payment was dismissed");
//       });
//     } catch (e) {
//       print("Error: $e");
//       rethrow;
//     }
//   }
// }
