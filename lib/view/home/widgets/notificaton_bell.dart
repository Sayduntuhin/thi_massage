import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class NotificationBell extends StatelessWidget {
  final int notificationCount;
  final String svgAssetPath;
  final String navigateTo;


  const NotificationBell({
    super.key,
    this.notificationCount = 0,
    required this.svgAssetPath,
    required this.navigateTo,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Get.toNamed(navigateTo);
      },
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          // Background Circle
          Container(
            width: 50.w,
            height: 50.h,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9EC), // Light background
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF3E9D2), width: 2), // Light border
            ),
            child: Center(
              child: SvgPicture.asset(
                svgAssetPath, // Load SVG
                width: 25.w,
                height: 25.h,
                colorFilter: const ColorFilter.mode(Color(0xFFB28D28), BlendMode.srcIn), // Gold color
              ),
            ),
          ),

          // Notification Badge
          if (notificationCount > 0)
            Positioned(
              top: 8.h,
              right: 10.w,
              child: Container(
                width: 14.w,
                height: 14.h,
                decoration: BoxDecoration(
                  color: Colors.red, // Red notification dot
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2), // White border
                ),
              ),
            ),
        ],
      ),
    );
  }
}
