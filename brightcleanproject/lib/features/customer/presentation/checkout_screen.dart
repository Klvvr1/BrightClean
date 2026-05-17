import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'order_success_screen.dart';
import 'package:brightcleanproject/features/customer/domain/models/cart_item.dart';
import 'package:brightcleanproject/features/customer/domain/models/order.dart';
import 'package:brightcleanproject/features/customer/data/providers/order_provider.dart';
import 'package:brightcleanproject/features/admin/presentation/admin_dashboard_screen.dart';
import '../data/providers/cart_provider.dart';

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

  final TextEditingController _locationDescriptionController =
      TextEditingController();

  Map<String, dynamic>? _appliedCoupon;
  final TextEditingController _couponController = TextEditingController();
  String? _couponErrorMessage;
  bool _isCouponApplied = false;
  bool _couponEnteredButConditionNotMet = false;

  void _applyCouponCode() {
    final cart = Provider.of<CartProvider>(context, listen: false);
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

    final matchingCoupons = AdminDashboardScreen.couponsList.where(
      (c) {
        // Check if code matches
        if (c['code'].toString().toLowerCase() != code.toLowerCase()) {
          return false;
        }

        // Check if coupon is active
        if (c['status'] != null && c['status'] != 'نشط') {
          return false;
        }

        // Check expiry date
        final endDateStr = c['endDate'];
        if (endDateStr != null && endDateStr != 'غير محدد') {
          try {
            // Parse date in format YYYY/MM/DD
            final parts = endDateStr.toString().split('/');
            if (parts.length == 3) {
              final year = int.tryParse(parts[0]);
              final month = int.tryParse(parts[1]);
              final day = int.tryParse(parts[2]);
              if (year != null && month != null && day != null) {
                final expiryDate = DateTime(year, month, day, 23, 59, 59);
                if (DateTime.now().isAfter(expiryDate)) {
                  return false;
                }
              }
            }
          } catch (e) {
            // If parsing fails, treat coupon as invalid
            return false;
          }
        }

        return true;
      },
    ).toList();

    if (matchingCoupons.isEmpty) {
      setState(() {
        _couponErrorMessage = 'كود الكوبون غير صحيح أو منتهي الصلاحية';
        _appliedCoupon = null;
        _isCouponApplied = false;
        _couponEnteredButConditionNotMet = false;
      });
      return;
    }

    final coupon = matchingCoupons.first;
    final minAmountStr = coupon['minAmount'];

    double minAmount = 0.0;
    if (minAmountStr != null && minAmountStr.toString().isNotEmpty) {
      minAmount = double.tryParse(minAmountStr.toString()) ?? 0.0;
    }

    // Compute the total amount for the items being checked out
    final itemsToCheckout = widget.directItems != null ? widget.directItems! : cart.items;
    final totalAmount = widget.directItems != null
        ? widget.directItems!.fold<double>(0.0, (sum, item) => sum + item.totalPrice)
        : cart.totalAmount;

    setState(() {
      _appliedCoupon = coupon;
      _couponErrorMessage = null;

      if (totalAmount >= minAmount) {
        _isCouponApplied = true;
        _couponEnteredButConditionNotMet = false;
      } else {
        _isCouponApplied = false;
        _couponEnteredButConditionNotMet = true;
      }
    });
  }

  void _removeCoupon() {
    setState(() {
      _couponController.clear();
      _appliedCoupon = null;
      _isCouponApplied = false;
      _couponErrorMessage = null;
      _couponEnteredButConditionNotMet = false;
    });
  }

  double _calculateDiscount(double totalAmount) {
    if (!_isCouponApplied || _appliedCoupon == null) {
      return 0.0;
    }

    final discountStr = _appliedCoupon!['discount'].toString();

    if (discountStr.endsWith('%')) {
      final pct =
          double.tryParse(discountStr.replaceAll('%', '').trim()) ?? 0.0;
      return totalAmount * (pct / 100);
    }

    return double.tryParse(discountStr) ?? 0.0;
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

  Widget _buildPaymentOption(String title, String value, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textMain,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final itemsToCheckout = widget.directItems != null ? widget.directItems! : cart.items;

    final totalAmount = widget.directItems != null
        ? widget.directItems!.fold<double>(0.0, (sum, item) => sum + item.totalPrice)
        : cart.totalAmount;
    final discountAmount = _calculateDiscount(totalAmount);
    final finalPrice = _calculateFinalPrice(totalAmount);

    final canCompleteOrder = _isLocationVerified &&
        _selectedDate != null &&
        _selectedTimeSlot != null &&
        itemsToCheckout.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('إتمام الطلب')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملخص الطلب',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...itemsToCheckout.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: ListTile(
                    title: Text('${item.serviceName} (${item.selectedType})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('الكمية: ${item.quantity}'),
                    trailing: Text('${item.totalPrice.toStringAsFixed(0)} ر.ي',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ),
                )),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'موقع التوصيل',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_isLocationVerified)
                  const Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppColors.success, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'تم التحقق',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 8),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _isLocationVerified
                      ? AppColors.success
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              elevation: 2,
              child: ListTile(
                leading: Icon(
                  Icons.location_on,
                  color:
                      _isLocationVerified ? AppColors.success : AppColors.primary,
                ),
                title: const Text('المنزل'),
                subtitle: const Text('شارع الزبيري، صنعاء'),
                trailing: TextButton(
                  onPressed: () {
                    setState(() {
                      _isLocationVerified = true;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم التحقق من الموقع بنجاح'),
                      ),
                    );
                  },
                  child: Text(_isLocationVerified ? 'تغيير' : 'تأكيد الموقع'),
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'وصف الموقع (اختياري)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _locationDescriptionController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText:
                    'مثلاً: بجوار صيدلية النور، رقم الدور، أو أي علامة مميزة...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'موعد الاستلام',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedDate == null
                              ? Colors.grey.shade400
                              : AppColors.primary,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: _selectedDate == null
                                ? Colors.grey
                                : AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedDate == null
                                ? 'اختر التاريخ'
                                : DateFormat('yyyy/MM/dd')
                                    .format(_selectedDate!),
                            style: TextStyle(
                              color: _selectedDate == null
                                  ? Colors.grey.shade700
                                  : AppColors.primary,
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
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      hintText: 'اختر الوقت',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
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

            const SizedBox(height: 24),

            const Text(
              'طريقة الدفع',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            _buildPaymentOption('الدفع كاش', 'cash', Icons.money),
            _buildPaymentOption(
              'تحويل لحساب بنكي',
              'bank_transfer',
              Icons.account_balance,
            ),
            _buildPaymentOption(
              'الدفع عبر المحفظة',
              'wallet',
              Icons.account_balance_wallet,
            ),

            const SizedBox(height: 24),

            const Text(
              'كوبون الخصم',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
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
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _applyCouponCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'تطبيق',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_couponErrorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _couponErrorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],

                  if (_isCouponApplied && _appliedCoupon != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'تم تطبيق الكوبون بنجاح: ${_appliedCoupon!['title']} (${_appliedCoupon!['discount']})',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
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
                          child: const Text(
                            'إلغاء',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (_couponEnteredButConditionNotMet &&
                      _appliedCoupon != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
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
                              const SizedBox(width: 8),
                              const Text(
                                'الشرط غير مستوفٍ',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 12,
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
                                child: const Text(
                                  'إلغاء',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'هذا العرض يتطلب طلباً بقيمة أعلى من ${_appliedCoupon!['minAmount']} ريال لتفعيل الخصم. المبلغ الحالي هو ${totalAmount.toStringAsFixed(0)} ر.ي (لم يتم تطبيق الخصم).',
                            style: const TextStyle(
                              color: AppColors.textMain,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المجموع الكلي:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (_isCouponApplied && _appliedCoupon != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${totalAmount.toStringAsFixed(0)} ر.ي',
                        style: const TextStyle(
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${finalPrice.toStringAsFixed(0)} ر.ي',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        'وفرت ${discountAmount.toStringAsFixed(0)} ر.ي',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    '${totalAmount.toStringAsFixed(0)} ر.ي',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canCompleteOrder
                  ? () {
                      // Create details string for the order
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

                      Provider.of<OrderProvider>(context, listen: false)
                          .addOrder(newOrder);

                      // Clear cart only if this is a cart-based checkout
                      if (widget.directItems == null) {
                        cart.clearCart();
                      }

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrderSuccessScreen(),
                        ),
                      );
                    }
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'الرجاء التحقق من الموقع واختيار موعد الاستلام لتأكيد الطلب',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canCompleteOrder ? AppColors.primary : Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'تأكيد الطلب',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}