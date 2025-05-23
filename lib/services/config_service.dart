import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigService {
  static String get googleMapsApiKey {
    return dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  }

  static String get firebaseApiKey {
    return dotenv.env['FIREBASE_API_KEY'] ?? '';
  }

  static String get payhereMerchantId {
    return dotenv.env['PAYHERE_MERCHANT_ID'] ?? '';
  }

  static String get payhereMerchantSecret {
    return dotenv.env['PAYHERE_MERCHANT_SECRET'] ?? '';
  }
}
