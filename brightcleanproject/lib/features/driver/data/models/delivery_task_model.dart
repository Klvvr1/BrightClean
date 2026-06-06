class DeliveryTaskModel {
  final int taskID;
  final int bookingID;
  final int? deliveryStaffID;
  final int pickupAddressID;
  final int dropoffAddressID;
  final int stageNumber;
  final int type; // TaskType: 0 = PickupFromClient, 1 = DeliveryToClient
  final int
      status; // DeliveryTaskStatus: 0 = Unassigned, 1 = Assigned, 2 = InProgress, 3 = Completed
  final double deliveryFee;
  final DateTime? assignedAt;
  final int currentStep;
  final DateTime? startedAt;
  final DateTime? lastProgressUpdatedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? pickupAddress;
  final Map<String, dynamic>? dropoffAddress;
  final Map<String, dynamic>? booking;

  DeliveryTaskModel({
    required this.taskID,
    required this.bookingID,
    this.deliveryStaffID,
    required this.pickupAddressID,
    required this.dropoffAddressID,
    required this.stageNumber,
    required this.type,
    required this.status,
    required this.deliveryFee,
    this.assignedAt,
    this.currentStep = 0,
    this.startedAt,
    this.lastProgressUpdatedAt,
    this.completedAt,
    this.pickupAddress,
    this.dropoffAddress,
    this.booking,
  });

  static Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  factory DeliveryTaskModel.fromJson(Map<String, dynamic> json) {
    // Parse type safely (TaskType enum)
    final rawType = json['type'] ?? json['Type'];
    int parsedType = 0;
    if (rawType is int) {
      parsedType = rawType;
    } else if (rawType is String) {
      if (rawType.toLowerCase() == 'pickupfromclient') {
        parsedType = 0;
      } else if (rawType.toLowerCase() == 'deliverytoclient') {
        parsedType = 1;
      }
    }

    // Parse status safely (DeliveryTaskStatus enum)
    final rawStatus = json['status'] ?? json['Status'];
    int parsedStatus = 0;
    if (rawStatus is int) {
      parsedStatus = rawStatus;
    } else if (rawStatus is String) {
      switch (rawStatus.toLowerCase()) {
        case 'unassigned':
          parsedStatus = 0;
          break;
        case 'assigned':
          parsedStatus = 1;
          break;
        case 'inprogress':
          parsedStatus = 2;
          break;
        case 'completed':
          parsedStatus = 3;
          break;
      }
    }

    return DeliveryTaskModel(
      taskID: json['taskID'] as int? ??
          json['taskId'] as int? ??
          json['TaskID'] as int? ??
          0,
      bookingID: json['bookingID'] as int? ??
          json['bookingId'] as int? ??
          json['BookingID'] as int? ??
          0,
      deliveryStaffID: json['deliveryStaffID'] as int? ??
          json['deliveryStaffId'] as int? ??
          json['DeliveryStaffID'] as int?,
      pickupAddressID: json['pickupAddressID'] as int? ??
          json['pickupAddressId'] as int? ??
          json['PickupAddressID'] as int? ??
          0,
      dropoffAddressID: json['dropoffAddressID'] as int? ??
          json['dropoffAddressId'] as int? ??
          json['DropoffAddressID'] as int? ??
          0,
      stageNumber:
          json['stageNumber'] as int? ?? json['StageNumber'] as int? ?? 0,
      type: parsedType,
      status: parsedStatus,
      deliveryFee:
          (json['deliveryFee'] ?? json['DeliveryFee'] as num?)?.toDouble() ??
              0.0,
      assignedAt: json['assignedAt'] == null && json['AssignedAt'] == null
          ? null
          : DateTime.tryParse(
              (json['assignedAt'] ?? json['AssignedAt']) as String),
      currentStep:
          json['currentStep'] as int? ?? json['CurrentStep'] as int? ?? 0,
      startedAt: json['startedAt'] == null && json['StartedAt'] == null
          ? null
          : DateTime.tryParse(
              (json['startedAt'] ?? json['StartedAt']) as String),
      lastProgressUpdatedAt: json['lastProgressUpdatedAt'] == null &&
              json['LastProgressUpdatedAt'] == null
          ? null
          : DateTime.tryParse((json['lastProgressUpdatedAt'] ??
              json['LastProgressUpdatedAt']) as String),
      completedAt: json['completedAt'] == null && json['CompletedAt'] == null
          ? null
          : DateTime.tryParse(
              (json['completedAt'] ?? json['CompletedAt']) as String),
      pickupAddress: _readMap(json['pickupAddress'] ?? json['PickupAddress']),
      dropoffAddress:
          _readMap(json['dropoffAddress'] ?? json['DropoffAddress']),
      booking: _readMap(json['booking'] ?? json['Booking']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskID': taskID,
      'bookingID': bookingID,
      'deliveryStaffID': deliveryStaffID,
      'pickupAddressID': pickupAddressID,
      'dropoffAddressID': dropoffAddressID,
      'stageNumber': stageNumber,
      'type': type,
      'status': status,
      'deliveryFee': deliveryFee,
      'assignedAt': assignedAt?.toIso8601String(),
      'currentStep': currentStep,
      'startedAt': startedAt?.toIso8601String(),
      'lastProgressUpdatedAt': lastProgressUpdatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'booking': booking,
    };
  }
}
