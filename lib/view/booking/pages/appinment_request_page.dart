import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../themes/colors.dart';
import '../../profile/pages/profile_page.dart';

class AppointmentRequestPage extends StatelessWidget {
  const AppointmentRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top colored background with curve
          Container(
            height: 0.32.sh,
            decoration: BoxDecoration(
              color: primaryTextColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30.r),
                bottomRight: Radius.circular(30.r),
              ),
            ),
            child: CustomPaint(
              painter: CurveShapePainter(),
              size: Size(double.infinity, 200.h),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar
                Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_ios, color: Colors.white, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text("Thai Massage", style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
                      Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_month, color: Colors.white, size: 14.sp),
                              SizedBox(width: 4.w),
                              Text("20 July, 2024", style: TextStyle(color: Colors.white, fontSize: 12.sp)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.white, size: 14.sp),
                              SizedBox(width: 4.w),
                              Text("11:00 am", style: TextStyle(color: Colors.white, fontSize: 12.sp)),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),


                // Customer Preferences
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Customer Preferences", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                      Icon(Icons.keyboard_arrow_down, size: 20.sp),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),

                // Map (Dummy Map Image)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.asset("assets/images/map.png", height: 140.h, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: 10.h),
                // Client Info Card
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  padding: EdgeInsets.all(12.r),

                  child: Row(
                    children: [
                      CircleAvatar(radius: 24.r, backgroundImage: AssetImage("assets/images/profilepic.png")),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text("Mike Milan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                                SizedBox(width: 4.w),
                                Icon(Icons.male, size: 16.sp, color: Colors.blue),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 14.sp),
                                SizedBox(width: 2.w),
                                Text("4.2 (200+) Past Customer", style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _actionButton("Accept", Colors.green),
                          SizedBox(width: 6.w),
                          _actionButton("Reject", Colors.red),
                        ],
                      )
                    ],
                  ),
                ),

                // Duration
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Duration", style: TextStyle(fontSize: 14.sp)),
                          Text("60 min", style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w500, fontSize: 13.sp)),
                        ],
                      ),
                      Slider(
                        value: 60,
                        min: 30,
                        max: 120,
                        onChanged: (value) {},
                        activeColor: primaryTextColor,
                        inactiveColor: Colors.grey.shade300,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("30 min", style: TextStyle(fontSize: 12.sp)),
                          Text("120 min", style: TextStyle(fontSize: 12.sp)),
                        ],
                      )
                    ],
                  ),
                ),

                SizedBox(height: 10.h),

                // Location Details
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: Color(0xffFFFDF5),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Color(0xffF3E1B9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _locationRow("Venue", "House"),
                        _locationRow("Number of floors", "2"),
                        _locationRow("Elevator/Escalator", "NO"),
                        _locationRow("Massage table", "NO"),
                        _locationRow("Parking", "Yes. Street Parking"),
                        _locationRow("Pet", "Yes. Cat"),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12.sp, fontWeight: FontWeight.w600)),
    );
  }

  Widget _locationRow(String key, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: TextStyle(fontSize: 13.sp, color: Colors.black54)),
          Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
