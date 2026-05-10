import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'order_success_screen.dart';
import 'package:brightcleanprojet/features/customer/domain/models/order.dart';
import 'package:brightcleanprojet/features/customer/data/providers/order_provider.dart';

class CheckoutScreen extends StatefulWidget {
  final String serviceName;
  final String selectedType;
  final int quantity;
  final double totalPrice;

  const CheckoutScreen({
    super.key, 
    this.serviceName = 'غسيل ملابس', 
    this.selectedType = 'غسيل وكي', 
    this.quantity = 5, 
    this.totalPrice = 50.0,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  String _selectedPaymentMethod = 'cash';
  bool _isLocationVerified = false;


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
      firstDate: DateTime.now(), // Prevent selecting past dates
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
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
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
    final canCompleteOrder = _isLocationVerified && _selectedDate != null && _selectedTimeSlot != null;

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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: ListTile(
                title: Text('${widget.serviceName} (${widget.selectedType})', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('الكمية / عدد القطع: ${widget.quantity}'),
                trailing: Text('${widget.totalPrice.toStringAsFixed(2)} درهم', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
            // Location
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('موقع التوصيل', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (_isLocationVerified)
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 16),
                      SizedBox(width: 4),
                      Text('تم التحقق', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  )
              ],
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _isLocationVerified ? AppColors.success : Colors.transparent,
                  width: 1,
                )
              ),
              elevation: 2,
              child: ListTile(
                leading: Icon(Icons.location_on, color: _isLocationVerified ? AppColors.success : AppColors.primary),
                title: const Text('المنزل'),
                subtitle: const Text('شارع الشيخ زايد، دبي'),
                trailing: TextButton(
                  onPressed: () {
                    setState(() {
                      _isLocationVerified = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم التحقق من الموقع بنجاح')),
                    );
                  },
                  child: Text(_isLocationVerified ? 'تغيير' : 'تأكيد الموقع'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Delivery Date & Time
            const Text('موعد الاستلام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: _selectedDate == null ? Colors.grey.shade400 : AppColors.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: _selectedDate == null ? Colors.grey : AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _selectedDate == null
                                ? 'اختر التاريخ'
                                : DateFormat('yyyy/MM/dd').format(_selectedDate!),
                            style: TextStyle(
                              color: _selectedDate == null ? Colors.grey.shade700 : AppColors.primary,
                              fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.bold,
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      hintText: 'اختر الوقت',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    initialValue: _selectedTimeSlot,
                    items: const [
                      DropdownMenuItem(value: 'morning', child: Text('09:00 - 12:00')),
                      DropdownMenuItem(value: 'afternoon', child: Text('12:00 - 15:00')),
                      DropdownMenuItem(value: 'evening', child: Text('15:00 - 18:00')),
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
            // Payment Method
            const Text('طريقة الدفع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildPaymentOption('الدفع كاش', 'cash', Icons.money),
            _buildPaymentOption('تحويل لحساب بنكي', 'bank_transfer', Icons.account_balance),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('المجموع الكلي:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('${widget.totalPrice.toStringAsFixed(2)} درهم', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 100), // padding for bottom bar
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
                      // Add order to list
                      final newOrder = Order(
                        orderId: const Uuid().v4(),
                        date: DateFormat('dd MMMM yyyy', 'ar').format(DateTime.now()),
                        details: '${widget.serviceName} (${widget.selectedType}) - ${widget.quantity} قطع',
                        status: 'قيد الانتظار',
                        activeStepIndex: 0,
                      );
                      Provider.of<OrderProvider>(context, listen: false).addOrder(newOrder);

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const OrderSuccessScreen()),
                      );
                    }
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('الرجاء التحقق من الموقع واختيار موعد الاستلام لتأكيد الطلب'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: canCompleteOrder ? AppColors.primary : Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('تأكيد الطلب', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}
