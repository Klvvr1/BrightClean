import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/theme/app_colors.dart';

class CustomerRegistrationScreen extends StatelessWidget {
  const CustomerRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل عميل جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: const [
                Expanded(child: CustomTextField(hintText: 'الاسم الأول')),
                SizedBox(width: 16),
                Expanded(child: CustomTextField(hintText: 'الاسم الأخير')),
              ],
            ),
            const SizedBox(height: 16),
            const CustomTextField(hintText: 'رقم الهاتف', keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            const CustomTextField(hintText: 'البريد الإلكتروني', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            const CustomTextField(hintText: 'كلمة المرور', isPassword: true),
            const SizedBox(height: 16),
            const CustomTextField(hintText: 'تأكيد كلمة المرور', isPassword: true),
            const SizedBox(height: 16),
            // Gender Dropdown Placeholder
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(hintText: 'الجنس'),
              items: const [
                DropdownMenuItem(value: 'M', child: Text('ذكر')),
                DropdownMenuItem(value: 'F', child: Text('أنثى')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            // DOB Picker Placeholder
            const CustomTextField(
              hintText: 'تاريخ الميلاد (YYYY-MM-DD)',
              prefixIcon: Icons.calendar_today,
            ),
            const SizedBox(height: 16),
            // Map Location Placeholder
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 40, color: AppColors.primary),
                    SizedBox(height: 8),
                    Text('اضغط لتحديد العنوان على الخريطة'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // T&C
            Row(
              children: [
                Checkbox(value: false, onChanged: (v) {}),
                const Expanded(child: Text('أوافق على الشروط والأحكام')),
              ],
            ),
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
