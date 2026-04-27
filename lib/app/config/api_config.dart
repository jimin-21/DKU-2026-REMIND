import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    // Flutter Web: Chrome 실행
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    // Windows 데스크톱 실행
    return 'http://127.0.0.1:8000';
  }
}