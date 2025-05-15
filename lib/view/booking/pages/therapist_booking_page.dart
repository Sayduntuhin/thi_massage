import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';
import '../../../api/api_service.dart';
import '../../home/widgets/shimmer_loading_for_therapist_home.dart';
import '../../widgets/app_logger.dart';
import '../../widgets/custom_snackbar.dart';
import 'package:toastification/toastification.dart';
import '../../../themes/colors.dart';
import 'dart:convert';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _showCalendar = true;
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _appointmentRequests = [];
  List<Map<String, dynamic>> _bookings = [];
  bool _isAppointmentRequestsLoading = true;
  bool _isBookingsLoading = true;
  String? _appointmentRequestsErrorMessage;
  String? _bookingsErrorMessage;
  final _baseUrl = ApiService.baseUrl;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAppointmentRequests();
    _fetchBookingsForDay(_focusedDay);
  }

  Future<void> _fetchAppointmentRequests() async {
    setState(() {
      _isAppointmentRequestsLoading = true;
      _appointmentRequestsErrorMessage = null;
    });
    try {
      final requests = await _apiService.getAppointmentRequests();
      setState(() {
        _appointmentRequests = requests;
        _isAppointmentRequestsLoading = false;
      });
      AppLogger.debug('Appointment Requests: $requests');
    } catch (e) {
      setState(() {
        _isAppointmentRequestsLoading = false;
        _appointmentRequestsErrorMessage = 'Failed to load appointment requests: $e';
      });
      CustomSnackBar.show(context, _appointmentRequestsErrorMessage!, type: ToastificationType.error);
      AppLogger.error('Failed to fetch appointment requests: $e');
    }
  }

  Future<void> _fetchBookingsForDay(DateTime day) async {
    setState(() {
      _isBookingsLoading = true;
      _bookingsErrorMessage = null;
      _bookings = [];
    });
    try {
      final formattedDate = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final bookings = await _apiService.getBookingsByDate(formattedDate);
      setState(() {
        _bookings = bookings.map((booking) {
          return {
            'name': booking['client_name'],
            'status': booking['status'] == 'Accepted' ? 'Scheduled' : booking['status'],
            'service': booking['service'],
            'time': booking['time'],
            'distance': booking['distance'].toString() + ' km',
            'location': booking['address'],
            'image': booking['client_image'].startsWith('/')
                ? '$_baseUrl/therapist${booking['client_image']}'
                : booking['client_image'],
          };
        }).toList();
        _isBookingsLoading = false;
      });
      AppLogger.debug('Bookings for $formattedDate:j');

      AppLogger.debug('Bookings for $formattedDate: $_bookings');
    } catch (e) {
      setState(() {
        _isBookingsLoading = false;
        _bookingsErrorMessage = 'Failed to load bookings: $e';
      });
      CustomSnackBar.show(context, _bookingsErrorMessage!, type: ToastificationType.error);
      AppLogger.error('Failed to fetch bookings: $e');
    }
  }

  Map<String, String> _parseDate(String dateStr) {
    try {
      final cleanedDate = dateStr.replaceAll(',', '');
      final parts = cleanedDate.split(' ');
      if (parts.length != 3) {
        throw Exception('Invalid date format: $dateStr');
      }
      final day = parts[0];
      final month = parts[1];
      final year = parts[2];
      return {
        'day': day,
        'month': month,
        'year': year,
      };
    } catch (e) {
      AppLogger.error('Failed to parse date: $dateStr, error: $e');
      final now = DateTime.now();
      return {
        'day': now.day.toString(),
        'month': _monthName(now.month),
        'year': now.year.toString(),
      };
    }
  }

  String _monthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SecondaryAppBar(title: _showCalendar ? "Calendar" : "Requests", showBackButton: false),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Container(
              height: 40.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFFB28D28)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showCalendar = false;
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: !_showCalendar ? const Color(0xFFB28D28) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            "Requests",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: !_showCalendar ? Colors.white : const Color(0xFFB28D28),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showCalendar = true;
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _showCalendar ? const Color(0xFFB28D28) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            "Calendar",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: _showCalendar ? Colors.white : const Color(0xFFB28D28),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Content - Either Calendar or Requests
          Expanded(
            child: _showCalendar ? _buildCalendarView() : _buildRequestsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar Widget
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5.r, offset: Offset(0, 5))],
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
                    _fetchBookingsForDay(selectedDay);
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
              '${_selectedDay!.weekday == 4 ? 'Thu' : 'Other'}, ${_selectedDay!.day} ${_monthName(_selectedDay!.month)}, ${_selectedDay!.year}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: primaryTextColor),
            ),

          SizedBox(height: 10.h),

          // Bookings list
          Expanded(
            child: _isBookingsLoading
                ? ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
              itemBuilder: (context, index) => const AppointmentCardShimmer(),
            )
                : _bookingsErrorMessage != null
                ? Center(
              child: Column(
                children: [
                  Text(
                    _bookingsErrorMessage!,
                    style: TextStyle(fontSize: 14.sp, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10.h),
                  ElevatedButton.icon(
                    onPressed: () => _fetchBookingsForDay(_selectedDay ?? DateTime.now()),
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      'Retry',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ],
              ),
            )
                : _bookings.isEmpty
                ? Center(
              child: Text(
                'No bookings for this date',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
                : ListView.builder(
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                return _appointmentCard(_bookings[index]);
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRequestsView() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10.h),
          Text(
            'Pending Requests',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: primaryTextColor),
          ),
          SizedBox(height: 10.h),
          Expanded(
            child: _isAppointmentRequestsLoading
                ? ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
              itemBuilder: (context, index) => const AppointmentRequestCardShimmer(),
            )
                : _appointmentRequestsErrorMessage != null
                ? Center(
              child: Column(
                children: [
                  Text(
                    _appointmentRequestsErrorMessage!,
                    style: TextStyle(fontSize: 14.sp, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10.h),
                  ElevatedButton.icon(
                    onPressed: _fetchAppointmentRequests,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      'Retry',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ],
              ),
            )
                : _appointmentRequests.isEmpty
                ? Center(
              child: Text(
                'No appointment requests',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
                : ListView.builder(
              itemCount: _appointmentRequests.length,
              itemBuilder: (context, index) {
                final request = _appointmentRequests[index];
                final dateParts = _parseDate(request['date'] ?? 'N/A');
                return _appointmentRequestCard(
                  name: request['client_name'] ?? 'Unknown',
                  service: request['specility'] ?? 'N/A',
                  day: dateParts['day']!,
                  month: dateParts['month']!,
                  year: dateParts['year']!,
                  time: request['time'] ?? 'N/A',
                  isFemale: request['client_gender'] != 'male',
                );
              },
            ),
          ),
        ],
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
    final bool isCompleted = item['status'] == "Complete";
    return GestureDetector(
      onTap: () {
        Get.toNamed('/appointmentRequestPage');
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
              backgroundImage: NetworkImage(item['image']),
              radius: 25.r,
              onBackgroundImageError: (_, __) => const AssetImage('assets/images/profilepic.png'),
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

  Widget _appointmentRequestCard({
    required String name,
    required String service,
    required String day,
    required String month,
    required String year,
    required String time,
    bool isFemale = false,
  }) {
    return GestureDetector(
      onTap: () {
        Get.toNamed('/appointmentRequestPage');
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            Container(
              height: 0.1.sh,
              width: 0.18.sw,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFB28D28),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  bottomLeft: Radius.circular(12.r),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(month, style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                  Text(year, style: TextStyle(fontSize: 10.sp, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                height: 0.1.sh,
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12.r),
                    bottomRight: Radius.circular(12.r),
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(2, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service,
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16.sp, color: Colors.black45),
                            SizedBox(width: 4.w),
                            Text(time, style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 0.2.sw,
                              height: 0.02.sh,
                              child: Text(
                                overflow: TextOverflow.ellipsis,
                                name,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              isFemale ? Icons.female : Icons.male,
                              color: isFemale ? Colors.purple : Colors.blue,
                              size: 16.sp,
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            _statusButton(
                              "Accept",
                              const Color(0xFFCBF299),
                              const Color(0xff33993A),
                              const Color(0xFFCBF299),
                            ),
                            SizedBox(width: 6.w),
                            _statusButton("Reject", Colors.transparent, Colors.red, Colors.red),
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

  Widget _statusButton(String label, Color color, Color textcolor, Color borderColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(color: textcolor, fontSize: 12.sp, fontWeight: FontWeight.w500),
      ),
    );
  }
}