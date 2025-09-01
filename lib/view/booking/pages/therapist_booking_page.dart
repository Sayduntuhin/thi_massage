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
import 'package:http/http.dart' as http;
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

  Future<String> _getAddressFromCoordinates(double lat, double lon) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1';
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'ThaiMassageApp/1.0'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['display_name'] ?? 'Unknown Location';
        return address;
      } else {
        return 'Unknown Location';
      }
    } catch (e) {
      AppLogger.error('Failed to fetch address: $e');
      return 'Unknown Location';
    }
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
      final List<Map<String, dynamic>> processedBookings = [];

      for (var booking in bookings) {
        String address = 'Unknown Location';
        try {
          final coords = booking['location'].split(',').map((s) => s.trim()).toList();
          if (coords.length == 2) {
            final lat = double.parse(coords[0]);
            final lon = double.parse(coords[1]);
            address = await _getAddressFromCoordinates(lat, lon);
          }
        } catch (e) {
          AppLogger.error('Failed to parse coordinates: ${booking['location']}, error: $e');
        }

        processedBookings.add({
          'booking_id': booking['booking_id'], // ✅ Preserve booking_id
          'name': booking['client_name'],
          'status': booking['status'] == 'Accepted' ? 'Scheduled' : booking['status'],
          'service': booking['service'],
          'time': booking['time'],
          'distance': booking['distance'].toString() + ' km',
          'location': address,
          'image': booking['client_image'].startsWith('/')
              ? '$_baseUrl/therapist${booking['client_image']}'
              : booking['client_image'],
        });
      }

      setState(() {
        _bookings = processedBookings;
        _isBookingsLoading = false;
      });
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
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
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
            _showCalendar ? _buildCalendarView() : _buildRequestsView(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar Widget
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3.r, offset: Offset(0, 2))],
            ),
            child: TableCalendar(
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
                  color: primaryTextColor.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: const Color(0xffE9C984),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(fontSize: 14.sp, color: Colors.black87),
                defaultTextStyle: TextStyle(fontSize: 14.sp, color: Colors.black87),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                leftChevronIcon: _arrowContainer(Icons.chevron_left),
                rightChevronIcon: _arrowContainer(Icons.chevron_right),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                weekendStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          _legend(),
          SizedBox(height: 15.h),

          // Date heading
          if (_selectedDay != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                '${_getWeekdayName(_selectedDay!.weekday)}, ${_selectedDay!.day} ${_monthName(_selectedDay!.month)}, ${_selectedDay!.year}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                  color: primaryTextColor,
                ),
              ),
            ),
          SizedBox(height: 10.h),

          // Bookings list
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3.r, offset: Offset(0, 1))],
            ),
            child: _isBookingsLoading
                ? ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
              itemCount: 2,
              itemBuilder: (context, index) => const AppointmentCardShimmer(),
            )
                : _bookingsErrorMessage != null
                ? Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Text(
                        _bookingsErrorMessage!,
                        style: TextStyle(fontSize: 14.sp, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    ElevatedButton.icon(
                      onPressed: () => _fetchBookingsForDay(_selectedDay ?? DateTime.now()),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(
                        'Retry',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        backgroundColor: const Color(0xFFB28D28),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : _bookings.isEmpty
                ? Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: Text(
                  'No bookings for this date',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                return _appointmentCard(_bookings[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsView() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Requests',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: primaryTextColor),
          ),
          SizedBox(height: 10.h),
          _isAppointmentRequestsLoading
              ? ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 2,
            itemBuilder: (context, index) => const AppointmentRequestCardShimmer(),
          )
              : _appointmentRequestsErrorMessage != null
              ? Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _appointmentRequestsErrorMessage!,
                    style: TextStyle(fontSize: 14.sp, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10.h),
                  ElevatedButton.icon(
                    onPressed: _fetchAppointmentRequests,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(
                      'Retry',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      backgroundColor: const Color(0xFFB28D28),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
              : _appointmentRequests.isEmpty
              ? Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: Center(
              child: Text(
                'No appointment requests',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _appointmentRequests.length,
            itemBuilder: (context, index) {
              final request = _appointmentRequests[index];
              final dateParts = _parseDate(request['date'] ?? 'N/A');
              return _appointmentRequestCard(
                index: index,
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
        ],
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  Widget _arrowContainer(IconData icon) {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: const Color(0xffF9F7F2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(icon, color: Colors.black, size: 20.sp),
    );
  }

  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(primaryTextColor.withOpacity(0.7), "Current Date"),
        SizedBox(width: 20.w),
        _legendItem(const Color(0xffE9C984), "Selected Date"),
        SizedBox(width: 20.w),
        _legendItem(Colors.redAccent, "Booked"),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12.w, height: 12.h, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 6.w),
        Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.black87)),
      ],
    );
  }

  Widget _appointmentCard(Map<String, dynamic> item) {
    final bool isCompleted = item['status'] == "Complete";
    return GestureDetector(
  /*    onTap: () {
        if (item['booking_id'] != null) {
          // Navigate to appointment request page with booking data
          Get.toNamed('/appointmentRequestPage', arguments: {
            'booking_id': item['booking_id'],
            'client_name': item['name'],
            'client_image': item['image'],
            'service': item['service'],
            'status': item['status'],
            'time': item['time'],
            'location': item['location'],
            'is_booking': true, // Flag to indicate this is a booking, not a request
          });
          AppLogger.debug('Navigating to appointment details for booking_id: ${item['booking_id']}');
        } else {
          CustomSnackBar.show(context, 'Unable to open booking details. Missing booking ID.',
              type: ToastificationType.error);
          AppLogger.error('No booking_id found in item: $item');
        }
      },*/
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3.r, offset: Offset(0, 1))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(item['image']),
              radius: 25.r,
              onBackgroundImageError: (_, __) => const AssetImage('assets/images/profilepic.png'),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['name'],
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: isCompleted ? const Color(0xFF28B446) : secounderyBorderColor,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          item['status'],
                          style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item['location'],
                    style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Service: ${item['service']}",
                        style: TextStyle(fontSize: 12.sp, color: primaryTextColor, fontWeight: FontWeight.w500),
                      ),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14.sp, color: Colors.grey.shade600),
                          SizedBox(width: 4.w),
                          Text(
                            item['time'],
                            style: TextStyle(fontSize: 12.sp, color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appointmentRequestCard({
    required int index,
    required String name,
    required String service,
    required String day,
    required String month,
    required String year,
    required String time,
    bool isFemale = false,
  }) {
    final request = _appointmentRequests[index];
    return GestureDetector(
     /* onTap: () {
        // Debug log to see what data we have
        AppLogger.debug('Request data: $request');

        // Check if booking_id exists in the request
        final bookingId = request['booking_id']?.toString() ??
            request['Booking_id']?.toString() ??
            request['id']?.toString();

        if (bookingId != null && bookingId.isNotEmpty) {
          Get.toNamed('/appointmentRequestPage', arguments: {
            'booking_id': bookingId,
            'client_name': request['client_name'] ?? 'Unknown',
            'client_image': request['client_image'],
            'client_gender': request['client_gender'] ?? 'male',
            'status': request['status'] ?? 'Pending',

          });
          AppLogger.debug('Navigating to appointmentRequestPage with booking_id: $bookingId');
        } else {
          AppLogger.error('No valid booking ID found in request: $request');
          CustomSnackBar.show(context, 'Unable to open request details. Missing booking ID.',
              type: ToastificationType.error);
        }
      },*/
      child: Padding(
        padding: EdgeInsets.only(bottom: 12.h),
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
                    BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(2, 2)),
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
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87),
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
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
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