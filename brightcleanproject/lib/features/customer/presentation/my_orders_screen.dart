import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:brightcleanproject/features/customer/domain/models/order.dart';
import 'package:brightcleanproject/features/customer/data/providers/order_provider.dart';
import 'package:brightcleanproject/features/customer/domain/models/review.dart';
import 'package:brightcleanproject/features/customer/data/providers/review_provider.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
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
    String title,
    bool isActive, {
    Color activeColor = AppColors.success,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? activeColor : Colors.grey.shade300,
          child: isActive
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppColors.textMain : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard({
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'طلب رقم #$orderId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    details,
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            if (showTracker) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStep(
                    'قيد الانتظار',
                    activeStepIndex >= 0,
                    activeColor: AppColors.success,
                  ),
                  Expanded(
                    child: Divider(
                      color: activeStepIndex >= 1
                          ? AppColors.success
                          : Colors.grey,
                      thickness: 2,
                    ),
                  ),
                  _buildStep(
                    'في الطريق',
                    activeStepIndex >= 1,
                    activeColor: AppColors.success,
                  ),
                  Expanded(
                    child: Divider(
                      color: activeStepIndex >= 2
                          ? AppColors.success
                          : Colors.grey,
                      thickness: 2,
                    ),
                  ),
                  _buildStep(
                    'قيد المعالجة',
                    activeStepIndex >= 2,
                    activeColor: AppColors.success,
                  ),
                  Expanded(
                    child: Divider(
                      color: activeStepIndex >= 3
                          ? AppColors.success
                          : Colors.grey,
                      thickness: 2,
                    ),
                  ),
                  _buildStep(
                    'جاهز',
                    activeStepIndex >= 3,
                    activeColor: AppColors.success,
                  ),
                  Expanded(
                    child: Divider(
                      color: activeStepIndex >= 4
                          ? AppColors.success
                          : Colors.grey,
                      thickness: 2,
                    ),
                  ),
                  _buildStep(
                    'تم التوصيل',
                    activeStepIndex >= 4,
                    activeColor: AppColors.success,
                  ),
                ],
              ),
            ],
            if (status == 'تم التوصيل') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isRated ? null : onRatePressed,
                  icon: Icon(isRated ? Icons.star : Icons.star_outline),
                  label: Text(isRated ? 'تم التقييم' : 'تقييم الخدمة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isRated ? Colors.grey.shade200 : AppColors.primary,
                    foregroundColor: isRated ? Colors.grey : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: isRated ? 0 : 2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext parentContext, String orderId) {
    double serviceRating = 5;
    double driverRating = 5;
    final TextEditingController reviewController = TextEditingController();

    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'تقييم الطلب',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'كيف كانت تجربتك الإجمالية مع برايت كلين؟',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              
              // 1. Service Rating Section
              const Text(
                'تقييم الخدمة والنظافة',
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMain),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => GestureDetector(
                  onTap: () => setState(() => serviceRating = index + 1.0),
                  child: Icon(
                    index < serviceRating ? Icons.star : Icons.star_border,
                    color: index < serviceRating ? Colors.amber : Colors.grey.shade400,
                    size: 36,
                  ),
                )),
              ),
              const SizedBox(height: 20),
              
              // 2. Driver Rating Section
              const Text(
                'تقييم تعامل وسرعة المندوب',
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMain),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => GestureDetector(
                  onTap: () => setState(() => driverRating = index + 1.0),
                  child: Icon(
                    index < driverRating ? Icons.star : Icons.star_border,
                    color: index < driverRating ? Colors.amber : Colors.grey.shade400,
                    size: 36,
                  ),
                )),
              ),
              const SizedBox(height: 24),
              
              // Comments
              TextField(
                controller: reviewController,
                maxLines: 3,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'اكتب رأيك هنا (اختياري)...',
                  hintStyle: const TextStyle(fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final review = Review(
                  userName: 'عميل برايت كلين',
                  comment: reviewController.text.isEmpty ? 'خدمة ممتازة وتوصيل سريع! شكراً لكم.' : reviewController.text,
                  rating: (serviceRating + driverRating) / 2.0,
                  serviceRating: serviceRating,
                  driverRating: driverRating,
                  date: DateTime.now(),
                );

                Provider.of<ReviewProvider>(
                  parentContext,
                  listen: false,
                ).addReview(review);

                Provider.of<OrderProvider>(
                  parentContext,
                  listen: false,
                ).markOrderAsRated(orderId);

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'شكراً لتقييمك! تم إضافة رأيك في القائمة الرئيسية.',
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'إرسال التقييم',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.pushReplacement('/customer_home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'اطلب الآن',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'طلباتي',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: 'الطلبات الحالية'),
              Tab(text: 'الطلبات السابقة'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                final currentOrders = orderProvider.orders;

                return currentOrders.isEmpty
                    ? _buildEmptyState(
                        context,
                        title: 'لا توجد طلبات حالية',
                        subtitle: 'قم بطلب خدمة جديدة لتبدأ التجربة.',
                        icon: Icons.receipt_rounded,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: currentOrders.length,
                        itemBuilder: (context, index) {
                          final Order order = currentOrders[index];

                          final displayOrderId = order.orderId.length > 8
                              ? order.orderId.substring(0, 8)
                              : order.orderId;

                          return _buildOrderCard(
                            orderId: displayOrderId,
                            date: order.date,
                            details: order.details,
                            status: order.status,
                            statusColor: _getStatusColor(order.status),
                            activeStepIndex: order.activeStepIndex,
                            isRated: order.isRated,
                            onRatePressed: () =>
                                _showRatingDialog(context, order.orderId),
                            showTracker: order.status != 'تم التوصيل' &&
                                order.status != 'ملغي',
                          );
                        },
                      );
              },
            ),
            _buildEmptyState(
              context,
              title: 'لا توجد طلبات سابقة',
              subtitle:
                  'يبدو أنك لم تقم بأي طلبات في الماضي. اطلب الآن لتجربة خدماتنا المميزة.',
              icon: Icons.receipt_long_rounded,
            ),
          ],
        ),
      ),
    );
  }
}