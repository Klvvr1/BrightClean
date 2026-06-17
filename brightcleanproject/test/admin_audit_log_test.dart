import 'package:brightcleanproject/core/error/exceptions.dart';
import 'package:brightcleanproject/core/network/api_client.dart';
import 'package:brightcleanproject/features/admin/data/models/admin_audit_log_model.dart';
import 'package:brightcleanproject/features/admin/data/providers/admin_provider.dart';
import 'package:brightcleanproject/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:brightcleanproject/features/admin/domain/repositories/admin_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminApiClient extends BaseApiClient {
  _FakeAdminApiClient(this.response);

  final dynamic response;
  String? requestedEndpoint;

  @override
  Future<dynamic> get(String endpoint) async {
    requestedEndpoint = endpoint;
    return response;
  }
}

class _FakeAdminRepository implements AdminRepository {
  _FakeAdminRepository(this.logs, {this.error});

  final List<AdminAuditLogModel> logs;
  final Object? error;

  @override
  Future<List<AdminAuditLogModel>> getAuditLogs() async {
    final currentError = error;
    if (currentError != null) throw currentError;
    return logs;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('AdminAuditLogModel reads audit log response casing', () {
    final log = AdminAuditLogModel.fromJson({
      'LogID': 7,
      'AdminID': 1,
      'AdminName': 'مدير النظام',
      'Action': 'CREATE_OFFER',
      'TargetEntity': 'Offer',
      'TargetID': 11,
      'Details': 'Created offer.',
      'IpAddress': '127.0.0.1',
      'PerformedAt': '2026-06-17T10:30:00Z',
    });

    expect(log.logID, 7);
    expect(log.adminName, 'مدير النظام');
    expect(log.action, 'CREATE_OFFER');
    expect(log.performedAt.toUtc().year, 2026);
  });

  test('AdminRepositoryImpl loads audit logs from backend wrapper', () async {
    final apiClient = _FakeAdminApiClient({
      'data': [
        {
          'logID': 1,
          'adminID': 1,
          'adminName': 'Admin User',
          'action': 'SEND_NOTIFICATION',
          'targetEntity': 'Notification',
          'targetID': 3,
          'performedAt': '2026-06-17T09:00:00Z',
        }
      ],
      'currentPage': 1,
      'pageSize': 50,
      'totalCount': 1,
    });
    final repository = AdminRepositoryImpl(apiClient: apiClient);

    final logs = await repository.getAuditLogs();

    expect(apiClient.requestedEndpoint, '/api/admin/audit-logs');
    expect(logs, hasLength(1));
    expect(logs.first.action, 'SEND_NOTIFICATION');
  });

  test('AdminProvider exposes loaded audit logs', () async {
    final provider = AdminProvider(
      adminRepository: _FakeAdminRepository([
        AdminAuditLogModel(
          logID: 1,
          adminID: 1,
          adminName: 'Admin User',
          action: 'CONFIRM_PAYMENT',
          targetEntity: 'Payment',
          targetID: 5,
          performedAt: DateTime.utc(2026, 6, 17),
        ),
      ]),
    );

    await provider.fetchAuditLogs();

    expect(provider.isAuditLogsLoading, isFalse);
    expect(provider.errorMessage, isNull);
    expect(provider.auditLogs, hasLength(1));
    expect(provider.auditLogs.first.action, 'CONFIRM_PAYMENT');
  });

  test('AdminProvider maps audit log loading failure', () async {
    final provider = AdminProvider(
      adminRepository: _FakeAdminRepository(
        const [],
        error: ServerException(message: 'ServerException: failed'),
      ),
    );

    await provider.fetchAuditLogs();

    expect(provider.isAuditLogsLoading, isFalse);
    expect(provider.auditLogs, isEmpty);
    expect(provider.errorMessage, isNotEmpty);
  });
}
