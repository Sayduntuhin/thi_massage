import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class PaymentOptionsSheet extends StatelessWidget {
  // Static method to show the bottom sheet with an optional route and arguments
  static void show(
      BuildContext context, {
        String? creditCardRoute,
        Map<String, dynamic>? arguments, // Add arguments parameter
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentOptionsSheet(
        creditCardRoute: creditCardRoute,
        arguments: arguments, // Pass arguments to the widget
      ),
    );
  }

  final String? creditCardRoute; // Optional route for Credit/Debit Card
  final Map<String, dynamic>? arguments; // Arguments to pass to the next screen

  const PaymentOptionsSheet({
    super.key,
    this.creditCardRoute,
    this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 50.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              SizedBox(height: 10.h),

              // Title
              Text(
                "Add Payment Method",
                style: TextStyle(
                  fontSize: 18.sp,
                  color: const Color(0xff333333),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Urbanist',
                ),
              ),
              SizedBox(height: 10.h),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Use the provided creditCardRoute, or default to '/addCard'
                    _buildPaymentOption(
                      "Credit/Debit Card",
                      "assets/images/credit.png",
                      creditCardRoute ?? '/addCard',
                    ),
                    _buildPaymentOption("PayPal", "assets/images/paypal.png", ''),
                    _buildPaymentOption("Google Pay", "assets/images/googlepay.png", ''),
                    _buildPaymentOption("Apple Pay", "assets/images/applepay.png", ''),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption(String title, String iconPath, String routeName) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: Image.asset(iconPath, width: 40.w),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xff666561),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          debugPrint("$title Selected");
          Navigator.pop(Get.context!); // Close bottom sheet before navigation
          if (routeName.isNotEmpty) {
            // Navigate to the corresponding route with the arguments
            Get.toNamed(
              routeName,
              arguments: arguments, // Pass the arguments to the next screen
            );
          }
        },
      ),
    );
  }
}