import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../controllers/language_controller.dart';
import '../../../../controllers/theme_controller.dart';

enum TrackingWorkflow { pickup, delivery }

class DriverTrackingScreen extends StatefulWidget {
  final String taskId;

  const DriverTrackingScreen({super.key, required this.taskId});

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
    // Simulate picking workflow based on ID (odd for pickup, even for delivery)
    _workflow = int.tryParse(widget.taskId)?.isOdd == true 
        ? TrackingWorkflow.pickup 
        : TrackingWorkflow.delivery;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = LanguageController().isArabic;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
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
                            padding: const EdgeInsets.all(8),
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
              ],
            ),
          ),
          
          // Details Panel
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: Customer Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _customerName,
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
                    IconButton.filled(
                      onPressed: () => _makePhoneCall(_customerPhone),
                      icon: const Icon(Icons.call),
                      style: IconButton.styleFrom(backgroundColor: AppColors.success),
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
                const SizedBox(height: 16),
                
                // Order Items
                Text(
                  isAr ? 'تفاصيل الطلب:' : 'Order Details:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
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
                            const SizedBox(width: 8),
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
                
                const SizedBox(height: 24),
                
                // Status Selection Label
                Text(
                  isAr ? 'تحديث حالة الطلب:' : 'Update Order Status:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

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
                        if (newValue != null) {
                          setState(() => _currentStep = newValue);
                        }
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Finish Task Button (Only shows when on the last step)
                if (_currentStep == currentStatuses.length - 1)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Save completion status to SharedPreferences
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('task_completed_${widget.taskId}', true);
                        
                        if (!context.mounted) return;
                        context.pop(); // Complete task and return to dashboard
                      },
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
        ],
      ),
    );
  }
}




