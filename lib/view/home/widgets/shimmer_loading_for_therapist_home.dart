// Shimmer widget for appointments
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class AppointmentCardShimmer extends StatelessWidget {
  const AppointmentCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: 0.8.sw,
          margin: EdgeInsets.only(right: 12.w),
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundColor: Colors.grey[300],
                  ),
                  SizedBox(width: 5.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100.w,
                          height: 14.h,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 2.h),
                        Container(
                          width: 150.w,
                          height: 11.h,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60.w,
                    height: 14.h,
                    color: Colors.grey[300],
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 50.w,
                    height: 12.h,
                    color: Colors.grey[300],
                  ),
                  Container(
                    width: 80.w,
                    height: 12.h,
                    color: Colors.grey[300],
                  ),
                  Container(
                    width: 60.w,
                    height: 12.h,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Shimmer widget for appointment requests
class AppointmentRequestCardShimmer extends StatelessWidget {
  const AppointmentRequestCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          children: [
            Container(
              height: 0.1.sh,
              width: 0.18.sw,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  bottomLeft: Radius.circular(12.r),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 0.1.sh,
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12.r),
                    bottomRight: Radius.circular(12.r),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 100.w,
                          height: 16.h,
                          color: Colors.grey[300],
                        ),
                        Container(
                          width: 60.w,
                          height: 12.h,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 80.w,
                          height: 13.h,
                          color: Colors.grey[300],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 50.w,
                              height: 20.h,
                              color: Colors.grey[300],
                            ),
                            SizedBox(width: 6.w),
                            Container(
                              width: 50.w,
                              height: 20.h,
                              color: Colors.grey[300],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}