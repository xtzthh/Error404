import 'dart:io';

class ApiConstants {
  // YOUR CURRENT MAC IP: 192.168.137.82
  static const String _macIp = "192.168.137.82";
  // Set true only if running on the Android emulator.
  static const bool _useAndroidEmulator = false;

  static String get baseUrl {
    if (Platform.isAndroid) {
      return _useAndroidEmulator
          ? "http://10.0.2.2:5102"
          : "http://$_macIp:5102";
    } else if (Platform.isIOS) {
      // Use Mac's IP for both simulator and physical device to be safe
      return "http://$_macIp:5102";
    }
    return "http://localhost:5102";
  }

  static String get storageEndpoint => "$baseUrl/api/storage";
  static String get marketEndpoint => "$baseUrl/api/market";
}
