import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../themes/colors.dart';
import '../../../controller/forget_pass_conteroller.dart';
import '../../../routers/app_router.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_button.dart';
import '../widgets/customTextField.dart';
import '../../widgets/custom_snackbar.dart';
import 'package:toastification/toastification.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ForgotPasswordController controller = Get.put(ForgotPasswordController());
    final emailController = TextEditingController();

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 0.05.sh),
            const CustomAppBar(),
            SizedBox(height: 0.04.sh),
            Text(
              "Forgot password",
              style: TextStyle(
                fontSize: 38.sp,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
                fontFamily: "PlayfairDisplay",
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              "A 4-digit OTP will be sent to your email to verify your email",
              style: TextStyle(
                fontSize: 14.sp,
                color: secounderyTextColor,
                fontFamily: "Urbanist",
              ),
            ),
            SizedBox(height: 20.h),
            CustomTextField(
              hintText: "Enter your email",
              icon: Icons.email_outlined,
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 0.05.sh),
            Obx(() => ThaiMassageButton(
              text: "Continue", // Always show "Continue" text when not loading
              isPrimary: true,
              isLoading: controller.isLoading.value, // Pass loading state
              onPressed: controller.isLoading.value
                  ? () {}
                  : () {
                debugPrint("Continue button pressed");
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  debugPrint("Empty email detected");
                  CustomSnackBar.show(
                    context,
                    'Please enter your email.',
                    type: ToastificationType.error,
                  );
                  return;
                }
                debugPrint("Calling resetPassword with email: $email");
                controller.resetPassword(email, context);
              },
              backgroundColor: controller.isLoading.value ? primaryButtonColor : null,
              textColor: controller.isLoading.value ? Colors.white : null,
            )),
          ],
        ),
      ),
    );
  }
}