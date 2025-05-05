import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../themes/colors.dart';

class ThaiMassageButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final double? width;
  final double fontsize;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const ThaiMassageButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.width,
    this.height = 55,
    this.fontsize = 16,
    this.borderRadius = 25,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPrimaryColor = primaryButtonColor;
    final defaultTextColor = isPrimary ? Colors.white : Colors.black54;
    final defaultBorderColor = buttonBorderColor;

    return SizedBox(
      width: width ?? double.infinity,
      height: height.h,
      child: isPrimary
          ? ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? defaultPrimaryColor,
          foregroundColor: textColor ?? defaultTextColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius.r),
            side: BorderSide(
              color: borderColor ?? defaultBorderColor,
              width: 1.w,
            ),
          ),
          elevation: 0,
          minimumSize: Size(width ?? double.infinity, height.h),
          alignment: Alignment.center, // Ensures text stays centered
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontsize.sp,
            fontWeight: FontWeight.w500,
            fontFamily: "Urbanist",
          ),
        ),
      )

          : OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: borderColor ?? defaultBorderColor,
            width: 1.w,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius.r),
          ),
          minimumSize: Size(width ?? double.infinity, height.h),
          alignment: Alignment.center,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontsize.sp,
            fontWeight: FontWeight.w400,
            color: buttonTextColor,
          ),
        ),
      )

    );
  }
}