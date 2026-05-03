import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_colors.dart';

class HelpCenterBottomSheet extends StatelessWidget {
  const HelpCenterBottomSheet({super.key});

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@brightclean.com',
      query: 'subject=طلب مساعدة عبر التطبيق', 
    );
    
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح تطبيق البريد الإلكتروني')),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    const String phoneNumber = '+971501234567'; // Preset support number
    const String message = 'مرحباً، أحتاج إلى مساعدة.';
    final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تطبيق واتساب غير مثبت على جهازك')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'مركز المساعدة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'كيف تفضل التواصل معنا؟',
            style: TextStyle(color: AppColors.textLight),
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.email, color: AppColors.primary),
            ),
            title: const Text('البريد الإلكتروني', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('support@brightclean.com'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pop(context);
              _launchEmail(context);
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat, color: Colors.green),
            ),
            title: const Text('واتساب', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('محادثة فورية مع الدعم'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pop(context);
              _launchWhatsApp(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
