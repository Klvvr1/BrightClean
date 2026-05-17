import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../data/providers/cart_provider.dart';
import 'package:brightcleanproject/features/customer/domain/models/service_option.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceType;

  const ServiceDetailsScreen({super.key, required this.serviceType});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final double basePrice = 10.0;
  int quantity = 1;

  late ServiceOption selectedOption;

  final TextEditingController _lengthController =
      TextEditingController(text: '1');
  final TextEditingController _widthController =
      TextEditingController(text: '1');

  final Map<String, double> _carTypes = {
    'سيارة صغيرة': 1.0,
    'سيارة وسط': 1.5,
    'سيارة كبيرة': 2.0,
  };

  late String selectedCarType;

  final Map<String, double> _acTypes = {
    'مكيف شباك': 1.0,
    'مكيف اسبليت': 1.5,
    'مكيف مركزي': 2.5,
  };

  late String selectedAcType;

  final Map<String, double> _solarPanelSizes = {
    'لوح 50 وات': 0.5,
    'لوح 100 وات': 1.0,
    'لوح 200 وات': 1.5,
    'لوح 300 وات': 2.0,
    'لوح 550-400 وات': 2.5,
    'لوح 600 وات فما فوق': 3.0,
  };

  late String selectedSolarPanelSize;

  final List<String> _clothingItems = [
    'ثوب أبيض',
    'ثوب ملون',
    'ثوب صوف',
    'غترة',
    'شماغ',
    'فليئة داخلية',
    'سروال قصير',
    'سروال طويل',
    'طاقية',
    'قميص نوم',
    'جوارب',
    'منشفة صغيرة',
    'منشفة كبيرة',
    'بدلة عسكرية',
    'بدلة رياضية',
    'بدلة باكستاني',
    'بدلة صوف',
    'بالطو',
    'بنطلون',
    'قميص',
    'ربطة عنق',
    'فستان',
    'بلوزة',
    'تنورة',
    'قميص حرير',
    'عباية',
    'طرحة',
    'شرشف مزدوج',
    'شرشف مفرد',
    'كيس مخدة',
    'مخدة',
    'روب حمام',
    'بجامة',
    'جاكيت',
    'جاكيت سبور',
    'بطانية',
    'مفرش',
    'ستائر',
    'سجاد',
    'فروة',
    'بشت',
  ];

  late String selectedClothingItem;

  List<ServiceOption> get _serviceOptions {
    switch (widget.serviceType) {
      case 'الملابس':
        return [
          const ServiceOption(
            id: 'wash_iron',
            displayName: 'غسيل وكي',
            priceMultiplier: 1.5,
          ),
          const ServiceOption(
            id: 'wash_only',
            displayName: 'غسيل فقط',
            priceMultiplier: 1.0,
          ),
          const ServiceOption(
            id: 'iron_only',
            displayName: 'كي فقط',
            priceMultiplier: 1.0,
          ),
        ];

      case 'السجاد والمفروشات':
        return [
          const ServiceOption(
            id: 'carpet_regular',
            displayName: 'غسيل سجاد عادي',
            priceMultiplier: 1.0,
          ),
          const ServiceOption(
            id: 'carpet_deep',
            displayName: 'غسيل سجاد عميق',
            priceMultiplier: 2.5,
          ),
          const ServiceOption(
            id: 'majlis_clean',
            displayName: 'تنظيف مجالس',
            priceMultiplier: 1.5,
          ),
        ];

      case 'السيارات':
        return [
          const ServiceOption(
            id: 'car_exterior',
            displayName: 'غسيل خارجي',
            priceMultiplier: 1.0,
          ),
          const ServiceOption(
            id: 'car_full',
            displayName: 'غسيل داخلي وخارجي',
            priceMultiplier: 2.5,
          ),
          const ServiceOption(
            id: 'car_polish',
            displayName: 'تلميع شامل',
            priceMultiplier: 1.5,
          ),
        ];

      case 'تنظيف المكيفات':
        return [
          const ServiceOption(
            id: 'ac_indoor',
            displayName: 'تنظيف وحدة داخلية',
            priceMultiplier: 1.5,
          ),
          const ServiceOption(
            id: 'ac_full',
            displayName: 'تنظيف شامل (داخلي وخارجي)',
            priceMultiplier: 2.5,
          ),
          const ServiceOption(
            id: 'ac_freon',
            displayName: 'تعبئة فريون',
            priceMultiplier: 1.5,
          ),
        ];

      case 'عاملات النظافة':
        return [
          const ServiceOption(
            id: 'clean_4h',
            displayName: 'زيارة (4 ساعات)',
            priceMultiplier: 1.5,
          ),
          const ServiceOption(
            id: 'clean_8h',
            displayName: 'زيارة (8 ساعات)',
            priceMultiplier: 2.5,
          ),
          const ServiceOption(
            id: 'clean_full',
            displayName: 'باقة يوم كامل',
            priceMultiplier: 2.5,
          ),
        ];

      case 'تنظيف الخزانات':
        return [
          const ServiceOption(
            id: 'tank_upper',
            displayName: 'تنظيف خزان علوي',
            priceMultiplier: 1.0,
          ),
          const ServiceOption(
            id: 'tank_ground',
            displayName: 'تنظيف خزان أرضي',
            priceMultiplier: 1.5,
          ),
          const ServiceOption(
            id: 'tank_sterilize',
            displayName: 'تعقيم شامل',
            priceMultiplier: 2.5,
          ),
        ];

      case 'غسيل الألواح الشمسية':
        return [
          const ServiceOption(
            id: 'solar_dust',
            displayName: 'غسيل بالماء (إزالة الأتربة والغبار)',
            priceMultiplier: 1.0,
          ),
          const ServiceOption(
            id: 'solar_soap',
            displayName: 'غسيل بالصابون المخصص (تنظيف عميق)',
            priceMultiplier: 1.5,
          ),
          const ServiceOption(
            id: 'solar_polish',
            displayName: 'تنظيف وتلميع بمواد خاصة (أعلى كفاءة)',
            priceMultiplier: 2.5,
          ),
        ];

      default:
        return [
          const ServiceOption(
            id: 'standard',
            displayName: 'خدمة قياسية',
            priceMultiplier: 1.0,
          ),
          const ServiceOption(
            id: 'premium',
            displayName: 'خدمة مميزة',
            priceMultiplier: 1.5,
          ),
          const ServiceOption(
            id: 'comprehensive',
            displayName: 'خدمة شاملة',
            priceMultiplier: 2.5,
          ),
        ];
    }
  }

  @override
  void initState() {
    super.initState();

    selectedClothingItem = _clothingItems.first;
    selectedOption = _serviceOptions.first;
    selectedCarType = _carTypes.keys.first;
    selectedAcType = _acTypes.keys.first;
    selectedSolarPanelSize = _solarPanelSizes.keys.first;

    _lengthController.addListener(() {
      setState(() {});
    });

    _widthController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    super.dispose();
  }

  double get totalPrice {
    double price = basePrice * selectedOption.priceMultiplier * quantity;

    if (widget.serviceType.contains('سجاد') ||
        widget.serviceType.contains('مفروشات')) {
      double length = double.tryParse(_lengthController.text) ?? 1.0;
      double width = double.tryParse(_widthController.text) ?? 1.0;

      if (length <= 0) length = 1.0;
      if (width <= 0) width = 1.0;

      price = price * (length * width);
    } else if (widget.serviceType.contains('سيار')) {
      price = price * (_carTypes[selectedCarType] ?? 1.0);
    } else if (widget.serviceType.contains('مكيف')) {
      price = price * (_acTypes[selectedAcType] ?? 1.0);
    } else if (widget.serviceType.contains('شمس')) {
      price = price * (_solarPanelSizes[selectedSolarPanelSize] ?? 1.0);
    }

    return price;
  }

  Widget _buildCheckboxOption(ServiceOption option) {
    final bool isSelected = selectedOption.id == option.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.05)
            : Colors.white,
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
            ),
          ),
          value: isSelected,
          activeColor: AppColors.primary,
          checkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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

  Widget _buildRadioSection({
    required String title,
    required List<String> items,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        RadioGroup<String>(
          groupValue: groupValue,
          onChanged: onChanged,
          child: Column(
            children: items.map((item) {
              return RadioListTile<String>(
                title: Text(item, style: const TextStyle(fontSize: 16)),
                value: item,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String get _selectedTypeForCart {
    String selectedType = selectedOption.displayName;

    if (widget.serviceType.contains('لابس')) {
      selectedType = '$selectedClothingItem - ${selectedOption.displayName}';
    } else if (widget.serviceType.contains('سيار')) {
      selectedType = '$selectedCarType - ${selectedOption.displayName}';
    } else if (widget.serviceType.contains('مكيف')) {
      selectedType = '$selectedAcType - ${selectedOption.displayName}';
    } else if (widget.serviceType.contains('شمس')) {
      selectedType = '$selectedSolarPanelSize - ${selectedOption.displayName}';
    }

    return selectedType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.serviceType,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.serviceType.contains('لابس'))
              _buildRadioSection(
                title: 'اختر نوع القطعة',
                items: _clothingItems,
                groupValue: selectedClothingItem,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedClothingItem = value;
                  });
                },
              ),

            if (widget.serviceType.contains('سيار'))
              _buildRadioSection(
                title: 'اختر حجم السيارة',
                items: _carTypes.keys.toList(),
                groupValue: selectedCarType,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedCarType = value;
                  });
                },
              ),

            if (widget.serviceType.contains('مكيف'))
              _buildRadioSection(
                title: 'اختر نوع المكيف',
                items: _acTypes.keys.toList(),
                groupValue: selectedAcType,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedAcType = value;
                  });
                },
              ),

            if (widget.serviceType.contains('شمس'))
              _buildRadioSection(
                title: 'اختر حجم اللوح',
                items: _solarPanelSizes.keys.toList(),
                groupValue: selectedSolarPanelSize,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedSolarPanelSize = value;
                  });
                },
              ),

            const Text(
              'اختر نوع الخدمة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
                  if (widget.serviceType.contains('سجاد') ||
                      widget.serviceType.contains('مفروشات')) ...[
                    const Text(
                      'مقاس القطعة (بالمتر)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _lengthController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'الطول',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _widthController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'العرض',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  Text(
                    widget.serviceType.contains('عاملات')
                        ? 'عدد الأشخاص'
                        : widget.serviceType.contains('شمس')
                            ? 'عدد الألواح'
                            : 'الكمية / عدد القطع',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

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
                              color: quantity > 1
                                  ? AppColors.primary
                                  : Colors.grey,
                              onPressed: () {
                                if (quantity > 1) {
                                  setState(() {
                                    quantity--;
                                  });
                                }
                              },
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              color: AppColors.primary,
                              onPressed: () {
                                setState(() {
                                  quantity++;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'السعر الإجمالي',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${totalPrice.toStringAsFixed(2)} ر.ي',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
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
              final cart = Provider.of<CartProvider>(context, listen: false);

              cart.addItem(
                serviceName: widget.serviceType,
                selectedType: _selectedTypeForCart,
                quantity: quantity,
                pricePerUnit: totalPrice / quantity,
                totalPrice: totalPrice,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('تم إضافة الخدمة إلى السلة بنجاح'),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'عرض السلة',
                    textColor: Colors.white,
                    onPressed: () => context.push('/cart'),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_shopping_cart),
                SizedBox(width: 8),
                Text(
                  'إضافة إلى السلة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}