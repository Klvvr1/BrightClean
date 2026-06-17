import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../error/exceptions.dart';
import '../error/user_error_message.dart';

class BaseApiClient {
  static String get defaultBaseUrl {
    const configuredUrl = String.fromEnvironment('BRIGHTCLEAN_API_BASE_URL');
    String baseUrl;
    if (configuredUrl.isNotEmpty) {
      baseUrl = configuredUrl;
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      baseUrl = 'http://10.0.2.2:5135';
    } else {
      baseUrl = 'http://localhost:5135';
    }
    // Normalize by removing trailing slash and whitespace
    return baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  }

  final http.Client _client;
  final String baseUrl;
  final FlutterSecureStorage _secureStorage;

  BaseApiClient({
    String? baseUrl,
    http.Client? client,
    FlutterSecureStorage? secureStorage,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        _client = client ?? http.Client(),
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

  Future<Map<String, String>> getAuthenticatedHeaders() async {
    return _getHeaders();
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
    final isSensitive = path.endsWith('/login') || path.contains('/register');
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
            requestUrl.path.contains('/register'));

    if (isSensitive) {
      debugPrint('Response Body: [REDACTED - sensitive endpoint]');
    } else {
      debugPrint('Response Body: ${response.body}');
    }
  }

  Uri _buildUrl(String endpoint) {
    // Ensure endpoint starts with '/' for proper concatenation
    final normalizedEndpoint =
        endpoint.startsWith('/') ? endpoint : '/$endpoint';
    // baseUrl is already normalized (no trailing slash) in constructor
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
      if (response.statusCode == 307 || response.statusCode == 308) {
        final redirectTarget =
            response.headers['location'] ?? response.headers['Location'];

        // Log redirect target for diagnostics in debug mode only
        if (kDebugMode && redirectTarget != null) {
          debugPrint('HTTP redirect detected: target=$redirectTarget');
        }

        throw ServerException(
          message:
              'الخادم حوّل الطلب إلى موقع آخر؛ تأكد من إعداد رابط الـ API وبروتوكول http/https.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode == 401) {
        unawaited(_secureStorage.delete(key: 'auth_token'));
        final authHeader = response.headers['www-authenticate'];
        debugPrint('Authentication failed: $authHeader');
        throw ServerException(
          message: 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.',
          statusCode: response.statusCode,
        );
      }

      String errorMessage = 'تعذر تنفيذ الطلب. يرجى المحاولة مرة أخرى.';
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
      final response = await _client
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      if (e is TimeoutException) {
        throw ServerException(
          message: 'انتهت مهلة الاتصال بالخادم. يرجى المحاولة مرة أخرى.',
        );
      }
      debugPrint('GET request failed: $e');
      throw ServerException(message: userMessageFromError(e));
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final url = _buildUrl(endpoint);
    final requestBody = body != null ? json.encode(body) : null;
    final headers = await _getHeaders();
    _logRequest('POST', url, headers, body: requestBody);
    try {
      final response = await _client
          .post(
            url,
            headers: headers,
            body: requestBody,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      if (e is TimeoutException) {
        throw ServerException(
          message: 'انتهت مهلة الاتصال بالخادم. يرجى المحاولة مرة أخرى.',
        );
      }
      debugPrint('POST request failed: $e');
      throw ServerException(message: userMessageFromError(e));
    }
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final url = _buildUrl(endpoint);
    final requestBody = body != null ? json.encode(body) : null;
    final headers = await _getHeaders();
    _logRequest('PATCH', url, headers, body: requestBody);
    try {
      final response = await _client
          .patch(
            url,
            headers: headers,
            body: requestBody,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      if (e is TimeoutException) {
        throw ServerException(
          message: 'انتهت مهلة الاتصال بالخادم. يرجى المحاولة مرة أخرى.',
        );
      }
      debugPrint('PATCH request failed: $e');
      throw ServerException(message: userMessageFromError(e));
    }
  }

  Future<dynamic> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
  }) async {
    final url = _buildUrl(endpoint);
    final headers = await _getHeaders();
    headers.remove(
        'Content-Type'); // http.MultipartRequest handles this boundary automatically

    final request = http.MultipartRequest('POST', url);
    request.headers.addAll(headers);
    request.fields.addAll(fields);
    request.files.addAll(files);

    debugPrint('--> POST MULTIPART ${url.toString()}');

    // Check if endpoint is sensitive and redact field values if so
    final path = url.path;
    final isSensitive = path.contains('/register') || path.contains('/login');

    if (isSensitive) {
      debugPrint(
          'Fields: [REDACTED - sensitive endpoint, keys: ${request.fields.keys.toList()}]');
    } else {
      debugPrint('Fields: ${request.fields}');
    }

    debugPrint(
        'Files: ${request.files.map((f) => "${f.field}: ${f.filename}").toList()}');

    try {
      final streamedResponse =
          await _client.send(request).timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      if (e is TimeoutException) {
        throw ServerException(
          message: 'انتهت مهلة الاتصال بالخادم. يرجى المحاولة مرة أخرى.',
        );
      }
      debugPrint('POST multipart request failed: $e');
      throw ServerException(message: userMessageFromError(e));
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final url = _buildUrl(endpoint);
    final requestBody = body != null ? json.encode(body) : null;
    final headers = await _getHeaders();
    _logRequest('PUT', url, headers, body: requestBody);
    try {
      final response = await _client
          .put(
            url,
            headers: headers,
            body: requestBody,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      if (e is TimeoutException) {
        throw ServerException(
          message: 'انتهت مهلة الاتصال بالخادم. يرجى المحاولة مرة أخرى.',
        );
      }
      debugPrint('PUT request failed: $e');
      throw ServerException(message: userMessageFromError(e));
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final url = _buildUrl(endpoint);
    final headers = await _getHeaders();
    _logRequest('DELETE', url, headers);
    try {
      final response = await _client
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      if (e is TimeoutException) {
        throw ServerException(
          message: 'انتهت مهلة الاتصال بالخادم. يرجى المحاولة مرة أخرى.',
        );
      }
      debugPrint('DELETE request failed: $e');
      throw ServerException(message: userMessageFromError(e));
    }
  }
}
