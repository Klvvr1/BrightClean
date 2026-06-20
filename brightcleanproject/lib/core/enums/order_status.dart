import 'package:flutter/material.dart';
import 'package:brightcleanproject/core/theme/app_colors.dart';

enum OrderStatus {
  pending('قيد الانتظار', 'Pending', Colors.orange),
  received('تم استلام الطلب', 'Received', AppColors.primary),
  washing('قيد الغسيل', 'Washing', Colors.blue),
  ready('جاهز للتسليم', 'Ready for Delivery', AppColors.success),
  completed('مكتمل', 'Completed', AppColors.secondary),
  rejected('مرفوض', 'Rejected', Colors.red);

  final String title;
  final String englishTitle;
  final Color color;

  const OrderStatus(this.title, this.englishTitle, this.color);
}
