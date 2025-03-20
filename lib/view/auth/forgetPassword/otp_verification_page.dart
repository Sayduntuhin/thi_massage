import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_button.dart';

class OTPVerificationPage extends StatefulWidget {
  const OTPVerificationPage({super.key});

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  TextEditingController otpController = TextEditingController();
  String currentOtp = "";
  String? flowType;

  @override
  void initState() {
    super.initState();
    flowType = Get.arguments ?? "signup"; // Default to signup if no argument is passed
  }

  void handleOTPSubmit() {
    debugPrint("Entered OTP: $currentOtp");

    if (flowType == "forgetPassword") {
      Get.toNamed("/resetPassword"); // Navigate to Reset Password Page
    } else {
      Get.toNamed("/profileSetup"); // Navigate to Profile Setup Page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              "Verify phone",
              style: TextStyle(
                fontSize: 38.sp,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
                fontFamily: "PlayfairDisplay",
              ),
            ),
            SizedBox(height: 5.h),

            // Subtitle with masked phone number
            Text.rich(
              TextSpan(
                text: "Please enter the 4-digit OTP sent at ",
                style: TextStyle(fontSize: 14.sp, color: secounderyTextColor, fontFamily: "Urbanist"),
                children: [
                  TextSpan(
                    text: "735-223-xxxx",
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: buttonTextColor),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // OTP Input Field
            Center(
              child: PinCodeTextField(
                autoFocus: true,
                autoUnfocus: true,
                appContext: context,
                length: 4,
                obscureText: false,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                textStyle: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10.r),
                  fieldHeight: 60.h,
                  fieldWidth: 60.w,
                  activeFillColor: const Color(0xFFF8F8F8),
                  selectedFillColor: const Color(0xFFF8F8F8),
                  inactiveFillColor: const Color(0xFFF8F8F8),
                  inactiveColor: Colors.grey, // No border initially
                  selectedColor: const Color(0xFF28B446), // Green border when selected
                  activeColor: const Color(0xFF28B446),   // Green border when active
                  borderWidth: currentOtp.isEmpty ? 0 : 1, // Border appears when OTP is entered
                ),
                cursorColor: primaryTextColor,
                controller: otpController,
                onChanged: (value) {
                  setState(() {
                    currentOtp = value;
                  });
                },
              ),
            ),
            SizedBox(height: 10.h),

            // Resend OTP
            Center(
              child: TextButton(
                onPressed: () {
                  debugPrint("Resend OTP tapped");
                },
                child: Text(
                  "Resend OTP",
                  style: TextStyle(fontSize: 14.sp, color: buttonTextColor),
                ),
              ),
            ),
            SizedBox(height: 0.135.sh),

            // Confirm Button - Visible only when 4 digits are entered
            if (currentOtp.length == 4)
              ThaiMassageButton(
                text: "Confirm",
                isPrimary: true,
                onPressed: handleOTPSubmit,
              ),
          ],
        ),
      ),
    );
  }
}
