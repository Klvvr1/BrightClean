import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../error/exceptions.dart';

class BaseApiClient {
  final http.Client _client;
  final String baseUrl;
  final FlutterSecureStorage _secureStorage;

  BaseApiClient({
    this.baseUrl = 'http://localhost:5135',
    http.Client? client,
    FlutterSecureStorage? secureStorage,
  })  : _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      debugPrint('Error loading auth token from SecureStorage: $e');
    }
    return headers;
  }

  void _logRequest(String method, Uri url, Map<String, String> headers,
      {String? body}) {
    debugPrint('--> $method ${url.toString()}');
    final loggedHeaders = Map<String, String>.from(headers);
    if (loggedHeaders.containsKey('Authorization')) {
      loggedHeaders['Authorization'] = 'Bearer ***';
    }
    debugPrint('Headers: $loggedHeaders');
    final path = url.path;
    final isSensitive = path.endsWith('/login') || path.endsWith('/register');
    if (body != null && !isSensitive) {
      debugPrint('Body: $body');
    }
  }

  void _logResponse(http.Response response) {
    debugPrint('<-- ${response.statusCode} ${response.request?.url}');

    // Redact response headers
    final responseHeaders = response.headers;
    final loggedHeaders = Map<String, String>.from(responseHeaders);
    if (loggedHeaders.containsKey('authorization')) {
      loggedHeaders['authorization'] = 'Bearer ***';
    }
    if (loggedHeaders.isNotEmpty) {
      debugPrint('Response Headers: $loggedHeaders');
    }

    // Check if response is from sensitive endpoint
    final requestUrl = response.request?.url;
    final isSensitive = requestUrl != null &&
        (requestUrl.path.endsWith('/login') ||
            requestUrl.path.endsWith('/register'));

    if (isSensitive) {
      debugPrint('Response Body: [REDACTED - sensitive endpoint]');
    } else {
      debugPrint('Response Body: ${response.body}');
    }
  }

  Uri _buildUrl(String endpoint) {
    final normalizedEndpoint =
        endpoint.startsWith('/') ? endpoint : '/$endpoint';
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
      String errorMessage =
          'Server responded with status code ${response.statusCode}';
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
