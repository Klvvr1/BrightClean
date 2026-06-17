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

  bool _isUserTouchingCarousel = false;

  final List<Map<String, dynamic>> _offers = [
    {
      'title': 'خصم 20%',
      'subtitle': 'على قيمة الفاتورة لجميع الخدمات',
      'image': 'assets/images/offer_discount.png',
    },
    {
      'title': 'خدمات متكاملة',
      'subtitle': 'كل ما تحتاجه لنظافة منزلك وسيارتك في تطبيق واحد.',
      'image': 'assets/images/offer_services.png',
    },
    {
      'title': 'راحتك أولويتنا',
      'subtitle': 'اختر الخدمة، حدد الموعد، واترك الباقي علينا.',
      'image': 'assets/images/offer_app_marketing.png',
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
    return _allCategories
        .where(
            (cat) => cat['title'].toString().contains(_searchController.text))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _currentOfferPage =
        3000; // Start at a large number for infinite scroll backwards
    _offersPageController =
        PageController(viewportFraction: 0.88, initialPage: _currentOfferPage);
    _searchController.addListener(() {
      setState(() {
        _isSearching = _searchController.text.isNotEmpty;
      });
    });

    // Auto-scroll the offers banner every 4 seconds
    _offersTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_offersPageController.hasClients && !_isUserTouchingCarousel) {
        _offersPageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _offersTimer?.cancel();
    _offersPageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildCategoryCard(
      BuildContext context, String title, IconData icon, Color color,
      {bool isSearch = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                Icon(icon, size: 40, color: isDark ? Colors.white : color),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildOfferCard(
      BuildContext context, String title, String subtitle, String imagePath,
      {bool isCarousel = false}) {
    final theme = Theme.of(context);

    return Container(
      width: isCarousel ? null : 280,
      margin: EdgeInsets.only(
        left: isCarousel ? AppSpacing.sm : AppSpacing.md,
        right: isCarousel ? AppSpacing.sm : 0,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.getMd(context),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
            // Dark Gradient Overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Text Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    width: 200, // Limit width so it doesn't span full card
                    child: Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.9)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // CTA Button
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: AppRadius.button,
                        boxShadow: AppShadows.getSm(context),
                      ),
                      child: Text(
                        'اطلب الآن',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalCategoryCard(
      BuildContext context, Map<String, dynamic> cat) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color catColor = cat['color'] as Color;
    final Color displayColor = isDark ? Colors.white : catColor;

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
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
                  builder: (context) =>
                      ServiceDetailsScreen(serviceType: cat['title']),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color:
                          displayColor.withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: AppRadius.button,
                      border: Border.all(
                        color:
                            displayColor.withValues(alpha: isDark ? 0.3 : 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      size: 28,
                      color: displayColor,
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
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
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
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.05),
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
          IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => context.push('/notifications')),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: AppRadius.input,
                  border: Border.all(
                    color: _isSearching
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    width: _isSearching ? 1.5 : 1,
                  ),
                  boxShadow: _isSearching ? AppShadows.getSm(context) : null,
                ),
                child: TextField(
                  controller: _searchController,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن خدمات...',
                    prefixIcon: Icon(Icons.search,
                        color: _isSearching
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.4)),
                    suffixIcon: _isSearching
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4)),
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
                    child: Text('لا توجد نتائج تطابق بحثك',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey)),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _filteredCategories.length,
                  itemBuilder: (context, index) {
                    final cat = _filteredCategories[index];
                    return _buildCategoryCard(
                        context, cat['title'], cat['icon'], cat['color'],
                        isSearch: true);
                  },
                ),
            ] else ...[
              // Offers Carousel (Auto-scrolling Horizontal View)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child:
                    Text('العروض الترويجية', style: theme.textTheme.titleLarge),
              ),
              const SizedBox(height: AppSpacing.md),
              Listener(
                onPointerDown: (_) =>
                    setState(() => _isUserTouchingCarousel = true),
                onPointerUp: (_) =>
                    setState(() => _isUserTouchingCarousel = false),
                onPointerCancel: (_) =>
                    setState(() => _isUserTouchingCarousel = false),
                child: SizedBox(
                  height: 160,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      },
                    ),
                    child: PageView.builder(
                      controller: _offersPageController,
                      itemCount: null, // Infinite
                      onPageChanged: (int index) {
                        setState(() {
                          _currentOfferPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final offer = _offers[index % _offers.length];
                        return _buildOfferCard(
                          context,
                          offer['title'] as String,
                          offer['subtitle'] as String,
                          offer['image'] as String,
                          isCarousel: true,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _offers.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width:
                        (_currentOfferPage % _offers.length) == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: (_currentOfferPage % _offers.length) == index
                          ? theme.colorScheme.primary
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Categories (Vertical Scroll)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child:
                    Text('الخدمات المتاحة', style: theme.textTheme.titleLarge),
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
            ],
          ],
        ),
      ),
    );
  }
}
