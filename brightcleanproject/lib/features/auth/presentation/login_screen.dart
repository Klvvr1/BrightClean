import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/database/database_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // GlobalKey to identify and manage the Form's state
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // State variable to manage the loading indicator
  bool _isLoading = false;
  bool _loginInProgress = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_loginInProgress) return;
    _loginInProgress = true;

    // Validate the form fields based on provided validators
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Simulate a network request taking 1.5 seconds
        await Future.delayed(const Duration(milliseconds: 1500));

        // DB Authentication Logic
        final user = await DatabaseHelper.instance.loginUser(
          _phoneController.text,
          _passwordController.text,
        );

        // After async gaps, check if the widget is still mounted
        if (mounted) {
          if (user != null) {
            // If needed, check user['role'] to route appropriately
            context.go('/customer_home');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('خطأ في رقم الجوال أو كلمة المرور'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ أثناء تسجيل الدخول: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        _loginInProgress = false;
      }
    } else {
      _loginInProgress = false;
    }
  }

  Widget _buildDebugLoginSection() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'حسابات تجريبية (للتطوير فقط)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _debugLoginButton('مدير النظام', '0500000000', 'Password123'),
            _debugLoginButton('المدير', '0511111111', 'Password123'),
            _debugLoginButton('عميل', '0522222222', 'Password123'),
            _debugLoginButton('مندوب التوصيل', '0533333333', 'Password123'),
          ],
        ),
      ],
    );
  }

  Widget _debugLoginButton(String role, String phone, String password) {
    return ActionChip(
      label: Text(role),
      onPressed: () {
        _phoneController.text = phone;
        _passwordController.text = password;
        // Small delay to ensure UI updates fields before logging in
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted || _loginInProgress) return;
          _handleLogin();
        });
      },
      backgroundColor: AppColors.primary.withOpacity(0.1),
      side: const BorderSide(color: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          // Place ConstrainedBox outside SingleChildScrollView for better scrolling and layout stability
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              // Wrap the widget tree with a Form widget to provide validation capabilities
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.water_drop,
                      size: 80,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'تسجيل الدخول',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'مرحباً بك مجدداً في برايت كلين',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 48),
                    CustomTextField(
                      controller: _phoneController,
                      hintText: 'رقم الهاتف',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال رقم الهاتف';
                        }
                        // Validate exact constraint
                        if (value.length > 10) {
                          return 'رقم الهاتف يجب ألا يتجاوز 10 أرقام';
                        }
                        // Check for any letters
                        if (value.contains(RegExp(r'[a-zA-Z]'))) {
                          return 'الرجاء إدخال رقم صالح';
                        }
                        // Simple regex to validate phone form
                        if (!RegExp(r'^[0-9]{9,10}$').hasMatch(value)) {
                          return 'الرجاء إدخال رقم هاتف صالح (9 أو 10 أرقام)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'كلمة المرور',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال كلمة المرور';
                        }
                        // Validate password length
                        if (value.length < 8) {
                          return 'كلمة المرور يجب أن تتكون من 8 أحرف على الأقل';
                        }
                        // Validate capital letter
                        if (!value.contains(RegExp(r'[A-Z]'))) {
                          return 'يجب أن تحتوي كلمة المرور على حرف كبير واحد على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      // Disable button interaction when loading
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('دخول'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'ليس لديك حساب؟',
                          style: TextStyle(color: AppColors.textMain),
                        ),
                        TextButton(
                          onPressed: () {
                            context.push('/role_selection');
                          },
                          child: const Text('تسجيل جديد'),
                        ),
                      ],
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 24),
                      _buildDebugLoginSection(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
