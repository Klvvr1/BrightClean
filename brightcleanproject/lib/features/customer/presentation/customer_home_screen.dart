import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';
import 'service_details_screen.dart';
import 'package:provider/provider.dart';
import '../data/providers/review_provider.dart';
import '../data/providers/cart_provider.dart';
import 'package:go_router/go_router.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final List<Map<String, dynamic>> _allCategories = [
    {'title': 'الملابس', 'icon': Icons.checkroom, 'color': AppColors.primary},
    {'title': 'السجاد والمفروشات', 'icon': Icons.dataset, 'color': AppColors.secondary},
    {'title': 'السيارات', 'icon': Icons.directions_car, 'color': AppColors.tertiary},
    {'title': 'تنظيف المكيفات', 'icon': Icons.ac_unit, 'color': Colors.teal},
    {'title': 'عاملات النظافة', 'icon': Icons.cleaning_services, 'color': Colors.pink},
    {'title': 'تنظيف الخزانات', 'icon': Icons.water_drop, 'color': Colors.blueAccent},
    {'title': 'غسيل الألواح الشمسية', 'icon': Icons.solar_power, 'color': Colors.orange},
  ];

  List<Map<String, dynamic>> get _filteredCategories {
    if (_searchController.text.isEmpty) return [];
    return _allCategories.where((cat) => cat['title'].toString().contains(_searchController.text)).toList();
  }

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

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon, Color color, {bool isSearch = false}) {
    return Container(
      width: isSearch ? null : 120, // null width to fill grid if searching
      margin: EdgeInsets.only(left: isSearch ? 0 : 16),
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
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () => context.push('/notifications')),
          Consumer<CartProvider>(
            builder: (context, cart, child) => Badge(
              label: Text(cart.itemCount.toString()),
              isLabelVisible: cart.itemCount > 0,
              backgroundColor: Colors.red,
              child: IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => context.push('/cart'),
              ),
            ),
          ),
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
            
            if (_isSearching) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('نتائج البحث', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              if (_filteredCategories.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('لا توجد نتائج تطابق بحثك', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _filteredCategories.length,
                  itemBuilder: (context, index) {
                    final cat = _filteredCategories[index];
                    return _buildCategoryCard(context, cat['title'], cat['icon'], cat['color'], isSearch: true);
                  },
                ),
            ] else ...[
            // Offers Carousel (Horizontal Scroll)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('العروض الترويجية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildOfferCard('خصم 20%', 'على غسيل السجاد والمفروشات', AppColors.primary),
                    _buildOfferCard('غسيل مجاني', 'اغسل 5 قمصان والسادس مجاناً', AppColors.tertiary),
                    _buildOfferCard('باقة التوفير', 'خصم خاص للاشتراكات الشهرية', Colors.teal),
                  ],
                ),
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
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCategoryCard(context, 'الملابس', Icons.checkroom, AppColors.primary),
                    _buildCategoryCard(context, 'السجاد والمفروشات', Icons.dataset, AppColors.secondary),
                    _buildCategoryCard(context, 'السيارات', Icons.directions_car, AppColors.tertiary),
                    _buildCategoryCard(context, 'تنظيف المكيفات', Icons.ac_unit, Colors.teal),
                    _buildCategoryCard(context, 'عاملات النظافة', Icons.cleaning_services, Colors.pink),
                    _buildCategoryCard(context, 'تنظيف الخزانات', Icons.water_drop, Colors.blueAccent),
                    _buildCategoryCard(context, 'غسيل الألواح الشمسية', Icons.solar_power, Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Reviews
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('آراء العملاء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Consumer<ReviewProvider>(
              builder: (context, reviewProvider, child) {
                final reviews = reviewProvider.reviews;
                if (reviews.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: reviews.map((review) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.lightBlue,
                                child: Icon(Icons.person, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              ...List.generate(5, (index) => Icon(
                                Icons.star, 
                                color: index < review.rating ? Colors.amber : Colors.grey.shade300, 
                                size: 16
                              )),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(review.comment, style: const TextStyle(color: Colors.black87)),
                        ],
                      ),
                    ),
                  )).toList(),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    ),
    );
  }
}
