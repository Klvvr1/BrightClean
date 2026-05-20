// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryTaskModel _$DeliveryTaskModelFromJson(Map<String, dynamic> json) =>
    DeliveryTaskModel(
      taskID: (json['taskID'] as num).toInt(),
      bookingID: (json['bookingID'] as num).toInt(),
      deliveryStaffID: (json['deliveryStaffID'] as num?)?.toInt(),
      pickupAddressID: (json['pickupAddressID'] as num).toInt(),
      dropoffAddressID: (json['dropoffAddressID'] as num).toInt(),
      stageNumber: (json['stageNumber'] as num).toInt(),
      type: (json['type'] as num).toInt(),
      status: (json['status'] as num).toInt(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      assignedAt: json['assignedAt'] == null
          ? null
          : DateTime.parse(json['assignedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      pickupAddress: json['pickupAddress'] as Map<String, dynamic>?,
      dropoffAddress: json['dropoffAddress'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$DeliveryTaskModelToJson(DeliveryTaskModel instance) =>
    <String, dynamic>{
      'taskID': instance.taskID,
      'bookingID': instance.bookingID,
      'deliveryStaffID': instance.deliveryStaffID,
      'pickupAddressID': instance.pickupAddressID,
      'dropoffAddressID': instance.dropoffAddressID,
      'stageNumber': instance.stageNumber,
      'type': instance.type,
      'status': instance.status,
      'deliveryFee': instance.deliveryFee,
      'assignedAt': instance.assignedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'pickupAddress': instance.pickupAddress,
      'dropoffAddress': instance.dropoffAddress,
    };
