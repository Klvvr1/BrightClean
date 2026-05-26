import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_styles.dart';
import '../data/providers/cart_provider.dart';
import '../data/providers/order_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('سلة الخدمات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 80, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: AppSpacing.md),
                  Text('سلتك فارغة حالياً', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: () => context.go('/customer_home'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                    ),
                    child: const Text('تصفح الخدمات'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      decoration: AppStyles.surface(context),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: AppRadius.button,
                              ),
                              child: Icon(Icons.cleaning_services, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.serviceName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(item.selectedType, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text('${item.pricePerUnit} ر.ي × ${item.quantity}', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${item.totalPrice} ر.ي', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                                  onPressed: () => cart.removeItem(item.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('الإجمالي', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          Text('${cart.totalAmount} ر.ي', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                            final router = GoRouter.of(context);

                            // Show progress dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              // TODO: Cart items need to store actual service IDs and user needs to select an agent
                              // Currently using placeholder values - this needs to be replaced with actual runtime data
                              // when service selection and agent selection UI is implemented
                              final itemsDto = cart.items.map((item) {
                                // FIXME: Hardcoded serviceID - should come from item.serviceId
                                final serviceId = 1; // int.tryParse(item.id);
                                if (serviceId == null || serviceId <= 0) {
                                  throw Exception('رقم الخدمة غير صالح');
                                }
                                return {
                                  'serviceID': serviceId,
                                  'quantity': item.quantity,
                                };
                              }).toList();

                              // FIXME: Hardcoded laundryAgentID - should come from selected agent in UI
                              final selectedAgentId = 2; // Should be from state/provider
                              if (selectedAgentId <= 0) {
                                throw Exception('يجب اختيار وكيل غسيل');
                              }

                              await orderProvider.createBooking(selectedAgentId, itemsDto);

                              // Pop progress dialog
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                router.push('/checkout');
                              }
                            } catch (e) {
                              // Pop progress dialog
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                              scaffoldMessenger.clearSnackBars();
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('حدث خطأ أثناء الانتقال للدفع: $e'),
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          ),
                          child: const Text('الانتقال للدفع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
