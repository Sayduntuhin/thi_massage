import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:thi_massage/routers/app_router.dart';
import 'package:thi_massage/view/widgets/custom_gradientButton.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_button.dart';

class ReviewSubmittedPage extends StatelessWidget {
  const ReviewSubmittedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              const CustomAppBar(), // Back + Logo
              Spacer(),

              /// Book/Document SVG
              SvgPicture.asset(
                'assets/svg/review_book.svg', // Replace with your SVG path
                height: 150.h,
              ),
              SizedBox(height: 40.h),

              /// Message
              Text(
                "Your documents have been submitted\nfor verification. Our team will get back\nto you soon.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff333333),
                ),
              ),
              const Spacer(flex: 1,),

              /// Contact Support Button
              CustomGradientButton(text: "Contact Support", onPressed: () {
                // Navigate or open chat/help
                Get.toNamed(Routes.supportPage);
              },),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
