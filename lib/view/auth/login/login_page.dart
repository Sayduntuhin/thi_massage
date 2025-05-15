import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/controller/auth_controller.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';
import 'package:toastification/toastification.dart';
import '../../../api/api_service.dart';
import '../../../controller/user_type_controller.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/loading_indicator.dart';
import '../widgets/customTextField.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthController authController = Get.find<AuthController>();
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    // Check if user is already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authController.isLoggedIn.value) {
        Get.offAllNamed('/homePage',
            arguments: {'isTherapist': Get.find<UserTypeController>().isTherapist.value});
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool validateInputs() {
    if (!GetUtils.isEmail(emailController.text.trim())) {
      CustomSnackBar.show(context, "Please enter a valid email",
          type: ToastificationType.error);
      return false;
    }
    if (passwordController.text.trim().isEmpty) {
      CustomSnackBar.show(context, "Please enter your password",
          type: ToastificationType.error);
      return false;
    }
    return true;
  }

  Future<void> handleLogin() async {
    if (!validateInputs()) return;

    LoadingManager.showLoading();

    try {
      final success = await authController.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      LoadingManager.hideLoading();

      if (success) {
        CustomSnackBar.show(context, "Login successful!", type: ToastificationType.success);
      }
    } catch (e) {
      LoadingManager.hideLoading();

      String errorMessage = "Failed to login. Please try again.";
      if (e is PendingApprovalException) {
        errorMessage = e.message;
      } else if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is UnauthorizedException) {
        errorMessage = "Invalid email or password.";
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      } else {
        AppLogger.error("Login Unexpected Error: $e");
      }
      CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
    }
  }
  Future<void> handleGoogleSignIn() async {
    final isTherapist = Get.arguments?['isTherapist'] ?? false;
    AppLogger.debug('Google Sign-In: isTherapist argument = $isTherapist');

    LoadingManager.showLoading();

    try {
      final success = await authController.googleSignIn(isTherapist: isTherapist);
      LoadingManager.hideLoading();

      if (success) {
        CustomSnackBar.show(context, "Google Sign-In successful!", type: ToastificationType.success);
      }
    } catch (e) {
      LoadingManager.hideLoading();

      String errorMessage = "Failed to sign in with Google. Please try again.";
      if (e is PendingApprovalException) {
        errorMessage = e.message;
      } else if (e is PlatformException) {
        AppLogger.error("Google Sign-In Error: ${e.code} - ${e.message}".toString());
            if (e.code == 'sign_in_failed') {
          errorMessage = "Google Sign-In failed. Please check your Google account.";
          if (e.message?.contains('ApiException: 10') == true) {
            errorMessage = "Configuration error: Verify OAuth client ID, SHA-1, and package name in Firebase Console.";
          }
        } else if (e.code == 'network_error') {
        errorMessage = "Network error. Please check your internet connection.";
      }
    } else if (e is BadRequestException) {
    errorMessage = e.message;
    } else if (e is NetworkException) {
    errorMessage = "No internet connection.";
    } else {
    AppLogger.error("Google Sign-In Unexpected Error: $e");
    }
    CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
  }
  }
  Future<void> handleFacebookSignIn() async {
    final isTherapist = Get.arguments?['isTherapist'] ?? false;
    AppLogger.debug('Facebook Sign-In: isTherapist argument = $isTherapist');

    LoadingManager.showLoading();

    try {
      final success = await authController.facebookSignIn(isTherapist: isTherapist);
      LoadingManager.hideLoading();

      if (success) {
        CustomSnackBar.show(context, "Facebook Sign-In successful!", type: ToastificationType.success);
      }
    } catch (e) {
      LoadingManager.hideLoading();

      String errorMessage = "Failed to sign in with Facebook. Please try again.";
      if (e is PendingApprovalException) {
        errorMessage = e.message;
      } else if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      } else {
        AppLogger.error("Facebook Sign-In Error: $e");
      }
      CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
    }
  }
  /*Future<void> handleAppleSignIn() async {
    final isTherapist = Get.arguments?['isTherapist'] ?? false;
    AppLogger.debug('Apple Sign-In: isTherapist argument = $isTherapist');

    LoadingManager.showLoading();

    try {
      final success = await authController.appleSignIn(isTherapist: isTherapist);
      LoadingManager.hideLoading();

      if (success) {
        CustomSnackBar.show(context, "Apple Sign-In successful!",
            type: ToastificationType.success);
      }
    } catch (e) {
      LoadingManager.hideLoading();

      String errorMessage = "Failed to sign in with Apple. Please try again.";
      if (e is SignInWithAppleAuthorizationException) {
        AppLogger.error("Apple Sign-In Exception: Code=${e.code}, Message=${e.message}");
        if (e.code == AuthorizationErrorCode.canceled) {
          errorMessage = "Apple Sign-In canceled.";
        } else if (e.code == AuthorizationErrorCode.failed) {
          errorMessage = "Apple Sign-In failed. Please check your Apple ID.";
        }
      } else if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      } else {
        AppLogger.error("Apple Sign-In Unexpected Error: $e");
      }
      CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
    }
  }*/

  @override
  Widget build(BuildContext context) {
    final isTherapist = Get.arguments?['isTherapist'] ?? false;
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
                "Welcome!",
                style: TextStyle(
                  fontSize: 42.sp,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                  fontFamily: "PlayfairDisplay",
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                "Login to continue",
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
              SizedBox(height: 15.h),
              CustomTextField(
                hintText: "Enter your password",
                icon: Icons.lock_outline,
                isPassword: true,
                controller: passwordController,
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (value) {
                      setState(() {
                        rememberMe = value ?? false;
                      });
                    },
                  ),
                  Text(
                    "Remember me",
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              ThaiMassageButton(
                text: "Login",
                isPrimary: true,
                onPressed: handleLogin,
              ),
              SizedBox(height: 20.h),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 0.25.sw,
                      child: Divider(
                        thickness: 1.w,
                        color: Color(0xffE8ECF4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Or Login with",
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Color(0xff6A707C),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 0.25.sw,
                      child: Divider(
                        thickness: 1.w,
                        color: Color(0xffE8ECF4),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: handleFacebookSignIn,
                    child: Image.asset('assets/images/facebook.png', width: 50.w),
                  ),
                  SizedBox(width: 20.w),
                  InkWell(
                    onTap: handleGoogleSignIn,
                    child: Image.asset('assets/images/google.png', width: 50.w),
                  ),
                  SizedBox(width: 20.w),
                  InkWell(
                    //onTap: handleAppleSignIn,
                    child: Image.asset('assets/images/apple.png', width: 50.w),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Center(
                child: TextButton(
                  onPressed: () {
                    Get.toNamed("/forgetPassword");
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                  ),
                ),
              ),
              Center(
                child: RichText(
                  text: TextSpan(
                    text: "Don’t have an account? ",
                    style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            Get.toNamed("/signUp",
                                arguments: {'isTherapist': isTherapist});
                          },
                          child: Text(
                            "Sign up",
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: buttonTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}