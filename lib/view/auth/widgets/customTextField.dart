import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../themes/colors.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.icon,
    this.isPassword = false,

  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: isPassword,
      autofocus: true,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black),
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 14.sp, color: Colors.black54),
        filled: true,
        fillColor: textFieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.r),
          borderSide: BorderSide(color: borderColor.withAlpha(40), width: 1.5.w),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.r),
          borderSide: BorderSide(color: borderColor.withAlpha(40), width: 1.5.w),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.r),
          borderSide: BorderSide(color: borderColor.withAlpha(40), width: 2.w),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16.h ),
      ),
    );
  }
}