import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool showIcon; // If true, show add icon
  const CustomGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.showIcon = false, // Default false, only show when needed
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Full width button
      height: 50.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFB28D28), // Gradient start color
            Color(0xFF8F5E0A), // Gradient end color
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.r),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showIcon) // Show icon only if `showIcon` is true
              Padding(
                padding: EdgeInsets.only(right: 8.w,bottom: 2.h),
                child: Image.asset("assets/images/plus.png",width: 20.w,),
              ),
            Text(
              text,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Urbanist'
              ),
            ),
          ],
        ),
      ),
    );
  }
}
