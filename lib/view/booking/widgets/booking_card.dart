import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/view/booking/widgets/review_buttom_sheet.dart';
import 'package:toastification/toastification.dart';

import '../../../api/api_service.dart';
import '../../../themes/colors.dart';
import '../../widgets/app_logger.dart';
import '../../widgets/custom_gradientButton.dart';
import '../../widgets/custom_snackBar.dart';
import '../../widgets/loading_indicator.dart';

class BookingCard extends StatelessWidget {
  final String date;
  final String year;
  final String title;
  final String therapist;
  final String status;
  final String time;
  final int bookingId;
  final int therapistId;
  final VoidCallback onBookingCancelled;
  final bool showReviewButton;
  final VoidCallback? onReviewPressed;

  const BookingCard({
    super.key,
    required this.date,
    required this.year,
    required this.title,
    required this.therapist,
    required this.status,
    required this.time,
    required this.bookingId,
    required this.therapistId,
    required this.onBookingCancelled,
    this.showReviewButton = false,
    this.onReviewPressed,
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
                width: .43.sw,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 0.03.sh,
                        width: 0.38.sw,
                        child: Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        children: [
                          Text("Therapist: ", style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
                          SizedBox(
                            width: 0.22.sw,
                            child: Text(
                              therapist,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: primaryTextColor),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5.h),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16.sp, color: Colors.black54),
                          SizedBox(width: 3.w),
                          Text(time, style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
                        ],
                      ),
                      SizedBox(height: 5.h),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: .27.sw,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 10),
                  child: Column(
                    children: [
                      Container(
                        width: 1.sw,
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: status == "Completed"
                              ? otpBorderColor
                              : status == "Pending"
                              ? secounderyBorderColor.withAlpha(60)
                              : status == "Cancelled"
                              ? Colors.red
                              : secounderyBorderColor,
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(15.r), bottomLeft: Radius.circular(15.r)),
                        ),
                        child: SizedBox(
                          width: 90.w,
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: status == "Pending"
                                  ? Color(0xffC4B17E)
                                  : status == "Cancelled"
                                  ? Colors.white
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 0.03.sh),
                      if (status != "Completed" && status != "Cancelled")
                        GestureDetector(
                          onTap: () {
                            _showCancellationPolicyBottomSheet(context, bookingId);
                          },
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFE91D29),
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFFE91D29),
                            ),
                          ),
                        ),
                      if (showReviewButton)
                        GestureDetector(
                          onTap: () {
                            _showReviewBottomSheet(context, therapist, bookingId);
                          },
                          child: Text(
                            "Add Review",
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFE91D29),
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFFE91D29),
                            ),
                          ),
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

  void _showCancellationPolicyBottomSheet(BuildContext context, int bookingId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.r),
        ),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20.r),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                "Confirmed Cancellation Policy",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              SizedBox(height: 15.h),
              Text(
                "Confirmed Bookings:",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "• If a cancellation is made within 24 hours before the scheduled appointment, a 50% cancellation fee of the total service price will be charged.\n"
                    "• If cancellation is made within 3 hours before the scheduled appointment, a 100% cancellation fee will be charged.",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 15.h),
              Text(
                "No-Shows and Last-Minute Cancellations:",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "• If a cancellation occurs within 30 minutes before the scheduled appointment or the client does not show up, the full session price will be charged.",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 15.h),
              Text(
                "Platform Operations Fee:",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "• If a confirmed appointment, a 7.5% platform operations fee will be applied. This fee applies to handling cancellations, including cancellations.",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 15.h),
              Text(
                "Note:",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "• No cancellation fees will be charged if the appointment is canceled before a provider has been confirmed for the booking.",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 25.h),
              CustomGradientButton(
                text: "Cancel Appointment",
                onPressed: () {
                  _showCancellationConfirmationDialog(context, bookingId);
                },
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 10.h),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelBooking(BuildContext context, int bookingId) async {
    LoadingManager.showLoading();
    try {
      CustomSnackBar.show(
        context,
        "Booking Cancelled Successfully",
        type: ToastificationType.success,
      );
      onBookingCancelled();
    } catch (e) {
      String errorMessage = "Failed to cancel booking. Please try again.";
      if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      } else if (e is UnauthorizedException) {
        errorMessage = "Authentication failed. Please log in again.";
        Get.offAllNamed('/login');
      } else if (e is ForbiddenException) {
        errorMessage = "Access denied.";
      } else if (e is NotFoundException) {
        errorMessage = "Cancellation endpoint not found.";
      } else if (e is ServerException) {
        errorMessage = "Server error occurred.";
      } else if (e is ApiException) {
        errorMessage = e.message;
      }
      CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
      AppLogger.error("Cancel booking error: $e");
    } finally {
      LoadingManager.hideLoading();
    }
  }

  void _showCancellationConfirmationDialog(BuildContext context, int bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Warning!",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  "Are you sure you want to cancel your appointment with your therapist? This action cannot be undone, and your scheduled session will be removed.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 30.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          backgroundColor: Color(0xFFB8860B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                        ),
                        child: Text(
                          "Back",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          await _cancelBooking(context, bookingId);
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReviewBottomSheet(BuildContext context, String therapist, int bookingId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return ReviewBottomSheet(
          therapist: therapist,
          bookingId: bookingId,
          therapistId: therapistId,
          onReviewSubmitted: (rating, review, disputes) {
            AppLogger.debug('Review submitted - Rating: $rating, Review: $review, Disputes: $disputes');
            if (onReviewPressed != null) {
              onReviewPressed!();
            }
          },
        );
      },
    );
  }
}