import 'dart:async';
import 'dart:io';

import 'package:brightcleanproject/core/error/exceptions.dart';
import 'package:brightcleanproject/core/error/user_error_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps clear server messages', () {
    expect(
      userMessageFromError(
        ServerException(message: 'رقم الهاتف مستخدم مسبقاً', statusCode: 400),
      ),
      'رقم الهاتف مستخدم مسبقاً',
    );
  });

  test('maps authentication and permission server errors', () {
    expect(
      userMessageFromError(ServerException(statusCode: 401)),
      'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى.',
    );
    expect(
      userMessageFromError(ServerException(statusCode: 403)),
      'ليس لديك صلاحية لتنفيذ هذا الإجراء.',
    );
  });

  test('hides technical response format messages', () {
    expect(
      userMessageFromError(
        ServerException(message: 'Invalid API response format for services'),
      ),
      'تعذر قراءة البيانات من الخادم. يرجى المحاولة مرة أخرى.',
    );
  });

  test('maps network and timeout errors', () {
    expect(
      userMessageFromError(TimeoutException('slow')),
      'انتهت مهلة الاتصال بالخادم. يرجى المحاولة مرة أخرى.',
    );
    expect(
      userMessageFromError(const SocketException('offline')),
      'تعذر الاتصال بالخادم. تحقق من اتصالك بالإنترنت ثم حاول مرة أخرى.',
    );
  });

  test('uses fallback for unknown technical exceptions', () {
    expect(
      userMessageFromError(Exception('ClientException: connection reset')),
      'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.',
    );
  });

  test('server exception string is user-facing', () {
    expect(
      ServerException(message: 'تعذر حفظ البيانات').toString(),
      'تعذر حفظ البيانات',
    );
  });
}
