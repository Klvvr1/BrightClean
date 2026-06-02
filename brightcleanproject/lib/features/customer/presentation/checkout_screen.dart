import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/exceptions.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:brightcleanproject/features/customer/domain/models/cart_item.dart';
import 'package:brightcleanproject/features/customer/domain/models/order.dart';
import 'package:brightcleanproject/features/customer/data/providers/order_provider.dart';
import '../data/providers/cart_provider.dart';
import '../../../../core/widgets/map_picker_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem>? directItems;
  const CheckoutScreen({super.key, this.directItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String _selectedPaymentMethod = 'cash';
  bool _isLocationVerified = false;
  String? _selectedAddress;

  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedAddress = result['address'] as String;
        _isLocationVerified = true;
      });
    }
  }

  Future<int?> _ensureAddressRegistered() async {
    if (_selectedAddress == null || _selectedAddress!.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.get('user_id')?.toString() ?? 'default_user';
    final lastRegStr =
        prefs.getString('last_registered_address_string_$userId');
    int? addressId = prefs.getInt('last_registered_address_id_$userId');

    if (lastRegStr != _selectedAddress || addressId == null) {
      String area = _selectedAddress!;
      String street = _selectedAddress!;
      final commaSplit = area.split(',');
      if (commaSplit.length >= 2) {
        area = commaSplit[0].trim();
        street = commaSplit.sublist(1).join(',').trim();
      }

      // Propagate errors to caller - do not swallow
      final response = await _apiClient.post('/api/addresses', body: {
        'area': area,
        'street': street,
        'latitude': 0.0,
        'longitude': 0.0,
      });

      if (response != null && response is Map<String, dynamic>) {
        addressId = response['addressID'] as int?;
        if (addressId != null) {
          await prefs.setInt('last_registered_address_id_$userId', addressId);
          await prefs.setString(
              'last_registered_address_string_$userId', _selectedAddress!);
        }
      }
    }
    return addressId;
  }

  final TextEditingController _locationDescriptionController =
      TextEditingController();

  final BaseApiClient _apiClient = BaseApiClient();
  List<Map<String, dynamic>> _agents = [];
  int? _selectedAgentId;
  bool _isLoadingAgents = false;
  double _apiDiscountAmount = 0.0;

  Map<String, dynamic>? _appliedCoupon;
  final TextEditingController _couponController = TextEditingController();
  String? _couponErrorMessage;
  bool _isCouponApplied = false;
  bool _couponEnteredButConditionNotMet = false;

  Future<void> _loadAgents() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAgents = true;
    });
    try {
      final response = await _apiClient.get('/api/users/agents');
      if (response is List) {
        if (!mounted) return;
        setState(() {
          _agents = response
              .map((a) => {
                    'id': a['id'] as int,
                    'businessName': a['businessName'] as String,
                  })
              .toList();

          // Do not pre-select an agent - let user explicitly choose
          _isLoadingAgents = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoadingAgents = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAgents = false;
      });
      debugPrint('Error fetching agents: $e');
    }
  }

  Future<void> _applyCouponCode() async {
    final code = _couponController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _couponErrorMessage = 'الرجاء إدخال كود الكوبون';
        _appliedCoupon = null;
        _isCouponApplied = false;
        _couponEnteredButConditionNotMet = false;
      });
      return;
    }

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    var bookingId = orderProvider.currentBookingId;

    // Direct checkout flow: if bookingId is null, we must create a draft booking on the fly
    if (bookingId == null) {
      if (widget.directItems != null && widget.directItems!.isNotEmpty) {
        // Validate that an agent is selected
        if (_selectedAgentId == null) {
          setState(() {
            _couponErrorMessage = 'يرجى اختيار مغسلة (وكيل) أولاً';
            _appliedCoupon = null;
            _isCouponApplied = false;
            _couponEnteredButConditionNotMet = false;
          });
          return;
        }

        // Show progress indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        try {
          final itemsDto = widget.directItems!.map((item) {
            return {
              'serviceID': item.serviceId,
              'quantity': item.quantity,
            };
          }).toList();

          final addressId = await _ensureAddressRegistered();
          bookingId = await orderProvider
              .createBooking(_selectedAgentId!, itemsDto, addressID: addressId);
          if (mounted) {
            Navigator.of(context).pop(); // pop progress dialog
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context).pop(); // pop progress dialog
          }
          setState(() {
            _couponErrorMessage = 'فشل إنشاء الحجز لتطبيق الكوبون: $e';
            _appliedCoupon = null;
            _isCouponApplied = false;
            _couponEnteredButConditionNotMet = false;
          });
          return;
        }
      } else {
        setState(() {
          _couponErrorMessage = 'لا يوجد حجز نشط لتطبيق الكوبون عليه.';
          _appliedCoupon = null;
          _isCouponApplied = false;
          _couponEnteredButConditionNotMet = false;
        });
        return;
      }
    }

    setState(() {
      _couponErrorMessage = null;
    });

    try {
      final result = await _apiClient.post(
        '/api/offers/validate',
        body: {
          'code': code,
          'bookingId': bookingId,
        },
      );

      if (result != null && result['isValid'] == true) {
        setState(() {
          _isCouponApplied = true;
          _apiDiscountAmount = (result['discountAmount'] as num).toDouble();
          _appliedCoupon = {
            'code': code,
            'title': result['displayText'] ?? 'خصم الكوبون',
            'discount': result['displayText'] ?? 'خصم الكوبون',
            'displayDiscount': result['displayText'] ?? 'خصم الكوبون',
          };
          _couponErrorMessage = null;
          _couponEnteredButConditionNotMet = false;
        });
      } else {
        setState(() {
          _couponErrorMessage = 'كود الكوبون غير صحيح أو منتهي الصلاحية';
          _appliedCoupon = null;
          _isCouponApplied = false;
          _couponEnteredButConditionNotMet = false;
        });
      }
    } on ServerException catch (e) {
      setState(() {
        _couponErrorMessage = e.message ?? 'فشل التحقق من الكوبون';
        _appliedCoupon = null;
        _isCouponApplied = false;
        _couponEnteredButConditionNotMet = false;
      });
    } catch (e) {
      setState(() {
        _couponErrorMessage = 'حدث خطأ غير متوقع: $e';
        _appliedCoupon = null;
        _isCouponApplied = false;
        _couponEnteredButConditionNotMet = false;
      });
    }
  }

  Future<void> _removeCoupon() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final bookingId = orderProvider.currentBookingId;
    if (bookingId != null) {
      try {
        await _apiClient.post(
          '/api/offers/remove',
          body: {
            'bookingId': bookingId,
          },
        );
      } catch (e) {
        debugPrint('Error removing coupon from backend: $e');
      }
    }
    setState(() {
      _couponController.clear();
      _appliedCoupon = null;
      _isCouponApplied = false;
      _apiDiscountAmount = 0.0;
      _couponErrorMessage = null;
      _couponEnteredButConditionNotMet = false;
    });
  }

  double _calculateDiscount(double totalAmount) {
    if (!_isCouponApplied) {
      return 0.0;
    }
    return _apiDiscountAmount;
  }

  double _calculateFinalPrice(double totalAmount) {
    final discountAmount = _calculateDiscount(totalAmount);
    final finalPrice = totalAmount - discountAmount;
    return finalPrice < 0 ? 0.0 : finalPrice;
  }

  @override
  void dispose() {
    _locationDescriptionController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _loadLocationData();
    if (widget.directItems != null) {
      _loadAgents();
    }
  }

  Future<void> _loadLocationData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final userId = prefs.get('user_id')?.toString() ?? 'default_user';
    String? savedAddress = prefs.getString('current_cart_address_$userId');
    if (savedAddress == null || savedAddress.isEmpty) {
      savedAddress = prefs.getString('user_registration_address_$userId');
    }
    if (!mounted) return;

    if (savedAddress != null && savedAddress.isNotEmpty) {
      setState(() {
        _selectedAddress = savedAddress;
        _isLocationVerified = true;
      });
    }
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('ar');
  }

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildPaymentOption(
      BuildContext context, String title, String value, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: AppRadius.button,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ listen:false — يمنع CheckoutScreen من إعادة البناء عند أي تغيير في CartProvider
    // الكارت يُقرأ مرة واحدة عند بناء الصفحة فقط، وليس عند كل notifyListeners()
    // هذا هو السبب الجذري لـ RenderBox crash: CartProvider.notifyListeners() كان
    // يُعيد بناء CheckoutScreen أثناء الـ navigation إلى /order_success
    final cart = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final itemsToCheckout =
        widget.directItems != null ? widget.directItems! : cart.items;

    final totalAmount = widget.directItems != null
        ? widget.directItems!
            .fold<double>(0.0, (sum, item) => sum + item.totalPrice)
        : cart.totalAmount;
    final discountAmount = _calculateDiscount(totalAmount);
    final finalPrice = _calculateFinalPrice(totalAmount);

    final canCompleteOrder = _isLocationVerified &&
        _selectedDate != null &&
        _selectedTimeSlot != null &&
        itemsToCheckout.isNotEmpty &&
        (widget.directItems == null || _selectedAgentId != null);

    return Scaffold(
      appBar: AppBar(title: const Text('إتمام الطلب')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(
            'ملخص الطلب',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...itemsToCheckout.map((item) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                decoration: AppStyles.surface(context),
                child: ListTile(
                  title: Text('${item.serviceName} (${item.selectedType})',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text('الكمية: ${item.quantity}',
                      style: theme.textTheme.bodyMedium),
                  trailing: Text('${item.totalPrice.toStringAsFixed(0)} ر.ي',
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary)),
                ),
              )),
          if (widget.directItems != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              'اختر مغسلة (الوكيل)',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_isLoadingAgents)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ))
            else if (_agents.isEmpty)
              const Text('لا يوجد وكلاء متوفرين حالياً',
                  style: TextStyle(color: Colors.grey))
            else
              DropdownButtonFormField<int>(
                initialValue: _selectedAgentId,
                hint: const Text('اختر المغسلة'),
                items: _agents.map((agent) {
                  return DropdownMenuItem<int>(
                    value: agent['id'] as int,
                    child: Text(agent['businessName'] as String),
                  );
                }).toList(),
                onChanged: orderProvider.currentBookingId != null
                    ? null // Disable dropdown if booking already created
                    : (val) {
                        setState(() {
                          _selectedAgentId = val;
                        });
                      },
                disabledHint: _selectedAgentId != null
                    ? Text(
                        _agents.firstWhere(
                          (agent) => agent['id'] == _selectedAgentId,
                          orElse: () => {'businessName': 'مغسلة محددة'},
                        )['businessName'] as String,
                      )
                    : const Text('اختر المغسلة'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: AppRadius.button),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'موقع التوصيل',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_isLocationVerified)
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'تم التحقق',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadius.card,
              border: Border.all(
                color: _isLocationVerified
                    ? AppColors.success
                    : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: AppShadows.getSm(context),
            ),
            child: ListTile(
              leading: Icon(
                Icons.location_on,
                color: _isLocationVerified
                    ? AppColors.success
                    : theme.colorScheme.primary,
              ),
              title: Text(_isLocationVerified ? 'الموقع المحدد' : 'الموقع',
                  style: theme.textTheme.titleMedium),
              subtitle: Text(
                  _selectedAddress ?? 'اضغط لتحديد العنوان على الخريطة',
                  style: theme.textTheme.bodyMedium),
              trailing: TextButton(
                onPressed: _selectLocation,
                child: Text(_isLocationVerified ? 'تغيير' : 'تحديد الموقع'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'وصف الموقع (اختياري)',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _locationDescriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'مثلاً: بجوار صيدلية النور، رقم الدور...',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              border: OutlineInputBorder(
                borderRadius: AppRadius.button,
                borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
              ),
              filled: true,
              fillColor: isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'موعد الاستلام',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: AppRadius.button,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedDate == null
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                            : theme.colorScheme.primary,
                      ),
                      borderRadius: AppRadius.button,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: _selectedDate == null
                              ? theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5)
                              : theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _selectedDate == null
                              ? 'اختر التاريخ'
                              : DateFormat('yyyy/MM/dd').format(_selectedDate!),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _selectedDate == null
                                ? theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7)
                                : theme.colorScheme.primary,
                            fontWeight: _selectedDate == null
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 14,
                    ),
                    hintText: 'اختر الوقت',
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.button,
                    ),
                  ),
                  initialValue: _selectedTimeSlot,
                  items: const [
                    DropdownMenuItem(
                      value: 'morning',
                      child: Text('09:00 - 12:00'),
                    ),
                    DropdownMenuItem(
                      value: 'afternoon',
                      child: Text('12:00 - 15:00'),
                    ),
                    DropdownMenuItem(
                      value: 'evening',
                      child: Text('15:00 - 18:00'),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _selectedTimeSlot = v;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'طريقة الدفع',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildPaymentOption(context, 'الدفع كاش', 'cash', Icons.money),
          _buildPaymentOption(context, 'تحويل لحساب بنكي', 'bank_transfer',
              Icons.account_balance),
          _buildPaymentOption(context, 'الدفع عبر المحفظة', 'wallet',
              Icons.account_balance_wallet),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'كوبون الخصم',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: AppStyles.surface(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        decoration: InputDecoration(
                          hintText: 'أدخل كود الخصم (مثال: WELCOME30)',
                          hintStyle: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5)),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.sm,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.button,
                            borderSide: BorderSide(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: AppRadius.button,
                            borderSide:
                                BorderSide(color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    ElevatedButton(
                      onPressed: _applyCouponCode,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(72, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      child: const Text('تطبيق'),
                    ),
                  ],
                ),
                if (_couponErrorMessage != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _couponErrorMessage!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (_isCouponApplied && _appliedCoupon != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'تم تطبيق الكوبون بنجاح: ${_appliedCoupon!['title']} (${_appliedCoupon!['displayDiscount'] ?? _appliedCoupon!['discount']})',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _removeCoupon,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                        ),
                        child: Text(
                          'إلغاء',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_couponEnteredButConditionNotMet &&
                    _appliedCoupon != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: AppRadius.button,
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.warning,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'الشرط غير مستوفٍ',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _removeCoupon,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                              ),
                              child: Text(
                                'إلغاء',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'هذا العرض يتطلب طلباً بقيمة أعلى من ${_appliedCoupon!['minAmount']} ريال لتفعيل الخصم. المبلغ الحالي هو ${totalAmount.toStringAsFixed(0)} ر.ي (لم يتم تطبيق الخصم).',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المجموع الكلي:',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_isCouponApplied && _appliedCoupon != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${totalAmount.toStringAsFixed(0)} ر.ي',
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      '${finalPrice.toStringAsFixed(0)} ر.ي',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      'وفرت ${discountAmount.toStringAsFixed(0)} ر.ي',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  '${totalAmount.toStringAsFixed(0)} ر.ي',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: _CheckoutBottomBar(
        canCompleteOrder: canCompleteOrder,
        finalPrice: finalPrice,
        itemsToCheckout: itemsToCheckout,
        selectedPaymentMethod: _selectedPaymentMethod,
        selectedDate: _selectedDate,
        selectedTimeSlot: _selectedTimeSlot,
        locationDescription: _locationDescriptionController.text,
        selectedAgentId: _selectedAgentId,
        directItems: widget.directItems,
        apiClient: _apiClient,
        ensureAddressRegistered: _ensureAddressRegistered,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Extracted StatefulWidget for the bottom bar — owns its own
// BuildContext so it is NEVER affected by CheckoutScreen rebuilds.
// ──────────────────────────────────────────────────────────────
class _CheckoutBottomBar extends StatefulWidget {
  final bool canCompleteOrder;
  final double finalPrice;
  final List<CartItem> itemsToCheckout;
  final String selectedPaymentMethod;
  final DateTime? selectedDate;
  final String? selectedTimeSlot;
  final String locationDescription;
  final int? selectedAgentId;
  final List<CartItem>? directItems;
  final BaseApiClient apiClient;
  final Future<int?> Function() ensureAddressRegistered;

  const _CheckoutBottomBar({
    required this.canCompleteOrder,
    required this.finalPrice,
    required this.itemsToCheckout,
    required this.selectedPaymentMethod,
    required this.selectedDate,
    required this.selectedTimeSlot,
    required this.locationDescription,
    required this.selectedAgentId,
    required this.directItems,
    required this.apiClient,
    required this.ensureAddressRegistered,
  });

  @override
  State<_CheckoutBottomBar> createState() => _CheckoutBottomBarState();
}

class _CheckoutBottomBarState extends State<_CheckoutBottomBar> {
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    var completedSuccessfully = false;

    // Capture all values synchronously before any await
    final capturedFinalPrice = widget.finalPrice;
    final capturedPaymentMethod = widget.selectedPaymentMethod;
    final orderDetails = widget.itemsToCheckout
        .map((i) => '${i.serviceName} (${i.selectedType})')
        .join(', ');

    final newOrder = Order(
      orderId: const Uuid().v4(),
      date: DateFormat('dd MMMM yyyy', 'ar').format(DateTime.now()),
      details: orderDetails,
      status: 'قيد الانتظار',
      activeStepIndex: 0,
      locationDescription: widget.locationDescription,
      paymentMethod: capturedPaymentMethod,
      pickupDate: widget.selectedDate,
      pickupTimeSlot: widget.selectedTimeSlot,
    );

    setState(() => _isSubmitting = true);

    try {
      var bookingId = orderProvider.currentBookingId;

      if (bookingId == null) {
        if (widget.directItems != null && widget.directItems!.isNotEmpty) {
          if (widget.selectedAgentId == null) {
            throw Exception('يرجى اختيار مغسلة (وكيل) أولاً');
          }
          final itemsDto = widget.directItems!
              .map((item) =>
                  {'serviceID': item.serviceId, 'quantity': item.quantity})
              .toList();
          final addressId = await widget.ensureAddressRegistered();
          bookingId = await orderProvider.createBooking(
            widget.selectedAgentId!,
            itemsDto,
            addressID: addressId,
            scheduledAt: widget.selectedDate,
            specialInstructions: widget.selectedTimeSlot,
            notifyOnStateChange: false,
          );
        } else {
          throw Exception('لا يوجد حجز نشط. يرجى إعادة المحاولة.');
        }
      }

      final serverFinalTotal = await orderProvider.submitOrder(
        bookingId,
        scheduledAt: widget.selectedDate,
        specialInstructions: widget.selectedTimeSlot,
        notifyOnStateChange: false,
      );
      final paymentAmount = serverFinalTotal ?? capturedFinalPrice;

      final methodMap = {
        'cash': 'Cash',
        'bank_transfer': 'BankTransfer',
        'wallet': 'Wallet'
      };
      await widget.apiClient.post('/api/payments', body: {
        'bookingID': bookingId,
        'amount': paymentAmount,
        'method': methodMap[capturedPaymentMethod] ?? 'Cash',
        'transactionRef': null,
      });

      await orderProvider.completeCheckoutAfterPayment(
        newOrder,
        notifyOnStateChange: false,
      );

      // Navigate AFTER all async work is done — this widget is still alive
      completedSuccessfully = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.go('/order_success');
      });
    } catch (e) {
      debugPrint('❌ Checkout error: $e');
      final errorText = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('ServerException: ', '');
      if (mounted) {
        messenger.clearSnackBars();
        messenger.showSnackBar(SnackBar(
          content: Text('فشل تأكيد الطلب: $errorText'),
          backgroundColor: errorColor,
          duration: const Duration(seconds: 6),
          showCloseIcon: true,
        ));
      }
    } finally {
      if (!completedSuccessfully && mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.canCompleteOrder
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final foregroundColor = widget.canCompleteOrder
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;

    void showValidationMessage() {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
          'الرجاء التحقق من الموقع واختيار موعد الاستلام لتأكيد الطلب',
        ),
        backgroundColor: theme.colorScheme.error,
      ));
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: AppShadows.getMd(context),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: Semantics(
            button: true,
            enabled: !_isSubmitting,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isSubmitting
                  ? null
                  : widget.canCompleteOrder
                      ? _submit
                      : showValidationMessage,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: AppRadius.button,
                ),
                child: Center(
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: foregroundColor,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'جاري معالجة الطلب...',
                              style: TextStyle(
                                color: foregroundColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'إتمام الطلب (${widget.finalPrice.toStringAsFixed(0)} ر.ي)',
                          style: TextStyle(
                            color: foregroundColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
