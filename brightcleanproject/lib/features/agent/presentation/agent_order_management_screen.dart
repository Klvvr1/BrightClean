import 'package:flutter/material.dart';
import 'package:brightcleanproject/core/theme/app_spacing.dart';

import 'package:go_router/go_router.dart';
import 'package:brightcleanproject/core/enums/order_status.dart';
import 'package:brightcleanproject/core/theme/app_colors.dart';
import 'package:brightcleanproject/core/controllers/language_controller.dart';
import 'package:brightcleanproject/features/agent/presentation/widgets/agent_app_bar_actions.dart';
import 'package:brightcleanproject/features/agent/presentation/agent_dashboard_screen.dart';

class AgentOrderManagementScreen extends StatefulWidget {
  final String orderId;
  final OrderStatus initialStatus;
  final bool isReadOnly;
  final AgentOrderModel order;

  const AgentOrderManagementScreen({
    super.key,
    required this.orderId,
    required this.initialStatus,
    this.isReadOnly = false,
    required this.order,
  });

  @override
  State<AgentOrderManagementScreen> createState() =>
      _AgentOrderManagementScreenState();
}

class _AgentOrderManagementScreenState extends State<AgentOrderManagementScreen> {
  late OrderStatus _currentStatus;
  bool _isLoading = false;
  bool _hasChanges = false;
  final TextEditingController _rejectReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  @override
  void dispose() {
    _rejectReasonController.dispose();
    super.dispose();
  }


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

  Future<bool> _showUnsavedChangesDialog(BuildContext context, bool isArabic) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تغييرات غير محفوظة' : 'Unsaved Changes'),
        content: Text(isArabic ? 'لديك تغييرات لم تقم بحفظها، هل أنت متأكد من رغبتك في الخروج؟' : 'You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isArabic ? 'البقاء' : 'Stay'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isArabic ? 'الخروج بدون حفظ' : 'Leave without saving'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _handleAccept(bool isArabic) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تأكيد قبول الطلب' : 'Confirm Order Acceptance'),
        content: Text(isArabic ? 'هل أنت متأكد من قبول هذا الطلب؟' : 'Are you sure you want to accept this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isArabic ? 'تأكيد القبول' : 'Confirm Accept'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 1)); // Simulate network
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentStatus = OrderStatus.received;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isArabic ? 'تم قبول الطلب بنجاح' : 'Order accepted successfully'),
        backgroundColor: AppColors.success,
      ));
      context.pop(_currentStatus);
    }
  }

  Future<void> _handleReject(bool isArabic) async {
    _rejectReasonController.clear();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تأكيد رفض الطلب' : 'Confirm Order Rejection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isArabic ? 'يرجى كتابة سبب واضح للرفض:' : 'Please provide a clear reason for rejection:'),
            const SizedBox(height: 10),
            TextField(
              controller: _rejectReasonController,
              decoration: InputDecoration(
                hintText: isArabic ? 'سبب الرفض...' : 'Reason for rejection...',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (_rejectReasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isArabic ? 'يجب إدخال سبب الرفض' : 'Rejection reason is required'),
                  backgroundColor: Colors.red,
                ));
              } else {
                Navigator.pop(context, true);
              }
            },
            child: Text(isArabic ? 'تأكيد الرفض' : 'Confirm Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 1)); // Simulate network
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isArabic ? 'تم رفض الطلب بنجاح' : 'Order rejected successfully'),
        backgroundColor: Colors.red,
      ));
      context.pop(OrderStatus.rejected);
    }
  }

  Future<void> _handleSaveChanges(bool isArabic) async {
    if (!_hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isArabic ? 'لا توجد تغييرات لحفظها' : 'No changes to save'),
      ));
      return;
    }

    // Guard: if the new status is rejected, route to the explicit rejection handler
    if (_currentStatus == OrderStatus.rejected) {
      await _handleReject(isArabic);
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تأكيد الحفظ' : 'Confirm Save'),
        content: Text(isArabic ? 'هل تريد حفظ الحالة الجديدة للطلب؟' : 'Do you want to save the new order status?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isArabic ? 'تأكيد' : 'Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 1)); // Simulate network
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isArabic ? 'تم تحديث حالة الطلب بنجاح' : 'Order status updated successfully'),
        backgroundColor: AppColors.success,
      ));
      context.pop(_currentStatus);
    }
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
        final isReadOnly = widget.isReadOnly || widget.initialStatus == OrderStatus.completed;

        return PopScope(
          canPop: !_hasChanges,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final bool shouldPop = await _showUnsavedChangesDialog(context, isArabic);
            if (shouldPop && context.mounted) {
              context.pop();
            }
          },
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF121212) : AppColors.background,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (!_hasChanges) {
                    context.pop(_currentStatus);
                  } else {
                    Navigator.maybePop(context);
                  }
                },
              ),
              title: Text(isArabic ? 'إدارة الطلب #${widget.orderId}' : 'Manage Order #${widget.orderId}'),
              elevation: 0,
              actions: const [
                AgentAppBarActions(),
              ],
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    if (isReadOnly)
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
                            const SizedBox(height: AppSpacing.md),
                            // Order Card showing simplified operational data
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
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.lg),
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
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(widget.order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                              Text(isArabic ? 'الطلب #${widget.orderId}' : 'Order #${widget.orderId}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600, letterSpacing: 0.5)),
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
                                            const SizedBox(width: AppSpacing.xs),
                                            Text(isArabic ? 'محتويات الطلب' : 'Order Contents', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        ...widget.order.items.map((item) => _buildItemRow(item, isArabic, isDark)),
                                        _buildNotesRow(isArabic, isDark, widget.order.notes),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            if (!isReadOnly && widget.initialStatus != OrderStatus.pending) ...[
                              _buildSectionHeader(isArabic ? 'تحديث حالة الغسيل' : 'Update Laundry Status', theme),
                              const SizedBox(height: AppSpacing.md),
                              DropdownButtonFormField<OrderStatus>(
                                initialValue: _currentStatus,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  filled: true,
                                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                                ),
                                items: OrderStatus.values
                                    .where((s) => s != OrderStatus.pending && s != OrderStatus.rejected) // Exclude pending and rejected from dropdown
                                    .map((status) => DropdownMenuItem(
                                          value: status,
                                          child: Text(isArabic ? status.title : status.englishTitle),
                                        ))
                                    .toList(),
                                onChanged: (OrderStatus? newStatus) {
                                  if (newStatus != null && newStatus != _currentStatus) {
                                    setState(() {
                                      _currentStatus = newStatus;
                                      _hasChanges = true;
                                    });
                                  }
                                },
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
                      child: isReadOnly 
                        ? OutlinedButton(
                            onPressed: _isLoading ? null : () => context.pop(_currentStatus),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: Text(isArabic ? 'العودة للخلف' : 'Go Back', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                          )
                        : (widget.initialStatus == OrderStatus.pending)
                          ? Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isLoading ? null : () => _handleReject(isArabic),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: Text(isArabic ? 'رفض' : 'Reject', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : () => _handleAccept(isArabic),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: Text(isArabic ? 'قبول الطلب' : 'Accept Order', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            )
                          : ElevatedButton(
                              onPressed: _isLoading ? null : () => _handleSaveChanges(isArabic),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                minimumSize: const Size(double.infinity, 50),
                                elevation: 4,
                                shadowColor: AppColors.primary.withValues(alpha: 0.4),
                              ),
                              child: Text(isArabic ? 'تأكيد وحفظ التغييرات' : 'Confirm & Save Changes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                    ),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
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
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)),
            ),
            child: Icon(item.icon, color: isDark ? AppColors.lightBlue : AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
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

  Widget _buildNotesRow(bool isArabic, bool isDark, String note) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              note,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.orange.shade200 : Colors.orange.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
