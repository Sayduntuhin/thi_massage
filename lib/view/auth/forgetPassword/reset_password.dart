import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../controller/reset_pass_controller.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_button.dart';
import '../widgets/customTextField.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ResetPasswordController controller = Get.put(ResetPasswordController());
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final email = Get.arguments['email'] as String? ?? ''; // Retrieve email from arguments

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
              CustomTextField(
                hintText: "Enter a new password",
                icon: Icons.lock_outline,
                isPassword: true,
                controller: newPasswordController,
              ),
              SizedBox(height: 15.h),
              CustomTextField(
                hintText: "Confirm password",
                icon: Icons.lock_outline,
                isPassword: true,
                controller: confirmPasswordController,
              ),
              SizedBox(height: 0.15.sh),
              Obx(() => ThaiMassageButton(
                text: "Confirm",
                isPrimary: true,
                isLoading: controller.isLoading.value,
                onPressed: controller.isLoading.value
                    ? () {}
                    : () {
                  if (email.isEmpty) {
                    Get.snackbar('Error', 'Email not provided.', backgroundColor: Colors.red, colorText: Colors.white);
                    return;
                  }
                  controller.resetPassword(
                    email: email,
                    newPassword: newPasswordController.text.trim(),
                    confirmPassword: confirmPasswordController.text.trim(),
                    context: context,
                  );
                },
                backgroundColor: controller.isLoading.value ? primaryButtonColor: null,
                textColor: controller.isLoading.value ? Colors.white : null,
              )),
            ],
          ),
        ),
      ),
    );
  }
}