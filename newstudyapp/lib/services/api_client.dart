import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<Map<String, dynamic>> postJson(
    Uri uri, {
    required Map<String, dynamic> body,
  }) async {
    final response = await _httpClient.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    _throwIfNotSuccessful(response);

    return _decodeBody(response);
  }

  Future<Map<String, dynamic>> getJson(Uri uri) async {
    final response = await _httpClient.get(uri, headers: const {'Accept': 'application/json'});

    _throwIfNotSuccessful(response);

    return _decodeBody(response);
  }

  void dispose() {
    _httpClient.close();
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const FormatException('Unexpected response structure');
  }

  void _throwIfNotSuccessful(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiClientException(
        statusCode: response.statusCode,
        message: response.body.isEmpty ? '请求失败' : response.body,
      );
    }
  }
}

class ApiClientException implements Exception {
  const ApiClientException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiClientException($statusCode): $message';
}

