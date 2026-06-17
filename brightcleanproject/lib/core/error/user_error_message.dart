import 'dart:async';
import 'dart:io';

import 'exceptions.dart';

const String defaultUserErrorMessage =
    'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
const String invalidResponseUserMessage =
    'تعذر قراءة البيانات من الخادم. يرجى المحاولة مرة أخرى.';
const String connectionUserMessage =
    'تعذر الاتصال بالخادم. تحقق من اتصالك بالإنترنت ثم حاول مرة أخرى.';
const String timeoutUserMessage =
    'انتهت مهلة الاتصال بالخادم. يرجى المحاولة مرة أخرى.';

String userMessageFromError(
  Object error, {
  String fallback = defaultUserErrorMessage,
}) {
  if (error is ServerException) {
    return _serverExceptionMessage(error, fallback: fallback);
  }
  if (error is TimeoutException) {
    return timeoutUserMessage;
  }
  if (error is SocketException) {
    return connectionUserMessage;
  }

  final text = error.toString();
  if (_isTechnicalMessage(text)) {
    return fallback;
  }
  return _cleanExceptionPrefix(text).trim().isNotEmpty
      ? _cleanExceptionPrefix(text)
      : fallback;
}

String _serverExceptionMessage(
  ServerException error, {
  required String fallback,
}) {
  final message = error.message?.trim();
  if (message != null &&
      message.isNotEmpty &&
      !_isTechnicalMessage(message)) {
    return message;
  }
  if (message != null &&
      message.isNotEmpty &&
      _isInvalidResponseMessage(message)) {
    return invalidResponseUserMessage;
  }

  switch (error.statusCode) {
    case 400:
      return 'تعذر تنفيذ الطلب. يرجى التحقق من البيانات والمحاولة مرة أخرى.';
    case 401:
      return 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.';
    case 403:
      return 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';
    case 404:
      return 'لم يتم العثور على البيانات المطلوبة.';
    case 409:
      return 'يوجد تعارض في البيانات. يرجى تحديث الصفحة والمحاولة مرة أخرى.';
    default:
      if (error.statusCode != null && error.statusCode! >= 500) {
        return 'حدث خلل في الخادم. يرجى المحاولة لاحقاً.';
      }
      return message != null && message.isNotEmpty
          ? _cleanExceptionPrefix(message)
          : fallback;
  }
}

bool _isTechnicalMessage(String message) {
  final lower = message.toLowerCase();
  return lower.contains('serverexception') ||
      lower.contains('cacheexception') ||
      lower.contains('clientexception') ||
      lower.contains('socketexception') ||
      lower.contains('httpexception') ||
      lower.contains('formatexception') ||
      _isInvalidResponseMessage(lower) ||
      lower.contains('server responded with status code') ||
      lower.contains('connection refused') ||
      lower.contains('connection reset') ||
      lower.contains('xmlhttprequest error') ||
      lower.contains('failed host lookup');
}

bool _isInvalidResponseMessage(String message) {
  return message.toLowerCase().contains('invalid api response');
}

String _cleanExceptionPrefix(String message) {
  return message
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .replaceFirst(RegExp(r'^ServerException:\s*'), '')
      .replaceFirst(RegExp(r'^message='), '')
      .trim();
}
