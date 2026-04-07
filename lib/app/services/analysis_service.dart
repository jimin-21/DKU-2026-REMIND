import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalysisService {
  // 나중에 실제 서버 주소로 바꾸면 됨
  // 안드로이드 에뮬레이터면 10.0.2.2를 써야 할 수도 있음
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<Map<String, dynamic>> analyzeUrl(String url) async {
    try {
      final uri = Uri.parse('$baseUrl/analyze').replace(
        queryParameters: {
          'url': url,
        },
      );

      final response = await http.post(
        uri,
        headers: {
          'accept': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        return {
          'title': (decoded['title'] ?? '').toString(),
          'summary': (decoded['summary'] ?? '').toString(),
          'category': (decoded['category'] ?? '기타').toString(),
          'tags': _parseTags(decoded['tags']),
          'thumbnail': (decoded['thumbnail'] ?? '').toString(),
          'url': (decoded['url'] ?? url).toString(),
          'status': (decoded['status'] ?? 'ACTIVE').toString(),
        };
      }

      return _fallbackResult(url);
    } catch (_) {
      return _fallbackResult(url);
    }
  }

  List<String> _parseTags(dynamic rawTags) {
    if (rawTags is List) {
      return rawTags.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  Map<String, dynamic> _fallbackResult(String url) {
    return {
      'title': '분석 중인 링크',
      'summary': '',
      'category': '기타',
      'tags': <String>[],
      'thumbnail': '',
      'url': url,
      'status': 'ACTIVE',
    };
  }
}