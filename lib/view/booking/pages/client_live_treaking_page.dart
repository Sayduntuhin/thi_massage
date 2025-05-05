import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../themes/colors.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background map
          SizedBox.expand(
            child: Image.asset(
              'assets/images/map.png', // Replace with your map image or real map
              fit: BoxFit.cover,
            ),
          ),

          /// Back button
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Container(
                width: 30.w,
                height: 35.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5.r)],
                  ),
                  child: IconButton(onPressed: Get.back, icon:  Icon(Icons.arrow_back_ios,color: primaryColor,))),
            ),
          ),

          /// Source and destination points
          Positioned(
            top: 100.h,
            left: 40.w,
            child: Column(
              children: [
                _mapPin("Hamill Ave"),
                SizedBox(height: 150.h),
                _destinationPin("San Diego"),
              ],
            ),
          ),

          /// Dashed path (mocked line)
          Positioned(
            top: 130.h,
            left: 80.w,
            child: RotatedBox(
              quarterTurns: 1,
              child: Container(
                width: 180.h,
                child: CustomPaint(
                  painter: DottedLinePainter(),
                ),
              ),
            ),
          ),

          /// Navigate button
          Positioned(
            bottom: 280.h,
            left: 0,
            right: 0.2.sh,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.navigation, color: primaryTextColor),
                label: Text("Navigate", style: TextStyle(color: primaryTextColor,fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                ),
              ),
            ),
          ),

          /// Bottom Card
          Positioned(
            bottom: 150.h,
            left: 0,
            right: 0,
            child: Container(
              height: 0.12.sh,
              padding: EdgeInsets.symmetric(horizontal: 16.w,),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFB28D28), // Gradient start color
                    Color(0xFF8F5E0A), // Gradient end color
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5.r)],
              ),
              child: Padding(
                padding:  EdgeInsets.only(top: 0.02.sh),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage('assets/images/fevTherapist1.png'),
                      radius: 24.r,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("Mical Martinez", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              SizedBox(width: 4.w),
                              SvgPicture.asset("assets/svg/male.svg"),
                            ],
                          ),
                          Text("Thai Massage Therapist", style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                        ],
                      ),
                    ),
                    SvgPicture.asset("assets/svg/chat_white.svg"),
                    SizedBox(width: 12.w),
                    SvgPicture.asset("assets/svg/phone.svg"),

                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 30.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5.r)],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - timeline with dots
                  Column(
                    children: [
                      // Top dot (Estimated time)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.access_time, color: Colors.white, size: 16),
                      ),
                      // Line connecting dots
                      Container(
                        width: 2,
                        height: 40.h,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      // Middle dot (starting point)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                      // Line connecting dots
                      Container(
                        width: 2,
                        height: 25.h,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      // Bottom triangle (destination)
                      Icon(Icons.location_on, color: Colors.black, size: 18),
                    ],
                  ),

                  SizedBox(width: 16.w),

                  // Right side - text information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Estimated time
                        Text("Estimated time", style: TextStyle(fontSize: 13.sp, color: Colors.grey)),
                        Text("28 min", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),

                        SizedBox(height: 14.h),

                        // Starting point
                        Text("Hamill Ave", style: TextStyle(fontSize: 14.sp)),

                        SizedBox(height: 20.h),

                        // Destination
                        Text("San Diego", style: TextStyle(fontSize: 14.sp)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _mapPin(String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Text(label, style: TextStyle(fontSize: 12.sp)),
        ),
        Icon(Icons.location_pin, color: Color(0xffB48D3C), size: 28.sp),
      ],
    );
  }

  Widget _destinationPin(String label) {
    return Column(
      children: [
        Icon(Icons.location_on, color: Color(0xffB48D3C), size: 30.sp),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Text(label, style: TextStyle(fontSize: 12.sp)),
        ),
      ],
    );
  }
}

/// Dashed line painter (vertical)
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 5, dashSpace = 5;
    double startY = 0;
    final paint = Paint()
      ..color = const Color(0xffB48D3C)
      ..strokeWidth = 2;
    while (startY < size.width) {
      canvas.drawLine(Offset(startY, 0), Offset(startY + dashWidth, 0), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
