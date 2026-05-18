import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_styles.dart';
import 'package:file_picker/file_picker.dart';

class WalletDetailsScreen extends StatelessWidget {
  final String balance;

  const WalletDetailsScreen({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('محفظتي'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance Card
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: AppRadius.card,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.md),
                child: Column(
                  children: [
                    Text(
                      'الرصيد الحالي',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      balance,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'شحن الرصيد',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'اختر وسيلة الإيداع المناسبة لك:',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Deposit Methods
            _buildDepositMethod(
              context,
              title: 'ايداع عن طريق العمقي',
              icon: Icons.account_balance,
              onTap: () => _showDepositDialog(context, 'العمقي'),
            ),
            _buildDepositMethod(
              context,
              title: 'ايداع عن طريق الكريمي ',
              icon: Icons.payments,
              onTap: () => _showDepositDialog(context, 'الكريمي'),
            ),
            _buildDepositMethod(
              context,
              title: 'ايداع عن طريق القطيبي',
              icon: Icons.account_balance_wallet,
              onTap: () => _showDepositDialog(context, 'القطيبي'),
            ),
            _buildDepositMethod(
              context,
              title: 'ايداع عن طريق البسيري',
              icon: Icons.money,
              onTap: () => _showDepositDialog(context, 'البسيري'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepositMethod(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: AppStyles.surface(context),
      clipBehavior: Clip.hardEdge,
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.right,
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        onTap: onTap,
      ),
    );
  }

  void _showDepositDialog(BuildContext context, String method) {
    String? selectedFileName;
    String? selectedFilePath;
    List<int>? selectedFileBytes;
    bool isPicking = false;
    final operationNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text('إيداع عبر $method'),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('يرجى تحويل المبلغ إلى الحساب التالي:', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.sm),
                    SelectableText(
                      '123456789',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('يجب إرفاق صورة السند أو ملف PDF/DOC لتأكيد العملية.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (isPicking) return;
                        setState(() => isPicking = true);
                        
                        try {
                          final result = await FilePicker.pickFiles(
                            type: FileType.any, // Avoid native filter crash on Windows/Android
                          );
                          
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            final ext = file.extension?.toLowerCase() ?? '';
                            
                            // Validate extension in Dart instead of native
                            if (['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'].contains(ext)) {
                              setState(() {
                                selectedFileName = file.name;
                                selectedFilePath = file.path;
                                selectedFileBytes = file.bytes;
                              });
                            } else {
                              setState(() {
                                selectedFileName = null;
                                selectedFilePath = null;
                                selectedFileBytes = null;
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('يرجى اختيار صورة، ملف PDF، أو مستند DOC.'),
                                    backgroundColor: theme.colorScheme.error,
                                  ),
                                );
                              }
                            }
                          }
                        } catch (e) {
                          debugPrint('Error picking file: $e');
                        } finally {
                          setState(() => isPicking = false);
                        }
                      },
                      icon: isPicking 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                          : const Icon(Icons.attach_file),
                      label: const Text('إرفاق ملف'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    if (selectedFileName != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'الملف المرفق: $selectedFileName',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.success, 
                          fontWeight: FontWeight.bold, 
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: operationNumberController,
                      decoration: InputDecoration(
                        hintText: 'رقم العملية (اختياري)',
                        border: OutlineInputBorder(borderRadius: AppRadius.button),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    operationNumberController.dispose();
                    Navigator.pop(context);
                  },
                  child: Text('إلغاء', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedFileName == null) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('يجب إرفاق صورة السند أو ملف PDF/DOC أولاً.'),
                          backgroundColor: theme.colorScheme.error,
                        ),
                      );
                      return;
                    }
                    // Implement submission logic
                    final operationNumber = operationNumberController.text.trim();

                    debugPrint('Deposit submission initiated: path=$selectedFilePath, bytes=${selectedFileBytes?.length}, op=$operationNumber');

                    // Note: Use selectedFilePath, selectedFileBytes, and operationNumber for actual upload
                    operationNumberController.dispose();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('تم إرسال طلب الإيداع بنجاح، سيتم التأكد قريباً.'), backgroundColor: theme.colorScheme.primary),
                    );
                  },
                  child: const Text('إرسال'),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}
