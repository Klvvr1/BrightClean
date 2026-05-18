import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_styles.dart';
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
      'color': AppColors.secondary, // Avoided hardcoded Colors.teal
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
      'color': AppColors.primary, // Avoided hardcoded teal
      'subtitle': 'غسيل وتطهير فلاتر ووحدات المكيف لزيادة الكفاءة'
    },
    {
      'title': 'عاملات النظافة',
      'icon': Icons.cleaning_services,
      'color': AppColors.secondary, // Avoided hardcoded pink
      'subtitle': 'عاملات نظافة محترفات ومدربات بنظام الساعات'
    },
    {
      'title': 'تنظيف الخزانات',
      'icon': Icons.water_drop,
      'color': AppColors.tertiary, // Avoided hardcoded blueAccent
      'subtitle': 'تعقيم وغسيل الخزانات العلوية والسفلية لحمايتكم'
    },
    {
      'title': 'غسيل الألواح الشمسية',
      'icon': Icons.solar_power,
      'color': AppColors.primary, // Avoided hardcoded orange
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

    // Auto-scroll the reviews banner every 4 seconds
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
    final theme = Theme.of(context);
    
    return Container(
      width: isSearch ? null : 120,
      margin: EdgeInsets.only(left: isSearch ? 0 : AppSpacing.md),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceDetailsScreen(serviceType: title),
            ),
          );
        },
        child: Container(
          decoration: AppStyles.surface(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildOfferCard(BuildContext context, String title, String subtitle, Color bgColor, {bool isCarousel = false}) {
    final theme = Theme.of(context);
    
    return Container(
      width: isCarousel ? null : 280,
      margin: EdgeInsets.only(
        left: isCarousel ? AppSpacing.sm : AppSpacing.md,
        right: isCarousel ? AppSpacing.sm : 0,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.getMd(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: theme.textTheme.titleLarge?.copyWith(color: AppColors.white)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle, 
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.8)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalCategoryCard(BuildContext context, Map<String, dynamic> cat) {
    final theme = Theme.of(context);
    final Color catColor = cat['color'] as Color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: AppStyles.surface(context),
      child: ClipRRect(
        borderRadius: AppRadius.card,
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.1),
                      borderRadius: AppRadius.button,
                      border: Border.all(
                        color: catColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      size: 28,
                      color: catColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat['title'] as String,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          cat['subtitle'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('برايت كلين', style: theme.textTheme.headlineSmall),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () => context.push('/notifications')),
          Consumer<CartProvider>(
            builder: (context, cart, child) => Badge(
              label: Text(cart.itemCount.toString()),
              isLabelVisible: cart.itemCount > 0,
              backgroundColor: AppColors.error,
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: AppRadius.input,
                  border: Border.all(
                    color: _isSearching ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    width: _isSearching ? 1.5 : 1,
                  ),
                  boxShadow: _isSearching ? AppShadows.getSm(context) : null,
                ),
                child: TextField(
                  controller: _searchController,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن خدمات...',
                    prefixIcon: Icon(Icons.search, color: _isSearching ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    suffixIcon: _isSearching
                        ? IconButton(
                            icon: Icon(Icons.clear, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                            onPressed: () {
                              _searchController.clear();
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            if (_isSearching) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('نتائج البحث', style: theme.textTheme.titleLarge),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_filteredCategories.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text('لا توجد نتائج تطابق بحثك', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('العروض الترويجية', style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: AppSpacing.md),
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
                      context,
                      offer['title'] as String,
                      offer['subtitle'] as String,
                      offer['color'] as Color,
                      isCarousel: true,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Categories (Vertical Scroll)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('الخدمات المتاحة', style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _allCategories.length,
              itemBuilder: (context, index) {
                final cat = _allCategories[index];
                return _buildVerticalCategoryCard(context, cat);
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Reviews Carousel (Auto-scrolling Horizontal View)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('آراء العملاء', style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: AppSpacing.md),
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
                          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: AppStyles.surface(context),
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
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(review.userName, style: theme.textTheme.labelLarge),
                                  const Spacer(),
                                  ...List.generate(5, (starIdx) {
                                    if ((starIdx + 1) <= displayRating) {
                                      return const Icon(Icons.star, color: AppColors.warning, size: 14);
                                    } else if (displayRating > starIdx && displayRating < (starIdx + 1)) {
                                      return const Icon(Icons.star_half, color: AppColors.warning, size: 14);
                                    } else {
                                      return Icon(Icons.star, color: Colors.grey.shade300, size: 14);
                                    }
                                  }),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  review.comment, 
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                  ),
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
            const SizedBox(height: AppSpacing.xxl),
          ],
        ],
      ),
    ),
  );
}
}
