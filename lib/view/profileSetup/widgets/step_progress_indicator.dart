import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StepProgressIndicator extends StatelessWidget {
  final int currentStep;

  const StepProgressIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle("1", currentStep >= 1),
        _buildProgressLine(currentStep > 1),
        _buildStepCircle("2", currentStep >= 2),
      ],
    );
  }

  Widget _buildStepCircle(String label, bool isActive) {
    return Container(
      width: 28.w,
      height: 28.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xff895B0E) : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black54,
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      width: 40.w,
      height: 4.h,
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2.r),
        color: isActive ? const Color(0xff895B0E) : Colors.grey.shade300,
      ),
    );
  }
}
