import 'package:flutter/material.dart';
import 'package:brightcleanprojet/core/theme/app_colors.dart';

enum OrderStatus {
  received('تم الاستلام', 'Received', AppColors.primary),
  inProgress('قيد التنفيذ', 'In Progress', AppColors.tertiary),
  ready('جاهز للتسليم', 'Ready', AppColors.success),
  delivered('تم التسليم', 'Delivered', AppColors.secondary);

  final String title;
  final String englishTitle;
  final Color color;

  const OrderStatus(this.title, this.englishTitle, this.color);
}
