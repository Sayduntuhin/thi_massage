import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';
import 'package:thi_massage/view/widgets/custom_gradientButton.dart';
import '../../../controller/location_controller.dart';
import '../../widgets/custom_appbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../api/api_service.dart';
import '../../widgets/custom_snackbar.dart';
import 'package:toastification/toastification.dart';

import '../widgets/payment_webview_page.dart';

class AppointmentPaymentScreen extends StatefulWidget {
  const AppointmentPaymentScreen({super.key});

  @override
  State<AppointmentPaymentScreen> createState() => _AppointmentPaymentScreenState();
}

class _AppointmentPaymentScreenState extends State<AppointmentPaymentScreen> {
  bool hasPromo = false;
  bool agreeNearby = false;
  bool agreeTerms = false;
  final TextEditingController _promoController = TextEditingController();
  final ApiService apiService = ApiService();
  Map<String, dynamic>? sessionSummary;
  String? massageType;
  bool isLoading = true;
  String? errorMessage;
  String? lastAppliedPromoCode;
  bool isLoyaltyPointsApplied = false;

  final List<String> cardImages = [
    'assets/images/card1.png',
    'assets/images/card2.png',
    'assets/images/card3.png',
  ];

  int _initialPage = 1;

  late final String massageImage;
  late final String massageName;
  late final String formattedDateTime;
  late final int bookingId;
  late final int? therapistUserId;
  late final String? therapistName;
  final LocationController locationController = Get.put(LocationController());

  @override
  void initState() {
    super.initState();
    // Get arguments
    final arguments = Get.arguments as Map<String, dynamic>?;
    massageImage = arguments?['image'] ?? 'assets/images/thi_massage.png';
    massageName = arguments?['name'] ?? 'Unknown Massage';
    bookingId = arguments?['booking_id'] as int? ?? 0;
    therapistUserId = arguments?['therapist_user_id'] as int?;
    therapistName = arguments?['therapist_name'] as String? ?? 'Unknown Therapist';
    AppLogger.debug(
        "Massage Image: $massageImage, Massage Name: $massageName, Booking ID: $bookingId, "
            "Therapist User ID: $therapistUserId, Therapist Name: $therapistName");

    // Format date and time
    final DateTime? selectedDateTime = arguments?['dateTime'] != null
        ? DateTime.parse(arguments!['dateTime'])
        : null;

    if (selectedDateTime != null) {
      final dateFormat = DateFormat('d MMMM yyyy');
      final timeFormat = DateFormat('h:mm a');
      final startTime = timeFormat.format(selectedDateTime);
      final endTime = timeFormat.format(selectedDateTime.add(Duration(minutes: 30)));
      formattedDateTime = "${dateFormat.format(selectedDateTime)}, $startTime - $endTime";
    } else {
      final now = DateTime.now();
      final dateFormat = DateFormat('d MMMM yyyy');
      final timeFormat = DateFormat('h:mm a');
      final startTime = timeFormat.format(now);
      final endTime = timeFormat.format(now.add(Duration(minutes: 30)));
      formattedDateTime = "${dateFormat.format(now)}, $startTime - $endTime";
    }

    // Delay fetchPaymentSummary to avoid build phase issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchPaymentSummary();
    });
  }

  Future<void> fetchPaymentSummary([String? promoCode, bool? redeem, bool isLoyaltyAction = false]) async {
    try {
      setState(() => isLoading = true);
      AppLogger.debug(
          'Fetching payment summary for booking_id: $bookingId, therapist_user_id: $therapistUserId, '
              'promo_code: $promoCode, redeem: $redeem, isLoyaltyAction: $isLoyaltyAction');
      final response = await apiService.getPaymentSummary(
        bookingId,
        promoCode ?? (hasPromo && _promoController.text.isNotEmpty ? _promoController.text : null),
        redeem,
      );
      AppLogger.debug('Payment Summary API Response: $response');
      setState(() {
        massageType = response['massage_type'] as String?;
        sessionSummary = response['session_summary'] as Map<String, dynamic>?;
        isLoading = false;
        lastAppliedPromoCode = promoCode ?? _promoController.text;
        isLoyaltyPointsApplied = (response['session_summary']['loyalty_points_used'] as int? ?? 0) > 0;
      });
      if (promoCode != null && response['session_summary']['promo_discount'] != 0.0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          CustomSnackBar.show(
            context,
            'Promo code applied successfully!',
            type: ToastificationType.success,
          );
        });
      }
      if (isLoyaltyAction) {
        if (redeem == true && response['session_summary']['loyalty_discount'] != 0.0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            CustomSnackBar.show(
              context,
              'Loyalty points applied successfully!',
              type: ToastificationType.success,
            );
          });
        } else if (redeem == false && response['session_summary']['loyalty_discount'] == 0.0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            CustomSnackBar.show(
              context,
              'Loyalty points removed successfully!',
              type: ToastificationType.success,
            );
          });
        }
      }
    } catch (e) {
      AppLogger.error('Fetch Payment Summary Error: $e');
      String detailedError = 'Failed to load payment summary: $e';
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
          detailedError,
          type: ToastificationType.error,
        );
      });
    }
  }

  Future<void> _toggleLoyaltyPoints() async {
    try {
      setState(() => isLoading = true);
      final newRedeemState = !isLoyaltyPointsApplied;
      await fetchPaymentSummary(
        hasPromo && _promoController.text.isNotEmpty ? _promoController.text : lastAppliedPromoCode,
        newRedeemState,
        true, // Indicate this is a loyalty action
      );
      setState(() {
        isLoyaltyPointsApplied = newRedeemState;
        isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error applying/removing loyalty points: $e');
      String detailedError = 'Failed to update loyalty points: $e';
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
        isLoading = false;
        errorMessage = detailedError;
        isLoyaltyPointsApplied = false; // Reset on error to reflect API state
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        CustomSnackBar.show(
          context,
          detailedError,
          type: ToastificationType.error,
        );
      });
    }
  }

  void _showCancellationPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    "Cancellation Policy",
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _policySection(
                            title: "Confirmed Bookings:",
                            points: [
                              "If a cancellation is made within 24 hours before the scheduled appointment, a 50% cancellation fee of the total service price will be charged.",
                              "If a cancellation is made within 3 hours before the scheduled appointment, a 100% cancellation fee of the total service price will be charged.",
                            ],
                          ),
                          _policySection(
                            title: "No-Shows and Last-Minute Cancellations:",
                            points: [
                              "If a cancellation occurs within 30 minutes before the scheduled appointment or if the client does not show up, the full session price will be charged.",
                            ],
                          ),
                          _policySection(
                            title: "Platform Operations Fee:",
                            points: [
                              "If a cancellation is made more than 24 hours before the confirmed appointment, a 7.5% platform operations fee will be applied. This fee helps support platform operations, including handling cancellations.",
                            ],
                          ),
                          _policySection(
                            title: "Note:",
                            points: [
                              "No cancellation fees will be charged if the appointment is canceled before a provider has been confirmed for the booking.",
                            ],
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SecondaryAppBar(title: "Payment"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sessionSummary == null
          ? Center(
        child: Text(
          errorMessage ?? 'Failed to load payment summary',
          style: TextStyle(fontSize: 14.sp, color: Colors.red),
          textAlign: TextAlign.center,
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Card Carousel
            Text("Select card",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 5.h),
            CarouselSlider.builder(
              options: CarouselOptions(
                height: 0.2.sh,
                enlargeCenterPage: true,
                initialPage: _initialPage,
                enableInfiniteScroll: false,
                viewportFraction: 0.75,
              ),
              itemCount: cardImages.length,
              itemBuilder: (context, index, realIdx) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Image.asset(cardImages[index], fit: BoxFit.cover),
                );
              },
            ),
            SizedBox(height: 20.h),

            /// Massage Summary Card
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 5.r, offset: Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: massageImage.startsWith('http')
                        ? CachedNetworkImage(
                      imageUrl: massageImage,
                      width: 60.w,
                      height: 60.h,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/images/thi_massage.png',
                        width: 60.w,
                        height: 60.h,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Image.asset(
                      massageImage,
                      width: 60.w,
                      height: 60.h,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          massageName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20.sp,
                            fontFamily: "PlayfairDisplay",
                            color: primaryTextColor,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 14.sp, color: Color(0xff828282)),
                            Obx(() => locationController.isLoading.value
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : Text(
                              locationController.hasError.value
                                  ? 'Unable to fetch location'
                                  : locationController.locationName.value,
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                            )),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(Icons.calendar_month,
                                size: 20.sp, color: primaryTextColor),
                            SizedBox(width: 4.w),
                            Text(
                              formattedDateTime.split(', ')[0],
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: primaryTextColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Icon(Icons.access_time,
                                size: 20.sp, color: primaryTextColor),
                            SizedBox(width: 4.w),
                            Text(
                              formattedDateTime.split(', ')[1],
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: primaryTextColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            /// Promo Code Section
            if (hasPromo)
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: secounderyBorderColor.withAlpha(90),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 24.w,
                          child: Checkbox(
                            value: hasPromo,
                            onChanged: (val) => setState(() {
                              hasPromo = val!;
                              if (!hasPromo) {
                                _promoController.clear();
                                lastAppliedPromoCode = null;
                                fetchPaymentSummary(null, isLoyaltyPointsApplied, false);
                              }
                            }),
                            activeColor: Color(0xFFD09C3F),
                          ),
                        ),
                        Text("Do you have a Promo code?",
                            style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Text("Promo Code",
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _promoController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: "Enter promo code",
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 12.h),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: () {
                            if (_promoController.text.isEmpty) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                CustomSnackBar.show(
                                  context,
                                  'Please enter a promo code',
                                  type: ToastificationType.error,
                                );
                              });
                              return;
                            }
                            if (_promoController.text == lastAppliedPromoCode) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                CustomSnackBar.show(
                                  context,
                                  'Promo code already applied',
                                  type: ToastificationType.info,
                                );
                              });
                              return;
                            }
                            fetchPaymentSummary(_promoController.text, isLoyaltyPointsApplied, false);
                          },
                          child: Container(
                            height: 48.h,
                            width: 48.h,
                            decoration: BoxDecoration(
                              color: Color(0xFFD09C3F),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(Icons.percent, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Checkbox(
                    value: hasPromo,
                    onChanged: (val) => setState(() {
                      hasPromo = val!;
                      if (!hasPromo) {
                        _promoController.clear();
                        lastAppliedPromoCode = null;
                        fetchPaymentSummary(null, isLoyaltyPointsApplied, false);
                      }
                    }),
                    activeColor: Color(0xFFD09C3F),
                  ),
                  Text("Do you have a Promo code?",
                      style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            SizedBox(height: 24.h),

            /// Session Summary
            Text("Session Summary",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 10.h),
            _summaryRow("Massage Fee",
                "\$${sessionSummary!['massage_fee'].toStringAsFixed(1)}"),
            _summaryRow(
              "Massage Table Deduction",
              "\$${sessionSummary!['massage_table_deduction'].toStringAsFixed(1)}",
              isNegative: sessionSummary!['massage_table_deduction'] > 0,
            ),
            if (sessionSummary!['promo_discount'] != 0.0)
              _summaryRow(
                "Promo Discount (${sessionSummary!['promo_percentage']?.toStringAsFixed(1)}%)",
                "\$${sessionSummary!['promo_discount'].toStringAsFixed(1)}",
                isNegative: true,
              ),
            if (sessionSummary!['loyalty_discount'] != 0.0)
              _summaryRow(
                "Loyalty Points Discount",
                "\$${sessionSummary!['loyalty_discount'].toStringAsFixed(1)}",
                isNegative: true,
              ),
            Divider(),
            _summaryRow(
                "Subtotal", "\$${sessionSummary!['subtotal'].toStringAsFixed(1)}"),
            _summaryRow(
                "Booking Fee", "\$${sessionSummary!['booking_fee'].toStringAsFixed(1)}"),
            _summaryRow("Tip", "\$${sessionSummary!['tip'].toStringAsFixed(1)}"),
            Divider(),
            Container(
              padding: EdgeInsets.all(16.w),
              margin: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        color: primaryTextColor,
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Redeem Your Points",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: primaryTextColor.withAlpha(80),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      "You have ${sessionSummary!['total_loyalty_points']} points (worth \$${sessionSummary!['loyalty_worth'].toStringAsFixed(2)} off)",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: buttonTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  GestureDetector(
                    onTap: _toggleLoyaltyPoints,
                    child: Row(
                      children: [
                        Container(
                          width: 20.w,
                          height: 20.h,
                          decoration: BoxDecoration(
                            color: isLoyaltyPointsApplied
                                ? Color(0xFFB8860B)
                                : Colors.transparent,
                            border: Border.all(
                                color: isLoyaltyPointsApplied
                                    ? Color(0xFFB8860B)
                                    : Colors.grey[600]!,
                                width: 2),
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                          child: isLoyaltyPointsApplied
                              ? Icon(
                            Icons.check,
                            size: 14.sp,
                            color: Colors.white,
                          )
                              : null,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            "Apply loyalty points for discount",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff787160),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total",
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20.sp)),
                Text(
                  "\$${sessionSummary!['total'].toStringAsFixed(1)}",
                  style: TextStyle(
                      fontSize: 18.sp,
                      color: Color(0xFFD09C3F),
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 15.h),
            RichText(
              text: TextSpan(
                text: "By continuing, you agree to ",
                style: TextStyle(color: Colors.black87, fontSize: 16.sp),
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      onTap: () => _showCancellationPolicy(context),
                      child: Text(
                        "Cancellation Policy",
                        style: TextStyle(
                          color: primaryTextColor,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 0.05.sh,
              child: Theme(
                data: Theme.of(context).copyWith(splashFactory: NoSplash.splashFactory,splashColor: Colors.transparent,highlightColor: Colors.transparent),
                child: CheckboxListTile(
                  value: agreeNearby,
                  onChanged: (val) => setState(() => agreeNearby = val ?? false),
                  title: Text("I agree to Thai massage near me.",
                      style: TextStyle(fontSize: 13.sp)),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  hoverColor: Colors.transparent,

                ),
              ),
            ),
            SizedBox(
              height: 0.05.sh,
              child: Theme(
                data: Theme.of(context).copyWith(splashFactory: NoSplash.splashFactory,splashColor: Colors.transparent,highlightColor: Colors.transparent),
                child: CheckboxListTile(
                  value: agreeTerms,
                  onChanged: (val) => setState(() => agreeTerms = val ?? false),
                  title: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.black, fontSize: 13.sp),
                      children: [
                        TextSpan(text: "I agree to "),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () => Get.toNamed("/termsAndConditions"),
                            child: Text(
                              "Terms and Conditions of Use",
                              style: TextStyle(
                                color: primaryTextColor,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            CustomGradientButton(
              text: "Pay",
              onPressed: () async {
                if (!agreeNearby || !agreeTerms) {
                  CustomSnackBar.show(
                    context,
                    'Please agree to all terms and conditions',
                    type: ToastificationType.error,
                  );
                  return;
                }
                AppLogger.debug(
                    'Initiating payment for booking_id: $bookingId, '
                        'therapist_user_id: $therapistUserId, therapist_name: $therapistName');
                try {
                  setState(() => isLoading = true);
                  final paymentData = await apiService.initiatePayment(bookingId);
                  setState(() => isLoading = false);

                  final sessionUrl = paymentData['session_url'] as String?;
                  final paymentId = paymentData['payment_id'] as int?;

                  if (sessionUrl != null && paymentId != null) {
                    // Navigate to WebView for payment
                    Get.to(() => PaymentWebViewPage(
                      sessionUrl: sessionUrl,
                      bookingId: bookingId,
                      paymentId: paymentId,
                    ));
                  } else {
                    CustomSnackBar.show(
                      context,
                      'Invalid payment response',
                      type: ToastificationType.error,
                    );
                  }
                } catch (e) {
                  setState(() => isLoading = false);
                  String errorMessage = 'Failed to initiate payment: $e';
                  if (e is NetworkException) {
                    errorMessage = 'Network error: Please check your internet connection.';
                  } else if (e is UnauthorizedException) {
                    errorMessage = 'Authentication failed: Please log in again.';
                  } else if (e is ServerException) {
                    errorMessage = 'Server error: Please try again later.';
                  } else if (e is BadRequestException) {
                    errorMessage = e.message;
                  }
                  AppLogger.error(errorMessage);
                  CustomSnackBar.show(
                    context,
                    errorMessage,
                    type: ToastificationType.error,
                  );
                }
              },
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String title, String value, {bool isNegative = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.black,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              color: isNegative ? Colors.red : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _policySection({required String title, required List<String> points}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.sp),
          ),
          SizedBox(height: 6.h),
          ...points.map((point) => Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("• ", style: TextStyle(fontSize: 14.sp)),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(fontSize: 14.sp, height: 1.4),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}