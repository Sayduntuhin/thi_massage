// lib/features/auth/presentation/pages/sign_up_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:toastification/toastification.dart';
import '../../../../api/api_service.dart';
import '../../../../controller/user_controller.dart';
import '../../../../themes/colors.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_snackbar.dart';
import '../../../widgets/loading_indicator.dart';
import '../../widgets/customTextField.dart';
import '../widgets/phone_code_picker.dart';

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

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
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
    if (!RegExp(r'^[\+]?[0-9]{7,15}$').hasMatch(phone)) {
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

    debugPrint("Phone number entered: ${phoneController.text.trim()}");

    LoadingManager.showLoading();

    try {
      final apiService = ApiService();
      final userTypeController = Get.find<UserTypeController>();
      final isTherapist = Get.arguments?['isTherapist'] ?? false;

      final response = await apiService.signUp({
        "email": emailController.text.trim(),
        "full_name": nameController.text.trim(),
        "phone_number": phoneController.text.trim(),
        "password": passwordController.text.trim(),
        "role": isTherapist ? "therapist" : "client",
      });

      LoadingManager.hideLoading();

      userTypeController.setUserType(isTherapist);

      CustomSnackBar.show(context, "Signup successful! Please verify your email.", type: ToastificationType.success);

      Get.toNamed(
        '/otpVerification',
        arguments: {
          "source": "signup",
          "email": emailController.text.trim(),
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
        CustomSnackBar.show(context, "Google Sign-In canceled", type: ToastificationType.warning);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        LoadingManager.hideLoading();
        CustomSnackBar.show(context, "Failed to retrieve user data", type: ToastificationType.error);
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

      CustomSnackBar.show(context, "Google Sign-In successful!", type: ToastificationType.success);

      Get.toNamed(
        '/profileSetup',
        arguments: {'isTherapist': isTherapistFromResponse},
      );
    } catch (e) {
      LoadingManager.hideLoading();

      String errorMessage;
      if (e is FirebaseAuthException) {
        errorMessage = "Firebase error: ${e.message}";
        if (e.code == 'account-exists-with-different-credential') {
          errorMessage = "This email is already registered with another provider.";
        }
      } else if (e is BadRequestException) {
        errorMessage = e.message; // Displays role conflict error
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      } else {
        errorMessage = "Failed to sign in with Google: $e";
      }
      debugPrint("Google Sign-In Error: $e");
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
                    onTap: () => debugPrint("Tap Facebook"),
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