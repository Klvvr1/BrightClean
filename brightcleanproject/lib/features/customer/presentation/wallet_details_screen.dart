import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_styles.dart';
import 'package:file_picker/file_picker.dart';
import '../data/providers/wallet_provider.dart';
import 'customer_bank_accounts.dart';

class WalletDetailsScreen extends StatelessWidget {
  final String balance;
  final VoidCallback? onDepositSuccess;

  const WalletDetailsScreen({super.key, required this.balance, this.onDepositSuccess});


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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/wallet_realistic_16x9.png',
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
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
            ...customerBankAccounts.map(
              (bank) => _buildDepositMethod(
                context,
                title: 'ايداع عن طريق ${bank['name']}',
                icon: Icons.account_balance,
                onTap: () => _showDepositDialog(
                  context,
                  bank['name']!,
                  bank['account']!,
                ),
              ),
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

  void _showDepositDialog(
      BuildContext context, String method, String accountNumber) {
    String? selectedFileName;
    String? selectedFilePath;
    bool isPicking = false;
    bool isSubmitting = false;
    final amountController = TextEditingController();
    final operationNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          amountController.dispose();
          operationNumberController.dispose();
          return true;
        },
        child: StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);

            // زر الإرسال يُفعَّل فقط عند توفر المبلغ والملف
            final canSubmit = amountController.text.trim().isNotEmpty &&
                double.tryParse(amountController.text.trim()) != null &&
                (double.tryParse(amountController.text.trim()) ?? 0) > 0 &&
                selectedFileName != null &&
                selectedFilePath != null &&
                !isSubmitting;

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
                      accountNumber,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── حقل المبلغ (جديد) ──
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'قيمة الإيداع',
                        hintText: '0.00',
                        suffixText: 'ريال',
                        border: OutlineInputBorder(borderRadius: AppRadius.button),
                        prefixIcon: const Icon(Icons.payments_outlined),
                      ),
                      onChanged: (_) => setState(() {}),
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
                            type: FileType.any,
                          );

                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            final ext = file.extension?.toLowerCase() ?? '';

                            if (['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'].contains(ext)) {
                              setState(() {
                                selectedFileName = file.name;
                                selectedFilePath = file.path;
                              });
                            } else {
                              setState(() {
                                selectedFileName = null;
                                selectedFilePath = null;
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
                    amountController.dispose();
                    operationNumberController.dispose();
                    Navigator.pop(context);
                  },
                  child: Text('إلغاء', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                ),
                ElevatedButton(
                  onPressed: canSubmit
                      ? () async {
                          if (!context.mounted) return;
                          setState(() => isSubmitting = true);

                          final depositAmount = double.parse(amountController.text.trim());
                          final walletProvider = context.read<WalletProvider>();

                          try {
                            await walletProvider.submitDeposit(
                              amount: depositAmount,
                              proofFilePath: selectedFilePath!,
                              operationNumber: operationNumberController.text.trim().isEmpty
                                  ? null
                                  : operationNumberController.text.trim(),
                            );

                            amountController.dispose();
                            operationNumberController.dispose();

                            if (!context.mounted) return;
                            Navigator.pop(context);

                            onDepositSuccess?.call();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم إيداع ${depositAmount.toStringAsFixed(2)} ريال في محفظتك بنجاح.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            setState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(walletProvider.errorMessage ?? 'فشل الإيداع. يرجى المحاولة مرة أخرى.'),
                                backgroundColor: theme.colorScheme.error,
                              ),
                            );
                          }
                        }
                      : null,
                  child: isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('إيداع'),
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}
