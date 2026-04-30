import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/map_picker_screen.dart';

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

  // Selected Files
  XFile? _idImage;
  XFile? _licenseImage;
  XFile? _carImage;

  // بيانات الموقع
  String? _selectedAddress;
  LatLng? _selectedCoordinates;

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

  // دالة اختيار الموقع
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

  void _submitForm() {
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

      if (_selectedAddress == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى تحديد الموقع'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري تسجيل السائق...'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Widget _buildFileUploadPlaceholder({
    required String title,
    required XFile? imageFile,
    required VoidCallback onTap,
  }) {
    bool isUploaded = imageFile != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isUploaded ? AppColors.primary.withOpacity(0.05) : AppColors.background,
          border: Border.all(
            color: isUploaded ? AppColors.primary : Colors.grey.shade400,
            width: isUploaded ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          image: isUploaded
              ? DecorationImage(
                  image: FileImage(File(imageFile!.path)),
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
              color: isUploaded ? AppColors.primary : AppColors.secondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              isUploaded ? 'تم اختيار $title بنجاح' : 'رفع $title',
              style: TextStyle(
                color: isUploaded ? AppColors.primary : AppColors.secondary,
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
                Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('سيارة'),
                      value: 'سيارة',
                      groupValue: _selectedVehicleType,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _selectedVehicleType = v),
                    ),
                    RadioListTile<String>(
                      title: const Text('دراجة نارية'),
                      value: 'دراجة نارية',
                      groupValue: _selectedVehicleType,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _selectedVehicleType = v),
                    ),
                    RadioListTile<String>(
                      title: const Text('تك تك'),
                      value: 'تك تك',
                      groupValue: _selectedVehicleType,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _selectedVehicleType = v),
                    ),
                  ],
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
                // الموقع
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
                      children: [
                        Icon(
                          Icons.map,
                          color: _selectedAddress == null
                              ? Colors.grey
                              : AppColors.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedAddress ?? 'حدد الموقع على الخريطة',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_hasAttemptedSubmit && _selectedAddress == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, right: 12),
                    child: Text(
                      'يرجى تحديد الموقع',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
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
                    onPressed: _submitForm,
                    child: const Text('تسجيل الآن'),
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
