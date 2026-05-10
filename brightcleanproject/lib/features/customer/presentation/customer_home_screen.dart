import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'service_details_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _isSearching = _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon, Color color) {
    return Container(
      width: 120, // fixed width for horizontal scrolling
      margin: const EdgeInsets.only(left: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailsScreen(serviceType: title),
            ),
          );
        },
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfferCard(String title, String subtitle, Color bgColor) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(left: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            subtitle, 
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('برايت كلين', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          IconButton(icon: const Icon(Icons.shopping_cart_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _isSearching ? AppColors.primary.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
                      blurRadius: _isSearching ? 8 : 4,
                      spreadRadius: _isSearching ? 2 : 0,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن خدمات...',
                    prefixIcon: Icon(Icons.search, color: _isSearching ? AppColors.primary : Colors.grey),
                    suffixIcon: _isSearching
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Offers Carousel (Horizontal Scroll)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('العروض الترويجية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildOfferCard('خصم 20%', 'على غسيل السجاد والمفروشات', AppColors.primary),
                  _buildOfferCard('غسيل مجاني', 'اغسل 5 قمصان والسادس مجاناً', AppColors.tertiary),
                  _buildOfferCard('باقة التوفير', 'خصم خاص للاشتراكات الشهرية', Colors.teal),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Categories (Horizontal Scroll)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('الخدمات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120, // Adjusted height for category cards
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryCard(context, 'الملابس', Icons.checkroom, AppColors.primary),
                  _buildCategoryCard(context, 'السجاد والمفروشات', Icons.dataset, AppColors.secondary),
                  _buildCategoryCard(context, 'السيارات', Icons.directions_car, AppColors.tertiary),
                  _buildCategoryCard(context, 'تنظيف المكيفات', Icons.ac_unit, Colors.teal),
                  _buildCategoryCard(context, 'عاملات النظافة', Icons.cleaning_services, Colors.pink),
                  _buildCategoryCard(context, 'تنظيف الخزانات', Icons.water_drop, Colors.blueAccent),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Reviews
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('آراء العملاء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
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
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.lightBlue,
                          child: Icon(Icons.person, color: AppColors.primary, size: 20),
                        ),
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
                    SizedBox(height: 12),
                    Text('خدمة ممتازة وتوصيل سريع! ملابسي عادت كأنها جديدة.', style: TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
