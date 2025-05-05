import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:toastification/toastification.dart';
import '../../../../api/api_service.dart';
import '../../../../controller/phone_number_controller.dart';
import '../../../../controller/user_controller.dart';
import '../../../../themes/colors.dart';
import '../../../widgets/app_logger.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_snackbar.dart';
import '../../../widgets/loading_indicator.dart';
import '../../widgets/customTextField.dart';

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
      CustomSnackBar.show(context, "Please enter your name", type: ToastificationType.error);
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
    final isTherapist = Get.arguments?['isTherapist'] ?? false;

    LoadingManager.showLoading();

    try {
      final apiService = ApiService();
      final userTypeController = Get.find<UserTypeController>();

      final response = await apiService.signUp({
        "full_name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone_number": phoneFieldController.getFullPhoneNumber(phoneController.text),
        "password": passwordController.text.trim(),
        "role": isTherapist ? "therapist" : "client",
      });

      final role = response['profile_data']?['role'] ?? 'client';
      final isTherapistFromResponse = role == 'therapist';
      final userId = response['profile_data']?['user'];
      AppLogger.debug(" Sign-Up User ID: $userId");
      final profileId = response['profile_data']?['id'];
      if (userId == null || profileId == null) {
        AppLogger.error("Missing user or id in signUp response: $response");
        CustomSnackBar.show(context, "Failed to retrieve user profile data", type: ToastificationType.error);
        return;
      }

      userTypeController.setUserType(isTherapistFromResponse);

      LoadingManager.hideLoading();

      CustomSnackBar.show(context, "Sign-up successful! Please verify your email.", type: ToastificationType.success);

      Get.toNamed(
        '/otpVerification',
        arguments: {
          "source": "signup",
          "email": emailController.text.trim(),
          "full_name": nameController.text.trim(),
          "phone_number": phoneController.text.trim(),
          "country_code": phoneFieldController.getCountryCode(),
          "isTherapist": isTherapistFromResponse,
          "user_id": userId, // Pass user as user_id
          "profile_id": profileId, // Pass id as profile_id
        },
      );
    } catch (e) {
      LoadingManager.hideLoading();
      String errorMessage = "Failed to sign up. Please try again.";
      if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      }
      CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
      AppLogger.error("Sign-up error: $e");
    }
  }
  Future<void> handleGoogleSignIn() async {
    final isTherapist = Get.arguments?['isTherapist'] ?? false;

    LoadingManager.showLoading();

    try {
      AppLogger.debug("Initiating Google Sign-In...");

      // Sign in with Google
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        LoadingManager.hideLoading();
        CustomSnackBar.show(context, "Google Sign-In canceled", type: ToastificationType.warning);
        return;
      }

      AppLogger.debug("Google User: ${googleUser.email}, ${googleUser.displayName}");

      final apiService = ApiService();
      final userTypeController = Get.find<UserTypeController>();

      final response = await apiService.socialSignUpSignIn({
        "email": googleUser.email,
        "full_name": googleUser.displayName ?? "Google User",
        "role": isTherapist ? "therapist" : "client",
        "auth_provider": "google",
      });

      LoadingManager.hideLoading();

      // Extract role, user_id, and profile_id from response
      final role = response['profile_data']?['role'] ?? 'client';
      final isTherapistFromResponse = role == 'therapist';
      final userId = response['profile_data']?['user'];
      final profileId = response['profile_data']?['id'];

      if (userId == null || profileId == null) {
        AppLogger.error("Missing user or id in socialSignUpSignIn response: $response");
        CustomSnackBar.show(context, "Failed to retrieve user profile data", type: ToastificationType.error);
        return;
      }

      AppLogger.debug("Google Sign-In User ID: $userId, Profile ID: $profileId");

      userTypeController.setUserType(isTherapistFromResponse);

      CustomSnackBar.show(context, "Google Sign-In successful!", type: ToastificationType.success);

      Get.toNamed(
        '/profileSetup',
        arguments: {
          'isTherapist': isTherapistFromResponse,
          'email': googleUser.email,
          'full_name': googleUser.displayName ?? "Google User",
          'source': 'social',
          'user_id': userId, // Pass profile_data.user as user_id
          'profile_id': profileId, // Pass profile_data.id as profile_id
        },
      );
    } catch (e, stackTrace) {
      LoadingManager.hideLoading();

      String errorMessage = "Failed to sign in with Google";
      if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      }
      AppLogger.error("Google Sign-In Error: $e", e, stackTrace);
      CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
    }
  }
  Future<void> handleFacebookSignIn() async {
    final isTherapist = Get.arguments?['isTherapist'] ?? false;

    LoadingManager.showLoading();

    try {
      AppLogger.debug("Initiating Facebook Sign-In...");
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      AppLogger.debug("Facebook Login Result: ${result.status}, ${result.message}, Token: ${result.accessToken?.tokenString}");

      if (result.status != LoginStatus.success) {
        LoadingManager.hideLoading();
        String message;
        switch (result.status) {
          case LoginStatus.cancelled:
            message = "Facebook Sign-In canceled";
            break;
          case LoginStatus.failed:
            message = "Facebook Sign-In failed: ${result.message}";
            break;
          default:
            message = "Unknown error during Facebook Sign-In";
        }
        CustomSnackBar.show(context, message, type: ToastificationType.warning);
        return;
      }

      AppLogger.debug("Fetching Facebook user data...");
      final userData = await FacebookAuth.instance.getUserData(
        fields: "email,name",
      );

      AppLogger.debug("Facebook User Data: $userData");

      final String? email = userData['email'];
      final String? fullName = userData['name'];

      if (email == null || fullName == null) {
        LoadingManager.hideLoading();
        CustomSnackBar.show(context, "Failed to retrieve user data", type: ToastificationType.error);
        return;
      }

      AppLogger.debug("Facebook User: $email, $fullName");

      final apiService = ApiService();
      final userTypeController = Get.find<UserTypeController>();

      final response = await apiService.socialSignUpSignIn({
        "email": email,
        "full_name": fullName,
        "role": isTherapist ? "therapist" : "client",
        "auth_provider": "facebook",
      });

      LoadingManager.hideLoading();

      final role = response['profile_data']?['role'] ?? 'client';
      final isTherapistFromResponse = role == 'therapist';
      final userId = response['profile_data']?['user']; // Extract user
      final profileId = response['profile_data']?['id']; // Extract id

      if (userId == null || profileId == null) {
        AppLogger.error("Missing user or id in socialSignUpSignIn response: $response");
        CustomSnackBar.show(context, "Failed to retrieve user profile data", type: ToastificationType.error);
        return;
      }

      userTypeController.setUserType(isTherapistFromResponse);

      CustomSnackBar.show(context, "Facebook Sign-In successful!", type: ToastificationType.success);

      Get.toNamed(
        '/profileSetup',
        arguments: {
          'isTherapist': isTherapistFromResponse,
          'email': email,
          'full_name': fullName,
          'source': 'social',
          'user_id': userId, // Pass user as user_id
          'profile_id': profileId, // Pass id as profile_id
        },
      );
    } catch (e, stackTrace) {
      LoadingManager.hideLoading();

      String errorMessage = "Failed to sign in with Facebook";
      if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      }
      AppLogger.error("Facebook Sign-In Error: $e", e, stackTrace);
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
                hintText: "Enter your name",
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
                      child: Divider(thickness: 1.w, color: Color(0xffE8ECF4)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Or Sign up with",
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Color(0xff6A707C),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 0.25.sw,
                      child: Divider(thickness: 1.w, color: Color(0xffE8ECF4)),
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