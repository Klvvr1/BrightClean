class ServerException implements Exception {
  final String? message;
  final int? statusCode;

  ServerException({this.message, this.statusCode});

  @override
  String toString() {
    return 'ServerException: message=$message, statusCode=$statusCode';
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
