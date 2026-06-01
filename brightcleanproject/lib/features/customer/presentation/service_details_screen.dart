import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/network/api_client.dart';
import '../data/models/booking_model.dart';
import '../data/providers/cart_provider.dart';
import 'package:brightcleanproject/features/customer/domain/models/service_option.dart';
import 'package:brightcleanproject/features/customer/domain/models/cart_item.dart';

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
  final TextEditingController _lengthController = TextEditingController(text: '1');
  final TextEditingController _widthController = TextEditingController(text: '1');

  final Map<String, double> _carTypes = {
    'دراجة نارية': 0.5,
    'تك تك': 0.7,
    'سيارة صغيرة': 1.0,
    'سيارة وسط': 1.5,
    'سيارة كبيرة': 2.0,
  };
  late String selectedCarType;
  final Map<String, int> _carQuantities = {};

  final Map<String, double> _acTypes = {
    'مكيف شباك': 1.0,
    'مكيف اسبليت': 1.5,
    'مكيف مركزي': 2.5,
  };
  late String selectedAcType;
  final Map<String, int> _acQuantities = {};

  final Map<String, double> _solarPanelSizes = {
    'لوح 50 وات': 0.5,
    'لوح 100 وات': 1.0,
    'لوح 200 وات': 1.5,
    'لوح 300 وات': 2.0,
    'لوح 550-400 وات': 2.5,
    'لوح 600 وات فما فوق': 3.0,
  };
  late String selectedSolarPanelSize;
  final Map<String, int> _solarQuantities = {};

  final Map<String, int> _carpetQuantities = {
    'غسيل سجاد عادي': 0,
    'غسيل منسوجات': 0,
  };
  final Map<String, List<TextEditingController>> _carpetLengthControllers = {
    'غسيل سجاد عادي': [],
    'غسيل منسوجات': [],
  };
  final Map<String, List<TextEditingController>> _carpetWidthControllers = {
    'غسيل سجاد عادي': [],
    'غسيل منسوجات': [],
  };

  final Map<String, double> _tankTypes = {
    'خزان علوي': 1.0,
    'خزان سفلي': 1.5,
  };
  final Map<String, int> _tankQuantities = {
    'خزان علوي': 0,
    'خزان سفلي': 0,
  };
  final Map<String, List<TextEditingController>> _tankVolumeControllers = {
    'خزان علوي': [],
    'خزان سفلي': [],
  };

  List<ServiceCatalogItemModel> _catalogServices = [];

  int maidHours = 1;
  int maidPersons = 1;

  // List of clothing items for the 'الملابس' service
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
    'المعوز',
    'العمامة',
  ];
  late String selectedClothingItem;
  final Map<String, int> _clothingQuantities = {};


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
          const ServiceOption(id: 'furniture_wash', displayName: 'غسيل وتطهير', priceMultiplier: 1.0),
        ];
      case 'السيارات':
        return [
          const ServiceOption(id: 'car_exterior', displayName: 'غسيل خارجي', priceMultiplier: 1.0),
          const ServiceOption(id: 'car_full', displayName: 'غسيل داخلي وخارجي', priceMultiplier: 2.5),
        ];
      case 'تنظيف المكيفات':
        return [
          const ServiceOption(id: 'ac_indoor', displayName: 'تنظيف وحدة داخلية', priceMultiplier: 1.5),
          const ServiceOption(id: 'ac_full', displayName: 'تنظيف شامل (داخلي وخارجي)', priceMultiplier: 2.5),
        ];
      case 'عاملات النظافة':
        return [
          const ServiceOption(id: 'maid_hourly', displayName: 'تنظيف بالساعة', priceMultiplier: 1.0),
        ];
      case 'تنظيف الخزانات':
        return [
          const ServiceOption(id: 'tank_regular', displayName: 'تنظيف غسيل وتعقيم', priceMultiplier: 1.0),
        ];
      case 'غسيل الألواح الشمسية':
        return [
          const ServiceOption(id: 'solar_dust', displayName: 'غسيل بالماء (إزالة الأتربة والغبار)', priceMultiplier: 1.0),
          const ServiceOption(id: 'solar_soap', displayName: 'غسيل بالصابون المخصص (تنظيف عميق)', priceMultiplier: 1.5),
          const ServiceOption(id: 'solar_polish', displayName: 'تنظيف وتلميع بمواد خاصة (أعلى كفاءة)', priceMultiplier: 2.5),
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
    for (var item in _clothingItems) {
      _clothingQuantities[item] = 0;
    }
    for (var key in _carTypes.keys) {
      _carQuantities[key] = 0;
    }
    for (var key in _acTypes.keys) {
      _acQuantities[key] = 0;
    }
    for (var key in _solarPanelSizes.keys) {
      _solarQuantities[key] = 0;
    }
    selectedClothingItem = _clothingItems.first;
    selectedOption = _serviceOptions.first;
    selectedCarType = _carTypes.keys.first;
    selectedAcType = _acTypes.keys.first;
    selectedSolarPanelSize = _solarPanelSizes.keys.first;
    _lengthController.addListener(() => setState(() {}));
    _widthController.addListener(() => setState(() {}));
    _loadCatalogServices();
  }

  Future<void> _loadCatalogServices() async {
    try {
      final apiClient = BaseApiClient();
      final response = await apiClient.get('/api/services');
      if (response is List) {
        final items = response.map((json) => ServiceCatalogItemModel.fromJson(json as Map<String, dynamic>)).toList();
        if (mounted) {
          setState(() {
            _catalogServices = items;
          });
        }
      } else {
        debugPrint('Services catalog response was not a list: $response');
      }
    } catch (e) {
      debugPrint('Error loading catalog services silently: $e');
    }
  }

  int get totalClothingPieces {
    int total = 0;
    _clothingQuantities.forEach((item, qty) {
      total += qty;
    });
    return total;
  }

  int get totalCarpetPieces {
    int total = 0;
    _carpetQuantities.forEach((item, qty) {
      total += qty;
    });
    return total;
  }

  int get totalTankPieces {
    int total = 0;
    _tankQuantities.forEach((item, qty) {
      total += qty;
    });
    return total;
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _carpetLengthControllers.forEach((_, list) {
      for (var c in list) {
        c.dispose();
      }
    });
    _carpetWidthControllers.forEach((_, list) {
      for (var c in list) {
        c.dispose();
      }
    });
    _tankVolumeControllers.forEach((_, list) {
      for (var c in list) {
        c.dispose();
      }
    });
    super.dispose();
  }

  void _updateCarpetQuantity(String item, int newQty) {
    setState(() {
      _carpetQuantities[item] = newQty;
      final lengthList = _carpetLengthControllers[item]!;
      final widthList = _carpetWidthControllers[item]!;
      
      while (lengthList.length < newQty) {
        final controller = TextEditingController(text: '1.0');
        controller.addListener(() => setState(() {}));
        lengthList.add(controller);
      }
      while (widthList.length < newQty) {
        final controller = TextEditingController(text: '1.0');
        controller.addListener(() => setState(() {}));
        widthList.add(controller);
      }
      
      // Dispose of excess controllers
      while (lengthList.length > newQty) {
        lengthList.removeLast().dispose();
      }
      while (widthList.length > newQty) {
        widthList.removeLast().dispose();
      }
    });
  }

  void _updateTankQuantity(String item, int newQty) {
    setState(() {
      _tankQuantities[item] = newQty;
      final volumeList = _tankVolumeControllers[item]!;
      
      while (volumeList.length < newQty) {
        final controller = TextEditingController(text: '1000');
        controller.addListener(() => setState(() {}));
        volumeList.add(controller);
      }
      
      // Dispose of excess controllers
      while (volumeList.length > newQty) {
        volumeList.removeLast().dispose();
      }
    });
  }

  double get totalPrice {
    if (widget.serviceType.contains('لابس')) {
      double total = 0.0;
      _clothingQuantities.forEach((item, qty) {
        if (qty > 0) {
          total += basePrice * selectedOption.priceMultiplier * qty;
        }
      });
      return total;
    }
    if (widget.serviceType.contains('سجاد') || widget.serviceType.contains('مفروشات')) {
      double total = 0.0;
      _carpetQuantities.forEach((item, qty) {
        if (qty > 0) {
          final lengthList = _carpetLengthControllers[item]!;
          final widthList = _carpetWidthControllers[item]!;
          double itemBaseMultiplier = (item == 'غسيل سجاد عادي') ? 1.0 : 1.5;
          for (int i = 0; i < qty; i++) {
            double l = double.tryParse(lengthList[i].text) ?? 1.0;
            double w = double.tryParse(widthList[i].text) ?? 1.0;
            if (l <= 0) l = 1.0;
            if (w <= 0) w = 1.0;
            total += basePrice * selectedOption.priceMultiplier * itemBaseMultiplier * (l * w);
          }
        }
      });
      return total;
    }
    if (widget.serviceType.contains('سيار')) {
      double total = 0.0;
      _carQuantities.forEach((type, qty) {
        if (qty > 0) {
          total += basePrice * selectedOption.priceMultiplier * (_carTypes[type] ?? 1.0) * qty;
        }
      });
      return total;
    }
    if (widget.serviceType.contains('مكيف')) {
      double total = 0.0;
      _acQuantities.forEach((type, qty) {
        if (qty > 0) {
          total += basePrice * selectedOption.priceMultiplier * (_acTypes[type] ?? 1.0) * qty;
        }
      });
      return total;
    }
    if (widget.serviceType.contains('شمس')) {
      double total = 0.0;
      _solarQuantities.forEach((size, qty) {
        if (qty > 0) {
          total += basePrice * selectedOption.priceMultiplier * (_solarPanelSizes[size] ?? 1.0) * qty;
        }
      });
      return total;
    }
    if (widget.serviceType.contains('عاملات')) {
      return basePrice * selectedOption.priceMultiplier * maidHours * maidPersons;
    }
    if (widget.serviceType.contains('خزان')) {
      double total = 0.0;
      _tankQuantities.forEach((type, qty) {
        if (qty > 0) {
          final volumeList = _tankVolumeControllers[type]!;
          double typeMultiplier = _tankTypes[type] ?? 1.0;
          for (int i = 0; i < qty; i++) {
            double volume = double.tryParse(volumeList[i].text) ?? 1000.0;
            if (volume <= 0) volume = 1000.0;
            double factor = (volume / 1000.0) < 1.0 ? 1.0 : (volume / 1000.0);
            total += basePrice * selectedOption.priceMultiplier * typeMultiplier * factor;
          }
        }
      });
      return total;
    }
    return basePrice * selectedOption.priceMultiplier * quantity;
  }

  Widget _buildCheckboxOption(ServiceOption option) {
    bool isSelected = selectedOption.id == option.id;
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.surface,
        borderRadius: AppRadius.button,
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Theme(
        data: theme.copyWith(
          unselectedWidgetColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        child: CheckboxListTile(
          title: Text(
            option.displayName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            )
          ),
          value: isSelected,
          activeColor: theme.colorScheme.primary,
          checkColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
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

  double _calculateCarpetPrice(String item, int qty) {
    if (qty <= 0) return 0.0;
    final lengthList = _carpetLengthControllers[item];
    final widthList = _carpetWidthControllers[item];
    if (lengthList == null || widthList == null) return 0.0;
    double itemBaseMultiplier = (item == 'غسيل سجاد عادي') ? 1.0 : 1.5;
    double sum = 0.0;
    for (int i = 0; i < qty; i++) {
      if (i >= lengthList.length || i >= widthList.length) break;
      double l = double.tryParse(lengthList[i].text) ?? 1.0;
      double w = double.tryParse(widthList[i].text) ?? 1.0;
      if (l <= 0) l = 1.0;
      if (w <= 0) w = 1.0;
      sum += basePrice * selectedOption.priceMultiplier * itemBaseMultiplier * (l * w);
    }
    return sum;
  }

  Widget _buildCounterRow({
    required String title,
    required int quantity,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    String? subtitle,
    double? unitPrice,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: quantity > 0 ? theme.colorScheme.primary.withValues(alpha: 0.05) : theme.colorScheme.surface,
        borderRadius: AppRadius.button,
        border: Border.all(
          color: quantity > 0 ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.2),
          width: quantity > 0 ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: quantity > 0 ? FontWeight.bold : FontWeight.normal,
                    color: quantity > 0 ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ],
            ),
          ),
          if (quantity > 0 && unitPrice != null) ...[
            Text(
              '${(unitPrice * quantity).toStringAsFixed(2)} ر.ي',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: AppRadius.button,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  color: quantity > 0 ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  onPressed: onDecrement,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(
                    '$quantity',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: quantity > 0 ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  color: theme.colorScheme.primary,
                  onPressed: onIncrement,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Resolved catalog lookup from backend API with local mapping fallback
  int _resolveServiceId(String itemName) {
    if (_catalogServices.isNotEmpty) {
      try {
        final matchingItem = _catalogServices.firstWhere(
          (s) => s.serviceName == itemName,
        );
        return matchingItem.serviceID;
      } catch (_) {
        // Fallback to standard "Wash & Iron" service ID dynamically
        try {
          final defaultItem = _catalogServices.firstWhere(
            (s) => s.serviceName == 'Wash & Iron',
          );
          return defaultItem.serviceID;
        } catch (_) {
          // Absolute fallback: first available catalog service ID
          return _catalogServices.first.serviceID;
        }
      }
    }

    // Resilient fallback to hardcoded IDs based on DbInitializer seed data
    switch (itemName) {
      case 'المعوز':
        return 2;
      case 'العمامة':
        return 3;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceType, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.serviceType.contains('لابس')) ...[
              const Text('اختر نوع القطعة والكمية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Column(
                children: _clothingItems.map((item) {
                  return _buildCounterRow(
                    title: item,
                    quantity: _clothingQuantities[item] ?? 0,
                    unitPrice: basePrice * selectedOption.priceMultiplier,
                    onDecrement: () {
                      final qty = _clothingQuantities[item] ?? 0;
                      if (qty > 0) {
                        setState(() {
                          _clothingQuantities[item] = qty - 1;
                        });
                      }
                    },
                    onIncrement: () {
                      final qty = _clothingQuantities[item] ?? 0;
                      setState(() {
                        _clothingQuantities[item] = qty + 1;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            if (widget.serviceType.contains('سجاد') || widget.serviceType.contains('مفروشات')) ...[
              const Text('اختر نوع الخدمة والكمية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Column(
                children: _carpetQuantities.keys.map((item) {
                  final qty = _carpetQuantities[item] ?? 0;
                  return _buildCounterRow(
                    title: item,
                    quantity: qty,
                    unitPrice: qty > 0
                        ? (_calculateCarpetPrice(item, qty) / qty)
                        : (basePrice * selectedOption.priceMultiplier * (item == 'غسيل سجاد عادي' ? 1.0 : 1.5)),
                    onDecrement: () {
                      final qty = _carpetQuantities[item] ?? 0;
                      if (qty > 0) {
                        _updateCarpetQuantity(item, qty - 1);
                      }
                    },
                    onIncrement: () {
                      final qty = _carpetQuantities[item] ?? 0;
                      _updateCarpetQuantity(item, qty + 1);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            if (widget.serviceType.contains('سيار')) ...[
              const Text('اختر نوع المركبة والكمية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Column(
                children: _carTypes.keys.map((type) {
                  return _buildCounterRow(
                    title: type,
                    quantity: _carQuantities[type] ?? 0,
                    subtitle: 'مضاعف السعر: ${_carTypes[type]}x',
                    unitPrice: basePrice * selectedOption.priceMultiplier * (_carTypes[type] ?? 1.0),
                    onDecrement: () {
                      final qty = _carQuantities[type] ?? 0;
                      if (qty > 0) {
                        setState(() {
                          _carQuantities[type] = qty - 1;
                        });
                      }
                    },
                    onIncrement: () {
                      final qty = _carQuantities[type] ?? 0;
                      setState(() {
                        _carQuantities[type] = qty + 1;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            if (widget.serviceType.contains('مكيف')) ...[
              const Text('اختر نوع المكيف والكمية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Column(
                children: _acTypes.keys.map((type) {
                  return _buildCounterRow(
                    title: type,
                    quantity: _acQuantities[type] ?? 0,
                    subtitle: 'مضاعف السعر: ${_acTypes[type]}x',
                    unitPrice: basePrice * selectedOption.priceMultiplier * (_acTypes[type] ?? 1.0),
                    onDecrement: () {
                      final qty = _acQuantities[type] ?? 0;
                      if (qty > 0) {
                        setState(() {
                          _acQuantities[type] = qty - 1;
                        });
                      }
                    },
                    onIncrement: () {
                      final qty = _acQuantities[type] ?? 0;
                      setState(() {
                        _acQuantities[type] = qty + 1;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            if (widget.serviceType.contains('عاملات')) ...[
              const Text('تحديد تفاصيل خدمة عاملة النظافة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildCounterRow(
                title: 'عدد الساعات المطلوبة',
                quantity: maidHours,
                subtitle: 'الحد الأدنى ساعة واحدة',
                unitPrice: basePrice * selectedOption.priceMultiplier * maidPersons,
                onDecrement: () {
                  if (maidHours > 1) {
                    setState(() {
                      maidHours--;
                    });
                  }
                },
                onIncrement: () {
                  setState(() {
                    maidHours++;
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildCounterRow(
                title: 'عدد العاملات المطلوبة',
                quantity: maidPersons,
                subtitle: 'عاملة نظافة أو أكثر',
                unitPrice: basePrice * selectedOption.priceMultiplier * maidHours,
                onDecrement: () {
                  if (maidPersons > 1) {
                    setState(() {
                      maidPersons--;
                    });
                  }
                },
                onIncrement: () {
                  setState(() {
                    maidPersons++;
                  });
                },
              ),
              const SizedBox(height: 24),
            ],
            if (widget.serviceType.contains('خزان')) ...[
              const Text('اختر نوع الخزانات والكمية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Column(
                children: _tankTypes.keys.map((type) {
                  return _buildCounterRow(
                    title: type,
                    quantity: _tankQuantities[type] ?? 0,
                    subtitle: 'مضاعف السعر: ${_tankTypes[type]}x',
                    unitPrice: basePrice * selectedOption.priceMultiplier * (_tankTypes[type] ?? 1.0),
                    onDecrement: () {
                      final qty = _tankQuantities[type] ?? 0;
                      if (qty > 0) {
                        _updateTankQuantity(type, qty - 1);
                      }
                    },
                    onIncrement: () {
                      final qty = _tankQuantities[type] ?? 0;
                      _updateTankQuantity(type, qty + 1);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            if (widget.serviceType.contains('شمس')) ...[
              const Text('اختر حجم لوح الشمس والكمية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Column(
                children: _solarPanelSizes.keys.map((size) {
                  return _buildCounterRow(
                    title: size,
                    quantity: _solarQuantities[size] ?? 0,
                    subtitle: 'مضاعف السعر: ${_solarPanelSizes[size]}x',
                    unitPrice: basePrice * selectedOption.priceMultiplier * (_solarPanelSizes[size] ?? 1.0),
                    onDecrement: () {
                      final qty = _solarQuantities[size] ?? 0;
                      if (qty > 0) {
                        setState(() {
                          _solarQuantities[size] = qty - 1;
                        });
                      }
                    },
                    onIncrement: () {
                      final qty = _solarQuantities[size] ?? 0;
                      setState(() {
                        _solarQuantities[size] = qty + 1;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            const Text('اختر نوع الخدمة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._serviceOptions.map((option) => _buildCheckboxOption(option)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: AppStyles.surface(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.serviceType.contains('سجاد') || widget.serviceType.contains('مفروشات')) ...[
                    ..._carpetQuantities.entries.expand((entry) {
                      final item = entry.key;
                      final qty = entry.value;
                      final lengthList = _carpetLengthControllers[item]!;
                      final widthList = _carpetWidthControllers[item]!;
                      
                      return List.generate(qty, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$item (القطعة ${index + 1})',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: lengthList[index],
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        labelText: 'الطول (بالمتر)',
                                        border: OutlineInputBorder(borderRadius: AppRadius.button),
                                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                        filled: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: TextField(
                                      controller: widthList[index],
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        labelText: 'العرض (بالمتر)',
                                        border: OutlineInputBorder(borderRadius: AppRadius.button),
                                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                        filled: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      });
                    }),
                  ],
                  if (widget.serviceType.contains('خزان')) ...[
                    ..._tankQuantities.entries.expand((entry) {
                      final item = entry.key;
                      final qty = entry.value;
                      final volumeList = _tankVolumeControllers[item]!;
                      
                      return List.generate(qty, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$item (القطعة ${index + 1})',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: volumeList[index],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'سعة الخزان (باللتر)',
                                  border: OutlineInputBorder(borderRadius: AppRadius.button),
                                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  filled: true,
                                ),
                              ),
                            ],
                          ),
                        );
                      });
                    }),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('إجمالي العدد المختار', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        '${widget.serviceType.contains('لابس') ? totalClothingPieces : (widget.serviceType.contains('سجاد') || widget.serviceType.contains('مفروشات') ? totalCarpetPieces : (widget.serviceType.contains('خزان') ? totalTankPieces : (widget.serviceType.contains('سيار') ? _carQuantities.values.fold<int>(0, (sum, q) => sum + q) : (widget.serviceType.contains('مكيف') ? _acQuantities.values.fold<int>(0, (sum, q) => sum + q) : (widget.serviceType.contains('شمس') ? _solarQuantities.values.fold<int>(0, (sum, q) => sum + q) : (widget.serviceType.contains('عاملات') ? maidPersons : 1))))))} قطعة',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('السعر الإجمالي', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                          const SizedBox(height: 4),
                          Text('${totalPrice.toStringAsFixed(2)} ر.ي', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
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
            onPressed: () async {
              final isCartService = widget.serviceType == 'الملابس' || widget.serviceType == 'السجاد والمفروشات';

              if (isCartService) {
                final cart = Provider.of<CartProvider>(context, listen: false);
                final messenger = ScaffoldMessenger.of(context);
                final router = GoRouter.of(context);

                if (widget.serviceType.contains('لابس')) {
                  if (totalClothingPieces == 0) {
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('يرجى اختيار قطعة ملابس واحدة على الأقل وزيادة كميتها'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  // Add all selected clothing items to the cart
                  for (var entry in _clothingQuantities.entries) {
                    if (entry.value > 0) {
                      await cart.addItem(
                        serviceName: widget.serviceType,
                        selectedType: '${entry.key} - ${selectedOption.displayName}',
                        quantity: entry.value,
                        pricePerUnit: basePrice * selectedOption.priceMultiplier,
                        totalPrice: basePrice * selectedOption.priceMultiplier * entry.value,
                        serviceId: _resolveServiceId(entry.key),
                      );
                    }
                  }
                  
                  // Reset clothing item quantities
                  if (!mounted) return;
                  setState(() {
                    for (var item in _clothingItems) {
                      _clothingQuantities[item] = 0;
                    }
                  });
                  
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('تم إضافة الخدمات إلى السلة بنجاح'),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 4),
                      behavior: SnackBarBehavior.floating,
                      showCloseIcon: true,
                      closeIconColor: Colors.white,
                      action: SnackBarAction(
                        label: 'عرض السلة',
                        textColor: Colors.white,
                        onPressed: () {
                          messenger.clearSnackBars();
                          router.push('/cart');
                        },
                      ),
                    ),
                  );
                } else if (widget.serviceType.contains('سجاد') || widget.serviceType.contains('مفروشات')) {
                  if (totalCarpetPieces == 0) {
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('يرجى اختيار سجادة أو منسوج واحد على الأقل وزيادة كميتها'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  
                  // Add all selected carpet pieces with their dimensions to the cart
                  for (var entry in _carpetQuantities.entries) {
                    if (entry.value > 0) {
                      final lengthList = _carpetLengthControllers[entry.key]!;
                      final widthList = _carpetWidthControllers[entry.key]!;
                      double itemBaseMultiplier = (entry.key == 'غسيل سجاد عادي') ? 1.0 : 1.5;
                      for (int i = 0; i < entry.value; i++) {
                        double l = double.tryParse(lengthList[i].text) ?? 1.0;
                        double w = double.tryParse(widthList[i].text) ?? 1.0;
                        if (l <= 0) l = 1.0;
                        if (w <= 0) w = 1.0;
                        double itemPrice = basePrice * selectedOption.priceMultiplier * itemBaseMultiplier * (l * w);
                        await cart.addItem(
                          serviceName: widget.serviceType,
                          selectedType: '${entry.key} (القطعة ${i + 1}: ${l.toStringAsFixed(1)}م x ${w.toStringAsFixed(1)}م)',
                          quantity: 1,
                          pricePerUnit: itemPrice,
                          totalPrice: itemPrice,
                          serviceId: _resolveServiceId(entry.key),
                        );
                      }
                    }
                  }
                  
                  if (!mounted) return;
                  setState(() {
                    for (final key in _carpetQuantities.keys.toList()) {
                      _updateCarpetQuantity(key, 0);
                    }
                  });
                  
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('تم إضافة الخدمات إلى السلة بنجاح'),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 4),
                      behavior: SnackBarBehavior.floating,
                      showCloseIcon: true,
                      closeIconColor: Colors.white,
                      action: SnackBarAction(
                        label: 'عرض السلة',
                        textColor: Colors.white,
                        onPressed: () {
                          messenger.clearSnackBars();
                          router.push('/cart');
                        },
                      ),
                    ),
                  );
                }
              } else {
                // Direct Checkout Flow
                if (widget.serviceType.contains('سيار')) {
                  final List<CartItem> list = [];
                  _carQuantities.forEach((type, qty) {
                    if (qty > 0) {
                      double unitPrice = basePrice * selectedOption.priceMultiplier * (_carTypes[type] ?? 1.0);
                      list.add(CartItem(
                        id: '${DateTime.now().millisecondsSinceEpoch}_$type',
                        serviceName: widget.serviceType,
                        selectedType: '$type - ${selectedOption.displayName}',
                        quantity: qty,
                        pricePerUnit: unitPrice,
                        totalPrice: unitPrice * qty,
                      ));
                    }
                  });
                  if (list.isEmpty) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى تحديد مركبة واحدة على الأقل')),
                    );
                    return;
                  }
                  context.push('/checkout', extra: list);
                } else if (widget.serviceType.contains('مكيف')) {
                  final List<CartItem> list = [];
                  _acQuantities.forEach((type, qty) {
                    if (qty > 0) {
                      double unitPrice = basePrice * selectedOption.priceMultiplier * (_acTypes[type] ?? 1.0);
                      list.add(CartItem(
                        id: '${DateTime.now().millisecondsSinceEpoch}_$type',
                        serviceName: widget.serviceType,
                        selectedType: '$type - ${selectedOption.displayName}',
                        quantity: qty,
                        pricePerUnit: unitPrice,
                        totalPrice: unitPrice * qty,
                      ));
                    }
                  });
                  if (list.isEmpty) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى تحديد مكيف واحد على الأقل')),
                    );
                    return;
                  }
                  context.push('/checkout', extra: list);
                } else if (widget.serviceType.contains('شمس')) {
                  final List<CartItem> list = [];
                  _solarQuantities.forEach((size, qty) {
                    if (qty > 0) {
                      double unitPrice = basePrice * selectedOption.priceMultiplier * (_solarPanelSizes[size] ?? 1.0);
                      list.add(CartItem(
                        id: '${DateTime.now().millisecondsSinceEpoch}_$size',
                        serviceName: widget.serviceType,
                        selectedType: '$size - ${selectedOption.displayName}',
                        quantity: qty,
                        pricePerUnit: unitPrice,
                        totalPrice: unitPrice * qty,
                      ));
                    }
                  });
                  if (list.isEmpty) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى تحديد لوح واحد على الأقل')),
                    );
                    return;
                  }
                  context.push('/checkout', extra: list);
                } else if (widget.serviceType.contains('خزان')) {
                  final List<CartItem> list = [];
                  _tankQuantities.forEach((type, qty) {
                    if (qty > 0) {
                      final volumeList = _tankVolumeControllers[type]!;
                      double typeMultiplier = _tankTypes[type] ?? 1.0;
                      for (int i = 0; i < qty; i++) {
                        double volume = double.tryParse(volumeList[i].text) ?? 1000.0;
                        if (volume <= 0) volume = 1000.0;
                        double factor = (volume / 1000.0) < 1.0 ? 1.0 : (volume / 1000.0);
                        double unitPrice = basePrice * selectedOption.priceMultiplier * typeMultiplier * factor;
                        list.add(CartItem(
                          id: '${DateTime.now().millisecondsSinceEpoch}_${type}_$i',
                          serviceName: widget.serviceType,
                          selectedType: '$type (سعة ${volume.toStringAsFixed(0)} لتر) - ${selectedOption.displayName}',
                          quantity: 1,
                          pricePerUnit: unitPrice,
                          totalPrice: unitPrice,
                        ));
                      }
                    }
                  });
                  if (list.isEmpty) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى تحديد خزان واحد على الأقل')),
                    );
                    return;
                  }
                  context.push('/checkout', extra: list);
                } else if (widget.serviceType.contains('عاملات')) {
                  final double unitPrice = basePrice * selectedOption.priceMultiplier * maidHours;
                  final directItem = CartItem(
                    id: DateTime.now().toString(),
                    serviceName: widget.serviceType,
                    selectedType: 'عاملات النظافة بالساعة (عدد الساعات: $maidHours، عدد العاملات: $maidPersons)',
                    quantity: maidPersons,
                    pricePerUnit: unitPrice,
                    totalPrice: unitPrice * maidPersons,
                  );
                  context.push('/checkout', extra: [directItem]);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  (widget.serviceType == 'الملابس' || widget.serviceType == 'السجاد والمفروشات')
                      ? Icons.add_shopping_cart
                      : Icons.check_circle_outline,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  (widget.serviceType == 'الملابس' || widget.serviceType == 'السجاد والمفروشات')
                      ? 'إضافة إلى السلة'
                      : 'إتمام الطلب',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
