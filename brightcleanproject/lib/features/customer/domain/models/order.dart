import 'package:flutter/material.dart';

class Order {
  final String orderId;
  final String date;
  final String details;
  final String status;
  final Color statusColor;
  final int activeStepIndex;

  Order({
    required this.orderId,
    required this.date,
    required this.details,
    required this.status,
    required this.statusColor,
    required this.activeStepIndex,
  });
}
