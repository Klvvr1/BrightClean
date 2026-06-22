import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/user_error_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/widgets/map_picker_screen.dart';
import '../../../../core/network/api_client.dart';
import '../data/providers/cart_provider.dart';
import '../data/providers/order_provider.dart';
import '../data/models/customer_address_model.dart';

import 'agent_selection_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, dynamic>? _selectedAgent;
  int? _selectedAgentId;

  String? _selectedLocationAddress;
  bool _isUsingRegistrationLocation = true;
  double? _selectedLatitude;
  double? _selectedLongitude;
  int? _selectedAddressId;
  List<CustomerAddressModel> _savedAddresses = [];

  @override
  void initState() {
    super.initState();
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    try {
      final response = await BaseApiClient().get('/api/addresses');
      final addresses = response is List
          ? response
              .whereType<Map>()
              .map((item) => CustomerAddressModel.fromJson(
                    item.map((key, value) => MapEntry(key.toString(), value)),
                  ))
              .where((address) => address.isValid)
              .toList()
          : <CustomerAddressModel>[];
      if (!mounted) return;
      setState(() {
        _savedAddresses = addresses;
        if (addresses.isNotEmpty) {
          final address = addresses.first;
          _selectedLocationAddress = address.label;
          _selectedAddressId = address.addressID;
          _selectedLatitude = address.latitude;
          _selectedLongitude = address.longitude;
          _isUsingRegistrationLocation = true;
        } else {
          _selectedLocationAddress = null;
          _selectedAddressId = null;
          _selectedLatitude = null;
          _selectedLongitude = null;
          _isUsingRegistrationLocation = false;
        }
      });
    } catch (e) {
      debugPrint('Error loading customer addresses: $e');
    }
  }

  double? _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Future<void> _selectCustomLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      final address = result['address']?.toString() ?? '';
      final coordinates = result['coordinates'];
      final latitude =
          _readDouble(result['latitude']) ?? _readDouble(coordinates?.latitude);
      final longitude = _readDouble(result['longitude']) ??
          _readDouble(coordinates?.longitude);

      if (address.isEmpty ||
          latitude == null ||
          longitude == null ||
          (latitude == 0.0 && longitude == 0.0)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('يرجى تحديد عنوان توصيل صالح'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      String area = address;
      String street = address;
      final commaSplit = address.split(',');
      if (commaSplit.length >= 2) {
        area = commaSplit[0].trim();
        street = commaSplit.sublist(1).join(',').trim();
      }

      try {
        final response = await BaseApiClient().post('/api/addresses', body: {
          'area': area,
          'street': street,
          'latitude': latitude,
          'longitude': longitude,
        });
        if (response is! Map<String, dynamic>) {
          throw Exception('Invalid address response');
        }
        final savedAddress = CustomerAddressModel.fromJson(response);
        if (!savedAddress.isValid) {
          throw Exception('Invalid address response');
        }
        if (!mounted) return;
        setState(() {
          _selectedLocationAddress = savedAddress.label;
          _selectedAddressId = savedAddress.addressID;
          _selectedLatitude = savedAddress.latitude;
          _selectedLongitude = savedAddress.longitude;
          _isUsingRegistrationLocation = false;
          _savedAddresses = [
            savedAddress,
            ..._savedAddresses
                .where((item) => item.addressID != savedAddress.addressID),
          ];
        });
      } catch (e) {
        if (!mounted) return;
        final message = userMessageFromError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حفظ عنوان التوصيل: $message'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _useRegistrationLocation() async {
    if (_savedAddresses.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('يرجى إضافة عنوان توصيل أولاً'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    final address = _savedAddresses.first;
    if (mounted) {
      setState(() {
        _selectedLocationAddress = address.label;
        _selectedAddressId = address.addressID;
        _selectedLatitude = address.latitude;
        _selectedLongitude = address.longitude;
        _isUsingRegistrationLocation = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('سلة الخدمات',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined,
                      size: 80,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: AppSpacing.md),
                  Text('سلتك فارغة حالياً',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5))),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: () => context.go('/customer_home'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                    ),
                    child: const Text('تصفح الخدمات'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      decoration: AppStyles.surface(context),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: AppRadius.button,
                              ),
                              child: Icon(Icons.cleaning_services,
                                  color: theme.colorScheme.primary),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.serviceName,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                  Text(item.selectedType,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.6))),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                      '${item.pricePerUnit} ر.ي × ${item.quantity}',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${item.totalPrice} ر.ي',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      color: theme.colorScheme.error),
                                  onPressed: () => cart.removeItem(item.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5)),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('اختر مغسلة (الوكيل)',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.sm),
                      if (_selectedAgent == null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result =
                                  await Navigator.push<Map<String, dynamic>>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AgentSelectionScreen(),
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  _selectedAgent = result;
                                  _selectedAgentId = result['id'] as int;
                                });
                              }
                            },
                            icon: const Icon(Icons.storefront_outlined),
                            label: const Text('اختر المغسلة المتوفرة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              foregroundColor:
                                  theme.colorScheme.onPrimaryContainer,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: AppStyles.surface(context),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white10
                                      : theme.colorScheme.primary
                                          .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.storefront,
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.white
                                        : theme.colorScheme.primary),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedAgent!['businessName'] as String,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedAgent!['address'] as String,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final result = await Navigator.push<
                                      Map<String, dynamic>>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AgentSelectionScreen(),
                                    ),
                                  );
                                  if (result != null) {
                                    setState(() {
                                      _selectedAgent = result;
                                      _selectedAgentId = result['id'] as int;
                                    });
                                  }
                                },
                                child: const Text('تغيير'),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      Text('موقع العميل (الاستلام والتوصيل)',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: AppStyles.surface(context),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    _selectedLocationAddress ??
                                        'جاري تحميل الموقع...',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _useRegistrationLocation,
                                    icon: const Icon(Icons.app_registration,
                                        size: 16),
                                    label: const Text('موقع التسجيل',
                                        style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor:
                                          _isUsingRegistrationLocation
                                              ? theme.colorScheme.primary
                                                  .withValues(alpha: 0.1)
                                              : Colors.transparent,
                                      side: BorderSide(
                                        color: _isUsingRegistrationLocation
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.2),
                                      ),
                                      foregroundColor:
                                          _isUsingRegistrationLocation
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _selectCustomLocation,
                                    icon: const Icon(Icons.map, size: 16),
                                    label: const Text('تحديد على الخريطة',
                                        style: TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor:
                                          !_isUsingRegistrationLocation
                                              ? theme.colorScheme.primary
                                                  .withValues(alpha: 0.1)
                                              : Colors.transparent,
                                      side: BorderSide(
                                        color: !_isUsingRegistrationLocation
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.2),
                                      ),
                                      foregroundColor:
                                          !_isUsingRegistrationLocation
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('الإجمالي',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text('${cart.totalAmount} ر.ي',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_selectedAgentId == null ||
                                  _selectedLocationAddress == null ||
                                  _selectedAddressId == null ||
                                  _selectedLatitude == null ||
                                  _selectedLongitude == null ||
                                  (_selectedLatitude == 0.0 &&
                                      _selectedLongitude == 0.0))
                              ? null
                              : () async {
                                  final scaffoldMessenger =
                                      ScaffoldMessenger.of(context);
                                  final orderProvider =
                                      Provider.of<OrderProvider>(context,
                                          listen: false);
                                  final router = GoRouter.of(context);
                                  // Show progress dialog
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (ctx) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  try {
                                    final addressId = _selectedAddressId;
                                    if (addressId == null ||
                                        _selectedLatitude == null ||
                                        _selectedLongitude == null ||
                                        (_selectedLatitude == 0.0 &&
                                            _selectedLongitude == 0.0)) {
                                      throw Exception(
                                          'يرجى إضافة عنوان توصيل صالح قبل إكمال الدفع');
                                    }
                                    final itemsDto = cart.items.map((item) {
                                      return {
                                        'serviceID': item.serviceId,
                                        'quantity': item.quantity,
                                        'unitPriceAtTimeOfBooking':
                                            item.pricePerUnit,
                                      };
                                    }).toList();
                                    if (itemsDto.any((item) =>
                                        (item['serviceID'] ?? 0) <= 0)) {
                                      throw Exception(
                                          'تحتوي السلة على خدمة غير مرتبطة بكتالوج الخادم. يرجى حذفها وإضافتها من جديد.');
                                    }

                                    final selectedAgentId = _selectedAgentId!;

                                    await orderProvider.createBooking(
                                        selectedAgentId, itemsDto,
                                        addressID: addressId);

                                    // Pop progress dialog
                                    if (context.mounted) {
                                      Navigator.of(context, rootNavigator: true)
                                          .pop();
                                      router.push('/checkout');
                                    }
                                  } catch (e) {
                                    // Pop progress dialog
                                    if (context.mounted) {
                                      Navigator.of(context, rootNavigator: true)
                                          .pop();
                                    }
                                    final message = userMessageFromError(e);
                                    scaffoldMessenger.clearSnackBars();
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'حدث خطأ أثناء الانتقال للدفع: $message'),
                                        backgroundColor:
                                            theme.colorScheme.error,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                          ),
                          child: const Text('الانتقال للدفع',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
