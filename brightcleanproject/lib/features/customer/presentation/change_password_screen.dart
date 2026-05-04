import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 3. Change Password (Backend Validation)
  Future<bool> _verifyOldPassword(String oldPassword) async {
    // TODO: Replace with actual backend API call
    // Example: final response = await authService.verifyPassword(oldPassword);
    // return response.isValid;

    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 1));

    // Placeholder: In production, call your authentication backend
    // to verify the old password
    return true; // Temporarily accept any password until backend is implemented
  }

  Future<bool> _updatePassword(String newPassword) async {
    // TODO: Replace with actual backend API call
    // Example: final response = await authService.updatePassword(newPassword);
    // return response.success;

    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 1));

    // Placeholder: In production, call your authentication backend
    // to persist the new password
    return true; // Temporarily return success until backend is implemented
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // 1. Validate the old password against the backend
      final isOldPasswordCorrect = await _verifyOldPassword(_oldPasswordController.text);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (!isOldPasswordCorrect) {
        // 2. Display a clear error if it doesn't match
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('كلمة المرور الحالية غير صحيحة. يرجى المحاولة مرة أخرى.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return; // Stop execution if old password is wrong
      }

      // If correct, proceed to save the new password
      setState(() {
        _isLoading = true;
      });

      final isPasswordUpdated = await _updatePassword(_newPasswordController.text);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (isPasswordUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تغيير كلمة المرور بنجاح'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل تحديث كلمة المرور. يرجى المحاولة مرة أخرى.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تغيير كلمة المرور'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPasswordField(
                controller: _oldPasswordController,
                label: 'كلمة المرور الحالية',
                obscureText: _obscureOld,
                onToggleVisibility: () {
                  setState(() {
                    _obscureOld = !_obscureOld;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال كلمة المرور الحالية';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'كلمة المرور الجديدة',
                obscureText: _obscureNew,
                onToggleVisibility: () {
                  setState(() {
                    _obscureNew = !_obscureNew;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال كلمة المرور الجديدة';
                  }
                  if (value.length < 8) {
                    return 'كلمة المرور يجب أن تتكون من 8 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'تأكيد كلمة المرور الجديدة',
                obscureText: _obscureConfirm,
                onToggleVisibility: () {
                  setState(() {
                    _obscureConfirm = !_obscureConfirm;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى تأكيد كلمة المرور';
                  }
                  if (value != _newPasswordController.text) {
                    return 'كلمات المرور غير متطابقة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'حفظ التغييرات',
                        style: TextStyle(fontSize: 16, color: AppColors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      validator: validator,
    );
  }
}
