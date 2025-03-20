import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PromotionCard extends StatelessWidget {
  final String image;
  final String discount;
  final String description;
  final VoidCallback onTap;

  const PromotionCard({
    super.key,
    required this.image,
    required this.discount,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          image: DecorationImage(
            image: AssetImage(image),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              discount,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              description,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10.h),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text("Invite Now", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
