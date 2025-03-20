import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_button.dart';
import '../widgets/customTextField.dart';


class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
              Text(
                "Welcome!",
                style: TextStyle(
                  fontSize: 42.sp,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                  fontFamily: "PlayfairDisplay"
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                "Login to continue",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: secounderyTextColor,
                    fontFamily: "Urbanist"
                ),
              ),
              SizedBox(height: 20.h),
              CustomTextField(
                hintText: "Enter your email",
                icon: Icons.email_outlined,
              ),
              SizedBox(height: 15.h),
              CustomTextField(
                hintText: "Enter your password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Checkbox(value: false, onChanged: (value) {}),
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
                onPressed: () {

                  Get.offNamed('/homePage');
                },
              ),
              SizedBox(height: 20.h),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                      onTap: (){debugPrint("Tap Facebook");},
                      child: Image.asset('assets/images/facebook.png', width: 50.w)),
                  SizedBox(width: 20.w),
                  InkWell(  onTap: (){debugPrint("Tap Google");},child: Image.asset('assets/images/google.png', width: 50.w)),
                  SizedBox(width: 20.w),
                  InkWell(  onTap: (){debugPrint("Tap Apple");},child: Image.asset('assets/images/apple.png', width: 50.w)),
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
                            Get.toNamed("/signUp");
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
