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
import 'dart:convert';
import 'package:http/http.dart' as http;


class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _grandfatherNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();

  final TextEditingController _carCompanyController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _carYearController = TextEditingController();

  XFile? _idImage;
  XFile? _licenseImage;
  XFile? _carImage;

  String? _selectedAddress;
  // ignore: unused_field
  LatLng? _selectedCoordinates;

  String? _selectedVehicleType;
  bool _isTermsAccepted = false;
  bool _hasAttemptedSubmit = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _fatherNameController.dispose();
    _grandfatherNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _plateNumberController.dispose();
    _carCompanyController.dispose();
    _carModelController.dispose();
    _carYearController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          if (type == 'ID') {
            _idImage = image;
          } else if (type == 'LICENSE') {
            _licenseImage = image;
          } else if (type == 'CAR') {
            _carImage = image;
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
    if (value == null || value.isEmpty) return 'كلمة المرور مطلوبة';
    if (value.length < 8) return 'يجب أن لا تقل عن 8 رموز';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'أدخل حرفاً كبيراً واحداً على الأقل';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'أدخل رقماً واحداً على الأقل';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'يرجى تأكيد كلمة المرور';
    if (value != _passwordController.text) return 'كلمة المرور غير متطابقة';
    return null;
  }

  Future<void> _submitForm() async {
    setState(() => _hasAttemptedSubmit = true);

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
      if (_selectedVehicleType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('الرجاء اختيار نوع المركبة'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      if (_idImage == null || _licenseImage == null || _carImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('يرجى رفع جميع الوثائق المطلوبة'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      if (_selectedAddress == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('يرجى تحديد الموقع'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        int vehicleTypeVal = 0;
        if (_selectedVehicleType == 'دراجة نارية') {
          vehicleTypeVal = 1;
        } else if (_selectedVehicleType == 'تك تك') {
          vehicleTypeVal = 2;
        }

        final String phoneNo = _phoneController.text.trim();

        // Construct exact payload for RegisterDriverDto
        final Map<String, dynamic> payload = {
          'FirstName': _firstNameController.text.trim(),
          'LastName': _lastNameController.text.trim(),
          'Email': _emailController.text.trim(),
          'Password': _passwordController.text, // raw password
          'PhoneNo': phoneNo,
          'DateOfBirth': _dobController.text.trim(),
          'FatherName': _fatherNameController.text.trim(),
          'GrandfatherName': _grandfatherNameController.text.trim(),
          'NationalIDNumber': phoneNo, // Unique and 10 digits
          'VehicleType': vehicleTypeVal,
          'VehicleMake': _selectedVehicleType == 'سيارة' ? _carCompanyController.text.trim() : (_selectedVehicleType ?? ''),
          'VehicleModel': _selectedVehicleType == 'سيارة' ? _carModelController.text.trim() : (_selectedVehicleType ?? ''),
          'PlateNumber': _plateNumberController.text.trim(),
          'BankAcc': 'SA$phoneNo',
        };

        final response = await http.post(
          Uri.parse('http://localhost:5135/api/auth/register/driver'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(payload),
        );

        // Required Logs
        // ignore: avoid_print
        print('DRIVER REGISTER STATUS: ${response.statusCode}');
        // ignore: avoid_print
        print('DRIVER REGISTER BODY: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم التسجيل بنجاح!'),
                backgroundColor: AppColors.success,
              ),
            );
            context.go('/login');
          }
        } else {
          String errorMsg = response.body;
          try {
            final Map<String, dynamic> decoded = json.decode(response.body);
            if (decoded.containsKey('message')) {
              errorMsg = decoded['message'].toString();
            } else if (decoded.containsKey('error')) {
              errorMsg = decoded['error'].toString();
            }
          } catch (_) {}

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('فشل التسجيل: $errorMsg'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ أثناء الاتصال بالخادم: $e'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تسجيل سائق جديد'),
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
                      validator: (v) => v == null || v.isEmpty ? 'يرجى اختيار تاريخ الميلاد' : null,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                Text(
                  'معلومات المركبة:',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                
                // Using DropdownButtonFormField instead of RadioGroup to fit the theme better
                // and because there is a deprecated RadioGroup widget locally
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(hintText: 'نوع المركبة'),
                  initialValue: _selectedVehicleType,
                  items: const [
                    DropdownMenuItem(value: 'سيارة', child: Text('سيارة')),
                    DropdownMenuItem(value: 'دراجة نارية', child: Text('دراجة نارية')),
                    DropdownMenuItem(value: 'تك تك', child: Text('تك تك')),
                  ],
                  onChanged: (v) => setState(() => _selectedVehicleType = v),
                  validator: (v) => v == null ? 'يرجى اختيار نوع المركبة' : null,
                ),

                const SizedBox(height: AppSpacing.md),
                if (_selectedVehicleType == 'سيارة') ...[
                  CustomTextField(
                    controller: _carCompanyController,
                    hintText: 'شركة السيارة (مثل تويوتا)',
                    validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال شركة السيارة' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _carModelController,
                    hintText: 'نوع المركبة (مثل كامري)',
                    validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال نوع المركبة' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _carYearController,
                    hintText: 'موديل المركبة (مثل 2013)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال موديل المركبة' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                CustomTextField(
                  controller: _plateNumberController,
                  hintText: 'رقم اللوحة',
                  validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال رقم اللوحة' : null,
                ),
                const SizedBox(height: AppSpacing.xl),

                _buildFileUploadPlaceholder(
                  title: 'صورة الهوية',
                  imageFile: _idImage,
                  onTap: () => _pickImage('ID'),
                ),
                _buildFileUploadPlaceholder(
                  title: 'رخصة القيادة',
                  imageFile: _licenseImage,
                  onTap: () => _pickImage('LICENSE'),
                ),
                _buildFileUploadPlaceholder(
                  title: 'صورة المركبة',
                  imageFile: _carImage,
                  onTap: () => _pickImage('CAR'),
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

                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Checkbox(
                      value: _isTermsAccepted,
                      onChanged: (v) => setState(() => _isTermsAccepted = v ?? false),
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
