import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';
import 'package:thi_massage/api/api_service.dart';
import 'package:thi_massage/view/widgets/custom_snackbar.dart';
import 'package:toastification/toastification.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({super.key});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? bookingDetails;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchBookingDetails();
    });
  }

  Future<void> fetchBookingDetails() async {
    final arguments = Get.arguments as Map<String, dynamic>?;
    final bookingId = arguments?['booking_id'] as int? ?? 0;
    final therapistId = arguments?['therapist_user_id'] as int? ?? 0;
    AppLogger.debug('Booking ID: $bookingId, Therapist ID: $therapistId');
    final therapistNameFallback = arguments?['therapist_name'] as String? ?? 'Unknown Therapist';

    if (bookingId == 0) {
      setState(() {
        errorMessage = 'Invalid booking ID';
        isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        CustomSnackBar.show(
          context,
          errorMessage!,
          type: ToastificationType.error,
        );
      });
      return;
    }

    try {
      setState(() => isLoading = true);
      AppLogger.debug('Fetching booking details for booking_id: $bookingId');
      final response = await apiService.getBookingDetails(bookingId);
      AppLogger.debug('Booking Details API Response: $response');
      setState(() {
        bookingDetails = response;
        isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Fetch Booking Details Error: $e');
      String detailedError = 'Failed to load booking details: $e';
      if (e is NetworkException) {
        detailedError = 'Network error: Please check your internet connection.';
      } else if (e is UnauthorizedException) {
        detailedError = 'Authentication failed: Please log in again.';
      } else if (e is ServerException) {
        detailedError = 'Server error: Please try again later.';
      } else if (e is BadRequestException) {
        detailedError = e.message;
      }
      setState(() {
        errorMessage = detailedError;
        isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        CustomSnackBar.show(
          context,
          errorMessage!,
          type: ToastificationType.error,
        );
      });
    }
  }

  // Utility to capitalize first letter
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments as Map<String, dynamic>?;
    final therapistNameFallback = arguments?['therapist_name'] as String? ?? 'Unknown Therapist';

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null || bookingDetails == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage ?? 'Failed to load booking details',
              style: TextStyle(fontSize: 14.sp, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: fetchBookingDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryButtonColor,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: Text(
                'Retry',
                style: TextStyle(fontSize: 16.sp, color: Colors.white),
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Header with CustomPainter
          Stack(
            children: [
              Container(
                height: 0.35.sh,
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
                      IconButton(
                        onPressed: Get.back,
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      ),
                      SizedBox(height: 5.h),
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: SizedBox(
                          width: 0.4.sw,
                          child: Text(
                            bookingDetails!['massage_type'] ?? 'Thai Massage',
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
                              "${_capitalizeFirst(bookingDetails!['preference'] ?? 'single')} at ${bookingDetails!['location_type'] ?? 'Home'}",
                              style: TextStyle(fontSize: 14.sp, color: Colors.white70),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(50),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                bookingDetails!['status'] ?? 'Upcoming',
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w500),
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
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Therapist
                  Text("Therapist",
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24.r,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: bookingDetails!['therapist']['image']?.isNotEmpty == true
                                ? bookingDetails!['therapist']['image'].startsWith('http')
                                ? bookingDetails!['therapist']['image']
                                : '${ApiService.baseUrl}/therapist${bookingDetails!['therapist']['image']}'
                                : '',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) {
                              AppLogger.error('Image load error: $error, URL: $url');
                              return Image.asset(
                                'assets/images/fevTherapist1.png',
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                bookingDetails!['therapist']['name'] ?? therapistNameFallback,
                                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(width: 4.w),
                              SvgPicture.asset(
                                bookingDetails!['therapist']['gender'] == 'male'
                                    ? "assets/svg/male.svg"
                                    : "assets/svg/female.svg",
                                width: 16.w,
                                height: 16.h,
                              ),
                            ],
                          ),
                          Text(
                            bookingDetails!['therapist']['role'] ?? 'Therapist',
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                          ),
                        ],
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          Get.toNamed("/liveTrackingPage", arguments: {
                            'booking_id': arguments?['booking_id'],
                          });
                        },
                        child: SvgPicture.asset("assets/svg/location.svg"),
                      ),
                      SizedBox(width: 8.w),
                      InkWell(
                        onTap: () {
                          final therapistImage = bookingDetails!['therapist']['image']?.isNotEmpty == true
                              ? bookingDetails!['therapist']['image'].startsWith('http')
                              ? bookingDetails!['therapist']['image']
                              : '${ApiService.baseUrl}/therapist${bookingDetails!['therapist']['image']}'
                              : 'assets/images/fevTherapist1.png';
                          Get.toNamed("/chatDetailsPage", arguments: {
                            'name': bookingDetails!['therapist']['name'] ?? therapistNameFallback,
                            'therapist_user_id': arguments?['therapist_user_id'] ?? "1",
                            'image': therapistImage,
                          });
                        },
                        child: SvgPicture.asset("assets/svg/chat.svg"),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  /// Duration
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Duration",
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                      Text(
                        bookingDetails!['duration'] ?? '60 min',
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Slider(
                    value: double.tryParse(
                        (bookingDetails!['duration'] ?? '60 min').replaceAll(' min', '')) ??
                        60,
                    min: 30,
                    max: 120,
                    activeColor: primaryTextColor,
                    inactiveColor: Colors.grey[200],
                    onChanged: (_) {}, // Disabled as it's display-only
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("30 min",
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                      Text("120 min",
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  /// Date & Time
                  Row(
                    children: [
                      Icon(Icons.calendar_month, color: primaryTextColor, size: 40),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Date Scheduled",
                              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500)),
                          Text(
                            bookingDetails!['scheduled_date'] ?? 'N/A',
                            style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor),
                          ),
                        ],
                      ),
                      SizedBox(width: 0.15.sw),
                      Icon(Icons.access_time, color: primaryTextColor, size: 40),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Time Scheduled",
                              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500)),
                          Text(
                            bookingDetails!['scheduled_time'] ?? 'N/A',
                            style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  /// Payment section
                  Text("Payment Detail",
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8.h),
                  Text(
                    "• Massage Fee: \$${bookingDetails!['payment_detail']['massage_fee'].toStringAsFixed(1)}\n"
                        "• Booking Fee: \$${bookingDetails!['payment_detail']['booking_fee'].toStringAsFixed(1)}\n"
                        "• Tip: \$${bookingDetails!['payment_detail']['tip_fee'].toStringAsFixed(1)}\n"
                        "• Total: \$${((bookingDetails!['payment_detail']['massage_fee'] as double) + (bookingDetails!['payment_detail']['booking_fee'] as double) + (bookingDetails!['payment_detail']['tip_fee'] as double)).toStringAsFixed(1)}",
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// CustomPainter for the header curve
class CurveShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(50)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.85, size.width * 0.5, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.55, size.width, size.height * 0.7)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}