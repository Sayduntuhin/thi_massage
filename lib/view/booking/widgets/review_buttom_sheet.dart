import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thi_massage/api/api_service.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/custom_gradientButton.dart';
import 'package:thi_massage/view/widgets/custom_snackBar.dart';
import 'package:toastification/toastification.dart';
import 'package:get/get.dart';

class ReviewBottomSheet extends StatefulWidget {
  final String therapist;
  final int bookingId;
  final int therapistId;
  final Function(int rating, String review, Map<String, dynamic> disputes) onReviewSubmitted;

  const ReviewBottomSheet({
    super.key,
    required this.therapist,
    required this.bookingId,
    required this.therapistId,
    required this.onReviewSubmitted,
  });

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  int selectedRating = 0;
  Map<String, bool> disputeSelections = {};
  String errorMessage = '';
  bool isLoadingDisputes = true;
  bool isSubmitting = false;
  List<Map<String, dynamic>> disputeSettings = [];
  final TextEditingController reviewController = TextEditingController();
  final TextEditingController disputeController = TextEditingController();
  int therapistId = 0;

  @override
  void initState() {
    super.initState();
    _fetchDisputeSettings();
    _resolveTherapistId();
  }

  Future<void> _fetchDisputeSettings() async {
    try {
      final apiService = ApiService();
      disputeSettings = await apiService.getDisputeSettings();
      AppLogger.debug("Fetched dispute settings: $disputeSettings");
      setState(() {
        disputeSelections = {
          for (var setting in disputeSettings) setting['dispute_type'] ?? 'Unknown': false
        };
        isLoadingDisputes = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load dispute types.";
        AppLogger.error("Error fetching dispute settings: $e");
        isLoadingDisputes = false;
      });
    }
  }

  Future<void> _resolveTherapistId() async {
    if (widget.therapistId == 0) {
      try {
        final apiService = ApiService();
        final details = await apiService.getBookingDetails(widget.bookingId);
        setState(() {
          therapistId = details['therapist_id'] ?? 0;
        });
        AppLogger.debug("Resolved therapistId: $therapistId");
      } catch (e) {
        AppLogger.error("Failed to fetch therapist ID: $e");
        setState(() {
          errorMessage = "Failed to fetch therapist details.";
        });
      }
    } else {
      therapistId = widget.therapistId;
    }
  }

  @override
  void dispose() {
    reviewController.dispose();
    disputeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug("Rebuilding ReviewBottomSheet: isLoading=$isLoadingDisputes, disputeSelections=$disputeSelections");

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16.w,
        right: 16.w,
        top: 16.h,
      ),
      child: SingleChildScrollView(
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
            SizedBox(height: 16.h),
            Row(
              children: [
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    widget.therapist.isNotEmpty ? widget.therapist[0].toUpperCase() : 'T',
                    style: TextStyle(color: Colors.black, fontSize: 20.sp, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.therapist,
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Text(
                            "Thai Massage Therapist",
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                          ),
                          SizedBox(width: 8.w),
                          Row(
                            children: List.generate(4, (index) {
                              return Icon(
                                Icons.star,
                                color: starColor,
                                size: 12.sp,
                              );
                            }),
                          ),
                          Icon(
                            Icons.star_border,
                            color: Colors.grey,
                            size: 12.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            "40+ Reviews",
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Text(
              "How is your Massage Experience",
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedRating = index + 1;
                      AppLogger.debug("Selected rating: $selectedRating");
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        index < selectedRating ? Icons.star : Icons.star_border,
                        color: index < selectedRating ? starColor : Colors.grey[400],
                        size: 32.sp,
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (selectedRating > 0)
              Center(
                child: Text(
                  _getRatingText(selectedRating),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: primaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            SizedBox(height: 15.h),
            Text(
              "Add review (optional)",
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: reviewController,
              decoration: InputDecoration(
                hintText: "Share your experience with this therapist...",
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              ),
              maxLines: 3,
              maxLength: 500,
              onChanged: (value) {
                AppLogger.debug("Review text changed: $value");
              },
            ),
            SizedBox(height: 15.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Report Issues (if any)",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  if (isLoadingDisputes)
                    const Center(child: CircularProgressIndicator())
                  else if (errorMessage.isNotEmpty)
                    Text(
                      errorMessage,
                      style: TextStyle(fontSize: 12.sp, color: Colors.red),
                    )
                  else if (disputeSettings.isEmpty)
                      Text(
                        "No dispute types available",
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      )
                    else
                      ...disputeSettings.map((setting) {
                        final disputeType = setting['dispute_type'] ?? 'Unknown';
                        return InkWell(
                          onTap: () {
                            setState(() {
                              disputeSelections[disputeType] = !(disputeSelections[disputeType] ?? false);
                              disputeSelections.forEach((key, value) {
                                if (key != disputeType) {
                                  disputeSelections[key] = false;
                                }
                              });
                              AppLogger.debug("Selected dispute: $disputeType = ${disputeSelections[disputeType]}");
                            });
                          },
                          borderRadius: BorderRadius.circular(8.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 24.h,
                                  width: 24.w,
                                  child: Checkbox(
                                    value: disputeSelections[disputeType] ?? false,
                                    onChanged: (value) {
                                      setState(() {
                                        disputeSelections[disputeType] = value ?? false;
                                        if (value == true) {
                                          disputeSelections.forEach((key, val) {
                                            if (key != disputeType) {
                                              disputeSelections[key] = false;
                                            }
                                          });
                                        }
                                        AppLogger.debug("Checkbox changed: $disputeType = $value");
                                      });
                                    },
                                    activeColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    disputeType,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: disputeSelections[disputeType] == true ? primaryTextColor : Colors.black87,
                                      fontWeight: disputeSelections[disputeType] == true ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: disputeSelections.containsValue(true) ? null : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: disputeSelections.containsValue(true) ? 1.0 : 0.0,
                child: disputeSelections.containsValue(true)
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 15.h),
                    Text(
                      "Give explanation *",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: disputeController,
                      decoration: InputDecoration(
                        hintText: "Please describe the issue you experienced...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: Colors.red[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: Colors.red[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                        prefixIcon: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red[400],
                        ),
                      ),
                      maxLines: 3,
                      maxLength: 300,
                      onChanged: (value) {
                        AppLogger.debug("Dispute details changed: $value");
                      },
                    ),
                  ],
                )
                    : const SizedBox.shrink(),
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: CustomGradientButton(
                text: isSubmitting ? "Submitting..." : "Submit Review",
                onPressed: () {
                  AppLogger.debug("Submit button tapped, isSubmitting=$isSubmitting, canSubmit=${_canSubmit()}");
                  if (!isSubmitting && _canSubmit()) {
                    _submitReview();
                  }
                },
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return "Poor";
      case 2:
        return "Fair";
      case 3:
        return "Good";
      case 4:
        return "Very Good";
      case 5:
        return "Excellent";
      default:
        return "";
    }
  }

  bool _canSubmit() {
    if (selectedRating == 0) {
      AppLogger.debug("Cannot submit: No rating selected");
      return false;
    }
    if (disputeSelections.containsValue(true) && disputeController.text.trim().isEmpty) {
      AppLogger.debug("Cannot submit: Dispute selected but explanation empty");
      return false;
    }
    if (therapistId == 0) {
      AppLogger.debug("Cannot submit: Invalid therapist ID");
      return false;
    }
    AppLogger.debug("Can submit: Rating=$selectedRating, DisputeText=${disputeController.text}, TherapistId=$therapistId");
    return true;
  }

  Future<void> _submitReview() async {
    if (!_canSubmit()) {
      AppLogger.debug("SubmitReview: Cannot submit");
      return;
    }

    setState(() {
      isSubmitting = true;
    });
    AppLogger.debug("SubmitReview: Started, isSubmitting=$isSubmitting");

    try {
      final apiService = ApiService();
      String? selectedDisputeType;
      int? disputeSettingId;
      disputeSelections.forEach((key, value) {
        if (value) {
          selectedDisputeType = key;
          disputeSettingId = disputeSettings.firstWhere(
                (setting) => setting['dispute_type'] == key,
            orElse: () => {'id': null},
          )['id'];
        }
      });
      AppLogger.debug("SubmitReview: DisputeType=$selectedDisputeType, DisputeSettingId=$disputeSettingId");

      AppLogger.debug("SubmitReview: Posting review with therapist_id=$therapistId, booking_id=${widget.bookingId}");
      await apiService.postReview({
        'therapist_id': therapistId,
        'booking_id': widget.bookingId,
        'rating': selectedRating,
        'review': reviewController.text.trim(),
      });

      if (selectedDisputeType != null && disputeSettingId != null) {
        AppLogger.debug("SubmitReview: Posting dispute with dispute_setting=$disputeSettingId");
        await apiService.postDispute({
          'dispute_setting': disputeSettingId,
          'booking': widget.bookingId,
          'description': disputeController.text.trim(),
        });
      }

      Map<String, dynamic> disputes = {
        'disputeType': selectedDisputeType,
        'disputeExplanation': disputeController.text.trim(),
      };
      AppLogger.debug("SubmitReview: Calling onReviewSubmitted with rating=$selectedRating, disputes=$disputes");
      widget.onReviewSubmitted(
        selectedRating,
        reviewController.text.trim(),
        disputes,
      );

      AppLogger.debug("SubmitReview: Showing success snackbar");
      CustomSnackBar.show(
        context,
        "Review submitted successfully!",
        type: ToastificationType.success,
      );

      AppLogger.debug("SubmitReview: Closing bottom sheet");
      Navigator.pop(context);
    } catch (e) {
      String errorMessage = "Failed to submit review. Please try again.";
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
        errorMessage = "Endpoint not found.";
      } else if (e is ServerException) {
        errorMessage = "Server error occurred.";
      } else if (e is ApiException) {
        errorMessage = e.message;
      }
      AppLogger.error("SubmitReview error: $e");
      CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
    } finally {
      setState(() {
        isSubmitting = false;
      });
      AppLogger.debug("SubmitReview: Finished, isSubmitting=$isSubmitting");
    }
  }
}