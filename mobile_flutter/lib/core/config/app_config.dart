import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'TransitGo';
  static const String appVersion = '1.0.0';
  static const String agencyName = 'Thane Municipal Transport (TMT)';

  // Default coordinates for Thane Railway Station (major transit hub)
  static const double defaultLatitude = 19.1860;
  static const double defaultLongitude = 72.9759;

  /// Returns standard default API URL based on runtime platform
  static String get defaultBaseUrl {
    const fromDefine = String.fromEnvironment('API_URL');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }
    if (Platform.isAndroid) {
      // 10.0.2.2 reaches localhost from Android emulator
      return 'http://10.0.2.2:8080/api';
    }
    return 'http://localhost:8080/api';
  }

  // Fallback map tile server (OpenStreetMap standard)
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String userAgentPackage = 'com.transitgo.mobile_flutter';
}
