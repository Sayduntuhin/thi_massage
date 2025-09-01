import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/view/widgets/custom_gradientButton.dart';
import 'package:toastification/toastification.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_snackBar.dart';
import 'package:flutter/services.dart';

class AddCardPage extends StatefulWidget {
  const AddCardPage({super.key});

  @override
  State<AddCardPage> createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardHolderController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  String cardNumber = "1234 1234 1234 1234";
  String cardHolder = "Name Here";
  String expiryDate = "MM/YY";
  String cvv = "123";

  // Validation function for card number (16 digits with spaces)
  bool _validateCardNumber(String value) {
    final cleaned = value.replaceAll(' ', '');
    return cleaned.length == 16 && RegExp(r'^\d+$').hasMatch(cleaned);
  }

  // Validation function for card holder name (letters and spaces only)
  bool _validateCardHolder(String value) {
    return value.isNotEmpty && RegExp(r'^[a-zA-Z\s]+$').hasMatch(value);
  }

  // Validation function for expiry date (MM/YY or MM/YYYY)
  bool _validateExpiryDate(String value) {
    if (!RegExp(r'^(0[1-9]|1[0-2])\/(\d{2}|\d{4})$').hasMatch(value)) {
      return false;
    }
    final parts = value.split('/');
    final month = int.tryParse(parts[0]) ?? 0;
    final year = int.tryParse(parts[1]) ?? 0;
    final currentYear = DateTime.now().year % 100; // Last two digits of current year
    return month >= 1 && month <= 12 && year >= currentYear;
  }

  // Validation function for CVV (3 or 4 digits)
  bool _validateCvv(String value) {
    return RegExp(r'^\d{3,4}$').hasMatch(value);
  }

  // Format card number input (adds spaces every 4 digits)
  String _formatCardNumber(String value) {
    final cleaned = value.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 0.05.sh),
              const CustomAppBar(),
              SizedBox(height: 0.04.sh),

              // Title
              Text(
                "Add Card",
                style: TextStyle(
                  fontSize: 30.sp,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                  fontFamily: "PlayfairDisplay",
                ),
              ),
              SizedBox(height: 20.h),

              // Card Number Input
              _buildTextField(
                controller: cardNumberController,
                label: "Card Number",
                hint: "1234 1234 1234 1234",
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  _CardNumberInputFormatter(),
                ],
                onChanged: (value) {
                  setState(() {
                    cardNumber = value.isEmpty ? "1234 1234 1234 1234" : _formatCardNumber(value);
                  });
                },
              ),
              SizedBox(height: 15.h),

              // Card Holder Name Input
              _buildTextField(
                controller: cardHolderController,
                label: "Card Holder",
                hint: "Enter name",
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                ],
                onChanged: (value) {
                  setState(() {
                    cardHolder = value.isEmpty ? "Name Here" : value;
                  });
                },
              ),
              SizedBox(height: 15.h),

              // Expiry Date & CVV Fields
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: expiryDateController,
                      label: "Expiry Date",
                      hint: "MM/YY",
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
                        LengthLimitingTextInputFormatter(7), // MM/YY or MM/YYYY
                        _ExpiryDateInputFormatter(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          expiryDate = value.isEmpty ? "MM/YY" : value;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _buildTextField(
                      controller: cvvController,
                      label: "CVV",
                      hint: "123",
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onChanged: (value) {
                        setState(() {
                          cvv = value.isEmpty ? "123" : value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Credit Card Preview
              _buildCardPreview(),
              SizedBox(height: 30.h),

              // Save Button
              CustomGradientButton(
                text: "Save",
                showIcon: false,
                onPressed: () {
                  if (!_validateCardNumber(cardNumberController.text)) {
                    CustomSnackBar.show(
                      context,
                      "Please enter a valid 16-digit card number.",
                      type: ToastificationType.error,
                    );
                    return;
                  }
                  if (!_validateCardHolder(cardHolderController.text)) {
                    CustomSnackBar.show(
                      context,
                      "Please enter a valid card holder name (letters only).",
                      type: ToastificationType.error,
                    );
                    return;
                  }
                  if (!_validateExpiryDate(expiryDateController.text)) {
                    CustomSnackBar.show(
                      context,
                      "Please enter a valid expiry date (MM/YY or MM/YYYY).",
                      type: ToastificationType.error,
                    );
                    return;
                  }
                  if (!_validateCvv(cvvController.text)) {
                    CustomSnackBar.show(
                      context,
                      "Please enter a valid CVV (3 or 4 digits).",
                      type: ToastificationType.error,
                    );
                    return;
                  }
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5.h),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Color(0xFFB0652E)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
          ),
        ),
      ],
    );
  }

  Widget _buildCardPreview() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.r),
        gradient: const LinearGradient(
          colors: [Color(0xFF0A397E), Color(0xFF703C6D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 5.r, offset: const Offset(2, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bank Icon & Credit Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.account_balance, color: Colors.white, size: 30.sp),
              Text("CREDIT", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 20.h),

          // Card Number
          Row(
            children: [
              Text(
                cardNumber,
                style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const Spacer(),
              Image.asset("assets/images/card_scan.png", width: 50.w),
            ],
          ),
          SizedBox(height: 15.h),

          // Expiry & CVV
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("VALID \nTHRU", style: TextStyle(color: Colors.white, fontSize: 8)),
              ),
              Text(expiryDate, style: TextStyle(color: Colors.white, fontSize: 14.sp)),
              SizedBox(width: 0.1.sw),
              Text(cvv, style: TextStyle(color: Colors.white, fontSize: 14.sp)),
            ],
          ),
          SizedBox(height: 15.h),

          // Card Holder Name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cardHolder,
                style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              Image.asset("assets/images/mastercard.png", width: 50.w),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom formatter for card number (adds spaces every 4 digits)
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = newValue.text.replaceAll(' ', '');
    if (cleaned.length > 16) {
      return oldValue;
    }
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0 && i < 16) {
        buffer.write(' ');
      }
      buffer.write(cleaned[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Custom formatter for expiry date (adds slash after MM)
class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = newValue.text.replaceAll('/', '');
    if (cleaned.length > 6) {
      return oldValue; // Limit to MM/YYYY
    }
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i == 2 && cleaned.length > 2) {
        buffer.write('/');
      }
      buffer.write(cleaned[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}