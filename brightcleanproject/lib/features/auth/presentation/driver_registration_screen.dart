import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/theme/app_colors.dart';

class DriverRegistrationScreen extends StatelessWidget {
  const DriverRegistrationScreen({super.key});

  Widget _buildFileUploadPlaceholder(String title) {
    return Container(
      height: 100,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.upload_file, color: AppColors.secondary),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: AppColors.secondary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل سائق جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CustomTextField(hintText: 'الاسم الكامل'),
            const SizedBox(height: 16),
            const CustomTextField(hintText: 'رقم الهاتف', keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            const CustomTextField(hintText: 'البريد الإلكتروني', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            const CustomTextField(hintText: 'كلمة المرور', isPassword: true),
            const SizedBox(height: 16),
            const CustomTextField(
              hintText: 'تاريخ الميلاد (YYYY-MM-DD)',
              prefixIcon: Icons.calendar_today,
            ),
            const SizedBox(height: 16),
            // Vehicle Information
            const CustomTextField(hintText: 'نوع المركبة (مثال: فان، سكوتر)'),
            const SizedBox(height: 16),
            const CustomTextField(hintText: 'رقم اللوحة'),
            const SizedBox(height: 16),
            _buildFileUploadPlaceholder('رفع صورة الهوية'),
            _buildFileUploadPlaceholder('رفع رخصة القيادة'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text('تسجيل'),
            ),
          ],
        ),
      ),
    );
  }
}
