import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/view/widgets/custom_gradientButton.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_appbar.dart';

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
                onChanged: (value) {
                  setState(() {
                    cardNumber = value.isEmpty ? "1234 1234 1234 1234" : value;
                  });
                },
              ),
              SizedBox(height: 15.h),
        
              // Card Holder Name Input
              _buildTextField(
                controller: cardHolderController,
                label: "Card Holder",
                hint: "Enter name",
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
                      hint: "MM/YYYY",
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
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Color(0xFFB0652E)),
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
        gradient: LinearGradient(
          colors: [Color(0xFF0A397E), Color(0xFF703C6D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 5.r, offset: Offset(2, 2)),
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
              SizedBox(width: 0.04.sw),
              Image.asset("assets/images/card_scan.png",width: 50.w,)

            ],
          ),
          SizedBox(height: 15.h),

          // Expiry & CVV
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("VALID \nTHRU", style: TextStyle(color: Colors.white, fontSize: 8.sp)),
              ),
              Text("$expiryDate", style: TextStyle(color: Colors.white, fontSize: 14.sp)),
              SizedBox(width: 0.1.sw,),
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
              Image.asset("assets/images/mastercard.png",width: 50.w,)
            ],
          ),
        ],
      ),
    );
  }
}
