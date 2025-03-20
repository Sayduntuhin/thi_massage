import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategoryItem extends StatelessWidget {
  final String title;
  final String image;
  const CategoryItem({super.key, required this.title, required this.image});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(image, width: 80.w),
        SizedBox(height: 5.h),
        Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
