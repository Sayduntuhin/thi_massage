import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../themes/colors.dart';
import '../widgets/online_offline_toggle.dart';

class TherapistHomePage extends StatelessWidget {
  const TherapistHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.menu, size: 24.sp),
                  Image.asset("assets/images/logo.png", width: 0.4.sw,),
                  SizedBox(width: 20.w),
                ],
              ),
              CircleAvatar(
                radius: 35.r,
                backgroundImage: AssetImage("assets/images/profilepic.png"),
              ),
              SizedBox(height: 10.h,),
              // Greeting & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hello Mical", style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.bold,color: primaryTextColor)),
                      Text("Thai Massage Therapist", style: TextStyle(fontSize: 14.sp, color: Colors.black26)),

                    ],
                  ),
                  OnlineOfflineToggle(
                    initialOnline: true,
                    onChanged: (isOnline) {
                      // You can call controller or update backend here
                      debugPrint("Therapist is now ${isOnline ? "online" : "offline"}");
                    },
                  ),

                ],
              ),
              SizedBox(height: 20.h),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem("31", "Sessions"),
                  _statItem("\$1.5k", "Earning"),
                  _statItem("4", "Booked"),
                ],
              ),
              SizedBox(height: 20.h),

              // Appointments
              /// In your section
              _sectionHeader("Upcoming Appointments", onTap: () {}),

              SizedBox(
                height: 0.14.sh,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _appointmentCard(
                      name: "Mike Milan",
                      date: "2 Mar",
                      time: "12:00 AM",
                      service: "Thai Massage",
                      location: "4761 Hamill Avenue, San Diego",
                      distance: "3.2",
                      isMale: true,
                    ),
                    _appointmentCard(
                      name: "Sarah Jones",
                      date: "5 Mar",
                      time: "1:00 PM",
                      service: "Swedish Massage",
                      location: "Downtown Wellness Spa",
                      distance: "5.0",
                      isMale: false,
                    ),
                  ],
                ),
              ),

              _sectionHeader("Appointment Requests"),
              _appointmentRequestCard("Mark Milan", "Thai Massage", "21 Feb", "12:00 AM"),
              _appointmentRequestCard("Jennie", "Thai Massage", "21 Feb", "12:00 AM", isFemale: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: color.withOpacity(0.1),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12.sp)),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.bold,color: primaryTextColor)),
        Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.black54)),
      ],
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
          if (onTap != null)
            GestureDetector(
              onTap: onTap,
              child: Text("see all", style: TextStyle(fontSize: 14.sp, color: primaryTextColor)),
            ),
        ],
      ),
    );
  }

  Widget _appointmentCard({
    required String name,
    required String date,
    required String time,
    required String service,
    required String location,
    required String distance,
    bool isMale = true,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 0.75.sw, // Card width to allow horizontal scroll
        margin: EdgeInsets.only(right: 12.w),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6,offset: Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Top Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Profile
                CircleAvatar(
                  backgroundImage: AssetImage("assets/images/profilepic.png"),
                  radius: 24.r,
                ),
                SizedBox(width: 10.w),

                /// Name + Location + Service
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp)),
                          SizedBox(width: 4.w),
                          Icon(
                            isMale ? Icons.male : Icons.female,
                            size: 16.sp,
                            color: isMale ? Colors.blue : Colors.pink,
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12.sp, color: Colors.grey),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(location,
                                style: TextStyle(
                                    fontSize: 11.sp, color: Colors.black54),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      RichText(
                        text: TextSpan(
                          text: "Service: ",
                          style: TextStyle(
                              fontSize: 12.sp, color: Colors.black54),
                          children: [
                            TextSpan(
                              text: service,
                              style: TextStyle(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                /// Date & Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(date,
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xffB28D28))),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14.sp, color: Colors.grey),
                        SizedBox(width: 4.w),
                        Text(time, style: TextStyle(fontSize: 12.sp)),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 8.h),

            /// Distance
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text("$distance km",
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _appointmentRequestCard(String name, String service, String date, String time, {bool isFemale = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primaryTextColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(date.split(" ")[0], style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                Text(date.split(" ")[1], style: TextStyle(fontSize: 10.sp)),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                Text(name + (isFemale ? " 👩" : " 👨"), style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  _actionButton("Accept", Colors.green),
                  SizedBox(width: 6.w),
                  _actionButton("Reject", Colors.red),
                ],
              ),
              SizedBox(height: 6.h),
              Text(time, style: TextStyle(fontSize: 12.sp)),
            ],
          )
        ],
      ),
    );
  }

  Widget _actionButton(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12.sp)),
    );
  }
}
