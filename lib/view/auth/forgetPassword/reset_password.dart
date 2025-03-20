import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_button.dart';
import '../widgets/customTextField.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 0.05.sh),
              const CustomAppBar(),
              SizedBox(height: 0.04.sh),
        
              // Title
              Text(
                "Reset password",
                style: TextStyle(
                  fontSize: 38.sp,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                  fontFamily: "PlayfairDisplay",
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                "Please enter new password",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: secounderyTextColor,
                  fontFamily: "Urbanist",
                ),
              ),
              SizedBox(height: 20.h),
        
              // New Password Field
              CustomTextField(
                hintText: "Enter a new password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              SizedBox(height: 15.h),
        
              // Confirm Password Field
              CustomTextField(
                hintText: "Confirm password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              SizedBox(height: 0.15.sh),
              // Confirm Button
              ThaiMassageButton(
                text: "Confirm",
                isPrimary: true,
                onPressed: () {
                  Get.toNamed("/logIn"); // Navigate back to login page
                },
              ),
        
            ],
          ),
        ),
      ),
    );
  }
}
