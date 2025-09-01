import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:toastification/toastification.dart';
import '../../../api/api_service.dart';
import '../../../controller/auth_controller.dart';
import '../../../controller/user_type_controller.dart';
import '../../../themes/colors.dart';
import '../../widgets/app_logger.dart';
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
  String? fullName;
  String? phoneNumber;
  String? countryCode;
  bool? isTherapist;
  int? userId;
  int? profileId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments as Map<String, dynamic>?;
    flowType = arguments?['source'] ?? arguments?['type'] ?? "signup";
    email = arguments?['email'] ?? "";
    fullName = arguments?['full_name'] ?? "";
    phoneNumber = arguments?['phone_number'] ?? "";
    countryCode = arguments?['country_code'] ?? "+1";
    isTherapist = arguments?['isTherapist'] ?? false;
    userId = arguments?['user_id'];
    profileId = arguments?['profile_id'];
    AppLogger.debug("OTPVerificationPage arguments: $arguments");
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

    setState(() {
      isLoading = true;
    });

    try {
      final apiService = ApiService();
      Map<String, dynamic> response;
      if (flowType == "forgetPassword") {
        response = await apiService.verifyOtpForForgetPassword(email!, currentOtp);
      } else {
        // Verify OTP for sign-up and get user data from profile_data
        response = await apiService.verifyOtpForSignUp(email!, currentOtp);
        final profileData = response['profile_data'] as Map<String, dynamic>?;
        if (profileData == null) {
          throw Exception("Profile data missing in OTP verification response");
        }
        userId = profileData['user'] as int?;
        profileId = profileData['id'] as int?;
        if (userId == null || profileId == null) {
          throw Exception("User ID or profile ID missing in OTP verification response");
        }
        // Handle approval message with a notification, but proceed to profile setup
        if (response['message'].contains("wait for super admin approval")) {
          CustomSnackBar.show(context, response['message'], type: ToastificationType.info);
        }
        // Update auth state after successful OTP verification
        final authController = Get.find<AuthController>();
        authController.isLoggedIn.value = true;
        authController.userId.value = userId.toString();
        await authController.storage.write(key: 'user_id', value: userId.toString());
        // Store access and refresh tokens
        await authController.storage.write(key: 'access_token', value: response['access']);
        await authController.storage.write(key: 'refresh_token', value: response['refresh']);
        await authController.userTypeController.setUserIds(
          clientId: profileData['clientId'],
          therapistId: profileData['therapistId'],
          role: profileData['role'],
        );
      }

      setState(() {
        isLoading = false;
      });

      CustomSnackBar.show(context, "Email verified successfully!", type: ToastificationType.success);

      if (flowType == "forgetPassword") {
        Get.toNamed("/resetPassword", arguments: {'email': email});
      } else {
        final userTypeController = Get.find<UserTypeController>();
        Get.toNamed(
          "/profileSetup",
          arguments: {
            'isTherapist': isTherapist ?? userTypeController.isTherapist.value,
            'full_name': fullName,
            'email': email,
            'phone_number': phoneNumber,
            'country_code': countryCode,
            'source': flowType,
            'user_id': userId,
            'profile_id': profileId,
          },
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      String errorMessage = "Failed to verify OTP. Please try again.";
      if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is ServerException) {
        errorMessage = "Server error. Please try again later.";
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      } else {
        AppLogger.error("OTP verification error: $e");
      }
      CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
    }
  }

  Future<void> handleResendOTP() async {
    if (email!.isEmpty) {
      CustomSnackBar.show(context, "Email not provided", type: ToastificationType.error);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final apiService = ApiService();
      await apiService.resendOtp(email!);

      setState(() {
        isLoading = false;
      });

      CustomSnackBar.show(context, "OTP resent successfully!", type: ToastificationType.success);
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      String errorMessage = "Failed to resend OTP. Please try again.";
      if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      }
      AppLogger.error("Resend OTP error: $e");
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
                onPressed: isLoading ? () {} : handleResendOTP,
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
                isLoading: isLoading,
                onPressed: isLoading ? () {} : handleOTPSubmit,
                backgroundColor: isLoading ? primaryButtonColor : null,
                textColor: isLoading ? Colors.white : null,
              ),
          ],
        ),
      ),
    );
  }
}