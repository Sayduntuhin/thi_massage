import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';
import '../../../themes/colors.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, List<Map<String, dynamic>>> appointments = {
    DateTime.utc(2025, 3, 8): [
      {
        "name": "Mike Milan",
        "status": "Completed",
        "service": "Thai Massage",
        "time": "12:00 AM",
        "distance": "3.2 km",
        "location": "4761 Hamill Avenue, San Diego",
        "image": "assets/images/profilepic.png"
      },
      {
        "name": "Alexa",
        "status": "Scheduled",
        "service": "Thai Massage",
        "time": "12:00 AM",
        "distance": "3.2 km",
        "location": "4761 Hamill Avenue, San Diego",
        "image": "assets/images/profilepic.png"
      },
    ],
    // Add more dates and data here
  };

  List<Map<String, dynamic>> getAppointmentsForDay(DateTime day) {
    return appointments[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SecondaryAppBar(title: "Calendar", showBackButton: false),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Widget
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5.r,offset: Offset(0, 5))],
              ),
              child: Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.utc(2026, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: primaryTextColor,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: const Color(0xffE9C984),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      leftChevronIcon: _arrowContainer(Icons.chevron_left),
                      rightChevronIcon: _arrowContainer(Icons.chevron_right),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _legend(),
                  SizedBox(height: 20.h),
                ],
              ),
            ),



            SizedBox(height: 20.h),

            // Date heading
            if (_selectedDay != null)
              Text(
                'Thu, ${_selectedDay!.day} ${_monthName(_selectedDay!.month)}, ${_selectedDay!.year}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: primaryTextColor),
              ),

            SizedBox(height: 10.h),

            // Appointments list
            Expanded(
              child: ListView(
                children: getAppointmentsForDay(_selectedDay ?? DateTime.now()).map((item) {
                  return _appointmentCard(item);
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _arrowContainer(IconData icon) {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: const Color(0xffF9F7F2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(icon, color: Colors.black),
    );
  }

  String _monthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _legendItem(primaryTextColor, "Current Date"),
        _legendItem(const Color(0xffE9C984), "Booked"),
        _legendItem(Colors.grey.shade300, "Unavailable"),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 6.w),
        Text(label, style: TextStyle(fontSize: 12.sp)),
      ],
    );
  }

  Widget _appointmentCard(Map<String, dynamic> item) {
    final bool isCompleted = item['status'] == "Completed";
    return GestureDetector(
      onTap: () {
        Get.toNamed('/appointmentRequestPage');// Navigate to appointment details page
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5.r)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(item['image']),
              radius: 25.r,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: isCompleted ? const Color(0xFF28B446) : secounderyBorderColor,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          item['status'],
                          style: TextStyle(color: Colors.white, fontSize: 10.sp),
                        ),
                      ),
                    ],
                  ),
                  Text(item['location'], style: TextStyle(fontSize: 12.sp, color: Colors.black45)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Service: ${item['service']}", style: TextStyle(fontSize: 12.sp, color: primaryTextColor)),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12.sp, color: Colors.grey),
                          SizedBox(width: 3.w),
                          Text(item['time'], style: TextStyle(fontSize: 12.sp)),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
