class AdminSummaryModel {
  final int customersCount;
  final int laundryAgentsCount;
  final int driversCount;
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final double totalRevenue;

  const AdminSummaryModel({
    required this.customersCount,
    required this.laundryAgentsCount,
    required this.driversCount,
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.totalRevenue,
  });

  factory AdminSummaryModel.empty() {
    return const AdminSummaryModel(
      customersCount: 0,
      laundryAgentsCount: 0,
      driversCount: 0,
      totalOrders: 0,
      pendingOrders: 0,
      completedOrders: 0,
      totalRevenue: 0,
    );
  }

  factory AdminSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdminSummaryModel(
      customersCount: _readInt(json['customersCount']),
      laundryAgentsCount: _readInt(json['laundryAgentsCount']),
      driversCount: _readInt(json['driversCount']),
      totalOrders: _readInt(json['totalOrders']),
      pendingOrders: _readInt(json['pendingOrders']),
      completedOrders: _readInt(json['completedOrders']),
      totalRevenue: _readDouble(json['totalRevenue']),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
