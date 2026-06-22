import 'package:brightcleanproject/core/network/api_client.dart';
import 'package:brightcleanproject/features/admin/data/models/admin_audit_log_model.dart';
import 'package:brightcleanproject/features/admin/data/models/admin_summary_model.dart';
import 'package:brightcleanproject/features/admin/data/models/pending_user_model.dart';
import 'package:brightcleanproject/features/admin/data/providers/admin_provider.dart';
import 'package:brightcleanproject/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:brightcleanproject/features/admin/domain/repositories/admin_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _PostTrackingApiClient extends BaseApiClient {
  String? requestedEndpoint;
  Map<String, dynamic>? requestedBody;

  @override
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    requestedEndpoint = endpoint;
    requestedBody = body;
    return {'message': 'ok'};
  }
}

class _RegistrationRepository implements AdminRepository {
  int? approvedUserId;
  int? rejectedUserId;
  int? dismissedUserId;
  int? warnedUserId;
  String? warningReason;
  int pendingRefreshCount = 0;
  int approvedStaffRefreshCount = 0;
  int auditRefreshCount = 0;
  int summaryRefreshCount = 0;

  @override
  Future<void> approveUser(int userId) async {
    approvedUserId = userId;
  }

  @override
  Future<void> rejectUser(int userId) async {
    rejectedUserId = userId;
  }

  @override
  Future<void> dismissUser(int userId) async {
    dismissedUserId = userId;
  }

  @override
  Future<void> warnUser(int userId, String reason) async {
    warnedUserId = userId;
    warningReason = reason;
  }

  @override
  Future<List<PendingUserModel>> getPendingApprovals() async {
    pendingRefreshCount++;
    return const [];
  }

  @override
  Future<List<dynamic>> getApprovedStaff() async {
    approvedStaffRefreshCount++;
    return const [];
  }

  @override
  Future<List<AdminAuditLogModel>> getAuditLogs() async {
    auditRefreshCount++;
    return const [];
  }

  @override
  Future<AdminSummaryModel> getSummary() async {
    summaryRefreshCount++;
    return AdminSummaryModel.empty();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('AdminRepositoryImpl rejects users through admin endpoint', () async {
    final apiClient = _PostTrackingApiClient();
    final repository = AdminRepositoryImpl(apiClient: apiClient);

    await repository.rejectUser(42);

    expect(apiClient.requestedEndpoint, '/api/admin/reject/42');
  });

  test('AdminRepositoryImpl dismisses users through admin endpoint', () async {
    final apiClient = _PostTrackingApiClient();
    final repository = AdminRepositoryImpl(apiClient: apiClient);

    await repository.dismissUser(42);

    expect(apiClient.requestedEndpoint, '/api/admin/dismiss/42');
  });

  test('AdminRepositoryImpl warns users through admin endpoint', () async {
    final apiClient = _PostTrackingApiClient();
    final repository = AdminRepositoryImpl(apiClient: apiClient);

    await repository.warnUser(42, 'Late delivery');

    expect(apiClient.requestedEndpoint, '/api/admin/warn/42');
    expect(apiClient.requestedBody?['reason'], 'Late delivery');
  });

  test('AdminRepositoryImpl sends all-users notification target unchanged',
      () async {
    final apiClient = _PostTrackingApiClient();
    final repository = AdminRepositoryImpl(apiClient: apiClient);

    await repository.sendNotification({
      'title': 'System notice',
      'message': 'Hello',
      'targetRole': 'All',
    });

    expect(apiClient.requestedEndpoint, '/api/admin/notifications');
    expect(apiClient.requestedBody?['targetRole'], 'All');
  });

  test(
      'AdminProvider refreshes pending, approved staff, and audit logs after approval',
      () async {
    final repository = _RegistrationRepository();
    final provider = AdminProvider(adminRepository: repository);

    await provider.approveUser(7);

    expect(repository.approvedUserId, 7);
    expect(repository.pendingRefreshCount, 1);
    expect(repository.approvedStaffRefreshCount, 1);
    expect(repository.auditRefreshCount, 1);
    expect(provider.isActionLoading, isFalse);
  });

  test('AdminProvider refreshes pending and audit logs after rejection',
      () async {
    final repository = _RegistrationRepository();
    final provider = AdminProvider(adminRepository: repository);

    await provider.rejectUser(9);

    expect(repository.rejectedUserId, 9);
    expect(repository.pendingRefreshCount, 1);
    expect(repository.approvedStaffRefreshCount, 0);
    expect(repository.auditRefreshCount, 1);
    expect(provider.isActionLoading, isFalse);
  });

  test('AdminProvider refreshes staff, summary, and audit logs after dismissal',
      () async {
    final repository = _RegistrationRepository();
    final provider = AdminProvider(adminRepository: repository);

    await provider.dismissUser(11);

    expect(repository.dismissedUserId, 11);
    expect(repository.approvedStaffRefreshCount, 1);
    expect(repository.summaryRefreshCount, 1);
    expect(repository.auditRefreshCount, 1);
    expect(provider.isActionLoading, isFalse);
  });

  test('AdminProvider refreshes audit logs after warning', () async {
    final repository = _RegistrationRepository();
    final provider = AdminProvider(adminRepository: repository);

    await provider.warnUser(12, 'Late delivery');

    expect(repository.warnedUserId, 12);
    expect(repository.warningReason, 'Late delivery');
    expect(repository.auditRefreshCount, 1);
    expect(provider.isActionLoading, isFalse);
  });
}
