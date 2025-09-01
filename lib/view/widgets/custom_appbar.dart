import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:thi_massage/themes/colors.dart';

class CustomAppBar extends StatelessWidget {
  final bool showBackButton;

  const CustomAppBar({super.key, this.showBackButton = true}); // ✅ Default true

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBackButton) // ✅ Only show when true
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
              border: Border.all(color: buttonBorderColor.withAlpha(60), width: 1.0),
            ),
            child: IconButton(
              icon: Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: Icon(Icons.arrow_back_ios, size: 24.sp, color: primaryButtonColor),
              ),
              onPressed: () {
                Get.back();
              },
            ),
          ),
        if(!showBackButton)
          SizedBox(
            width: 50.w,
            height: 50.h,
          ),
          Spacer(), // ✅ Maintain spacing when back button exists

        Center(
          child: Image.asset(
            'assets/images/logo.png',
            width: 0.5.sw,
          ),
        ),

        Spacer(flex: 2), // ✅ Keeps logo centered properly
      ],
    );
  }
}


class SecondaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showManuButton; // Default to false
  final VoidCallback? onMenuPressed; // Callback for menu button

  const SecondaryAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.showManuButton = false, // Default to false
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false, // Remove default back button
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      centerTitle: true, // Keeps title centered
      leadingWidth: (showBackButton || showManuButton) ? 0.14.sw : 0,
      leading: (showBackButton || showManuButton)
          ? Padding(
        padding: EdgeInsets.only(left: 10.w, top: 5.h, bottom: 5.h),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
            border: Border.all(color: buttonBorderColor.withAlpha(60), width: 1.0),
          ),
          child: showBackButton
              ? IconButton(
            icon: Padding(
              padding: EdgeInsets.only(left: 5.w),
              child: Icon(Icons.arrow_back_ios, size: 20.sp, color: primaryButtonColor),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          )
              : IconButton(
            icon: Icon(Icons.menu, size: 20.sp, color: primaryButtonColor),
            onPressed: onMenuPressed,
          ),
        ),
      )
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(56.h);
}