import 'dart:convert';
import 'package:http/http.dart' as http;
import '../error/exceptions.dart';

class BaseApiClient {
  final http.Client _client;
  final String baseUrl;

  BaseApiClient({
    this.baseUrl = 'http://localhost:5000',
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  void _logRequest(String method, Uri url, {String? body}) {
    print('--> $method ${url.toString()}');
    print('Headers: $_headers');
    if (body != null) {
      print('Body: $body');
    }
  }

  void _logResponse(http.Response response) {
    print('<-- ${response.statusCode} ${response.request?.url}');
    print('Response Body: ${response.body}');
  }

  dynamic _processResponse(http.Response response) {
    _logResponse(response);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      }
      return null;
    } else {
      throw ServerException(
        message: 'Server responded with status code ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
  }

  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    _logRequest('GET', url);
    try {
      final response = await _client.get(url, headers: _headers);
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final requestBody = body != null ? json.encode(body) : null;
    _logRequest('POST', url, body: requestBody);
    try {
      final response = await _client.post(
        url,
        headers: _headers,
        body: requestBody,
      );
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final requestBody = body != null ? json.encode(body) : null;
    _logRequest('PUT', url, body: requestBody);
    try {
      final response = await _client.put(
        url,
        headers: _headers,
        body: requestBody,
      );
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    _logRequest('DELETE', url);
    try {
      final response = await _client.delete(url, headers: _headers);
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
