import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_gradientButton.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  bool showCurrentPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:SecondaryAppBar(title: "Change Password"),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            SizedBox(height: 30.h),

            // Current Password
            _buildPasswordField("Current password", showCurrentPassword, () {
              setState(() {
                showCurrentPassword = !showCurrentPassword;
              });
            }),

            SizedBox(height: 15.h),

            // New Password
            _buildPasswordField("New password", showNewPassword, () {
              setState(() {
                showNewPassword = !showNewPassword;
              });
            }),

            SizedBox(height: 15.h),

            // Confirm Password
            _buildPasswordField("Confirm password", showConfirmPassword, () {
              setState(() {
                showConfirmPassword = !showConfirmPassword;
              });
            }),

            Spacer(),
            // Save Button
            CustomGradientButton(
              text: "Save",
              onPressed: () {
                debugPrint("Password changed successfully!");
                Get.back();
              },
            ),
            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(String hintText, bool isVisible, VoidCallback toggleVisibility) {
    return TextField(
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
