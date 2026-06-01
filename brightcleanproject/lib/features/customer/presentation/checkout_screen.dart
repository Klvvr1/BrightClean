import 'package:flutter/material.dart';
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
import 'order_success_screen.dart';
import 'package:brightcleanproject/features/customer/domain/models/cart_item.dart';
import 'package:brightcleanproject/features/customer/domain/models/order.dart';
import 'package:brightcleanproject/features/customer/data/providers/order_provider.dart';
import '../data/providers/cart_provider.dart';
import '../../../../core/widgets/map_picker_screen.dart';

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
          _agents = response.map((a) => {
            'id': a['id'] as int,
            'businessName': a['businessName'] as String,
          }).toList();

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

          bookingId = await orderProvider.createBooking(_selectedAgentId!, itemsDto);
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
    if (widget.directItems != null) {
      _loadAgents();
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

  Widget _buildPaymentOption(BuildContext context, String title, String value, IconData icon) {
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
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: AppRadius.button,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
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
    final cart = Provider.of<CartProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final itemsToCheckout = widget.directItems != null ? widget.directItems! : cart.items;

    final totalAmount = widget.directItems != null
        ? widget.directItems!.fold<double>(0.0, (sum, item) => sum + item.totalPrice)
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ملخص الطلب',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...itemsToCheckout.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  decoration: AppStyles.surface(context),
                  child: ListTile(
                    title: Text('${item.serviceName} (${item.selectedType})',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    subtitle: Text('الكمية: ${item.quantity}', style: theme.textTheme.bodyMedium),
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
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_isLoadingAgents)
                const Center(child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ))
              else if (_agents.isEmpty)
                const Text('لا يوجد وكلاء متوفرين حالياً', style: TextStyle(color: Colors.grey))
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
                      ? null  // Disable dropdown if booking already created
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  ),
                ),
            ],

            const SizedBox(height: AppSpacing.xl),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'موقع التوصيل',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_isLocationVerified)
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 16),
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
                  color: _isLocationVerified ? AppColors.success : theme.colorScheme.primary,
                ),
                title: Text(_isLocationVerified ? 'الموقع المحدد' : 'الموقع', style: theme.textTheme.titleMedium),
                subtitle: Text(_selectedAddress ?? 'اضغط لتحديد العنوان على الخريطة', style: theme.textTheme.bodyMedium),
                trailing: TextButton(
                  onPressed: _selectLocation,
                  child: Text(_isLocationVerified ? 'تغيير' : 'تحديد الموقع'),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            Text(
              'وصف الموقع (اختياري)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),

            TextField(
              controller: _locationDescriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'مثلاً: بجوار صيدلية النور، رقم الدور...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.button,
                  borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                ),
                filled: true,
                fillColor: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              'موعد الاستلام',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                                ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                                : theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            _selectedDate == null
                                ? 'اختر التاريخ'
                                : DateFormat('yyyy/MM/dd')
                                    .format(_selectedDate!),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _selectedDate == null
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
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
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),

            _buildPaymentOption(context, 'الدفع كاش', 'cash', Icons.money),
            _buildPaymentOption(context, 'تحويل لحساب بنكي', 'bank_transfer', Icons.account_balance),
            _buildPaymentOption(context, 'الدفع عبر المحفظة', 'wallet', Icons.account_balance_wallet),

            const SizedBox(height: AppSpacing.xl),

            Text(
              'كوبون الخصم',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                            hintStyle: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.button,
                              borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppRadius.button,
                              borderSide: BorderSide(color: theme.colorScheme.primary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      ElevatedButton(
                        onPressed: _applyCouponCode,
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
                            style: theme.textTheme.labelSmall?.copyWith(color: AppColors.error),
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
                                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.error),
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
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_isCouponApplied && _appliedCoupon != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${totalAmount.toStringAsFixed(0)} ر.ي',
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
      ),
      bottomSheet: Consumer<OrderProvider>(
        builder: (orderContext, orderProvider, child) {
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
                child: ElevatedButton(
                  onPressed: (canCompleteOrder && !orderProvider.isCheckoutLoading)
                      ? () async {
                          final navigator = Navigator.of(context);
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          final orderDetails = itemsToCheckout
                              .map((i) => '${i.serviceName} (${i.selectedType})')
                              .join(', ');

                          final newOrder = Order(
                            orderId: const Uuid().v4(),
                            date: DateFormat('dd MMMM yyyy', 'ar')
                                .format(DateTime.now()),
                            details: orderDetails,
                            status: 'قيد الانتظار',
                            activeStepIndex: 0,
                            locationDescription:
                                _locationDescriptionController.text,
                            paymentMethod: _selectedPaymentMethod,
                            pickupDate: _selectedDate,
                            pickupTimeSlot: _selectedTimeSlot,
                          );

                           try {
                             // Use the actual booking ID from the order provider's current booking
                             var bookingId = orderProvider.currentBookingId;
                             if (bookingId == null) {
                               if (widget.directItems != null && widget.directItems!.isNotEmpty) {
                                 // Validate that an agent is selected
                                 if (_selectedAgentId == null) {
                                   throw Exception('يرجى اختيار مغسلة (وكيل) أولاً');
                                 }

                                 final itemsDto = widget.directItems!.map((item) {
                                   return {
                                     'serviceID': item.serviceId,
                                     'quantity': item.quantity,
                                   };
                                 }).toList();

                                 bookingId = await orderProvider.createBooking(_selectedAgentId!, itemsDto);
                               } else {
                                 throw Exception('No active booking found');
                               }
                             }
                             await orderProvider.submitOrder(bookingId, localOrder: newOrder);

                             // POST /api/payments after booking submission - MUST succeed before clearing cart
                             // Map local payment method string to API enum string
                             final methodMap = {
                               'cash': 'Cash',
                               'bank_transfer': 'BankTransfer',
                               'wallet': 'Wallet',
                             };
                             final apiMethod = methodMap[_selectedPaymentMethod] ?? 'Cash';

                             await _apiClient.post('/api/payments', body: {
                               'bookingID': bookingId,
                               'amount': finalPrice,
                               'method': apiMethod,
                               'transactionRef': null,
                             });

                             // Only clear cart and navigate after successful payment
                             if (widget.directItems == null) {
                               await cart.clearCart();
                             }

                             navigator.pushReplacement(
                               MaterialPageRoute(
                                 builder: (context) => const OrderSuccessScreen(),
                               ),
                             );
                          } catch (e) {
                            scaffoldMessenger.clearSnackBars();
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('فشل تأكيد الطلب: $e'),
                                backgroundColor: theme.colorScheme.error,
                              ),
                            );
                          }
                        }
                      : (orderProvider.isCheckoutLoading
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'الرجاء التحقق من الموقع واختيار موعد الاستلام لتأكيد الطلب',
                                  ),
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                            }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canCompleteOrder ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: canCompleteOrder ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                  ),
                  child: orderProvider.isCheckoutLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'إتمام الطلب (${finalPrice.toStringAsFixed(0)} ر.ي)',
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}