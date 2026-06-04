import 'package:flutter/material.dart';
import 'package:brightcleanproject/core/theme/app_spacing.dart';

import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/controllers/language_controller.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../auth/data/providers/auth_provider.dart';
import '../data/models/delivery_task_model.dart';
import '../data/providers/driver_provider.dart';

enum TrackingWorkflow { pickup, delivery }

class DriverTrackingScreen extends StatefulWidget {
  final String taskId;
  final TrackingWorkflow workflow;
  final DeliveryTaskModel? task;

  const DriverTrackingScreen({
    super.key,
    required this.taskId,
    required this.workflow,
    this.task,
  });

  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen> {
  late TrackingWorkflow _workflow;
  int _currentStep = 0;
  
  // Mock Locations
  final LatLng _customerLocation = const LatLng(25.1972, 55.2744); // Downtown Dubai
  final LatLng _laundryLocation = const LatLng(25.2285, 55.3273); // Deira
  
  // Mock Order Details
  final List<Map<String, dynamic>> _items = [
    {'nameAr': 'ثوب', 'nameEn': 'Thobe', 'count': 5, 'icon': Icons.checkroom},
    {'nameAr': 'تيشرت', 'nameEn': 'T-Shirt', 'count': 3, 'icon': Icons.checkroom},
    {'nameAr': 'سجادات', 'nameEn': 'Carpets', 'count': 2, 'icon': Icons.grid_view},
  ];

  final String _customerName = 'أحمد محمد';
  final String _customerPhone = '0533333333';
  final String _laundryName = 'المغسلة الذهبية';

  @override
  void initState() {
    super.initState();
    // Initialize workflow from the parameter passed by the caller
    _workflow = widget.workflow;
    final status = widget.task?.status;
    if (status == 3) {
      _currentStep = widget.workflow == TrackingWorkflow.pickup ? 3 : 2;
    } else if (status == 2) {
      _currentStep = 1;
    }
  }

  DeliveryTaskModel? _findCurrentTask(DriverProvider provider) {
    for (final task in provider.tasks) {
      if (task.taskID.toString() == widget.taskId) {
        return task;
      }
    }
    return widget.task;
  }

  String _formatAddress(Map<String, dynamic>? address, int? fallbackId) {
    if (address == null) {
      return fallbackId == null ? '-' : 'Address ID $fallbackId';
    }
    final parts = [
      address['area'],
      address['street'],
      address['buildingNo'],
      address['city'],
    ]
        .where((part) => part != null && part.toString().trim().isNotEmpty)
        .map((part) => part.toString().trim())
        .toList();
    return parts.isEmpty
        ? (fallbackId == null ? '-' : 'Address ID $fallbackId')
        : parts.join(' ');
  }

  Future<void> _claimTask(DriverProvider provider, bool isAr) async {
    final driverId = context.read<AuthProvider>().userId;
    final taskId = int.tryParse(widget.taskId);
    if (driverId == null || taskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr
              ? 'تعذر تحديد المندوب أو الطلب'
              : 'Could not identify the driver or task'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isAr ? 'تأكيد قبول الطلب' : 'Confirm Order Claim'),
        content: Text(isAr
            ? 'هل تريد قبول هذا الطلب وإضافته إلى طلباتي؟'
            : 'Do you want to claim this order and move it to My Orders?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isAr ? 'قبول الطلب' : 'Claim Order'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    try {
      await provider.claimTask(taskId, driverId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr
              ? 'تم قبول الطلب بنجاح وسيظهر في طلباتي'
              : 'Order claimed successfully and moved to My Orders'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop('claimed');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'فشل قبول الطلب: $e' : 'Failed to claim order: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _completeTask(DriverProvider provider, bool isAr) async {
    final taskId = int.tryParse(widget.taskId);
    if (taskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'Ø±Ù‚Ù… Ø§Ù„Ù…Ù‡Ù…Ø© ØºÙŠØ± ØµØ­ÙŠØ­' : 'Invalid task number'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      await provider.completeTask(taskId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'ØªÙ… Ø¥ÙƒÙ…Ø§Ù„ Ø§Ù„Ù…Ù‡Ù…Ø© Ø¨Ù†Ø¬Ø§Ø­' : 'Task completed successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'ÙØ´Ù„ Ø¥ÙƒÙ…Ø§Ù„ Ø§Ù„Ù…Ù‡Ù…Ø©: $e' : 'Failed to complete task: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LanguageController().isArabic
                ? 'تعذر إجراء المكالمة. تم نسخ الرقم إلى الحافظة.'
                : 'Could not make the call. Number copied to clipboard.'),
            action: SnackBarAction(
              label: LanguageController().isArabic ? 'حسناً' : 'OK',
              onPressed: () {},
            ),
          ),
        );
        await Clipboard.setData(ClipboardData(text: phoneNumber));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageController().isArabic
              ? 'حدث خطأ. تم نسخ الرقم إلى الحافظة.'
              : 'An error occurred. Number copied to clipboard.'),
          action: SnackBarAction(
            label: LanguageController().isArabic ? 'حسناً' : 'OK',
            onPressed: () {},
          ),
        ),
      );
      await Clipboard.setData(ClipboardData(text: phoneNumber));
    }
  }

  Future<void> _sendMessage(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'sms', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LanguageController().isArabic
                ? 'تعذر فتح تطبيق الرسائل. تم نسخ الرقم إلى الحافظة.'
                : 'Could not open messaging app. Number copied to clipboard.'),
            action: SnackBarAction(
              label: LanguageController().isArabic ? 'حسناً' : 'OK',
              onPressed: () {},
            ),
          ),
        );
        await Clipboard.setData(ClipboardData(text: phoneNumber));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageController().isArabic
              ? 'حدث خطأ. تم نسخ الرقم إلى الحافظة.'
              : 'An error occurred. Number copied to clipboard.'),
          action: SnackBarAction(
            label: LanguageController().isArabic ? 'حسناً' : 'OK',
            onPressed: () {},
          ),
        ),
      );
      await Clipboard.setData(ClipboardData(text: phoneNumber));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = LanguageController().isArabic;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<DriverProvider>();
    final task = _findCurrentTask(provider);
    final pickupAddress = _formatAddress(task?.pickupAddress, task?.pickupAddressID);
    final dropoffAddress = _formatAddress(task?.dropoffAddress, task?.dropoffAddressID);
    final activeAddress = _workflow == TrackingWorkflow.pickup ? pickupAddress : dropoffAddress;
    final isTaskUnassigned = task?.status == 0;
    final isTaskCompleted = task?.status == 3;
    final isTaskEditable = task == null || task.status == 1 || task.status == 2;
    
    // Workflow Labels
    final List<String> pickupStatuses = isAr 
        ? ['في الطريق إليك', 'تم الاستلام', 'في الطريق للمغسلة', 'تم التسليم للمغسلة']
        : ['On my way to you', 'Picked Up', 'Heading to Laundry', 'Delivered to Laundry'];

    final List<String> deliveryStatuses = isAr 
        ? ['تم الاستلام من $_laundryName', 'في الطريق إليك', 'تم التسليم للعميل']
        : ['Picked from $_laundryName', 'On my way to you', 'Delivered to Customer'];

    final currentStatuses = _workflow == TrackingWorkflow.pickup ? pickupStatuses : deliveryStatuses;
    final currentTarget = (_workflow == TrackingWorkflow.pickup && _currentStep < 2) || 
                          (_workflow == TrackingWorkflow.delivery && _currentStep >= 1)
        ? _customerLocation 
        : _laundryLocation;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Stack(
            children: [
              // Back Button - Always on the left for LTR icons consistency, or based on locale?
              // User wants icons on the left. If icons are on the left, back button should be at the very edge (left: 16).
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              // Icons forced to the LEFT (absolute)
              Positioned(
                left: 60,
                top: 0,
                bottom: 0,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      ValueListenableBuilder<Locale>(
                        valueListenable: LanguageController().locale,
                        builder: (context, locale, _) {
                          return TextButton(
                            onPressed: () => LanguageController().toggleLanguage(),
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero, 
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              locale.languageCode == 'ar' ? 'EN' : 'عربي',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: ThemeController().themeMode,
                        builder: (context, themeMode, _) {
                          return IconButton(
                            icon: Icon(
                              themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode, 
                              color: Colors.white, 
                              size: 18
                            ),
                            onPressed: () => ThemeController().toggleTheme(),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Centered Title
              Center(
                child: Text(
                  '${isAr ? 'طلب' : 'Order'} #${widget.taskId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900, 
                    color: Colors.white, 
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        elevation: 0,
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Map Section
          Expanded(
            flex: 4,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: currentTarget,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.brightclean.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentTarget,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Details Panel
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                // Header: Customer Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(
                          _customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          isAr ? 'شارع الشيخ زايد، دبي' : 'Sheikh Zayed Rd, Dubai',
                          style: TextStyle(color: isDark ? Colors.white : Colors.grey, fontSize: 14),
                        ),
                        ],
                      ),
                    ),
                    if (task != null)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            activeAddress,
                            textAlign: TextAlign.end,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        IconButton.filled(
                          onPressed: () => _sendMessage(_customerPhone),
                          icon: const Icon(Icons.message),
                          style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        IconButton.filled(
                          onPressed: () => _makePhoneCall(_customerPhone),
                          icon: const Icon(Icons.call),
                          style: IconButton.styleFrom(backgroundColor: AppColors.success),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 30),
                
                // Status Stepper
                Text(
                  '${isAr ? 'الحالة الحالية:' : 'Current Status:'} ${currentStatuses[_currentStep]}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.white : AppColors.primary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Order Items
                Text(
                  isAr ? 'تفاصيل الطلب:' : 'Order Details:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(item['icon'] as IconData, size: 18, color: isDark ? Colors.white : AppColors.primary),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '${item['count']} x ${isAr ? item['nameAr'] : item['nameEn']}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Status Selection Label
                Text(
                  isAr ? 'تحديث حالة الطلب:' : 'Update Order Status:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Status Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _currentStep,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_circle, color: AppColors.primary),
                      dropdownColor: theme.cardColor,
                      items: List.generate(currentStatuses.length, (index) {
                        return DropdownMenuItem(
                          value: index,
                          child: Text(
                            currentStatuses[index],
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: _currentStep == index ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }),
                      onChanged: (newValue) {
                        if (newValue != null && isTaskEditable) {
                          setState(() => _currentStep = newValue);
                        }
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),

                if (isTaskUnassigned)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      isAr
                          ? 'ÙŠØ¬Ø¨ Ù‚Ø¨ÙˆÙ„ Ø§Ù„Ù…Ù‡Ù…Ø© Ù…Ù† Ø§Ù„Ù‚Ø§Ø¦Ù…Ø© Ù‚Ø¨Ù„ ØªØºÙŠÙŠØ± Ø­Ø§Ù„ØªÙ‡Ø§.'
                          : 'Claim this task from the list before changing its status.',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isTaskUnassigned) ...[
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: provider.isActionLoading
                          ? null
                          : () => _claimTask(provider, isAr),
                      icon: provider.isActionLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.assignment_turned_in),
                      label: Text(
                        isAr ? 'قبول الطلب' : 'Claim Order',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
                if (isTaskCompleted)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      isAr ? 'ØªÙ… Ø¥ÙƒÙ…Ø§Ù„ Ù‡Ø°Ù‡ Ø§Ù„Ù…Ù‡Ù…Ø©.' : 'This task has been completed.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                
                // Finish Task Button (Only shows when on the last step)
                if (_currentStep == currentStatuses.length - 1 && isTaskEditable)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: provider.isActionLoading
                          ? null
                          : () => _completeTask(provider, isAr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text(
                        isAr ? 'إنهاء المهمة بنجاح' : 'Task Completed Successfully',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}




