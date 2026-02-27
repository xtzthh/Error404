import 'dart:io';

class DiseaseApiConfig {
  static const String _lanFallback = 'http://192.168.1.34:8000';

  static String get baseUrl {
    const override = String.fromEnvironment('DISEASE_API_BASE');
    if (override.isNotEmpty) return override;

    // Android emulator cannot access host via localhost.
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';

    // iOS simulator / macOS desktop can use localhost.
    if (Platform.isIOS || Platform.isMacOS) return 'http://127.0.0.1:8000';

    // Physical device fallback. Replace with your Mac LAN IP if needed.
    return _lanFallback;
  }

  static List<String> get candidateBaseUrls {
    const override = String.fromEnvironment('DISEASE_API_BASE');
    if (override.isNotEmpty) return [override, _lanFallback];

    final urls = <String>[];
    if (Platform.isIOS || Platform.isMacOS) {
      urls.add('http://127.0.0.1:8000');
      urls.add(_lanFallback);
      return urls;
    }
    if (Platform.isAndroid) {
      urls.add('http://10.0.2.2:8000');
      urls.add(_lanFallback);
      return urls;
    }
    urls.add(_lanFallback);
    return urls;
  }
}
