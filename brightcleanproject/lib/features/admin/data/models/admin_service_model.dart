class AdminServiceModel {
  final int serviceID;
  final String serviceName;
  final int category;
  final int type;
  final double price;
  final int pricingModel;
  final int deliveryModel;
  final bool isAvailable;
  final bool isDeleted;
  final int linkedAgentCount;
  final int activeAgentCount;
  final bool hasHistoricalUsage;
  final bool canDelete;
  final bool canDisable;

  const AdminServiceModel({
    required this.serviceID,
    required this.serviceName,
    required this.category,
    required this.type,
    required this.price,
    required this.pricingModel,
    required this.deliveryModel,
    required this.isAvailable,
    required this.isDeleted,
    required this.linkedAgentCount,
    required this.activeAgentCount,
    required this.hasHistoricalUsage,
    required this.canDelete,
    required this.canDisable,
  });

  factory AdminServiceModel.fromJson(Map<String, dynamic> json) {
    final serviceID = readInt(json, ['serviceID', 'serviceId', 'ServiceID']);
    final serviceName =
        readString(json, ['serviceName', 'ServiceName'], fallback: '');
    final price = readDouble(json, ['price', 'Price']);

    // Validate parsed fields
    if (serviceID <= 0) {
      throw FormatException(
          'Invalid serviceID: expected > 0, got $serviceID. JSON: $json');
    }
    if (serviceName.isEmpty) {
      throw FormatException(
          'Invalid serviceName: expected non-empty string. JSON: $json');
    }
    if (price < 0) {
      throw FormatException(
          'Invalid price: expected >= 0, got $price. JSON: $json');
    }

    return AdminServiceModel(
      serviceID: serviceID,
      serviceName: serviceName,
      category: readInt(json, ['category', 'Category']),
      type: readInt(json, ['type', 'Type']),
      price: price,
      pricingModel: readInt(json, ['pricingModel', 'PricingModel']),
      deliveryModel: readInt(json, ['deliveryModel', 'DeliveryModel']),
      isAvailable: readBool(json, ['isAvailable', 'IsAvailable']),
      isDeleted: readBool(json, ['isDeleted', 'IsDeleted']),
      linkedAgentCount:
          readInt(json, ['linkedAgentCount', 'LinkedAgentCount']),
      activeAgentCount:
          readInt(json, ['activeAgentCount', 'ActiveAgentCount']),
      hasHistoricalUsage:
          readBool(json, ['hasHistoricalUsage', 'HasHistoricalUsage']),
      canDelete: readBool(json, ['canDelete', 'CanDelete']),
      canDisable: readBool(json, ['canDisable', 'CanDisable']),
    );
  }

  static int readInt(Map json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static double readDouble(Map json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is double) return value;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  static bool readBool(Map json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is num) return value != 0;
    }
    return false;
  }

  static String readString(
    Map json,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }
}
