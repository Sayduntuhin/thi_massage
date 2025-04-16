import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
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
      final isTherapist = Get.arguments?['isTherapist'] ?? false;

      final response = await apiService.login({
        "email": emailController.text.trim(),
        "password": passwordController.text.trim(),
      });

      LoadingManager.hideLoading();

      // Set user role
      final role = response['user_profile']?['role'] ?? 'client';
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

    LoadingManager.showLoading();

    try {
      // Sign in with Google via Firebase
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        LoadingManager.hideLoading();
        CustomSnackBar.show(context, "Google Sign-In canceled",
            type: ToastificationType.warning);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        LoadingManager.hideLoading();
        CustomSnackBar.show(context, "Failed to retrieve user data",
            type: ToastificationType.error);
        return;
      }

      debugPrint("Firebase User: ${firebaseUser.email}, ${firebaseUser.displayName}");

      // Call backend API
      final apiService = ApiService();
      final userTypeController = Get.find<UserTypeController>();

      final response = await apiService.socialSignUpSignIn({
        "email": firebaseUser.email ?? "",
        "full_name": firebaseUser.displayName ?? "Google User",
        "role": isTherapist ? "therapist" : "client",
        "auth_provider": "google",
      });

      LoadingManager.hideLoading();

      // Use the role from the backend response
      final role = response['user_profile']?['role'] ?? 'client';
      final isTherapistFromResponse = role == 'therapist';
      userTypeController.setUserType(isTherapistFromResponse);

      CustomSnackBar.show(context, "Google Sign-In successful!",
          type: ToastificationType.success);

      Get.offAllNamed('/homePage',
          arguments: {'isTherapist': isTherapistFromResponse});
    } catch (e) {
      LoadingManager.hideLoading();

      String errorMessage;
      if (e is FirebaseAuthException) {
        errorMessage = "Firebase error: ${e.message}";
        if (e.code == 'account-exists-with-different-credential') {
          errorMessage = "This email is already registered with another provider.";
        }
      } else if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      } else {
        errorMessage = "Failed to sign in with Google: $e";
      }
      debugPrint("Google Sign-In Error: $e");
      CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
    }
  }

  Future<void> handleFacebookSignIn() async {
    final isTherapist = Get.arguments?['isTherapist'] ?? false;

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
        LoadingManager.hideLoading();
        CustomSnackBar.show(context, "Failed to retrieve user data",
            type: ToastificationType.error);
        return;
      }

      debugPrint("Facebook User: $email, $fullName");

      // Call backend API
      final apiService = ApiService();
      final userTypeController = Get.find<UserTypeController>();

      final response = await apiService.socialSignUpSignIn({
        "email": email,
        "full_name": fullName,
        "role": isTherapist ? "therapist" : "client",
        "auth_provider": "facebook",
      });

      LoadingManager.hideLoading();

      // Use the role from the backend response
      final role = response['user_profile']?['role'] ?? 'client';
      final isTherapistFromResponse = role == 'therapist';
      userTypeController.setUserType(isTherapistFromResponse);

      CustomSnackBar.show(context, "Facebook Sign-In successful!",
          type: ToastificationType.success);

      Get.offAllNamed('/homePage',
          arguments: {'isTherapist': isTherapistFromResponse});
    } catch (e) {
      LoadingManager.hideLoading();

      String errorMessage;
      if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      } else {
        errorMessage = "Failed to sign in with Facebook: $e";
      }
      debugPrint("Facebook Sign-In Error: $e");
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
                    onTap: () => debugPrint("Tap Apple"),
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