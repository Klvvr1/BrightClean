class ServerException implements Exception {
  final String? message;
  final int? statusCode;

  ServerException({this.message, this.statusCode});

  @override
  String toString() {
    return message ?? 'حدث خطأ في الخادم';
  }
}

class CacheException implements Exception {
  final String? message;

  CacheException({this.message});

  @override
  String toString() {
    return 'CacheException: message=$message';
  }
}
