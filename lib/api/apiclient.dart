import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = "http://192.168.1.18:8082/api/";

  static Future<dynamic> request(
    String endpoint, {
    String method = "GET",
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      String cleanEndpoint = endpoint.replaceFirst(RegExp(r'^/+'), '');
      cleanEndpoint = cleanEndpoint.replaceFirst(RegExp(r'^api/'), '');

      final uri = Uri.parse(baseUrl + cleanEndpoint);

      print("API URL: $uri");
      print("METHOD: $method");
      print("BODY: $body");

      final defaultHeaders = {"Content-Type": "application/json", ...?headers};

      late http.Response response;

      if (method.toUpperCase() == "GET") {
        response = await http
            .get(uri, headers: defaultHeaders)
            .timeout(const Duration(seconds: 20));
      } else {
        response = await http
            .post(
              uri,
              headers: defaultHeaders,
              body: body == null
                  ? null
                  : body is String
                  ? body
                  : jsonEncode(body),
            )
            .timeout(const Duration(seconds: 20));
      }

      print("STATUS: ${response.statusCode}");
      print("RESPONSE: ${response.body}");

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          response.body.isNotEmpty
              ? response.body
              : "Error ${response.statusCode}",
        );
      }

      if (response.body.isEmpty) return null;

      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    } catch (error) {
      print("API Error: $error");
      rethrow;
    }
  }
}
