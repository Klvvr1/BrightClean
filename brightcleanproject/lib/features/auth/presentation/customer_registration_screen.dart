import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import 'package:provider/provider.dart';
import '../data/providers/auth_provider.dart';
import '../data/models/register_client_model.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/widgets/map_picker_screen.dart';

class CustomerRegistrationScreen extends StatefulWidget {
  const CustomerRegistrationScreen({super.key});

  @override
  State<CustomerRegistrationScreen> createState() =>
      _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState
    extends State<CustomerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();

  String? _selectedGender;
  String? _selectedAddress;
  LatLng? _selectedCoordinates;
  bool _isTermsAccepted = false;
  bool _isLoading = false;
  bool _hasAttemptedSubmit = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDOB() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedCoordinates = result['coordinates'] as LatLng;
        _selectedAddress = result['address'] as String;
      });
    }
  }

  Future<void> _submitForm() async {
    setState(() => _hasAttemptedSubmit = true);

    if (!_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('الرجاء الموافقة على الشروط والأحكام أولاً'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_selectedAddress == null || _selectedCoordinates == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى تحديد موقعك على الخريطة أولاً'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final String mappedGender = _selectedGender == 'M' ? 'Male' : 'Female';
        final clientModel = RegisterClientModel(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNo: _phoneController.text.trim(),
          dateOfBirth: _dobController.text.trim(),
          gender: mappedGender,
        );

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.registerClient(clientModel);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم التسجيل بنجاح! جاري تحويلك...'),
              backgroundColor: AppColors.success,
            ),
          );
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            context.go('/login');
          }
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'حدث خطأ أثناء التسجيل';
          if (e is ServerException) {
            errorMessage = e.message ?? errorMessage;
          } else {
            errorMessage = '$errorMessage: $e';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
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

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال هذا الحقل';
    }
    if (!RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$').hasMatch(value)) {
      return 'يجب أن يحتوي على أحرف فقط';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال رقم الهاتف';
    }
    if (value.length != 9) {
      return 'رقم الهاتف يجب أن يتكون من 9 أرقام بالضبط';
    }
    if (value.contains(RegExp(r'[a-zA-Z]'))) {
      return 'الرجاء إدخال رقم صالح';
    }
    if (!RegExp(r'^[0-9]{9}$').hasMatch(value)) {
      return 'الرجاء إدخال رقم هاتف يمني صالح مكون من 9 أرقام';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }
    final email = value.trim().toLowerCase();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'الرجاء إدخال بريد إلكتروني صحيح';
    }
    final allowedDomains = ['gmail.com', 'hotmail.com', 'yahoo.com', 'outlook.com'];
    final parts = email.split('@');
    if (parts.length != 2 || !allowedDomains.contains(parts[1])) {
      return 'البريد الإلكتروني يجب أن يكون من النطاقات المسموحة فقط (gmail.com, hotmail.com, yahoo.com, outlook.com)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }
    if (value.length < 8) {
      return 'كلمة المرور يجب أن لا تقل عن 8 رموز';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'يجب أن تحتوي على حرف كبير واحد على الأقل';
    }
    if (!RegExp(r'[a-zA-Z\u0600-\u06FF]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value)) {
      return 'يجب أن تحتوي على حرف ورقم على الأقل';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء تأكيد كلمة المرور';
    }
    if (value != _passwordController.text) {
      return 'كلمة المرور غير متطابقة';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل عميل جديد')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _firstNameController,
                          hintText: 'الاسم الأول',
                          validator: _validateName,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: CustomTextField(
                          controller: _lastNameController,
                          hintText: 'الاسم الأخير',
                          validator: _validateName,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _phoneController,
                    hintText: 'رقم الهاتف',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    validator: _validatePhone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'البريد الإلكتروني',
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'كلمة المرور',
                    isPassword: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    hintText: 'تأكيد كلمة المرور',
                    isPassword: true,
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(hintText: 'الجنس'),
                    initialValue: _selectedGender,
                    items: const [
                      DropdownMenuItem(value: 'M', child: Text('ذكر')),
                      DropdownMenuItem(value: 'F', child: Text('أنثى')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'الرجاء اختيار الجنس' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTap: _selectDOB,
                    child: AbsorbPointer(
                      child: CustomTextField(
                        controller: _dobController,
                        hintText: 'تاريخ الميلاد (YYYY-MM-DD)',
                        prefixIcon: Icons.calendar_today,
                        validator: (value) => value == null || value.isEmpty
                            ? 'الرجاء اختيار تاريخ الميلاد'
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTap: _selectLocation,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(
                          color: _selectedAddress == null
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.2)
                              : theme.colorScheme.primary,
                        ),
                        borderRadius: AppRadius.button,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map,
                            size: 40,
                            color: _selectedAddress == null
                                ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _selectedAddress ?? 'اضغط لتحديد العنوان على الخريطة',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _selectedAddress == null
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                                  : theme.colorScheme.primary,
                              fontWeight: _selectedAddress == null
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_hasAttemptedSubmit && _selectedAddress == null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs, right: AppSpacing.md),
                      child: Text(
                        'الرجاء تحديد الموقع',
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Checkbox(
                        value: _isTermsAccepted,
                        onChanged: (v) {
                          setState(() {
                            _isTermsAccepted = v ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          'أوافق على الشروط والأحكام',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Text('تسجيل'),
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
}
