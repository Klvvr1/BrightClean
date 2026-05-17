import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/database/database_helper.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controllers
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

  // Controllers for car details
  final TextEditingController _carCompanyController = TextEditingController();
  final TextEditingController _carModelController = TextEditingController();
  final TextEditingController _carYearController = TextEditingController();

  // Selected Files
  XFile? _idImage;
  XFile? _licenseImage;
  XFile? _carImage;

  String? _selectedVehicleType;
  bool _isTermsAccepted = false;
  bool _hasAttemptedSubmit = false;

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

  // Pick Image Logic
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

  // Select DOB Logic
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



  // Validation Logic
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
    if (!RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$').hasMatch(value)) {
      return 'يجب أن يحتوي على أحرف فقط';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'رقم الهاتف مطلوب';
    if (!RegExp(r'^[0-9]{9,10}$').hasMatch(value)) {
      return 'أدخل رقم هاتف صالح (9-10 أرقام)';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'البريد الإلكتروني مطلوب';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'أدخل بريد إلكتروني صحيح';
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
        const SnackBar(
          content: Text('الرجاء الموافقة على الشروط أولاً'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (_selectedVehicleType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء اختيار نوع المركبة'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_idImage == null || _licenseImage == null || _carImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى رفع جميع الوثائق المطلوبة'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        final dbHelper = DatabaseHelper.instance;
        final userData = {
          'first_name': _firstNameController.text.trim(),
          'father_name': _fatherNameController.text.trim(),
          'grandfather_name': _grandfatherNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'password': dbHelper.hashPassword(_passwordController.text),
          'dob': _dobController.text.trim(),
          'vehicle_type': _selectedVehicleType,
          'car_company': _selectedVehicleType == 'سيارة' ? _carCompanyController.text.trim() : null,
          'car_model': _selectedVehicleType == 'سيارة' ? _carModelController.text.trim() : null,
          'car_year': _selectedVehicleType == 'سيارة' ? _carYearController.text.trim() : null,
          'plate_number': _plateNumberController.text.trim(),
          'role': 'driver',

          'id_image_path': _idImage?.path,
          'license_image_path': _licenseImage?.path,
          'car_image_path': _carImage?.path,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        };

        await dbHelper.registerUser(userData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم التسجيل بنجاح!'),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ أثناء التسجيل: $e'),
              backgroundColor: Colors.red,
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

  bool _isSubmitting = false;


  Widget _buildFileUploadPlaceholder({
    required String title,
    required XFile? imageFile,
    required VoidCallback onTap,
  }) {
    bool isUploaded = imageFile != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isUploaded
              ? (isDark ? AppColors.primary.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.05))
              : (isDark ? Colors.grey.shade900 : AppColors.background),
          border: Border.all(
            color: isUploaded
                ? AppColors.primary
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade400),
            width: isUploaded ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
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
                  ? (isDark ? Colors.greenAccent : AppColors.primary)
                  : (isDark ? Colors.white70 : AppColors.secondary),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              isUploaded ? 'تم اختيار $title بنجاح' : 'رفع $title',
              style: TextStyle(
                color: isUploaded
                    ? (isDark ? AppColors.lightBlue : AppColors.primary)
                    : (isDark ? Colors.white70 : AppColors.secondary),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Fields
                Row(
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
                        controller: _fatherNameController,
                        hintText: 'اسم الأب',
                        validator: _validateName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _grandfatherNameController,
                        hintText: 'اسم الجد',
                        validator: _validateName,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _lastNameController,
                        hintText: 'اسم العائلة',
                        validator: _validateName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                CustomTextField(
                  controller: _phoneController,
                  hintText: 'رقم الهاتف',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                const SizedBox(height: 24),

                // Vehicle Information
                const Text(
                  'معلومات المركبة:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                RadioGroup<String>(
                  groupValue: _selectedVehicleType ?? '',
                  onChanged: (v) => setState(() => _selectedVehicleType = v),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('سيارة'),
                        value: 'سيارة',
                        activeColor: AppColors.primary,
                      ),
                      RadioListTile<String>(
                        title: const Text('دراجة نارية'),
                        value: 'دراجة نارية',
                        activeColor: AppColors.primary,
                      ),
                      RadioListTile<String>(
                        title: const Text('تك تك'),
                        value: 'تك تك',
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                if (_hasAttemptedSubmit && _selectedVehicleType == null)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Text(
                      'يرجى اختيار نوع المركبة',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),
                if (_selectedVehicleType == 'سيارة') ...[
                  CustomTextField(
                    controller: _carCompanyController,
                    hintText: 'شركة السيارة (مثل تويوتا)',
                    validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال شركة السيارة' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _carModelController,
                    hintText: 'نوع المركبة (مثل كامري)',
                    validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال نوع المركبة' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _carYearController,
                    hintText: 'موديل المركبة (مثل 2013)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال موديل المركبة' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                CustomTextField(
                  controller: _plateNumberController,
                  hintText: 'رقم اللوحة',
                  validator: (v) => v == null || v.isEmpty ? 'يرجى إدخال رقم اللوحة' : null,
                ),
                const SizedBox(height: 24),

                // Documents
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


                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _isTermsAccepted,
                      onChanged: (v) => setState(() => _isTermsAccepted = v ?? false),
                    ),
                    const Expanded(child: Text('أوافق على الشروط والأحكام')),
                  ],
                ),
                const SizedBox(height: 24),
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
