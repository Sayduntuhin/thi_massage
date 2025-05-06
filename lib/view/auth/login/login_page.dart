import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:logger/logger.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';
import 'package:toastification/toastification.dart';
import '../../../../api/api_service.dart';
import '../../../../controller/user_controller.dart';
import '../../../../themes/colors.dart';
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
  bool rememberMe = false;
  var logger = Logger();

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
      final apiService = ApiService();
      final userTypeController = Get.find<UserTypeController>();

      final response = await apiService.login({
        "email": emailController.text.trim(),
        "password": passwordController.text.trim(),
      });

      LoadingManager.hideLoading();

      // Set user role
      final role = response['profile_data']?['role'] ?? 'client';
      userTypeController.setUserType(role == 'therapist');

      CustomSnackBar.show(context, "Login successful!",
          type: ToastificationType.success);

      Get.offAllNamed('/homePage', arguments: {'isTherapist': role == 'therapist'});
    } catch (e) {
      LoadingManager.hideLoading();

      String errorMessage = "Failed to login. Please try again.";
      if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is UnauthorizedException) {
        errorMessage = "Invalid email or password.";
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      }
      CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
    }
  }
  Future<void> handleGoogleSignIn() async {
    final isTherapist = Get.arguments?['isTherapist'] ?? false;
    AppLogger.debug('Google Sign-In: isTherapist argument = $isTherapist');

    LoadingManager.showLoading();

    try {
      // Initialize GoogleSignIn with clientId and serverClientId
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: '1048463216573-xyz123.apps.googleusercontent.com',
        serverClientId: '1048463216573-68qmf5ml28m1f8uol09cstfno4jb33gk.apps.googleusercontent.com',
      );

      // Sign out to ensure fresh login
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      AppLogger.debug('Google Sign-In: Signed out previous sessions');

      // Sign in with Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        AppLogger.debug("Google Sign-In: User canceled sign-in");
        LoadingManager.hideLoading();
        CustomSnackBar.show(context, "Google Sign-In canceled",
            type: ToastificationType.warning);
        return;
      }

      AppLogger.debug("Google Sign-In: User selected ${googleUser.email}");

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception("Google Sign-In: No ID token received");
      }

      AppLogger.debug("Google Sign-In: ID token received");

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception("Google Sign-In: Failed to retrieve Firebase user data");
      }

      AppLogger.debug("Firebase User: ${firebaseUser.email}, ${firebaseUser.displayName}");

      // Call backend API
      final apiService = ApiService();
      final userTypeController = Get.find<UserTypeController>();

      final response = await apiService.socialSignUpSignIn({
        "email": firebaseUser.email ?? "",
        "full_name": firebaseUser.displayName ?? "Google User",
        "role": isTherapist ? "therapist" : "client",
        "auth_provider": "google",
      });

      AppLogger.debug('Backend response: $response');
      AppLogger.debug('Role from response: ${response['profile_data']?['role']}');

      LoadingManager.hideLoading();

      // Use the role from the backend response
      final role = response['profile_data']?['role'] ?? (isTherapist ? 'therapist' : 'client');
      final isTherapistFromResponse = role == 'therapist';
      AppLogger.debug('Setting userType: $isTherapistFromResponse');
      userTypeController.setUserType(isTherapistFromResponse);

      CustomSnackBar.show(context, "Google Sign-In successful!",
          type: ToastificationType.success);

      AppLogger.debug('Navigating to /homePage with isTherapist: $isTherapistFromResponse');
      Get.offAllNamed('/homePage',
          arguments: {'isTherapist': isTherapistFromResponse});
    } catch (e) {
      LoadingManager.hideLoading();

      String errorMessage = "Failed to sign in with Google. Please try again.";
      if (e is PlatformException) {
        AppLogger.error("Google Sign-In PlatformException: Code=${e.code}, Message=${e.message}, Details=${e.details}");
        if (e.code == 'sign_in_failed') {
          errorMessage = "Google Sign-In failed. Please check your Google account or app configuration.";
          if (e.message?.contains('ApiException: 10') == true) {
            errorMessage = "Configuration error: Verify OAuth client ID, SHA-1, and package name in Firebase Console.";
          }
        } else if (e.code == 'network_error') {
          errorMessage = "Network error. Please check your internet connection.";
        }
      } else if (e is FirebaseAuthException) {
        AppLogger.error("FirebaseAuthException: Code=${e.code}, Message=${e.message}");
        errorMessage = "Firebase error: ${e.message}";
        if (e.code == 'account-exists-with-different-credential') {
          errorMessage = "This email is already registered with another provider.";
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
      // Sign in with Facebook
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

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

      // Get user data
      final userData = await FacebookAuth.instance.getUserData(
        fields: "email,name",
      );

      final String? email = userData['email'];
      final String? fullName = userData['name'];

      if (email == null || fullName == null) {
        throw Exception("Facebook Sign-In: Failed to retrieve user data");
      }

      AppLogger.debug("Facebook User: $email, $fullName");

      // Call backend API
      final apiService = ApiService();
      final userTypeController = Get.find<UserTypeController>();

      final response = await apiService.socialSignUpSignIn({
        "email": email,
        "full_name": fullName,
        "role": isTherapist ? "therapist" : "client",
        "auth_provider": "facebook",
      });

      AppLogger.debug('Backend response: $response');
      AppLogger.debug('Role from response: ${response['profile_data']?['role']}');

      LoadingManager.hideLoading();

      // Use the role from the backend response
      final role = response['profile_data']?['role'] ?? (isTherapist ? 'therapist' : 'client');
      final isTherapistFromResponse = role == 'therapist';
      AppLogger.debug('Setting userType: $isTherapistFromResponse');
      userTypeController.setUserType(isTherapistFromResponse);

      CustomSnackBar.show(context, "Facebook Sign-In successful!",
          type: ToastificationType.success);

      AppLogger.debug('Navigating to /homePage with isTherapist: $isTherapistFromResponse');
      Get.offAllNamed('/homePage',
          arguments: {'isTherapist': isTherapistFromResponse});
    } catch (e) {
      LoadingManager.hideLoading();

      String errorMessage = "Failed to sign in with Facebook. Please try again.";
      if (e is BadRequestException) {
        errorMessage = e.message;
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
                    onTap: () => AppLogger.debug("Tap Apple"),
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