import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../themes/colors.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly; // Added for read-only mode
  final bool isVisible; // Added for visibility toggle

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.controller,
    this.keyboardType,
    this.onChanged,
    this.readOnly = false, // Default to false (editable)
    this.isVisible = true, // Default to true (visible)
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true; // Tracks password visibility state

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword; // Initialize based on isPassword
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink(); // Return empty widget if not visible
    }

    return TextField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false, // Use _obscureText for password fields
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      readOnly: widget.readOnly, // Apply read-only property
      decoration: InputDecoration(
        prefixIcon: Icon(widget.icon, color: Colors.black),
        suffixIcon: widget.isPassword
            ? IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.black54,
          ),
          onPressed: _togglePasswordVisibility,
        )
            : null, // Show eye button only for password fields
        hintText: widget.hintText,
        hintStyle: TextStyle(fontSize: 14.sp, color: Colors.black54),
        filled: true,
        fillColor: widget.readOnly ? Colors.grey.shade200 : textFieldColor, // Optional: Change background for read-only
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
        contentPadding: EdgeInsets.symmetric(vertical: 16.h),
      ),
    );
  }
}