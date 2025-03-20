import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:thi_massage/routers/app_router.dart';
import 'package:thi_massage/view/auth/signup/widgets/phone_code_picker.dart';
import '../../../../themes/colors.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/custom_button.dart';
import '../../widgets/customTextField.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
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

              // Title
              Text(
                "Sign up",
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

              // Name Field
              CustomTextField(
                hintText: "Enter your name",
                icon: Icons.person_outline,
              ),
              SizedBox(height: 15.h),

              // Email Field
              CustomTextField(
                hintText: "Enter your email",
                icon: Icons.email_outlined,
              ),
              SizedBox(height: 15.h),

              // Phone Number Field
              PhoneNumberField(),
              SizedBox(height: 20.h),

              // Sign Up Button
              ThaiMassageButton(
                text: "Sign up",
                isPrimary: true,
                onPressed: () {
                  Get.toNamed(Routes.otpVerification,arguments: "signup");
                },
              ),
              SizedBox(height: 20.h),

              // Or Sign Up With
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 0.3.sw,
                      child: Divider(
                          thickness: 1.w,
                          color: Color(0xffE8ECF4)
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Or Login with",
                        style: TextStyle(fontSize: 14.sp, color:Color(0xff6A707C)),
                      ),
                    ),
                    SizedBox(
                      width: 0.3.sw,
                      child: Divider(
                          thickness: 1.w,
                          color: Color(0xffE8ECF4)
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),

              // Social Login Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => debugPrint("Tap Facebook"),
                    child: Image.asset('assets/images/facebook.png', width: 50.w),
                  ),
                  SizedBox(width: 20.w),
                  InkWell(
                    onTap: () => debugPrint("Tap Google"),
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

              // Login Navigation
              Center(
                child: RichText(
                  text: TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
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
