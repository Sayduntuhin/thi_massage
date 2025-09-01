import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/api/api_service.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';
import 'package:thi_massage/view/widgets/custom_gradientButton.dart';
import 'package:thi_massage/view/widgets/custom_snackbar.dart';
import 'package:toastification/toastification.dart';


class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  bool showCurrentPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecondaryAppBar(title: "Change Password"),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30.h),

            // Current Password
            _buildPasswordField(
              "Current password",
              showCurrentPassword,
                  () {
                setState(() {
                  showCurrentPassword = !showCurrentPassword;
                });
              },
              _currentPasswordController,
            ),

            SizedBox(height: 15.h),

            // New Password
            _buildPasswordField(
              "New password",
              showNewPassword,
                  () {
                setState(() {
                  showNewPassword = !showNewPassword;
                });
              },
              _newPasswordController,
            ),

            SizedBox(height: 15.h),

            // Confirm Password
            _buildPasswordField(
              "Confirm password",
              showConfirmPassword,
                  () {
                setState(() {
                  showConfirmPassword = !showConfirmPassword;
                });
              },
              _confirmPasswordController,
            ),

            Spacer(),
            // Save Button
            _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryButtonColor))
                : CustomGradientButton(
              text: "Save",
              onPressed: () async {
                if (_validateInputs()) {
                  setState(() => _isLoading = true);
                  try {
                    await _apiService.changePassword({
                      "current_password": _currentPasswordController.text,
                      "new_password": _newPasswordController.text,
                    });
                    CustomSnackBar.show(
                      context,
                      'Password changed successfully!',
                      type: ToastificationType.success,
                    );
                    Get.back();
                  } catch (e) {
                    if (e is BadRequestException) {
                      CustomSnackBar.show(
                        context,
                        e.message,
                        type: ToastificationType.error,
                      );
                    } else if (e is NetworkException) {
                      CustomSnackBar.show(
                        context,
                        e.message,
                        type: ToastificationType.error,
                      );
                    } else if (e is ServerException) {
                      CustomSnackBar.show(
                        context,
                        e.message,
                        type: ToastificationType.error,
                      );
                    } else {
                      CustomSnackBar.show(
                        context,
                        'An unexpected error occurred: $e',
                        type: ToastificationType.error,
                      );
                    }
                  } finally {
                    setState(() => _isLoading = false);
                  }
                }
              },
            ),
            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }

  bool _validateInputs() {
    if (_currentPasswordController.text.isEmpty) {
      CustomSnackBar.show(
        context,
        'Please enter your current password',
        type: ToastificationType.error,
      );
      return false;
    }
    if (_newPasswordController.text.isEmpty) {
      CustomSnackBar.show(
        context,
        'Please enter a new password',
        type: ToastificationType.error,
      );
      return false;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      CustomSnackBar.show(
        context,
        'New password and confirm password do not match',
        type: ToastificationType.error,
      );
      return false;
    }
    if (_newPasswordController.text.length < 8) {
      CustomSnackBar.show(
        context,
        'New password must be at least 8 characters long',
        type: ToastificationType.error,
      );
      return false;
    }
    return true;
  }

  Widget _buildPasswordField(String hintText, bool isVisible, VoidCallback toggleVisibility, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock_outline, color: Colors.black),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.black54),
          onPressed: toggleVisibility,
        ),
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 14.sp, color: Colors.black54),
        filled: true,
        fillColor: textFieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.r),
          borderSide: BorderSide(color: borderColor.withAlpha(40), width: 1.5.w),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.r),
          borderSide: BorderSide(color: borderColor.withAlpha(40), width: 1.5.w),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.r),
          borderSide: BorderSide(color: borderColor.withAlpha(40), width: 2.w),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16.h),
      ),
    );
  }
}