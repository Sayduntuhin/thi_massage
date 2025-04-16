import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:toastification/toastification.dart';
import '../../../api/api_service.dart';
import '../../../controller/user_controller.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/loading_indicator.dart';

class OTPVerificationPage extends StatefulWidget {
  const OTPVerificationPage({super.key});

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  TextEditingController otpController = TextEditingController();
  String currentOtp = "";
  String? flowType;
  String? email;

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments as Map<String, dynamic>?;
    flowType = arguments?['source'] ?? "signup";
    email = arguments?['email'] ?? "";
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  Future<void> handleOTPSubmit() async {
    if (currentOtp.length != 4) {
      CustomSnackBar.show(context, "Please enter a 4-digit OTP", type: ToastificationType.error);
      return;
    }

    debugPrint("Entered OTP: $currentOtp");

    LoadingManager.showLoading();

    try {
      final apiService = ApiService();
      await apiService.verifyOtp(email!, currentOtp);

      LoadingManager.hideLoading();

      CustomSnackBar.show(context, "Email verified successfully!", type: ToastificationType.success);

      if (flowType == "forgetPassword") {
        Get.toNamed("/resetPassword");
      } else {
        final userTypeController = Get.find<UserTypeController>();
        Get.toNamed(
          "/profileSetup",
          arguments: {'isTherapist': userTypeController.isTherapist.value},
        );
      }
    } catch (e) {
      LoadingManager.hideLoading();

      String errorMessage = "Failed to verify OTP. Please try again.";
      if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      }
      CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
    }
  }

  Future<void> handleResendOTP() async {
    if (email!.isEmpty) {
      CustomSnackBar.show(context, "Email not provided", type: ToastificationType.error);
      return;
    }

    LoadingManager.showLoading();

    try {
      final apiService = ApiService();
      await apiService.resendOtp(email!);

      LoadingManager.hideLoading();

      CustomSnackBar.show(context, "OTP resent successfully!", type: ToastificationType.success);
    } catch (e) {
      LoadingManager.hideLoading();

      String errorMessage = "Failed to resend OTP. Please try again.";
      if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      }
      CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
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
            Text(
              "Verify email",
              style: TextStyle(
                fontSize: 38.sp,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
                fontFamily: "PlayfairDisplay",
              ),
            ),
            SizedBox(height: 5.h),
            Text.rich(
              TextSpan(
                text: "Please enter the 4-digit OTP sent to ",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: secounderyTextColor,
                  fontFamily: "Urbanist",
                ),
                children: [
                  TextSpan(
                    text: email,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: buttonTextColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
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
                  inactiveColor: Colors.grey,
                  selectedColor: const Color(0xFF28B446),
                  activeColor: const Color(0xFF28B446),
                  borderWidth: currentOtp.isEmpty ? 0 : 1,
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
            Center(
              child: TextButton(
                onPressed: handleResendOTP,
                child: Text(
                  "Resend OTP",
                  style: TextStyle(fontSize: 14.sp, color: buttonTextColor),
                ),
              ),
            ),
            SizedBox(height: 0.06.sh),
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