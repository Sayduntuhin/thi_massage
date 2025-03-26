import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/custom_gradientButton.dart';

import '../../../controller/user_controller.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  String _selectedTab = "All";

  final List<Map<String, String>> bookings = [
    {"date": "21 Feb", "year": "2025", "title": "Thai Massage", "therapist": "Mark Milan", "status": "Completed"},
    {"date": "23 Feb", "year": "2025", "title": "Swedish Massage", "therapist": "Mical Martinez", "status": "Completed"},
    {"date": "25 Feb", "year": "2025", "title": "Thai Massage", "therapist": "Mark Milan", "status": "Upcoming"},
    {"date": "26 Feb", "year": "2025", "title": "Thai Massage", "therapist": "Mark Milan", "status": "Upcoming"},
  ];

  @override
  Widget build(BuildContext context) {
    final UserTypeController userTypeController = Get.find<UserTypeController>();

    // Filter bookings based on _selectedTab
    List<Map<String, String>> filteredBookings;
    if (_selectedTab == "All") {
      filteredBookings = bookings;
    } else if (_selectedTab == "Completed") {
      filteredBookings = bookings.where((b) => b['status'] == "Completed").toList();
    } else {
      filteredBookings = bookings.where((b) => b['status'] == "Upcoming").toList();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Bookings", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500)),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),
            // 🔄 Tab Bar (All, Completed, Upcoming)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: ["All", "Completed", "Upcoming"].map((tab) {
                bool isSelected = _selectedTab == tab;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTab = tab;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isSelected ? boxColor : Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSelected ? borderColor.withAlpha(100) : Color(0xffE0E0E0),
                        ),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color:  Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 10.h),
            // 📌 Booking List (Dynamic)
            Expanded(
              child: _buildBookingList(filteredBookings), // Use filtered bookings
            ),

            Padding(
              padding:  EdgeInsets.only(left: 0.1.sw,right: 0.1.sw),
              child: CustomGradientButton(text: "Book an Appointment", onPressed: (){
                 Get.toNamed('/appointmentPage');

              }),
            )
          ],
        ),
      ),
    );
  }

  /// 🔹 Booking List Builder
  Widget _buildBookingList(List<Map<String, String>> filteredBookings) {
    return ListView.builder(
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        return BookingCard(
          date: booking['date']!,
          year: booking['year']!,
          title: booking['title']!,
          therapist: booking['therapist']!,
          status: booking['status']!,
        );
      },
    );
  }
}

/// 🎟 Booking Card Widget
class BookingCard extends StatelessWidget {
  final String date;
  final String year;
  final String title;
  final String therapist;
  final String status;

  const BookingCard({
    super.key,
    required this.date,
    required this.year,
    required this.title,
    required this.therapist,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 📆 Date Section
        Container(
          height: 0.11.sh,
          margin: EdgeInsets.symmetric(vertical: 8.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: secounderyBorderColor,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(8.r), bottomLeft: Radius.circular(8.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5.r,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(date, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(year, style: TextStyle(fontSize: 12.sp, color: Colors.white)),
            ],
          ),
        ),

        // 📖 Booking Details
        Container(
          height: 0.11.sh,
          width: .7.sw,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topRight: Radius.circular(8.r), bottomRight: Radius.circular(8.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5.r,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: .4.sw,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      Text("Therapist: ", style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
                      Text(
                        therapist,
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFFB28D28)),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(
                width: .26.sw,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 10),
                  child: Column(
                    children: [
                      Container(
                        width: 100.w,
                        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: status == "Completed" ? const Color(0xFF28B446) : secounderyBorderColor,
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(15.r), bottomLeft: Radius.circular(15.r)),
                        ),
                        child: SizedBox(
                          width: 90.w,
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Row(
                        children: [
                          SizedBox(width: 15.w),
                          Icon(Icons.access_time, size: 16.sp, color: Colors.black54),
                          SizedBox(width: 3.w),
                          Text("12:00 AM", style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}