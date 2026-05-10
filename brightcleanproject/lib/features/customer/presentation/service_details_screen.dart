import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'checkout_screen.dart';
import '../../domain/models/service_option.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceType;
  
  const ServiceDetailsScreen({super.key, required this.serviceType});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  int quantity = 1;
  final double basePrice = 10.0;
  late ServiceOption selectedOption;

  List<ServiceOption> get _serviceOptions {
    switch (widget.serviceType) {
      case 'الملابس':
        return [
          const ServiceOption(id: 'wash_iron', displayName: 'غسيل وكي', priceMultiplier: 1.5),
          const ServiceOption(id: 'wash_only', displayName: 'غسيل فقط', priceMultiplier: 1.0),
          const ServiceOption(id: 'iron_only', displayName: 'كي فقط', priceMultiplier: 1.0),
        ];
      case 'السجاد والمفروشات':
        return [
          const ServiceOption(id: 'carpet_regular', displayName: 'غسيل سجاد عادي', priceMultiplier: 1.0),
          const ServiceOption(id: 'carpet_deep', displayName: 'غسيل سجاد عميق', priceMultiplier: 2.5),
          const ServiceOption(id: 'majlis_clean', displayName: 'تنظيف مجالس', priceMultiplier: 1.5),
        ];
      case 'السيارات':
        return [
          const ServiceOption(id: 'car_exterior', displayName: 'غسيل خارجي', priceMultiplier: 1.0),
          const ServiceOption(id: 'car_full', displayName: 'غسيل داخلي وخارجي', priceMultiplier: 2.5),
          const ServiceOption(id: 'car_polish', displayName: 'تلميع شامل', priceMultiplier: 1.5),
        ];
      case 'تنظيف المكيفات':
        return [
          const ServiceOption(id: 'ac_indoor', displayName: 'تنظيف وحدة داخلية', priceMultiplier: 1.5),
          const ServiceOption(id: 'ac_full', displayName: 'تنظيف شامل (داخلي وخارجي)', priceMultiplier: 2.5),
          const ServiceOption(id: 'ac_freon', displayName: 'تعبئة فريون', priceMultiplier: 1.5),
        ];
      case 'عاملات النظافة':
        return [
          const ServiceOption(id: 'clean_4h', displayName: 'زيارة (4 ساعات)', priceMultiplier: 1.5),
          const ServiceOption(id: 'clean_8h', displayName: 'زيارة (8 ساعات)', priceMultiplier: 2.5),
          const ServiceOption(id: 'clean_full', displayName: 'باقة يوم كامل', priceMultiplier: 2.5),
        ];
      case 'تنظيف الخزانات':
        return [
          const ServiceOption(id: 'tank_upper', displayName: 'تنظيف خزان علوي', priceMultiplier: 1.0),
          const ServiceOption(id: 'tank_ground', displayName: 'تنظيف خزان أرضي', priceMultiplier: 1.5),
          const ServiceOption(id: 'tank_sterilize', displayName: 'تعقيم شامل', priceMultiplier: 2.5),
        ];
      default:
        return [
          const ServiceOption(id: 'standard', displayName: 'خدمة قياسية', priceMultiplier: 1.0),
          const ServiceOption(id: 'premium', displayName: 'خدمة مميزة', priceMultiplier: 1.5),
          const ServiceOption(id: 'comprehensive', displayName: 'خدمة شاملة', priceMultiplier: 2.5),
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    selectedOption = _serviceOptions.first;
  }

  double get totalPrice {
    return basePrice * selectedOption.priceMultiplier * quantity;
  }

  Widget _buildCheckboxOption(ServiceOption option) {
    bool isSelected = selectedOption.id == option.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
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
            option.displayName,
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
                selectedOption = option;
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
                    color: Colors.black.withOpacity(0.05),
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
                  selectedType: selectedOption.displayName,
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
