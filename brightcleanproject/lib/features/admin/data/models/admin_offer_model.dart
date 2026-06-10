class AdminOfferModel {
  final int offerID;
  final String offerCode;
  final String type;
  final String scope;
  final double discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final double? minOrderValue;
  final int? maxUsageCount;
  final int usageCount;
  final int? laundryAgentID;
  final String? laundryAgentName;
  final bool isValid;

  const AdminOfferModel({
    required this.offerID,
    required this.offerCode,
    required this.type,
    required this.scope,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    required this.minOrderValue,
    required this.maxUsageCount,
    required this.usageCount,
    required this.laundryAgentID,
    required this.laundryAgentName,
    required this.isValid,
  });

  factory AdminOfferModel.fromJson(Map<String, dynamic> json) {
    return AdminOfferModel(
      offerID: _readInt(json['offerID'] ?? json['offerId'] ?? json['OfferID']),
      offerCode:
          (json['offerCode'] ?? json['OfferCode'] ?? '').toString(),
      type: (json['type'] ?? json['Type'] ?? '').toString(),
      scope: (json['scope'] ?? json['Scope'] ?? '').toString(),
      discountValue:
          _readDouble(json['discountValue'] ?? json['DiscountValue']),
      startDate: _readDate(json['startDate'] ?? json['StartDate']),
      endDate: _readDate(json['endDate'] ?? json['EndDate']),
      minOrderValue: _readNullableDouble(
          json['minOrderValue'] ?? json['MinOrderValue']),
      maxUsageCount:
          _readNullableInt(json['maxUsageCount'] ?? json['MaxUsageCount']),
      usageCount: _readInt(json['usageCount'] ?? json['UsageCount']),
      laundryAgentID:
          _readNullableInt(json['laundryAgentID'] ?? json['LaundryAgentID']),
      laundryAgentName:
          (json['laundryAgentName'] ?? json['LaundryAgentName'])?.toString(),
      isValid: _readBool(json['isValid'] ?? json['IsValid']),
    );
  }

  String get targetLabel {
    if (scope == 'SpecificAgent') {
      return laundryAgentName?.isNotEmpty == true
          ? laundryAgentName!
          : 'مغسلة محددة';
    }
    return 'جميع العملاء';
  }

  String get discountLabel {
    if (type == 'Percentage') {
      return '${discountValue.toStringAsFixed(0)}%';
    }
    return '${discountValue.toStringAsFixed(0)} ريال';
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static double? _readNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static DateTime _readDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
