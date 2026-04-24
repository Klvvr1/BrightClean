import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:brightcleanprojet/core/enums/order_status.dart';
import 'package:brightcleanprojet/core/theme/app_colors.dart';
import 'package:brightcleanprojet/core/localization/language_controller.dart';
import 'package:brightcleanprojet/features/agent/presentation/widgets/agent_app_bar_actions.dart';

class AgentOrderManagementScreen extends StatefulWidget {
  final String orderId;
  final OrderStatus initialStatus;
  final bool isReadOnly;

  const AgentOrderManagementScreen({
    super.key, 
    required this.orderId,
    required this.initialStatus,
    this.isReadOnly = false,
  });

  @override
  State<AgentOrderManagementScreen> createState() =>
      _AgentOrderManagementScreenState();
}

// نموذج بيانات للعنصر في الطلب
class OrderItemMock {
  final String itemName;
  final String serviceType;
  final int quantity;
  final IconData icon;

  OrderItemMock(this.itemName, this.serviceType, this.quantity, this.icon);
}

class _AgentOrderManagementScreenState extends State<AgentOrderManagementScreen> {
  late OrderStatus _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
  }

  // عناصر وهمية للطلب
  final List<OrderItemMock> _items = [
    OrderItemMock('ثوب', 'كوي', 5, Icons.iron),
    OrderItemMock('تيشيرت', 'غسيل', 3, Icons.local_laundry_service),
    OrderItemMock('شماغ', 'غسيل وكوي', 2, Icons.dry_cleaning),
  ];

  String _translateItem(String item) {
    final Map<String, String> translations = {
      'ثوب': 'Thoob',
      'تيشيرت': 'T-shirt',
      'شماغ': 'Shemagh',
    };
    return translations[item] ?? item;
  }

  String _translateService(String service) {
    final Map<String, String> translations = {
      'غسيل': 'Wash',
      'كوي': 'Iron',
      'غسيل وكوي': 'Wash & Iron',
      'تنظيف جاف': 'Dry Clean',
    };
    return translations[service] ?? service;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final langController = LanguageController();

    return ValueListenableBuilder<Locale>(
      valueListenable: langController.locale,
      builder: (context, locale, _) {
        final isArabic = locale.languageCode == 'ar';

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : AppColors.background,
          appBar: AppBar(
            title: Text(isArabic ? 'إدارة الطلب #${widget.orderId}' : 'Manage Order #${widget.orderId}'),
            elevation: 0,
            actions: const [
              AgentAppBarActions(),
            ],
          ),
          body: Column(
            children: [
              // Premium Header / Status Banner
              if (widget.isReadOnly)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.success.withValues(alpha: 0.8), AppColors.success],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        isArabic ? 'هذا الطلب مكتمل ولا يمكن تعديله' : 'This order is finalized and cannot be modified',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionHeader(isArabic ? 'تفاصيل الطلب' : 'Order Details', theme),
                      const SizedBox(height: 16),
                      
                      // Modern Order Card
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          children: [
                            // Card Header with Gradient
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark 
                                      ? [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.01)]
                                      : [AppColors.primary.withValues(alpha: 0.05), Colors.transparent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24, 
                                    backgroundColor: isDark ? AppColors.lightBlue.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.1), 
                                    child: Icon(Icons.person_rounded, size: 24, color: isDark ? AppColors.lightBlue : AppColors.primary)
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(isArabic ? 'أحمد محمد' : 'Ahmed Mohamed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                        Text(isArabic ? 'عميل بريميوم' : 'Premium Customer', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600, letterSpacing: 0.5)),
                                      ],
                                    ),
                                  ),
                                  _buildStatusBadge(_currentStatus, isArabic),
                                ],
                              ),
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.inventory_2_outlined, size: 16, color: isDark ? AppColors.lightBlue : AppColors.primary),
                                      const SizedBox(width: 8),
                                      Text(isArabic ? 'محتويات الطلب' : 'Order Contents', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ..._items.map((item) => _buildItemRow(item, isArabic, isDark)),
                                  
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Divider(height: 1, thickness: 1),
                                  ),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(isArabic ? 'الإجمالي المتوقع' : 'Estimated Total', style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontWeight: FontWeight.w500)),
                                      Text(
                                        isArabic ? '100 درهم' : '100 AED', 
                                        style: TextStyle(
                                          color: isDark ? AppColors.lightBlue : AppColors.primary, 
                                          fontWeight: FontWeight.w900, 
                                          fontSize: 22,
                                          letterSpacing: -0.5,
                                        )
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      if (!widget.isReadOnly) ...[
                        _buildSectionHeader(isArabic ? 'تحديث حالة الطلب' : 'Update Order Status', theme),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: OrderStatus.values.map((status) {
                            final isSelected = _currentStatus == status;
                            return _buildStatusChip(status, isSelected, isArabic, isDark);
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Bottom Action Area
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
                  ],
                ),
                child: widget.isReadOnly 
                  ? OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(isArabic ? 'العودة للخلف' : 'Go Back', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isArabic ? 'تم تحديث حالة الطلب بنجاح' : 'Order status updated successfully'), 
                            backgroundColor: AppColors.success, 
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                        context.pop(_currentStatus);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      ),
                      child: Text(isArabic ? 'تأكيد وحفظ التغييرات' : 'Confirm & Save Changes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildStatusBadge(OrderStatus status, bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: status.color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        isArabic ? status.title : status.englishTitle,
        style: TextStyle(color: status.color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildItemRow(OrderItemMock item, bool isArabic, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)),
            ),
            child: Icon(item.icon, color: isDark ? AppColors.lightBlue : AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isArabic ? item.itemName : _translateItem(item.itemName), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(isArabic ? item.serviceType : _translateService(item.serviceType), style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.primary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${item.quantity} ${isArabic ? 'قطع' : 'pcs'}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status, bool isSelected, bool isArabic, bool isDark) {
    return InkWell(
      onTap: () => setState(() => _currentStatus = status),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? status.color : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : Colors.grey.shade200),
            width: 1.5,
          ),
          boxShadow: isSelected 
              ? [BoxShadow(color: status.color.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Text(
          isArabic ? status.title : status.englishTitle,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
