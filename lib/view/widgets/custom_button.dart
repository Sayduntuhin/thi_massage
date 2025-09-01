import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
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
  final bool isLoading; // New property for loading state

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
    this.isLoading = false, // Default to false
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
        onPressed: isLoading ? () {} : onPressed, // Disable button when loading
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? (isLoading ? Colors.grey[400] : defaultPrimaryColor),
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
          alignment: Alignment.center,
        ),
        child: isLoading
            ? LoadingAnimationWidget.hexagonDots(
          color: textColor ?? Colors.white,
          size: 24.sp, // Adjusted for button size
        )
            : Text(
          text,
          style: TextStyle(
            fontSize: fontsize.sp,
            fontWeight: FontWeight.w500,
            fontFamily: "Urbanist",
            color: textColor ?? defaultTextColor, // Ensure text color consistency
          ),
        ),
      )
          : OutlinedButton(
        onPressed: isLoading ? () {} : onPressed, // Disable button when loading
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
        child: isLoading
            ? LoadingAnimationWidget.hexagonDots(
          color: buttonTextColor,
          size: 24.sp,
        )
            : Text(
          text,
          style: TextStyle(
            fontSize: fontsize.sp,
            fontWeight: FontWeight.w400,
            color: buttonTextColor,
            fontFamily: "Urbanist",
          ),
        ),
      ),
    );
  }
}