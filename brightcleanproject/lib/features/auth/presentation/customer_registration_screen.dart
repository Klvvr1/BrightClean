import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/widgets/map_picker_screen.dart';

class CustomerRegistrationScreen extends StatefulWidget {
  const CustomerRegistrationScreen({super.key});

  @override
  State<CustomerRegistrationScreen> createState() =>
      _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState
    extends State<CustomerRegistrationScreen> {
  // 1. Form Infrastructure
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

  // Pick Date of Birth
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

  // Map Location Integration
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

  // Submit Form Handling
  Future<void> _submitForm() async {
    setState(() => _hasAttemptedSubmit = true);

    // 4. Strict Validation for Terms & Conditions
    if (!_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء الموافقة على الشروط والأحكام أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final dbHelper = DatabaseHelper.instance;
        final userData = {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'password': dbHelper.hashPassword(_passwordController.text),
          'gender': _selectedGender ?? '',
          'dob': _dobController.text.trim(),
          'role': 'customer',
          'address_string': _selectedAddress,
          'latitude': _selectedCoordinates?.latitude,
          'longitude': _selectedCoordinates?.longitude,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
        };

        if (kIsWeb) {
          debugPrint(
            "Web mode detected: Geocoding bypassed. Saving raw coordinates: $_selectedCoordinates",
          );
        }

        await dbHelper.registerUser(userData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم التسجيل بنجاح! جاري تحويلك...'),
              backgroundColor: Colors.green,
            ),
          );
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            context.go('/login');
          }
        }
      } catch (e) {
        if (mounted) {
          final errorMessage = e.toString().contains('تعذر')
              ? 'تعذر الاتصال بقاعدة البيانات المحلية'
              : 'حدث خطأ أثناء التسجيل: $e';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
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

  // Validation Logic
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
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'الرجاء إدخال بريد إلكتروني صحيح';
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
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل عميل جديد')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          controller: _lastNameController,
                          hintText: 'الاسم الأخير',
                          validator: _validateName,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _phoneController,
                    hintText: 'رقم الهاتف',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: _validatePhone,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'البريد الإلكتروني',
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'كلمة المرور',
                    isPassword: true,
                    validator: _validatePassword,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    hintText: 'تأكيد كلمة المرور',
                    isPassword: true,
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: 16),
                  // Gender Dropdown
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
                  const SizedBox(height: 16),
                  // DOB Picker (Read-only for typing, triggers picker on tap)
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
                  const SizedBox(height: 16),
                  // Map Location Integration
                  GestureDetector(
                    onTap: _selectLocation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        border: Border.all(
                          color: _selectedAddress == null
                              ? Colors.grey.shade300
                              : AppColors.primary,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map,
                            size: 40,
                            color: _selectedAddress == null
                                ? Colors.grey
                                : AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedAddress ??
                                'اضغط لتحديد العنوان على الخريطة',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _selectedAddress == null
                                  ? Colors.grey
                                  : AppColors.primary,
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
                    const Padding(
                      padding: EdgeInsets.only(top: 8, right: 12),
                      child: Text(
                        'الرجاء تحديد الموقع',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // T&C
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
                      const Expanded(child: Text('أوافق على الشروط والأحكام')),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                          : const Text('تسجيل', style: TextStyle(fontSize: 16)),
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
