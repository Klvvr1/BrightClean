import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
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

  late final PageController _offersPageController;
  Timer? _offersTimer;
  int _currentOfferPage = 0;

  late final PageController _reviewsPageController;
  Timer? _reviewsTimer;
  int _currentReviewPage = 0;

  final List<Map<String, dynamic>> _offers = [
    {
      'title': 'خصم 20%',
      'subtitle': 'على غسيل السجاد والمفروشات',
      'color': AppColors.primary,
    },
    {
      'title': 'غسيل مجاني',
      'subtitle': 'اغسل 5 قمصان والسادس مجاناً',
      'color': AppColors.tertiary,
    },
    {
      'title': 'باقة التوفير',
      'subtitle': 'خصم خاص للاشتراكات الشهرية',
      'color': Colors.teal,
    },
  ];

  final List<Map<String, dynamic>> _allCategories = [
    {
      'title': 'الملابس',
      'icon': Icons.checkroom,
      'color': AppColors.primary,
      'subtitle': 'غسيل وكي ملابس بأعلى معايير الجودة والنظافة'
    },
    {
      'title': 'السجاد والمفروشات',
      'icon': Icons.dataset,
      'color': AppColors.secondary,
      'subtitle': 'تنظيف عميق وتطهير للسجاد والموكيت والمفروشات'
    },
    {
      'title': 'السيارات',
      'icon': Icons.directions_car,
      'color': AppColors.tertiary,
      'subtitle': 'تلميع وغسيل خارجي وداخلي متكامل عند باب بيتك'
    },
    {
      'title': 'تنظيف المكيفات',
      'icon': Icons.ac_unit,
      'color': Colors.teal,
      'subtitle': 'غسيل وتطهير فلاتر ووحدات المكيف لزيادة الكفاءة'
    },
    {
      'title': 'عاملات النظافة',
      'icon': Icons.cleaning_services,
      'color': Colors.pink,
      'subtitle': 'عاملات نظافة محترفات ومدربات بنظام الساعات'
    },
    {
      'title': 'تنظيف الخزانات',
      'icon': Icons.water_drop,
      'color': Colors.blueAccent,
      'subtitle': 'تعقيم وغسيل الخزانات العلوية والسفلية لحمايتكم'
    },
    {
      'title': 'غسيل الألواح الشمسية',
      'icon': Icons.solar_power,
      'color': Colors.orange,
      'subtitle': 'تنظيف دوري بمواد خاصة لزيادة كفاءة الألواح'
    },
  ];

  List<Map<String, dynamic>> get _filteredCategories {
    if (_searchController.text.isEmpty) return [];
    return _allCategories.where((cat) => cat['title'].toString().contains(_searchController.text)).toList();
  }

  @override
  void initState() {
    super.initState();
    _offersPageController = PageController(viewportFraction: 0.88, initialPage: 0);
    _reviewsPageController = PageController(viewportFraction: 0.88, initialPage: 0);
    _searchController.addListener(() {
      setState(() {
        _isSearching = _searchController.text.isNotEmpty;
      });
    });

    // Auto-scroll the offers banner every 3 seconds
    _offersTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_offersPageController.hasClients) {
        _currentOfferPage++;
        if (_currentOfferPage >= _offers.length) {
          _currentOfferPage = 0;
        }
        _offersPageController.animateToPage(
          _currentOfferPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });

    // Auto-scroll the reviews banner every 4 seconds (slower to allow reading text)
    _reviewsTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_reviewsPageController.hasClients) {
        final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
        final reviewCount = reviewProvider.reviews.length;
        if (reviewCount > 0) {
          _currentReviewPage++;
          if (_currentReviewPage >= reviewCount) {
            _currentReviewPage = 0;
          }
          _reviewsPageController.animateToPage(
            _currentReviewPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _offersTimer?.cancel();
    _offersPageController.dispose();
    _reviewsTimer?.cancel();
    _reviewsPageController.dispose();
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

  Widget _buildOfferCard(String title, String subtitle, Color bgColor, {bool isCarousel = false}) {
    return Container(
      width: isCarousel ? null : 280,
      margin: EdgeInsets.only(
        left: isCarousel ? 6 : 16,
        right: isCarousel ? 6 : 0,
      ),
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

  Widget _buildVerticalCategoryCard(BuildContext context, Map<String, dynamic> cat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderCol = isDark ? Colors.white12 : Colors.grey.shade100;
    final textCol = isDark ? Colors.white : AppColors.textMain;
    final subtitleCol = isDark ? Colors.white70 : AppColors.textLight;
    final Color catColor = cat['color'] as Color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceDetailsScreen(serviceType: cat['title']),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          catColor.withValues(alpha: 0.15),
                          catColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: catColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      size: 28,
                      color: catColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat['title'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textCol,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cat['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleCol,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: isDark ? Colors.white54 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.background,
      appBar: AppBar(
        title: const Text('برايت كلين', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : AppColors.primary,
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
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
            // Offers Carousel (Auto-scrolling Horizontal View)
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
                child: PageView.builder(
                  controller: _offersPageController,
                  itemCount: _offers.length,
                  onPageChanged: (int index) {
                    _currentOfferPage = index;
                  },
                  itemBuilder: (context, index) {
                    final offer = _offers[index];
                    return _buildOfferCard(
                      offer['title'] as String,
                      offer['subtitle'] as String,
                      offer['color'] as Color,
                      isCarousel: true,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Categories (Vertical Scroll)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('الخدمات المتاحة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _allCategories.length,
              itemBuilder: (context, index) {
                final cat = _allCategories[index];
                return _buildVerticalCategoryCard(context, cat);
              },
            ),
            const SizedBox(height: 24),

            // Reviews Carousel (Auto-scrolling Horizontal View)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('آراء العملاء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Consumer<ReviewProvider>(
              builder: (context, reviewProvider, child) {
                final reviews = reviewProvider.reviews;
                if (reviews.isEmpty) return const SizedBox.shrink();
                return SizedBox(
                  height: 140,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      },
                    ),
                    child: PageView.builder(
                      controller: _reviewsPageController,
                      itemCount: reviews.length,
                      onPageChanged: (int index) {
                        _currentReviewPage = index;
                      },
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        // Publicly only display the service rating (keeping driver rating private/internal)
                        final displayRating = review.serviceRating ?? review.rating;
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.lightBlue,
                                    child: Icon(Icons.person, color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const Spacer(),
                                  ...List.generate(5, (starIdx) => Icon(
                                    Icons.star, 
                                    color: starIdx < displayRating ? Colors.amber : Colors.grey.shade300, 
                                    size: 14
                                  )),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: Text(
                                  review.comment, 
                                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
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
