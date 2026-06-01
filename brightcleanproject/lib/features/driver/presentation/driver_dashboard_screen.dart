import 'package:flutter/material.dart';
import 'package:brightcleanproject/core/theme/app_spacing.dart';

import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/controllers/theme_controller.dart';
import '../../../core/controllers/language_controller.dart';
import '../data/providers/driver_provider.dart';
import '../data/models/delivery_task_model.dart';
import '../../auth/data/providers/auth_provider.dart';
import '../../customer/data/providers/cart_provider.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _selectedIndex = 0;
  bool _isOnline = false;

  // Mock data for user profile
  String _userName = 'سائق برايت كلين';
  String _userPhone = '0533333333';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DriverProvider>().fetchTaskPool();
      }
    });
  }

  Future<void> _loadUserData() async {
    final isAr = LanguageController().isArabic;
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      final savedName = prefs.getString('user_name');
      final isDefaultName = prefs.getBool('user_name_is_default') ?? true;

      // Only localize if explicitly marked as default
      if (savedName == null ||
          isDefaultName ||
          savedName == 'سائق برايت كلين' ||
          savedName == 'Bright Clean Driver') {
        _userName = isAr ? 'سائق برايت كلين' : 'Bright Clean Driver';
        // Keep the flag set to true since we're using a default name
        prefs.setBool('user_name_is_default', true);
      } else {
        _userName = savedName;
      }
      _userPhone = prefs.getString('user_phone') ?? '0533333333';
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index != 0) {
      _loadUserData(); // Refresh data when switching tabs
    }
  }

  // --- Home Tab (Incoming Orders) ---
  Widget _buildHomeTab() {
    final isAr = LanguageController().isArabic;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Welcome Section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              PopupMenuButton<int>(
                onSelected: (value) {
                  if (value == 1) {
                    setState(() => _selectedIndex = 2); // Go to Profile tab
                  } else if (value == 2) {
                    _showLogoutDialog();
                  }
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 1,
                    child: ListTile(
                      leading: Icon(Icons.person_outline,
                          color: theme.colorScheme.primary),
                      title: Text(isAr ? 'حسابي' : 'My Account'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 2,
                    child: ListTile(
                      leading:
                          const Icon(Icons.logout, color: Colors.redAccent),
                      title: Text(isAr ? 'تسجيل الخروج' : 'Logout',
                          style: const TextStyle(color: Colors.redAccent)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.person,
                        color:
                            isDark ? Colors.white : theme.colorScheme.primary,
                        size: 35),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'مرحباً بك،' : 'Welcome back,',
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? Colors.white : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _isOnline
                      ? AppColors.success.withValues(alpha: 0.1)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isOnline
                        ? AppColors.success.withValues(alpha: 0.2)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _isOnline
                            ? AppColors.success
                            : (isDark ? Colors.white : Colors.grey),
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (_isOnline)
                            BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.5),
                                blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      isAr
                          ? (_isOnline ? 'نشط' : 'غير نشط')
                          : (_isOnline ? 'Active' : 'Offline'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _isOnline
                            ? AppColors.success
                            : (isDark ? Colors.white : Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Work Status Toggle
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr
                      ? 'وضعية العمل (استقبال الطلبات)'
                      : 'Work Mode (Accepting Orders)',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87),
                ),
                Switch.adaptive(
                  value: _isOnline,
                  activeTrackColor: AppColors.success,
                  onChanged: (v) => setState(() => _isOnline = v),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _isOnline
              ? _buildOnlineContent(isAr, isDark)
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_off_outlined,
                          size: 80,
                          color: isDark
                              ? Colors.white12
                              : Colors.grey.withValues(alpha: 0.2)),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        isAr
                            ? 'قم بتفعيل وضع العمل للبدء'
                            : 'Enable Work Mode to Start',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            color: isDark ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _refreshOrders() async {
    await context.read<DriverProvider>().fetchTaskPool();
    if (mounted) {
      _loadUserData();
    }
  }

  Widget _buildRealTaskCard({
    required DeliveryTaskModel task,
    required bool isAr,
    required bool isDark,
    required DriverProvider provider,
  }) {
    final theme = Theme.of(context);
    final workflow = task.type == 0 ? 1 : 2; // 1 = Pickup, 2 = Delivery
    final isUnassigned = task.status == 0;
    final isAssigned = task.status == 1 || task.status == 2;
    final isCompleted = task.status == 3;

    // Build pickup and dropoff address descriptions
    final fromAddress = task.pickupAddress != null
        ? "${task.pickupAddress!['area'] ?? ''} ${task.pickupAddress!['street'] ?? ''}"
        : "Address ID ${task.pickupAddressID}";
    final toAddress = task.dropoffAddress != null
        ? "${task.dropoffAddress!['area'] ?? ''} ${task.dropoffAddress!['street'] ?? ''}"
        : "Address ID ${task.dropoffAddressID}";

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (workflow == 1
                                ? AppColors.primary
                                : AppColors.secondary)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        workflow == 1
                            ? (isAr ? 'استلام' : 'Pickup')
                            : (isAr ? 'توصيل' : 'Delivery'),
                        style: TextStyle(
                          color: workflow == 1
                              ? AppColors.primary
                              : AppColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // Order Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isAr ? 'مهمة' : 'Task',
                        style: const TextStyle(
                          color: AppColors.tertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text('${isAr ? 'مهمة' : 'Task'} #${task.taskID}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87)),
                  ],
                ),
                Text(
                  isAr ? '${task.deliveryFee} ريال' : '${task.deliveryFee} YER',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.trip_origin,
                    size: 16,
                    color: isDark ? Colors.white : theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: Text('${isAr ? 'من:' : 'From:'} $fromAddress',
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87))),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.location_on,
                    size: 16,
                    color: isDark ? Colors.white : AppColors.secondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: Text('${isAr ? 'إلى:' : 'To:'} $toAddress',
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87))),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.receipt_long,
                    size: 16,
                    color: Colors.amber.shade700),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: Text('${isAr ? 'رقم الحجز:' : 'Booking ID:'} #${task.bookingID}',
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87))),
              ],
            ),
            if (isUnassigned) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: provider.isActionLoading
                      ? null
                      : () async {
                          final driverId = Provider.of<AuthProvider>(context, listen: false).userId;
                          if (driverId == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('خطأ: لم يتم العثور على معرف السائق'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                            return;
                          }
                          try {
                            await provider.claimTask(task.taskID, driverId);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم قبول المهمة بنجاح!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('فشل قبول المهمة: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  icon: provider.isActionLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.hail),
                  label: Text(isAr ? 'قبول المهمة' : 'Claim Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            if (isAssigned) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: provider.isActionLoading
                      ? null
                      : () async {
                          try {
                            await provider.completeTask(task.taskID);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم إكمال المهمة بنجاح!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('فشل إكمال المهمة: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  icon: provider.isActionLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(isAr ? 'إكمال المهمة' : 'Complete Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            if (isCompleted) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAr ? 'تم بنجاح' : 'Completed Successfully',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.success, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineContent(bool isAr, bool isDark) {
    return Consumer<DriverProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 60),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    isAr ? 'حدث خطأ أثناء تحميل الطلبات' : 'Error loading requests',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () => provider.fetchTaskPool(),
                    child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final availableTasks = provider.tasks.where((t) => t.status == 0).toList();

        if (availableTasks.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshOrders,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                _buildEarningsCard(),
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 80,
                          color: isDark
                              ? Colors.white
                              : Colors.grey.withValues(alpha: 0.2)),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        isAr
                            ? 'لا توجد طلبات متاحة حالياً'
                            : 'No Available Orders Yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18,
                            color: isDark ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        isAr ? 'اسحب للأسفل للتحديث' : 'Pull down to refresh',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshOrders,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _buildEarningsCard(),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  isAr ? 'الطلبات المتاحة' : 'Available Requests',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...availableTasks.map((task) => _buildRealTaskCard(
                    task: task,
                    isAr: isAr,
                    isDark: isDark,
                    provider: provider,
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarningsCard() {
    final isAr = LanguageController().isArabic;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'أرباحك اليوم' : 'Today\'s Earnings',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isAr ? '120.50 ر.ي' : '120.50 YER',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.payments_outlined,
                  color: Colors.white, size: 35),
            ),
          ],
        ),
      ),
    );
  }



  // --- My Orders Tab (Current/Previous Toggle) ---
  Widget _buildMyOrdersTab() {
    final isAr = LanguageController().isArabic;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer2<DriverProvider, AuthProvider>(
      builder: (context, provider, authProvider, child) {
        final driverId = authProvider.userId;
        final currentTasks = driverId == null ? <dynamic>[] : provider.tasks
            .where((t) => t.deliveryStaffID == driverId && (t.status == 1 || t.status == 2))
            .toList();
        final previousTasks = driverId == null ? <dynamic>[] : provider.tasks
            .where((t) => t.deliveryStaffID == driverId && t.status == 3)
            .toList();

        List<Widget> currentWidgets = [];
        if (currentTasks.isEmpty) {
          currentWidgets.add(
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  isAr ? 'لا توجد طلبات جارية' : 'No current orders',
                  style: TextStyle(color: isDark ? Colors.white : Colors.grey),
                ),
              ),
            ),
          );
        } else {
          currentWidgets.addAll(
            currentTasks.map((task) => _buildRealTaskCard(
                  task: task,
                  isAr: isAr,
                  isDark: isDark,
                  provider: provider,
                )),
          );
        }

        List<Widget> previousWidgets = [];
        if (previousTasks.isEmpty) {
          previousWidgets.add(
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  isAr ? 'لا توجد طلبات سابقة' : 'No previous orders',
                  style: TextStyle(color: isDark ? Colors.white : Colors.grey),
                ),
              ),
            ),
          );
        } else {
          previousWidgets.addAll(
            previousTasks.map((task) => _buildRealTaskCard(
                  task: task,
                  isAr: isAr,
                  isDark: isDark,
                  provider: provider,
                )),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: theme.cardColor,
                child: TabBar(
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: isDark ? Colors.white : Colors.grey,
                  indicatorColor: theme.colorScheme.primary,
                  tabs: [
                    Tab(text: isAr ? 'الطلبات الحالية' : 'Current Orders'),
                    Tab(text: isAr ? 'الطلبات السابقة' : 'Previous Orders'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Current Orders
                    ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: currentWidgets,
                    ),
                    // Previous Orders
                    ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: previousWidgets,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Profile Tab ---
  Widget _buildProfileTab() {
    final isAr = LanguageController().isArabic;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Profile Header
        Center(
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: theme.colorScheme.primary, width: 2),
                ),
                child: Icon(Icons.person,
                    size: 60,
                    color: isDark ? Colors.white : theme.colorScheme.primary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _userName,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87),
              ),
              Text(
                isAr ? 'شريك توصيل معتمد' : 'Certified Delivery Partner',
                style: TextStyle(color: isDark ? Colors.white : Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),

        // Info Cards
        _buildProfileItem(Icons.phone_outlined,
            isAr ? 'رقم الهاتف' : 'Phone Number', _userPhone),
        _buildProfileItem(
            Icons.email_outlined,
            isAr ? 'البريد الإلكتروني' : 'Email Address',
            'driver@brightclean.com'),
        _buildProfileItem(
            Icons.drive_eta_outlined,
            isAr ? 'نوع المركبة' : 'Vehicle Type',
            isAr ? 'سيارة صالون' : 'Sedan Car'),
        _buildProfileItem(Icons.confirmation_number_outlined,
            isAr ? 'رقم اللوحة' : 'Plate Number', 'A 12345'),

        const SizedBox(height: AppSpacing.lg),

        // التفضيلات
        _buildSettingsHeader(isAr ? 'التفضيلات' : 'Preferences'),
        ListTile(
          leading: Icon(Icons.language, color: isDark ? Colors.white : AppColors.primary),
          title: Text(isAr ? 'لغة التطبيق' : 'App Language', style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isAr ? 'العربية' : 'English', 
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.primary, 
                fontWeight: FontWeight.bold
              )
            ),
          ),
          onTap: () {
            setState(() {
              LanguageController().toggleLanguage();
              _loadUserData();
            });
          },
        ),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController().themeMode,
          builder: (context, themeMode, child) {
            final isDarkTheme = themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    MediaQuery.of(context).platformBrightness == Brightness.dark);
            return _buildSwitchTile(
              isAr ? 'الوضع الليلي' : 'Night Mode',
              isDarkTheme,
              (_) => ThemeController().toggleTheme(),
              icon: isDarkTheme ? Icons.dark_mode : Icons.light_mode,
            );
          },
        ),

        const Divider(height: 40),

        // Logout Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: Text(isAr ? 'تسجيل الخروج' : 'Logout',
                style: const TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: TextStyle(fontSize: 14, color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade600, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged, {IconData? icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SwitchListTile(
      secondary: Icon(
        icon ?? (value ? Icons.dark_mode : Icons.light_mode), 
        color: value 
            ? (isDark ? Colors.white : AppColors.primary) 
            : (isDark ? Colors.white38 : Colors.grey)
      ),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : null)),
      value: value,
      onChanged: onChanged,
      activeTrackColor: isDark ? Colors.white30 : AppColors.primary.withValues(alpha: 0.5),
      activeThumbColor: isDark ? Colors.white : AppColors.primary,
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: isDark ? Colors.white : theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey,
                      fontSize: 12)),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    final isAr = LanguageController().isArabic;
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAr ? 'تسجيل الخروج' : 'Logout'),
        content: Text(isAr
            ? 'هل أنت متأكد أنك تريد تسجيل الخروج؟'
            : 'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Close the dialog first
              await Provider.of<AuthProvider>(context, listen: false).logout(
                Provider.of<CartProvider>(context, listen: false)
              );
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: Text(isAr ? 'خروج' : 'Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = LanguageController().isArabic;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          isAr ? 'برايت كلين' : 'Bright Clean',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        elevation: 4,
        shadowColor: Colors.black26,
        backgroundColor: AppColors.primary,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          _buildMyOrdersTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: isDark ? Colors.white : AppColors.primary,
          unselectedItemColor: isDark ? Colors.white70 : Colors.grey.shade600,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.cardColor,
          elevation: 0,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined, size: 26),
              activeIcon: const Icon(Icons.home, size: 26),
              label: isAr ? 'الرئيسية' : 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.assignment_outlined, size: 26),
              activeIcon: const Icon(Icons.assignment, size: 26),
              label: isAr ? 'طلباتي' : 'Orders',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline, size: 26),
              activeIcon: const Icon(Icons.person, size: 26),
              label: isAr ? 'حسابي' : 'My Account',
            ),
          ],
        ),
      ),
    );
  }
}
