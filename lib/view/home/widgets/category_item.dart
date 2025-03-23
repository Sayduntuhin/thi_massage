import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategoryItem extends StatelessWidget {
  final String title;
  final String image;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryItem({
    super.key,
    required this.title,
    required this.image,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 0.3.sw,
            height: 0.12.sh,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              image: DecorationImage(
                image: AssetImage(image),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background shade when selected
                if (isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        color: const Color(0xFFB28D28).withOpacity(0.5), // Move color inside BoxDecoration
                      ),
                    ),
                  ),
                // Check icon when selected
                if (isSelected)
                  Container(
                    padding: EdgeInsets.all(5.w),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.black,
                      size: 20.sp,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 0.04.sh,
            width: 0.3.sw,
            child: Text(
              title,
              maxLines: 2,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                fontFamily: "Urbanist",
                color:  const Color(0xff666561),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}