import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../themes/colors.dart';
import '../../auth/signup/widgets/phone_code_picker.dart';
import '../../auth/widgets/customTextField.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_gradientButton.dart';

class InviteFriendPage extends StatelessWidget {
  const InviteFriendPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SecondaryAppBar(title: "Invite Friend"),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom AppBar

            // Title
            Text(
              "Invite friend",
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
                fontFamily: "PlayfairDisplay",
              ),
            ),

            SizedBox(height: 5.h),

            // Subtitle
            Text(
              "Invite friends and get promo codes",
              style: TextStyle(
                fontSize: 14.sp,
                color: secounderyTextColor,
                fontFamily: "Urbanist",
              ),
            ),

            SizedBox(height: 20.h),

            // Email Input
            const CustomTextField(
              hintText: "Enter email",
              icon: Icons.email_outlined,
            ),

            SizedBox(height: 20.h),

            // Divider with Text
            _buildDividerWithText("Or Sign up with"),

            SizedBox(height: 20.h),

            // Phone Number Field
            const PhoneNumberField(),

            SizedBox(height: 60.h),

            // Send Invite Button
            CustomGradientButton(
              text: "Send Invite",
              onPressed: () {
                debugPrint("Invite Sent!");
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDividerWithText(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 0.25.sw,
          child: Divider(
            thickness: 1.w,
            color: const Color(0xffE8ECF4),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Text(
            text,
            style: TextStyle(fontSize: 14.sp, color: const Color(0xff6A707C)),
          ),
        ),
        SizedBox(
          width: 0.25.sw,
          child: Divider(
            thickness: 1.w,
            color: const Color(0xffE8ECF4),
          ),
        ),
      ],
    );
  }
}
