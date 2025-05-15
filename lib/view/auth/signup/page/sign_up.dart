import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../../../../api/api_service.dart';
import '../../../../api/auth_service.dart';
import '../../../../controller/phone_number_controller.dart';
import '../../../../controller/user_type_controller.dart';
import '../../../../themes/colors.dart';
import '../../../widgets/app_logger.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_snackbar.dart';
import '../../../widgets/loading_indicator.dart';
import '../../widgets/customTextField.dart';
import '../../../../controller/auth_controller.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneFieldController = PhoneNumberFieldController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    phoneFieldController.dispose();
    super.dispose();
  }

  bool validateInputs() {
    if (nameController.text.trim().isEmpty) {
      CustomSnackBar.show(context, "Please enter your full name", type: ToastificationType.error);
      return false;
    }
    if (!GetUtils.isEmail(emailController.text.trim())) {
      CustomSnackBar.show(context, "Please enter a valid email", type: ToastificationType.error);
      return false;
    }
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      CustomSnackBar.show(context, "Please enter a phone number", type: ToastificationType.error);
      return false;
    }
    if (!RegExp(r'^[0-9]{7,15}$').hasMatch(phone)) {
      CustomSnackBar.show(context, "Please enter a valid phone number (7-15 digits)", type: ToastificationType.error);
      return false;
    }
    if (passwordController.text.length < 6) {
      CustomSnackBar.show(context, "Password must be at least 6 characters", type: ToastificationType.error);
      return false;
    }
    return true;
  }

  Future<void> handleSignUp() async {
    if (!validateInputs()) return;

    final isTherapist = Get.arguments?['isTherapist'] ?? false;

    LoadingManager.showLoading();

    try {
      final authService = Get.find<AuthService>();
      final userTypeController = Get.find<UserTypeController>();
      final authController = Get.find<AuthController>();

      final response = await authService.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        fullName: nameController.text.trim(),
        phoneNumber: phoneFieldController.getFullPhoneNumber(phoneController.text),
        role: isTherapist ? "therapist" : "client",
      );

      final role = response['profile_data']?['role'] ?? 'client';
      final isTherapistFromResponse = role == 'therapist';
      final userId = response['profile_data']?['user'];
      final profileId = response['profile_data']?['id'];
      if (userId == null || profileId == null) {
        AppLogger.error("Missing user or id in signUp response: $response");
        CustomSnackBar.show(context, "Failed to retrieve user profile data", type: ToastificationType.error);
        return;
      }

      userTypeController.setUserType(isTherapistFromResponse);
      authController.isLoggedIn.value = true;
      authController.userId.value = userId.toString();

      LoadingManager.hideLoading();

      CustomSnackBar.show(context, "Sign-up successful! Please verify your email.", type: ToastificationType.success);

      Get.offAllNamed(
        '/otpVerification',
        arguments: {
          "source": "signup",
          "email": emailController.text.trim(),
          "full_name": nameController.text.trim(),
          "phone_number": phoneController.text.trim(),
          "country_code": phoneFieldController.getCountryCode(),
          "isTherapist": isTherapistFromResponse,
          "user_id": userId,
          "profile_id": profileId,
        },
      );
    } catch (e) {
      LoadingManager.hideLoading();
      String errorMessage = "Failed to sign up. Please try again.";
      if (e is PendingApprovalException) {
        errorMessage = e.message;
        CustomSnackBar.show(context, errorMessage, type: ToastificationType.warning);
      } else if (e is BadRequestException) {
        errorMessage = e.message;
        if (e.message.contains('already registered')) {
          Get.offAllNamed(
            '/logIn',
            arguments: {
              'isTherapist': isTherapist,
              'email': emailController.text.trim(),
            },
          );
        }
      } else if (e is ServerException) {
        errorMessage = "Server error. Please try again later.";
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      } else {
        AppLogger.error("Sign-up error: $e");
      }
      CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
    }
  }

  Future<void> handleGoogleSignIn() async {
    final isTherapist = Get.arguments?['isTherapist'] ?? false;
    String? firebaseEmail;

    LoadingManager.showLoading();

    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google Sign-In cancelled');
      firebaseEmail = googleUser.email;
      AppLogger.debug('Firebase email: $firebaseEmail');

      final authService = Get.find<AuthService>();
      final userTypeController = Get.find<UserTypeController>();
      final authController = Get.find<AuthController>();

      final response = await authService.googleSignIn(isTherapist: isTherapist);

      AppLogger.debug('Backend response: $response');
      AppLogger.debug('Role from response: ${response['profile_data']?['role']}');

      final role = response['profile_data']?['role'] ?? (isTherapist ? 'therapist' : 'client');
      final isTherapistFromResponse = role == 'therapist';
      final userId = response['profile_data']?['user'];
      final profileId = response['profile_data']?['id'];
      final userEmail = response['profile_data']?['email'] ?? firebaseEmail ?? '';

      if (userId == null || profileId == null) {
        AppLogger.error("Missing user or id in socialSignUpSignIn response: $response");
        CustomSnackBar.show(context, "Failed to retrieve user profile data", type: ToastificationType.error);
        LoadingManager.hideLoading();
        return;
      }

      final attemptedRole = isTherapist ? 'therapist' : 'client';
      if (role != attemptedRole) {
        LoadingManager.hideLoading();
        CustomSnackBar.show(
          context,
          "This email is already registered as a ${role == 'therapist' ? 'therapist' : 'client'}. Please log in.",
          type: ToastificationType.error,
        );
        Get.offAllNamed(
          '/logIn',
          arguments: {
            'isTherapist': isTherapist,
            'email': userEmail,
          },
        );
        return;
      }

      userTypeController.setUserType(isTherapistFromResponse);
      authController.isLoggedIn.value = true;
      authController.userId.value = userId.toString();

      LoadingManager.hideLoading();

      CustomSnackBar.show(context, "Google Sign-In successful!", type: ToastificationType.success);

      Get.toNamed(
        '/profileSetup',
        arguments: {
          'isTherapist': isTherapistFromResponse,
          'email': userEmail,
          'full_name': response['profile_data']?['full_name'] ?? 'Google User',
          'source': 'social',
          'user_id': userId,
          'profile_id': profileId,
        },
      );
    } catch (e) {
      LoadingManager.hideLoading();

      String errorMessage = "Failed to sign in with Google. Please try again.";
      if (e is PendingApprovalException) {
        errorMessage = e.message;
        CustomSnackBar.show(context, errorMessage, type: ToastificationType.warning);
      } else if (e is PlatformException) {
        AppLogger.error("Google Sign-In PlatformException: Code=${e.code}, Message=${e.message}, Details=${e.details}");
        if (e.code == 'sign_in_failed') {
          errorMessage = "Google Sign-In failed. Please check your Google account or app configuration.";
          if (e.message?.contains('ApiException: 10') == true) {
            errorMessage = "Configuration error: Verify OAuth client ID, SHA-1, and package name in Firebase Console.";
          }
        } else if (e.code == 'network_error') {
          errorMessage = "Network error. Please check your internet connection.";
        }
      } else if (e is BadRequestException) {
        errorMessage = e.message;
        if (e.message.contains('already registered')) {
          Get.offAllNamed(
            '/logIn',
            arguments: {
              'isTherapist': isTherapist,
              'email': firebaseEmail ?? '',
            },
          );
        }
      } else if (e is ServerException) {
        errorMessage = "Server error. Please try again later.";
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
    String? firebaseEmail;

    LoadingManager.showLoading();

    try {
      final facebookLoginResult = await FacebookAuth.instance.login();
      if (facebookLoginResult.status != LoginStatus.success) throw Exception('Facebook Sign-In cancelled');
      final facebookUser = await FacebookAuth.instance.getUserData();
      firebaseEmail = facebookUser['email'];
      AppLogger.debug('Firebase email: $firebaseEmail');

      final authService = Get.find<AuthService>();
      final userTypeController = Get.find<UserTypeController>();
      final authController = Get.find<AuthController>();

      final response = await authService.facebookSignIn(isTherapist: isTherapist);

      AppLogger.debug('Backend response: $response');
      AppLogger.debug('Role from response: ${response['profile_data']?['role']}');

      final role = response['profile_data']?['role'] ?? 'client';
      final isTherapistFromResponse = role == 'therapist';
      final userId = response['profile_data']?['user'];
      final profileId = response['profile_data']?['id'];
      final userEmail = response['profile_data']?['email'] ?? firebaseEmail ?? '';

      if (userId == null || profileId == null) {
        AppLogger.error("Missing user or id in socialSignUpSignIn response: $response");
        CustomSnackBar.show(context, "Failed to retrieve user profile data", type: ToastificationType.error);
        LoadingManager.hideLoading();
        return;
      }

      final attemptedRole = isTherapist ? 'therapist' : 'client';
      if (role != attemptedRole) {
        LoadingManager.hideLoading();
        CustomSnackBar.show(
          context,
          "This email is already registered as a ${role == 'therapist' ? 'therapist' : 'client'}. Please log in.",
          type: ToastificationType.error,
        );
        Get.offAllNamed(
          '/logIn',
          arguments: {
            'isTherapist': isTherapist,
            'email': userEmail,
          },
        );
        return;
      }

      userTypeController.setUserType(isTherapistFromResponse);
      authController.isLoggedIn.value = true;
      authController.userId.value = userId.toString();

      LoadingManager.hideLoading();

      CustomSnackBar.show(context, "Facebook Sign-In successful!", type: ToastificationType.success);

      Get.offAllNamed(
        '/profileSetup',
        arguments: {
          'isTherapist': isTherapistFromResponse,
          'email': userEmail,
          'full_name': response['profile_data']?['full_name'] ?? 'Facebook User',
          'source': 'social',
          'user_id': userId,
          'profile_id': profileId,
        },
      );
    } catch (e) {
      LoadingManager.hideLoading();

      String errorMessage = "Failed to sign in with Facebook. Please try again.";
      if (e is PendingApprovalException) {
        errorMessage = e.message;
        CustomSnackBar.show(context, errorMessage, type: ToastificationType.warning);
      } else if (e is BadRequestException) {
        errorMessage = e.message;
        if (e.message.contains('already registered')) {
          Get.offAllNamed(
            '/logIn',
            arguments: {
              'isTherapist': isTherapist,
              'email': firebaseEmail ?? '',
            },
          );
        }
      } else if (e is ServerException) {
        errorMessage = "Server error. Please try again later.";
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      } else {
        AppLogger.error("Facebook Sign-In Error: $e");
      }
      CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
    }
  }

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
                "Sign up as ${isTherapist ? 'Therapist' : 'Client'}",
                style: TextStyle(
                  fontSize: 42.sp,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                  fontFamily: "PlayfairDisplay",
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                "Create a new account",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: secounderyTextColor,
                  fontFamily: "Urbanist",
                ),
              ),
              SizedBox(height: 20.h),
              CustomTextField(
                hintText: "Enter your full name",
                icon: Icons.person_outline,
                controller: nameController,
              ),
              SizedBox(height: 15.h),
              CustomTextField(
                hintText: "Enter your email",
                icon: Icons.email_outlined,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 15.h),
              PhoneNumberField(
                controller: phoneController,
                phoneFieldController: phoneFieldController,
              ),
              SizedBox(height: 15.h),
              CustomTextField(
                hintText: "Enter your password",
                icon: Icons.lock_outline,
                isPassword: true,
                controller: passwordController,
              ),
              SizedBox(height: 20.h),
              ThaiMassageButton(
                text: "Sign up",
                isPrimary: true,
                onPressed: handleSignUp,
              ),
              SizedBox(height: 20.h),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 0.25.sw,
                      child: Divider(thickness: 1.w, color: const Color(0xffE8ECF4)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Or Sign up with",
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xff6A707C),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 0.25.sw,
                      child: Divider(thickness: 1.w, color: const Color(0xffE8ECF4)),
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
                    onTap: () => AppLogger.debug("Tap Apple"),
                    child: Image.asset('assets/images/apple.png', width: 50.w),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Center(
                child: RichText(
                  text: TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            Get.toNamed(
                              '/logIn',
                              arguments: {'isTherapist': isTherapist},
                            );
                          },
                          child: Text(
                            "Login",
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