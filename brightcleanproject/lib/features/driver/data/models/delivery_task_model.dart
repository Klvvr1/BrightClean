import 'package:json_annotation/json_annotation.dart';

part 'delivery_task_model.g.dart';

@JsonSerializable()
class DeliveryTaskModel {
  @JsonKey(name: 'taskID')
  final int taskID;

  @JsonKey(name: 'bookingID')
  final int bookingID;

  @JsonKey(name: 'deliveryStaffID')
  final int? deliveryStaffID;

  @JsonKey(name: 'pickupAddressID')
  final int pickupAddressID;

  @JsonKey(name: 'dropoffAddressID')
  final int dropoffAddressID;

  @JsonKey(name: 'stageNumber')
  final int stageNumber;

  @JsonKey(name: 'type')
  final int type; // TaskType: 0 = PickupFromClient, 1 = DeliveryToClient

  @JsonKey(name: 'status')
  final int status; // DeliveryTaskStatus: 0 = Unassigned, 1 = Assigned, 2 = InProgress, 3 = Completed

  @JsonKey(name: 'deliveryFee')
  final double deliveryFee;

  @JsonKey(name: 'assignedAt')
  final DateTime? assignedAt;

  @JsonKey(name: 'completedAt')
  final DateTime? completedAt;

  @JsonKey(name: 'pickupAddress')
  final Map<String, dynamic>? pickupAddress;

  @JsonKey(name: 'dropoffAddress')
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

  factory DeliveryTaskModel.fromJson(Map<String, dynamic> json) =>
      _$DeliveryTaskModelFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryTaskModelToJson(this);
}
