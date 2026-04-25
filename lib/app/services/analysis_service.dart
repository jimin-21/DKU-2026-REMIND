import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class AnalysisService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<bool> analyzeUrl(String url) async {
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
        return decoded['status'] == 'success';
      }

      print('URL analyze failed: ${response.body}');
      return false;
    } catch (e) {
      print('Analyze URL Error: $e');
      return false;
    }
  }

  Future<bool> analyzeImageBytes(Uint8List bytes, String filename) async {
    try {
      final uri = Uri.parse('$baseUrl/analyze/image');

      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'accept': 'application/json',
      });

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        return decoded['status'] == 'success';
      }

      print('Image analyze failed: ${response.body}');
      return false;
    } catch (e) {
      print('Analyze Image Error: $e');
      return false;
    }
  }
}