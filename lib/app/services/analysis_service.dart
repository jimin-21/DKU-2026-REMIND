import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalysisService {
  // 실제 서버 주소로 바꾸면 됨
  // 안드로이드 에뮬레이터면 10.0.2.2 사용
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<bool> analyzeUrl(String url) async {
    try {
      final uri = Uri.parse('$baseUrl/analyze');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode({
          'url': url,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}