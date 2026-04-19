import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('برايت كلين'),
        actions: [
          IconButton(icon: const Icon(Icons.local_offer), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ad Carousel Placeholder
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('عروض الترويجية (Carousel)', style: TextStyle(color: AppColors.primary, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('الخدمات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Categories Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildCategoryCard(context, 'الملابس', Icons.checkroom, AppColors.primary),
                _buildCategoryCard(context, 'السجاد والمفروشات', Icons.dataset, AppColors.secondary),
                _buildCategoryCard(context, 'السيارات', Icons.directions_car, AppColors.tertiary),
                _buildCategoryCard(context, 'تنظيف المكيفات', Icons.ac_unit, Colors.teal),
                _buildCategoryCard(context, 'عاملات النظافة', Icons.cleaning_services, Colors.pink),
                _buildCategoryCard(context, 'تنظيف الخزانات', Icons.water_drop, Colors.blueAccent),
              ],
            ),
            const SizedBox(height: 24),
            const Text('آراء العملاء', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Reviews Placeholder
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: AppColors.textLight),
                      SizedBox(width: 8),
                      Text('أحمد محمد', style: TextStyle(fontWeight: FontWeight.bold)),
                      Spacer(),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('خدمة ممتازة وتوصيل سريع!'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
