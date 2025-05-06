import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:thi_massage/themes/colors.dart';

import '../../client_profile/pages/profile_page.dart';

class AppointmentDetailScreen extends StatelessWidget {
  const AppointmentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with CustomPainter
          Stack(
            children: [
              Container(
                height: 0.3.sh,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xffB48D3C),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24.r),
                    bottomRight: Radius.circular(24.r),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: CurveShapePainter(),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(onPressed: Get.back, icon: Icon(Icons.arrow_back_ios,color: Colors.white,)),
                      SizedBox(height: 5.h),
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: SizedBox(
                          width: 0.4.sw,
                          child: Text(
                            "Thai Massage",
                            style: TextStyle(
                              fontSize: 30.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: "PlayfairDisplay",
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Single at Home",
                              style: TextStyle(fontSize: 14.sp, color: Colors.white70),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(50),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                "Upcoming",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Body
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Therapist
                Text("Therapist", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24.r,
                      backgroundImage: AssetImage("assets/images/fevTherapist1.png"),
                    ),
                    SizedBox(width: 10.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("Mical Martinez", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                            SizedBox(width: 4.w),
                            SvgPicture.asset("assets/svg/male.svg"),
                          ],
                        ),
                        Text("Thai Massage Therapist", style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                      ],
                    ),
                    const Spacer(),
                    InkWell(
                        onTap: () {
                          Get.toNamed("/liveTrackingPage");
                        },
                        child: SvgPicture.asset("assets/svg/location.svg")),
                    SizedBox(width: 8.w),
                    SvgPicture.asset("assets/svg/chat.svg"),
                  ],
                ),

                SizedBox(height: 24.h),

                /// Duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Duration", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                    Text("60 min", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: primaryTextColor)),
                  ],
                ),
                SizedBox(height: 8.h),
                Slider(
                  value: 60,
                  min: 30,
                  max: 120,
                  activeColor: primaryTextColor,
                  onChanged: (_) {},
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("30 min", style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                    Text("120 min", style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                  ],
                ),

                SizedBox(height: 20.h),

                /// Date & Time
                Row(
                  children: [
                    Icon(Icons.calendar_month, color: primaryTextColor,size: 40,),
                    Column(
                      children: [
                        Text("Date Scheduled", style: TextStyle(fontSize: 12.sp,fontWeight: FontWeight.w500)),
                        Text("20 July, 2024", style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: primaryTextColor)),
                      ],
                    ),
                    SizedBox(width: 0.15.sw),
                    Icon(Icons.access_time, color: primaryTextColor,size: 40,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Time Scheduled", style: TextStyle(fontSize: 12.sp,fontWeight: FontWeight.w500)),
                        Text("11:00 am", style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: primaryTextColor)),
                      ],
                    ),
                  ],
                ),


                SizedBox(height: 24.h),

                /// Payment section (placeholder)
                Text("Payment detail", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 8.h),
                Text("• Subtotal: \$89.0\n• Tip: \$5.0\n• Total: \$96.0", style: TextStyle(fontSize: 13.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
