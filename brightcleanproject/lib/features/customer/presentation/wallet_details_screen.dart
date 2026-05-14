import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:file_picker/file_picker.dart';

class WalletDetailsScreen extends StatelessWidget {
  final String balance;

  const WalletDetailsScreen({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محفظتي'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 32.0, horizontal: 16.0),
                child: Column(
                  children: [
                    const Text(
                      'الرصيد الحالي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      balance,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'شحن الرصيد',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            const Text(
              'اختر وسيلة الإيداع المناسبة لك:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 24),

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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          textAlign: TextAlign.right,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showDepositDialog(BuildContext context, String method) {
    String? selectedFileName;
    bool isPicking = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text('إيداع عبر $method'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('يرجى تحويل المبلغ إلى الحساب التالي:'),
                    const SizedBox(height: 8),
                    const SelectableText(
                      '123456789',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    const Text('يجب إرفاق صورة السند أو ملف PDF/DOC لتأكيد العملية.'),
                    const SizedBox(height: 12),
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
                              });
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('يرجى اختيار صورة، ملف PDF، أو مستند DOC.'),
                                    backgroundColor: Colors.red,
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
                      label: const Text('إرفاق ملف (صورة، PDF، أو DOC)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightBlue,
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                    if (selectedFileName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'الملف المرفق: $selectedFileName',
                        style: const TextStyle(
                          color: AppColors.success, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 12
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'رقم العملية (اختياري)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedFileName == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('يجب إرفاق صورة السند أو ملف PDF/DOC أولاً.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    // Implement submission logic
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال طلب الإيداع بنجاح، سيتم التأكد قريباً.')),
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
