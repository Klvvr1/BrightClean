import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../error/exceptions.dart';

class BaseApiClient {
  final http.Client _client;
  final String baseUrl;

  BaseApiClient({
    this.baseUrl = 'http://localhost:5000',
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      debugPrint('Error loading auth token from SharedPreferences: $e');
    }
    return headers;
  }

  void _logRequest(String method, Uri url, Map<String, String> headers, {String? body}) {
    debugPrint('--> $method ${url.toString()}');
    debugPrint('Headers: $headers');
    if (body != null) {
      debugPrint('Body: $body');
    }
  }

  void _logResponse(http.Response response) {
    debugPrint('<-- ${response.statusCode} ${response.request?.url}');
    debugPrint('Response Body: ${response.body}');
  }

  Uri _buildUrl(String endpoint) {
    final normalizedEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$baseUrl$normalizedEndpoint');
  }

  dynamic _processResponse(http.Response response) {
    _logResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      }
      return null;
    } else {
      String errorMessage = 'Server responded with status code ${response.statusCode}';
      try {
        if (response.body.isNotEmpty) {
          final decodedBody = json.decode(response.body);
          if (decodedBody is Map<String, dynamic>) {
            errorMessage = decodedBody['message']?.toString() ??
                decodedBody['error']?.toString() ??
                decodedBody['title']?.toString() ??
                errorMessage;
          }
        }
      } catch (e) {
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }

      throw ServerException(
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }
  }

  Future<dynamic> get(String endpoint) async {
    final url = _buildUrl(endpoint);
    final headers = await _getHeaders();
    _logRequest('GET', url, headers);
    try {
      final response = await _client.get(url, headers: headers);
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final url = _buildUrl(endpoint);
    final requestBody = body != null ? json.encode(body) : null;
    final headers = await _getHeaders();
    _logRequest('POST', url, headers, body: requestBody);
    try {
      final response = await _client.post(
        url,
        headers: headers,
        body: requestBody,
      );
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final url = _buildUrl(endpoint);
    final requestBody = body != null ? json.encode(body) : null;
    final headers = await _getHeaders();
    _logRequest('PUT', url, headers, body: requestBody);
    try {
      final response = await _client.put(
        url,
        headers: headers,
        body: requestBody,
      );
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final url = _buildUrl(endpoint);
    final headers = await _getHeaders();
    _logRequest('DELETE', url, headers);
    try {
      final response = await _client.delete(url, headers: headers);
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
