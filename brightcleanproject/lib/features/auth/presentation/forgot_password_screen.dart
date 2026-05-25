import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../data/providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _debugOtp;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSendOtp() async {
    if (_emailFormKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final email = _emailController.text.trim();
        final otp = await authProvider.forgotPassword(email);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال رمز التحقق إلى بريدك الإلكتروني'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isOtpSent = true;
            _debugOtp = otp.isNotEmpty ? otp : null;
            // Pre-fill OTP in debug mode for easier testing
            if (otp.isNotEmpty) {
              _otpController.text = otp;
            }
          });
        }
      } catch (e) {
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final errorMsg = authProvider.errorMessage ?? 'فشل إرسال رمز التحقق. يرجى التحقق من البريد الإلكتروني.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _handleResetPassword() async {
    if (_resetFormKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final email = _emailController.text.trim();
        final token = _otpController.text.trim();
        final newPassword = _passwordController.text;

        await authProvider.resetPassword(email, token, newPassword);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إعادة تعيين كلمة المرور بنجاح. يمكنك تسجيل الدخول الآن.'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final errorMsg = authProvider.errorMessage ?? 'رمز التحقق غير صحيح أو منتهي الصلاحية.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعادة تعيين كلمة المرور'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isOtpSent ? _buildResetForm(theme) : _buildEmailForm(theme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(ThemeData theme) {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('email_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.lock_reset,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'نسيت كلمة المرور؟',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'أدخل بريدك الإلكتروني المسجل وسنقوم بإرسال رمز تحقق لإعادة تعيين كلمة المرور الخاصة بك.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          CustomTextField(
            controller: _emailController,
            hintText: 'البريد الإلكتروني',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال البريد الإلكتروني';
              }
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'الرجاء إدخال بريد إلكتروني صالح';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSendOtp,
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('إرسال رمز التحقق'),
          ),
        ],
      ),
    );
  }

  Widget _buildResetForm(ThemeData theme) {
    return Form(
      key: _resetFormKey,
      child: Column(
        key: const ValueKey('reset_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'أدخل رمز التحقق',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'تم إرسال رمز التحقق إلى بريدك الإلكتروني ${_emailController.text}. يرجى إدخال الرمز وكلمة المرور الجديدة.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (_debugOtp != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.button,
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                'رمز التحقق للتجربة: $_debugOtp',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          CustomTextField(
            controller: _otpController,
            hintText: 'رمز التحقق (OTP)',
            prefixIcon: Icons.security_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'الرجاء إدخال رمز التحقق';
              }
              if (value.trim().length != 6) {
                return 'رمز التحقق يتكون من 6 أرقام';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          CustomTextField(
            controller: _passwordController,
            hintText: 'كلمة المرور الجديدة',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال كلمة المرور';
              }
              if (value.length < 8) {
                return 'كلمة المرور يجب أن تتكون من 8 رموز على الأقل';
              }
              if (!value.contains(RegExp(r'[A-Z]'))) {
                return 'يجب أن تحتوي على حرف كبير واحد على الأقل';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          CustomTextField(
            controller: _confirmPasswordController,
            hintText: 'تأكيد كلمة المرور الجديدة',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء تأكيد كلمة المرور';
              }
              if (value != _passwordController.text) {
                return 'كلمة المرور غير متطابقة';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleResetPassword,
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('إعادة تعيين كلمة المرور'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () {
              setState(() {
                _isOtpSent = false;
                _otpController.clear();
                _passwordController.clear();
                _confirmPasswordController.clear();
              });
            },
            child: const Text('تغيير البريد الإلكتروني'),
          ),
        ],
      ),
    );
  }
}
