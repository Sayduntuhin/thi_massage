import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../widgets/custom_button.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Top image section with gradient overlay
            Stack(
              children: [
                // Image container
                Container(
                  height: 0.5.sh,
                  width: 1.sw,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/welcome.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Gradient overlay for smooth transition
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 50.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withAlpha(0),
                          Colors.white,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Logo and buttons section
            Expanded(
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 0.08.sw),
                child: Column(
                  children: [
                    // Thai Massage logo
                    SizedBox(
                      width: 0.7.sw,
                      height: 0.2.sh,
                      child: Image.asset('assets/images/logo.png'),
                    ),
                    SizedBox(height: 0.03.sh,),
                    // Login button
                    ThaiMassageButton(
                      text: 'Login',
                      isPrimary: true,
                      onPressed: () {
                        Get.toNamed('/logIn');
                        debugPrint('Login button pressed');
                      },
                    ),
                    SizedBox(height: 0.02.sh,),
                    // Sign up button
                    ThaiMassageButton(
                      text: 'Sign up',
                      isPrimary: false,
                      onPressed: () {
                        Get.toNamed('/signUp');
                        debugPrint('Sign up button pressed');
                      },
                    ),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}