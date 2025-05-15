import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../controller/user_type_controller.dart';
import '../../widgets/custom_button.dart';


class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final UserTypeController userTypeController = Get.put(UserTypeController());

    // Show the bottom sheet after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUserTypeBottomSheet(context, userTypeController);
    });

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Top image section with gradient overlay
            Stack(
              children: [
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

            // Logo and login/signup buttons
            Expanded(
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 0.08.sw),
                child: Column(
                  children: [
                    SizedBox(
                      width: 0.7.sw,
                      height: 0.2.sh,
                      child: Image.asset('assets/images/logo.png'),
                    ),
                    SizedBox(height: 0.03.sh),
                    // Use Obx to rebuild the UI when isTherapist changes
                    Obx(() {
                      // If no user type is selected, show a placeholder message
                      final userTypeText = userTypeController.isTherapist.value
                          ? "Therapist"
                          : "Client";

                      return Column(
                        children: [
                          // Optional: Add a welcome message
                          Text(
                            "Welcome, $userTypeText!",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 0.03.sh),
                          ThaiMassageButton(
                            text: 'Login as $userTypeText',
                            isPrimary: true,
                            onPressed: () {
                              Get.toNamed('/logIn',
                                  arguments: {'isTherapist': userTypeController.isTherapist.value});
                            },
                          ),
                          SizedBox(height: 0.02.sh),
                          ThaiMassageButton(
                            text: 'Sign up as $userTypeText',
                            isPrimary: false,
                            onPressed: () {
                              Get.toNamed('/signUp',
                                  arguments: {'isTherapist': userTypeController.isTherapist.value});
                            },
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet to select user type
  void _showUserTypeBottomSheet(BuildContext context, UserTypeController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Continue as",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff222222),
                ),
              ),
              SizedBox(height: 20.h),
              ThaiMassageButton(
                text: "Client",
                isPrimary: true,
                onPressed: () {
                  // Update the user type in the controller
                  controller.setUserType(false);
                  // Close the bottom sheet
                  Navigator.pop(context);
                  // Stay on the WelcomePage (no navigation)
                },
              ),
              SizedBox(height: 12.h),
              ThaiMassageButton(
                text: "Therapist",
                isPrimary: false,
                onPressed: () {
                  // Update the user type in the controller
                  controller.setUserType(true);
                  // Close the bottom sheet
                  Navigator.pop(context);
                  // Stay on the WelcomePage (no navigation)
                },
              ),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }
}