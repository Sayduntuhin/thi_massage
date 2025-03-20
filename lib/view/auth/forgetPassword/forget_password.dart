import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:thi_massage/view/auth/signup/widgets/phone_code_picker.dart';
import '../../../../themes/colors.dart';
import '../../../routers/app_router.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_button.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 0.05.sh),
            const CustomAppBar(),
            SizedBox(height: 0.04.sh),
            // Title
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
              "A 4-digit OTP will be sent via SMS to verify your phone number",
              style: TextStyle(
                fontSize: 14.sp,
                color: secounderyTextColor,
                fontFamily: "Urbanist",
              ),
            ),
            SizedBox(height: 20.h),

            // Phone Number Field
            PhoneNumberField(),
            SizedBox(height: 0.2.sh),
            // Continue Button
            ThaiMassageButton(
              text: "Continue",
              isPrimary: true,
              onPressed: () {
                Get.toNamed(Routes.otpVerification, arguments: "forgetPassword");

                debugPrint("Continue button pressed");
              },
            ),


          ],
        ),
      ),
    );
  }
}
