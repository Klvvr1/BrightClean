import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/network/api_client.dart';
import '../data/providers/review_provider.dart';
import '../domain/models/review.dart';

class AgentSelectionScreen extends StatefulWidget {
  const AgentSelectionScreen({super.key});

  @override
  State<AgentSelectionScreen> createState() => _AgentSelectionScreenState();
}

class _AgentSelectionScreenState extends State<AgentSelectionScreen> {
  List<Map<String, dynamic>> _agents = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiClient = BaseApiClient();
      final response = await apiClient.get('/api/users/agents');
      if (response is List) {
        setState(() {
          _agents = response.where((a) {
            // Validate required fields exist and are of correct type
            if (a == null || a is! Map) return false;
            final idValue = a['id'];
            final nameValue = a['businessName'];
            if (idValue == null || nameValue == null) return false;
            // Accept int or parseable String for id
            if (idValue is! int && (idValue is! String || int.tryParse(idValue) == null)) return false;
            return true;
          }).map((a) {
            // Safe extraction with type coercion
            final idValue = a['id'];
            final id = idValue is int ? idValue : int.parse(idValue as String);
            final businessName = (a['businessName'] ?? '').toString();
            
            // Map realistic mock info depending on the agent ID
            String address = 'شارع بيروت، حولي';
            String workingHours = '8:00 ص - 10:00 م';
            double rating = 4.8;
            int reviewCount = 85;
            
            if (id == 1) {
              address = 'شارع تونس، حولي (بجانب مجمع البحر)';
              workingHours = '7:30 ص - 11:00 م';
              rating = 4.9;
              reviewCount = 124;
            } else if (id == 2) {
              address = 'شارع بغداد، السالمية';
              workingHours = '8:00 ص - 10:00 م';
              rating = 4.7;
              reviewCount = 68;
            } else {
              address = 'شارع عمان، السالمية';
              workingHours = '9:00 ص - 9:30 م';
              rating = 4.5;
              reviewCount = 42;
            }

            return {
              'id': id,
              'businessName': businessName,
              'address': address,
              'workingHours': workingHours,
              'rating': rating,
              'reviewCount': reviewCount,
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'فشل في تحميل قائمة الوكلاء';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطأ في الاتصال بالخادم. يرجى المحاولة مرة أخرى.';
        _isLoading = false;
      });
    }
  }

  void _showLaundryDetailsBottomSheet(BuildContext context, Map<String, dynamic> agent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Get reviews from provider or use default seeded ones
    final providerReviews = Provider.of<ReviewProvider>(context, listen: false).reviews;
    
    // Customize mock reviews specific to the laundry agent, fallback if provider is empty
    final List<Review> agentReviews = providerReviews.isNotEmpty ? providerReviews : [
      Review(
        userName: 'أحمد محمد',
        comment: 'غسيل ممتاز جداً وسرعة في استلام وتوصيل الملابس. أنصح بالتعامل معهم.',
        rating: 5.0,
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Review(
        userName: 'سارة عمر',
        comment: 'الملابس نظيفة ومعطرة والتعامل راقي. السعر مناسب مقارنة بالجودة.',
        rating: 4.5,
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Review(
        userName: 'خالد عبدالله',
        comment: 'كي الملابس ممتاز، لكن التأخير في التوصيل لبعض الوقت.',
        rating: 4.0,
        date: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handlebar
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'معلومات المغسلة',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              
              // Content Scroll
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Laundry Details Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.background,
                          borderRadius: AppRadius.card,
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(context, Icons.storefront, 'الاسم التجاري', agent['businessName'] as String),
                            const Divider(height: 24),
                            _buildDetailRow(context, Icons.location_on_outlined, 'العنوان', agent['address'] as String),
                            const Divider(height: 24),
                            _buildDetailRow(context, Icons.access_time, 'أوقات العمل', agent['workingHours'] as String),
                            const Divider(height: 24),
                            _buildDetailRow(context, Icons.star_outline, 'التقييم العام', '${agent['rating']} ⭐ (${agent['reviewCount']} تقييم)'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Reviews Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'تقييمات العملاء',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.primary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${agent['rating']} / 5.0',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      // Reviews List
                      if (agentReviews.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.xl),
                            child: Text('لا توجد تقييمات بعد لهذه المغسلة', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: agentReviews.length,
                          itemBuilder: (context, index) {
                            final review = agentReviews[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: AppStyles.surface(context),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: isDark ? Colors.white10 : AppColors.primary.withValues(alpha: 0.1),
                                            child: Icon(Icons.person, size: 20, color: isDark ? Colors.white : AppColors.primary),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Text(
                                            review.userName,
                                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: List.generate(5, (starIdx) {
                                          return Icon(
                                            Icons.star,
                                            color: starIdx < review.rating.floor() ? AppColors.warning : Colors.grey.shade300,
                                            size: 14,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    review.comment,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              
              // Select Action Button at Bottom
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ElevatedButton(
                    onPressed: () {
                      final navigator = Navigator.of(context);
                      navigator.pop(); // Close BottomSheet
                      navigator.pop(agent); // Pop SelectionScreen returning selected agent
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('تأكيد اختيار هذه المغسلة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: isDark ? Colors.white : AppColors.primary, size: 22),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المغاسل المتوفرة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 60),
                        const SizedBox(height: AppSpacing.md),
                        Text(_error!, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton(
                          onPressed: _loadAgents,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : _agents.isEmpty
                  ? const Center(
                      child: Text('لا توجد مغاسل متوفرة حالياً في النظام.', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _agents.length,
                      itemBuilder: (context, index) {
                        final agent = _agents[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: AppStyles.surface(context),
                          clipBehavior: Clip.hardEdge,
                          child: InkWell(
                            onTap: () => _showLaundryDetailsBottomSheet(context, agent),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                children: [
                                  // Logo Avatar
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.storefront, size: 30, color: isDark ? Colors.white : AppColors.primary),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  
                                  // Information
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          agent['businessName'] as String,
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: AppColors.warning, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${agent['rating']} (${agent['reviewCount']} تقييم)',
                                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), size: 14),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                agent['address'] as String,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  
                                  // Action Icon
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
