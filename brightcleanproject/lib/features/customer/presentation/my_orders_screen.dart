import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/user_error_message.dart';
import 'package:brightcleanproject/features/customer/domain/models/order.dart';
import 'package:brightcleanproject/features/customer/data/providers/order_provider.dart';
import 'package:brightcleanproject/features/customer/data/providers/review_provider.dart';
import 'package:brightcleanproject/features/auth/data/providers/auth_provider.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool _hasLoadedOrders = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryLoadOrders();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Avoid notifying OrderProvider while this page is still being built inside
    // CustomerMainLayout's AnimatedOpacity stack.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryLoadOrders();
    });
  }

  void _tryLoadOrders() {
    if (!mounted) return;

    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (userId != null && !_hasLoadedOrders) {
      Provider.of<OrderProvider>(context, listen: false).fetchMyOrders();
      _hasLoadedOrders = true;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'قيد الانتظار':
        return AppColors.warning;
      case 'في الطريق':
        return AppColors.warning;
      case 'قيد المعالجة':
        return AppColors.secondary;
      case 'جاهز':
        return AppColors.success;
      case 'تم التوصيل':
        return AppColors.success;
      case 'ملغي':
        return AppColors.error;
      default:
        return AppColors.textLight;
    }
  }

  Widget _buildStep(
    BuildContext context,
    String title,
    bool isActive, {
    Color activeColor = AppColors.success,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor:
              isActive ? activeColor : theme.colorScheme.onSurface.withValues(alpha: 0.2),
          child: isActive
              ? Icon(Icons.check, size: 16, color: theme.colorScheme.surface)
              : null,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isActive
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(
    BuildContext context, {
    required String orderId,
    required String date,
    required String details,
    required String status,
    required Color statusColor,
    bool showTracker = true,
    int activeStepIndex = 1,
    bool isRated = false,
    VoidCallback? onRatePressed,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: AppStyles.surface(context),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'طلب رقم #$orderId',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.button,
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    details,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  date,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            if (showTracker) ...[
              const SizedBox(height: AppSpacing.md),
              Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStep(
                    context,
                    'قيد الانتظار',
                    activeStepIndex >= 0,
                    activeColor: AppColors.success,
                  ),
                  Expanded(
                    child: Divider(
                      color: activeStepIndex >= 1
                          ? AppColors.success
                          : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      thickness: 2,
                    ),
                  ),
                  _buildStep(
                    context,
                    'في الطريق',
                    activeStepIndex >= 1,
                    activeColor: AppColors.success,
                  ),
                  Expanded(
                    child: Divider(
                      color: activeStepIndex >= 2
                          ? AppColors.success
                          : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      thickness: 2,
                    ),
                  ),
                  _buildStep(
                    context,
                    'قيد المعالجة',
                    activeStepIndex >= 2,
                    activeColor: AppColors.success,
                  ),
                  Expanded(
                    child: Divider(
                      color: activeStepIndex >= 3
                          ? AppColors.success
                          : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      thickness: 2,
                    ),
                  ),
                  _buildStep(
                    context,
                    'جاهز',
                    activeStepIndex >= 3,
                    activeColor: AppColors.success,
                  ),
                  Expanded(
                    child: Divider(
                      color: activeStepIndex >= 4
                          ? AppColors.success
                          : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      thickness: 2,
                    ),
                  ),
                  _buildStep(
                    context,
                    'توصيل', // Shortened to avoid overflow
                    activeStepIndex >= 4,
                    activeColor: AppColors.success,
                  ),
                ],
              ),
            ],
            if (status == 'تم التوصيل') ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isRated ? null : onRatePressed,
                  icon: Icon(isRated ? Icons.star : Icons.star_outline),
                  label: Text(isRated ? 'تم التقييم' : 'تقييم الخدمة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRated
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.primary,
                    foregroundColor: isRated
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(
      BuildContext parentContext, String orderId, bool requiresDriverRating) {
    double serviceRating = 5;
    double driverRating = 5;
    final TextEditingController reviewController = TextEditingController();

    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final theme = Theme.of(dialogContext);
          return AlertDialog(
            scrollable: true,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.dialog),
            backgroundColor: theme.colorScheme.surface,
            title: Text(
              'تقييم الطلب',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'كيف كانت تجربتك الإجمالية مع برايت كلين؟',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 1. Service Rating Section
                Text(
                  'تقييم الخدمة والنظافة',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => GestureDetector(
                      onTap: () => setState(() => serviceRating = index + 1.0),
                      child: Icon(
                        index < serviceRating ? Icons.star : Icons.star_border,
                        color: index < serviceRating
                            ? Colors.amber
                            : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        size: 36,
                      ),
                    ),
                  ),
                ),

                if (requiresDriverRating) ...[
                  const SizedBox(height: AppSpacing.lg),

                  // 2. Driver Rating Section
                  Text(
                    'تقييم تعامل وسرعة المندوب',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => GestureDetector(
                        onTap: () => setState(() => driverRating = index + 1.0),
                        child: Icon(
                          index < driverRating ? Icons.star : Icons.star_border,
                          color: index < driverRating
                              ? Colors.amber
                              : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),

                // Comments
                TextField(
                  controller: reviewController,
                  maxLines: 3,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'اكتب رأيك هنا (اختياري)...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.button,
                      borderSide: BorderSide(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                    ),
                    filled: true,
                    fillColor:
                        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'إلغاء',
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);

                  // Capture context-sensitive objects BEFORE the async gap
                  final reviewProvider =
                      Provider.of<ReviewProvider>(parentContext, listen: false);
                  final orderProvider =
                      Provider.of<OrderProvider>(parentContext, listen: false);
                  final messenger = ScaffoldMessenger.of(parentContext);
                  final commentText = reviewController.text.trim();

                  // POST /api/bookings/{id}/rate
                  try {
                    final apiClient = BaseApiClient();
                    final bookingIdInt = int.tryParse(orderId);
                    if (bookingIdInt == null) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                              'خطأ: معرف الطلب غير صالح، لا يمكن إرسال التقييم.'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    await apiClient.post(
                      '/api/bookings/$bookingIdInt/rate',
                      body: {
                        'agentRating': serviceRating.toInt(),
                        'agentComment': commentText.isEmpty ? null : commentText,
                        'deliveryRating':
                            requiresDriverRating ? driverRating.toInt() : null,
                        'deliveryComment': null,
                      },
                    );

                    await reviewProvider.fetchRecentReviews();
                    orderProvider.markOrderAsRated(orderId);

                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('شكراً لتقييمك! تم إضافة رأيك بنجاح.'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } on ServerException catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                            'فشل إرسال التقييم: ${userMessageFromError(e, fallback: "خطأ في الخادم")}'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    debugPrint('Rating submission error: $e');
                    final message = userMessageFromError(e);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                            'حدث خطأ غير متوقع أثناء إرسال التقييم: $message'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('إرسال التقييم'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      reviewController.dispose();
    });
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              onPressed: () {
                context.pushReplacement('/customer_home');
              },
              child: const Text('اطلب الآن'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('طلباتي'),
          centerTitle: true,
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3,
            labelStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'الطلبات الحالية'),
              Tab(text: 'الطلبات السابقة'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ─── Tab 1: الطلبات الحالية ────────────────────────────────────
            Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                if (orderProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (orderProvider.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 48),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            orderProvider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton(
                            onPressed: () {
                              final userId =
                                  Provider.of<AuthProvider>(context, listen: false)
                                      .userId;
                              if (userId != null) {
                                orderProvider.fetchMyOrders();
                              }
                            },
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // الطلبات الحالية = كل ما ليس مكتملاً أو ملغياً
                final currentOrders = orderProvider.orders
                    .where((o) => o.status != 'تم التوصيل' && o.status != 'ملغي')
                    .toList();

                return currentOrders.isEmpty
                    ? _buildEmptyState(
                        context,
                        title: 'لا توجد طلبات حالية',
                        subtitle: 'قم بطلب خدمة جديدة لتبدأ التجربة.',
                        icon: Icons.receipt_rounded,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: currentOrders.length,
                        itemBuilder: (context, index) {
                          final Order order = currentOrders[index];

                          final displayOrderId = order.orderId.length > 8
                              ? order.orderId.substring(0, 8)
                              : order.orderId;

                          return _buildOrderCard(
                            context,
                            orderId: displayOrderId,
                            date: order.date,
                            details: order.details,
                            status: order.status,
                            statusColor: _getStatusColor(order.status),
                            activeStepIndex: order.activeStepIndex,
                            isRated: order.isRated,
                            onRatePressed: () => _showRatingDialog(
                                context, order.orderId, order.requiresDriverRating),
                            showTracker: true,
                          );
                        },
                      );
              },
            ),

            // ─── Tab 2: الطلبات السابقة ────────────────────────────────────
            Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                if (orderProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // الطلبات السابقة = المكتملة أو الملغاة
                final pastOrders = orderProvider.orders
                    .where((o) => o.status == 'تم التوصيل' || o.status == 'ملغي')
                    .toList();

                return pastOrders.isEmpty
                    ? _buildEmptyState(
                        context,
                        title: 'لا توجد طلبات سابقة',
                        subtitle:
                            'يبدو أنك لم تقم بأي طلبات مكتملة بعد. اطلب الآن لتجربة خدماتنا المميزة.',
                        icon: Icons.receipt_long_rounded,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: pastOrders.length,
                        itemBuilder: (context, index) {
                          final Order order = pastOrders[index];

                          final displayOrderId = order.orderId.length > 8
                              ? order.orderId.substring(0, 8)
                              : order.orderId;

                          return _buildOrderCard(
                            context,
                            orderId: displayOrderId,
                            date: order.date,
                            details: order.details,
                            status: order.status,
                            statusColor: _getStatusColor(order.status),
                            activeStepIndex: order.activeStepIndex,
                            isRated: order.isRated,
                            // يمكن التقييم فقط للمكتملة وليس الملغاة
                            onRatePressed: order.status == 'تم التوصيل'
                                ? () => _showRatingDialog(
                                    context, order.orderId, order.requiresDriverRating)
                                : null,
                            showTracker: false,
                          );
                        },
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}
