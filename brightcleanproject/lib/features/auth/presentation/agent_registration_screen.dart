import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/map_picker_screen.dart';
import 'package:provider/provider.dart';
import '../data/providers/auth_provider.dart';
import '../data/models/register_agent_model.dart';
import '../../customer/data/providers/cart_provider.dart';

class AgentRegistrationScreen extends StatefulWidget {
  const AgentRegistrationScreen({super.key});

  @override
  State<AgentRegistrationScreen> createState() =>
      _AgentRegistrationScreenState();
}

class _AgentRegistrationScreenState extends State<AgentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _grandfatherNameController =
      TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _commercialRegisterController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();

  XFile? _commercialRegImage;
  XFile? _idImage;

  final Map<String, bool> _availableServices = {
    'ملابس': false,
    'مفارش': false,
    'منسوجات': false,
    'سيارات': false,
    'دراجات نارية': false,
    'الواح طاقة': false,
    'مكيفات': false,
    'خزانات': false,
  };

  String? _selectedAddress;
  LatLng? _selectedCoordinates;

  bool _isTermsAccepted = false;
  bool _hasAttemptedSubmit = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _fatherNameController.dispose();
    _grandfatherNameController.dispose();
    _lastNameController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _nationalIdController.dispose();
    _commercialRegisterController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isCommercial) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          if (isCommercial) {
            _commercialRegImage = image;
          } else {
            _idImage = image;
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
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

  Widget _buildFileUploadPlaceholder({
    required String title,
    required XFile? imageFile,
    required VoidCallback onTap,
  }) {
    bool isUploaded = imageFile != null;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: isUploaded
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          border: Border.all(
            color: isUploaded
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.2),
            width: isUploaded ? 2 : 1,
          ),
          borderRadius: AppRadius.button,
          image: isUploaded
              ? DecorationImage(
                  image: FileImage(File(imageFile.path)),
                  fit: BoxFit.cover,
                  opacity: 0.2,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUploaded ? Icons.check_circle : Icons.add_a_photo,
              color: isUploaded
                  ? AppColors.success
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isUploaded ? 'تم اختيار $title بنجاح' : 'رفع $title',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isUploaded
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: isUploaded ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(String service) {
    bool isSelected = _availableServices[service] ?? false;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        setState(() {
          _availableServices[service] = !isSelected;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: AppRadius.button,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              service,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateNationalId(String? value) {
    if (value == null || value.trim().isEmpty) return 'رقم الهوية الوطنية مطلوب';
    if (!RegExp(r'^[0-9]{11}$').hasMatch(value.trim())) {
      return 'يجب أن يتكون رقم الهوية من 11 رقماً';
    }
    return null;
  }

  String? _validateCR(String? value) {
    if (value == null || value.trim().isEmpty) return 'رقم السجل التجاري مطلوب';
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
      return 'رقم السجل التجاري يجب أن يتكون من 10 أرقام';
    }
    return null;
  }

  String? _validateBankAccount(String? value) {
    if (value == null || value.trim().isEmpty) return 'رقم الحساب البنكي مطلوب';
    final val = value.trim();
    if (!RegExp(r'^[0-9]{5,9}$').hasMatch(val)) {
      return 'رقم الحساب يجب أن يتكون من 5 إلى 9 أرقام (حسب البنك)';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
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
    if (!RegExp(r'^(77|78|73|71|70)[0-9]{7}$').hasMatch(value)) {
      return 'رقم الهاتف يجب أن يتكون من 9 أرقام ويبدأ بـ (77, 78, 73, 71, 70)';
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
    if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
    if (value.length < 8) return 'يجب أن لا تقل عن 8 رموز';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'أدخل حرفاً كبيراً واحداً على الأقل';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'أدخل رقماً واحداً على الأقل';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'يرجى تأكيد كلمة المرور';
    if (value != _passwordController.text) return 'كلمة المرور غير متطابقة';
    return null;
  }

  int? _serviceCategoryForRegistrationLabel(String label) {
    final normalized = label.trim();
    final labels = _availableServices.keys.toList();
    final index = labels.indexOf(normalized);
    switch (index) {
      case 0:
        return 0; // ServiceCategory.Laundry
      case 1:
      case 2:
        return 1; // ServiceCategory.HomeWovens
      case 3:
      case 4:
        return 3; // ServiceCategory.VehicleWash
      case 5:
      case 6:
      case 7:
        return 2; // ServiceCategory.HomeServices
      default:
        return null;
    }
  }

  void _submitForm() {
    setState(() => _hasAttemptedSubmit = true);

    final selectedServices = _availableServices.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    bool isServiceSelected = selectedServices.isNotEmpty;

    if (!_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('الرجاء الموافقة على الشروط أولاً'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (_selectedAddress == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('يرجى تحديد الموقع'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      if (!isServiceSelected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('يرجى اختيار خدمة واحدة على الأقل'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      if (_commercialRegImage == null || _idImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('يرجى رفع السجل التجاري وصورة الهوية'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      _performRegistration(selectedServices);
    }
  }

  Future<void> _performRegistration(List<String> selectedServices) async {
    setState(() => _isSubmitting = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final selectedServiceCategories = selectedServices
          .map(_serviceCategoryForRegistrationLabel)
          .whereType<int>()
          .toSet()
          .toList();
      
      final agentModel = RegisterAgentModel(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNo: _phoneController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        fatherName: _fatherNameController.text.trim(),
        grandfatherName: _grandfatherNameController.text.trim(),
        nationalIdNumber: _nationalIdController.text.trim(),
        businessName: _businessNameController.text.trim(),
        commercialRegister: _commercialRegisterController.text.trim(),
        bankAcc: _bankAccountController.text.trim(),
        area: _selectedAddress ?? '',
        street: _selectedAddress ?? '',
        latitude: _selectedCoordinates?.latitude ?? 0.0,
        longitude: _selectedCoordinates?.longitude ?? 0.0,
        selectedServiceCategories: selectedServiceCategories,
      );

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await authProvider.registerAgent(
        agentModel,
        commercialRegisterImagePath: _commercialRegImage!.path,
        nationalIdImagePath: _idImage!.path,
      );

      // Crucially logout after registration succeeds so the pending applicant doesn't remain authenticated
      await authProvider.logout(cartProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل المغسلة بنجاح وهي قيد المراجعة من الإدارة!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final errorMsg = authProvider.errorMessage ?? 'حدث خطأ أثناء التسجيل';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تسجيل مغسلة جديدة'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                        controller: _fatherNameController,
                        hintText: 'اسم الأب',
                        validator: _validateName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _grandfatherNameController,
                        hintText: 'اسم الجد',
                        validator: _validateName,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: CustomTextField(
                        controller: _lastNameController,
                        hintText: 'اسم العائلة',
                        validator: _validateName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  controller: _businessNameController,
                  hintText: 'اسم المغسلة',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'يرجى إدخال اسم المغسلة' : null,
                ),
                const SizedBox(height: AppSpacing.xl),

                Text(
                  'الخدمات المتوفرة:',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: _availableServices.keys
                      .map((service) => _buildServiceItem(service))
                      .toList(),
                ),
                if (_hasAttemptedSubmit &&
                    !_availableServices.values.contains(true))
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'يرجى اختيار خدمة واحدة على الأقل',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),

                const SizedBox(height: AppSpacing.xl),
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
                GestureDetector(
                  onTap: _selectDOB,
                  child: AbsorbPointer(
                    child: CustomTextField(
                      controller: _dobController,
                      hintText: 'تاريخ الميلاد',
                      prefixIcon: Icons.calendar_today,
                      validator: (v) => v == null || v.isEmpty
                          ? 'يرجى اختيار تاريخ الميلاد'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  controller: _nationalIdController,
                  hintText: 'رقم الهوية الوطنية للمدير',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  validator: _validateNationalId,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  controller: _commercialRegisterController,
                  hintText: 'رقم السجل التجاري / الترخيص',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: _validateCR,
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  controller: _bankAccountController,
                  hintText: 'رقم الحساب البنكي / الآيبان (IBAN)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  validator: _validateBankAccount,
                ),
                const SizedBox(height: AppSpacing.xl),

                _buildFileUploadPlaceholder(
                  title: 'السجل التجاري',
                  imageFile: _commercialRegImage,
                  onTap: () => _pickImage(true),
                ),
                _buildFileUploadPlaceholder(
                  title: 'صورة الهوية',
                  imageFile: _idImage,
                  onTap: () => _pickImage(false),
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
                      children: [
                        Icon(
                          Icons.map,
                          color: _selectedAddress == null
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _selectedAddress ?? 'حدد الموقع على الخريطة',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _selectedAddress == null
                                ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                                : theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_hasAttemptedSubmit && _selectedAddress == null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs, right: AppSpacing.sm),
                    child: Text(
                      'يرجى تحديد الموقع',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),

                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Checkbox(
                      value: _isTermsAccepted,
                      onChanged: (v) =>
                          setState(() => _isTermsAccepted = v ?? false),
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
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('تسجيل الآن'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
