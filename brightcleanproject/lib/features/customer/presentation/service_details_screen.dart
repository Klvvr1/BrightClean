import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'checkout_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceType;
  
  const ServiceDetailsScreen({super.key, required this.serviceType});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  int quantity = 1;
  final double basePrice = 10.0;
  String selectedType = '';

  List<String> get _serviceOptions {
    switch (widget.serviceType) {
      case 'الملابس':
        return ['غسيل وكي', 'غسيل فقط', 'كي فقط'];
      case 'السجاد والمفروشات':
        return ['غسيل سجاد عادي', 'غسيل سجاد عميق', 'تنظيف مجالس'];
      case 'السيارات':
        return ['غسيل خارجي', 'غسيل داخلي وخارجي', 'تلميع شامل'];
      case 'تنظيف المكيفات':
        return ['تنظيف وحدة داخلية', 'تنظيف شامل (داخلي وخارجي)', 'تعبئة فريون'];
      case 'عاملات النظافة':
        return ['زيارة (4 ساعات)', 'زيارة (8 ساعات)', 'باقة يوم كامل'];
      case 'تنظيف الخزانات':
        return ['تنظيف خزان علوي', 'تنظيف خزان أرضي', 'تعقيم شامل'];
      default:
        return ['خدمة قياسية', 'خدمة مميزة', 'خدمة شاملة'];
    }
  }

  @override
  void initState() {
    super.initState();
    selectedType = _serviceOptions.first;
  }

  double get totalPrice {
    double multiplier = 1.0;
    if (selectedType.contains('فقط') || selectedType.contains('خارجي') || selectedType.contains('علوي') || selectedType.contains('عادي')) {
      multiplier = 1.0;
    } else if (selectedType.contains('شامل') || selectedType.contains('عميق') || selectedType.contains('8 ساعات') || selectedType.contains('يوم كامل') || selectedType.contains('داخلي وخارجي')) {
      multiplier = 2.5;
    } else {
      multiplier = 1.5;
    }
    return basePrice * multiplier * quantity;
  }

  Widget _buildCheckboxOption(String title) {
    bool isSelected = selectedType == title;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          unselectedWidgetColor: Colors.grey.shade400,
        ),
        child: CheckboxListTile(
          title: Text(
            title, 
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : Colors.black87,
            )
          ),
          value: isSelected,
          activeColor: AppColors.primary,
          checkColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onChanged: (bool? value) {
            if (value == true) {
              setState(() {
                selectedType = title;
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.serviceType, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اختر نوع الخدمة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._serviceOptions.map((option) => _buildCheckboxOption(option)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الكمية / عدد القطع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              color: quantity > 1 ? AppColors.primary : Colors.grey,
                              onPressed: () {
                                if (quantity > 1) setState(() => quantity--);
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('$quantity', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              color: AppColors.primary,
                              onPressed: () {
                                setState(() => quantity++);
                              },
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('السعر الإجمالي', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('${totalPrice.toStringAsFixed(2)} درهم', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CheckoutScreen(
                  serviceName: widget.serviceType,
                  selectedType: selectedType,
                  quantity: quantity,
                  totalPrice: totalPrice,
                )),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: const Text('إكمال الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
