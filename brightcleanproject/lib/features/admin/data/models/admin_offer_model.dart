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
      offerCode: _readRequiredString(
          json['offerCode'] ?? json['OfferCode'], 'offerCode'),
      type: _readRequiredString(json['type'] ?? json['Type'], 'type'),
      scope: _readRequiredString(json['scope'] ?? json['Scope'], 'scope'),
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

  static String _readRequiredString(dynamic value, String fieldName) {
    if (value == null || (value is String && value.isEmpty)) {
      throw FormatException(
          'Required field "$fieldName" is null or empty in offer JSON');
    }
    return value.toString();
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
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed == null) {
        throw FormatException(
            'Failed to parse required int field: value "$value" is not a valid integer');
      }
      return parsed;
    }
    throw FormatException(
        'Failed to parse required int field: value "$value" has invalid type ${value.runtimeType}');
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
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed == null) {
        throw FormatException(
            'Failed to parse required double field: value "$value" is not a valid number');
      }
      return parsed;
    }
    throw FormatException(
        'Failed to parse required double field: value "$value" has invalid type ${value.runtimeType}');
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
    if (value is int) return value == 1;
    if (value is double) return value == 1.0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }
    throw FormatException(
        'Failed to parse bool field: value "$value" (type ${value.runtimeType}) cannot be converted to bool');
  }

  static DateTime _readDate(dynamic value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed == null) {
        throw FormatException(
            'Failed to parse date field: value "$value" is not a valid ISO date string');
      }
      return parsed;
    }
    throw FormatException(
        'Failed to parse date field: value "$value" (type ${value.runtimeType}) is not a String');
  }
}
