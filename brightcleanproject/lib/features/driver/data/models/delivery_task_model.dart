class DeliveryTaskModel {
  final int taskID;
  final int bookingID;
  final int? deliveryStaffID;
  final int pickupAddressID;
  final int dropoffAddressID;
  final int stageNumber;
  final int type; // TaskType: 0 = PickupFromClient, 1 = DeliveryToClient
  final int status; // DeliveryTaskStatus: 0 = Unassigned, 1 = Assigned, 2 = InProgress, 3 = Completed
  final double deliveryFee;
  final DateTime? assignedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? pickupAddress;
  final Map<String, dynamic>? dropoffAddress;

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
    this.completedAt,
    this.pickupAddress,
    this.dropoffAddress,
  });

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
      taskID: json['taskID'] as int? ?? json['taskId'] as int? ?? json['TaskID'] as int? ?? 0,
      bookingID: json['bookingID'] as int? ?? json['bookingId'] as int? ?? json['BookingID'] as int? ?? 0,
      deliveryStaffID: json['deliveryStaffID'] as int? ?? json['deliveryStaffId'] as int? ?? json['DeliveryStaffID'] as int?,
      pickupAddressID: json['pickupAddressID'] as int? ?? json['pickupAddressId'] as int? ?? json['PickupAddressID'] as int? ?? 0,
      dropoffAddressID: json['dropoffAddressID'] as int? ?? json['dropoffAddressId'] as int? ?? json['DropoffAddressID'] as int? ?? 0,
      stageNumber: json['stageNumber'] as int? ?? json['StageNumber'] as int? ?? 0,
      type: parsedType,
      status: parsedStatus,
      deliveryFee: (json['deliveryFee'] ?? json['DeliveryFee'] as num?)?.toDouble() ?? 0.0,
      assignedAt: json['assignedAt'] == null && json['AssignedAt'] == null
          ? null
          : DateTime.tryParse((json['assignedAt'] ?? json['AssignedAt']) as String),
      completedAt: json['completedAt'] == null && json['CompletedAt'] == null
          ? null
          : DateTime.tryParse((json['completedAt'] ?? json['CompletedAt']) as String),
      pickupAddress: (json['pickupAddress'] ?? json['PickupAddress']) as Map<String, dynamic>?,
      dropoffAddress: (json['dropoffAddress'] ?? json['DropoffAddress']) as Map<String, dynamic>?,
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
      'completedAt': completedAt?.toIso8601String(),
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
    };
  }
}
