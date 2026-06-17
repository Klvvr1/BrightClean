class AdminAuditLogModel {
  final int logID;
  final int adminID;
  final String adminName;
  final String action;
  final String targetEntity;
  final int targetID;
  final String? details;
  final String? ipAddress;
  final DateTime performedAt;

  const AdminAuditLogModel({
    required this.logID,
    required this.adminID,
    required this.adminName,
    required this.action,
    required this.targetEntity,
    required this.targetID,
    required this.performedAt,
    this.details,
    this.ipAddress,
  });

  factory AdminAuditLogModel.fromJson(Map<String, dynamic> json) {
    return AdminAuditLogModel(
      logID: _readInt(json, ['logID', 'LogID']),
      adminID: _readInt(json, ['adminID', 'AdminID']),
      adminName: _readString(json, ['adminName', 'AdminName']),
      action: _readString(json, ['action', 'Action']),
      targetEntity: _readString(json, ['targetEntity', 'TargetEntity']),
      targetID: _readInt(json, ['targetID', 'TargetID']),
      details: _readNullableString(json, ['details', 'Details']),
      ipAddress: _readNullableString(json, ['ipAddress', 'IpAddress']),
      performedAt: DateTime.tryParse(
            _readString(json, ['performedAt', 'PerformedAt']),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static int _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value.toString();
    }
    return '';
  }

  static String? _readNullableString(
      Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value.toString();
    }
    return null;
  }
}
