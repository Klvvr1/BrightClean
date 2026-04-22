import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceType;
  
  const ServiceDetailsScreen({super.key, required this.serviceType});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  int quantity = 1;
  final double basePrice = 10.0;

  double get totalPrice => basePrice * quantity;

  Widget _buildClothesForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('نوع القطعة'),
        DropdownButtonFormField<String>(
          items: const [
            DropdownMenuItem(value: 'shirt', child: Text('قميص')),
            DropdownMenuItem(value: 'pants', child: Text('بنطلون')),
            DropdownMenuItem(value: 'dress', child: Text('فستان')),
          ],
          onChanged: (v) {},
        ),
        const SizedBox(height: 16),
        const Text('نوع الغسيل'),
        DropdownButtonFormField<String>(
          items: const [
            DropdownMenuItem(value: 'wash_iron', child: Text('غسيل وكي')),
            DropdownMenuItem(value: 'wash_only', child: Text('غسيل فقط')),
            DropdownMenuItem(value: 'iron_only', child: Text('كي فقط')),
          ],
          onChanged: (v) {},
        ),
      ],
    );
  }

  Widget _buildDynamicForm() {
    // Scaffold other forms based on serviceType matching
    if (widget.serviceType == 'shoes') return const Text('فورم غسيل الأحذية');
    if (widget.serviceType == 'carpets') return const Text('فورم غسيل السجاد (متر مربع)');
    if (widget.serviceType == 'cars') return const Text('فورم غسيل السيارات (داخلي/خارجي)');
    if (widget.serviceType == 'ac') return const Text('فورم تنظيف المكيفات (نوع المكيف)');
    if (widget.serviceType == 'maids') return const Text('فورم عاملات النظافة (بالساعة/توفير أدوات)');
    if (widget.serviceType == 'tanks') return const Text('فورم تنظيف الخزانات (علوي/أرضي)');

    return _buildClothesForm(); // default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تفاصيل خدمة: ${widget.serviceType}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDynamicForm(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الكمية:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle, color: quantity > 0 ? AppColors.primary : Colors.grey),
                      onPressed: () {
                        if (quantity > 0) setState(() => quantity--);
                      },
                    ),
                    Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primary),
                      onPressed: () {
                        setState(() => quantity++);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('السعر الإجمالي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${totalPrice.toStringAsFixed(2)} درهم', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: quantity > 0 ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم إضافة $quantity عنصر إلى السلة بنجاح!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('إضافة إلى السلة / متابعة للإكمال', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
