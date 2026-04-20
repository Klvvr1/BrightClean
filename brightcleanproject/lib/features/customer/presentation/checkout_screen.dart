import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إتمام الطلب')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            const Text('ملخص الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: const Text('غسيل ملابس (غسيل وكي)'),
                subtitle: const Text('الكمية: 5 قطع'),
                trailing: const Text('50 درهم', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            // Location
            const Text('موقع التوصيل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on, color: AppColors.primary),
                title: const Text('المنزل'),
                subtitle: const Text('شارع الشيخ زايد، دبي'),
                trailing: TextButton(onPressed: () {}, child: const Text('تغيير')),
              ),
            ),
            const SizedBox(height: 24),
            // Delivery Time Slots
            const Text('وقت التوصيل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(hintText: 'اختر الموعد'),
              items: const [
                DropdownMenuItem(value: 'morning', child: Text('09:00 ص - 12:00 م')),
                DropdownMenuItem(value: 'afternoon', child: Text('12:00 م - 03:00 م')),
                DropdownMenuItem(value: 'evening', child: Text('03:00 م - 06:00 م')),
              ],
              onChanged: (v) {},
            ),
            const SizedBox(height: 24),
            // Payment Method
            const Text('طريقة الدفع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: 'cash', // Fake logic for UI
              onChanged: (String? v) {},
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('دفع عند الاستلام'),
                    value: 'cash',
                  ),
                  RadioListTile<String>(
                    title: const Text('بطاقة ائتمان'),
                    value: 'card',
                  ),
                  RadioListTile<String>(
                    title: const Text('المحفظة (150 درهم متوفر)'),
                    value: 'wallet',
                  ),
                ],
              ),
            ),
            const Divider(),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المجموع الكلي:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('50 درهم', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {},
            child: const Text('تأكيد الطلب'),
          ),
        ),
      ),
    );
  }
}
