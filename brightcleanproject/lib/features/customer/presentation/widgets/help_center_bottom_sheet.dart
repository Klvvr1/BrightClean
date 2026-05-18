import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_radius.dart';

class HelpCenterBottomSheet extends StatelessWidget {
  const HelpCenterBottomSheet({super.key});

  Future<void> _launchEmail(ScaffoldMessengerState messenger) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@brightclean.com',
      queryParameters: {'subject': 'طلب مساعدة عبر التطبيق'},
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('لا يمكن فتح تطبيق البريد الإلكتروني')),
      );
    }
  }

  Future<void> _launchWhatsApp(ScaffoldMessengerState messenger) async {
    const String phoneNumber = '971501234567'; // Removed '+' prefix
    const String message = 'مرحباً، أحتاج إلى مساعدة.';
    final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('تطبيق واتساب غير مثبت على جهازك')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.bottomSheet,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'مركز المساعدة',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'كيف تفضل التواصل معنا؟',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: AppSpacing.xxl),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.email, color: theme.colorScheme.primary),
            ),
            title: Text('البريد الإلكتروني', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text('support@brightclean.com', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            onTap: () {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              _launchEmail(messenger);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat, color: Colors.green),
            ),
            title: Text('واتساب', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text('محادثة فورية مع الدعم', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            onTap: () {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              _launchWhatsApp(messenger);
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
