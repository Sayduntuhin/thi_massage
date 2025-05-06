import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_appbar.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: SecondaryAppBar(title: "Support"),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30.h),
            // Title
            Text(
              "Support",
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
              "If you have any query or complaint, \nplease contact,",
              style: TextStyle(
                fontSize: 14.sp,
                color: secounderyTextColor,
                fontFamily: "Urbanist",
              ),
            ),

            SizedBox(height: 30.h),

            // Email Support
            _buildSupportItem(
              icon: Icons.email_outlined,
              text: "support@thaimassage.com",
              onTap: () {
                debugPrint("Opening Email...");
              },
            ),

            SizedBox(height: 20.h),

            // Phone Support
            _buildSupportItem(
              icon: Icons.phone,
              text: "+1 0123 456789",
              onTap: () {
                debugPrint("Calling Support...");
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportItem({required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: boxColor,
              shape: BoxShape.circle,
              border: Border.all(color: secounderyBorderColor.withAlpha(60), width: 1.5.w),
            ),
            child: Icon(icon, color: primaryTextColor, size: 22.sp),
          ),
          SizedBox(width: 10.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: primaryTextColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}
