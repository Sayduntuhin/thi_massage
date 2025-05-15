import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class TherapistCardShimmer extends StatelessWidget {
  const TherapistCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200.h, // Match TherapistCarousel height
      width: 0.8.sw, // Match viewportFraction: 0.8
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.r),
          ),
        ),
      ),
    );
  }
}