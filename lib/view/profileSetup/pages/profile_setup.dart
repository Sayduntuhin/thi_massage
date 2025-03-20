import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../themes/colors.dart';
import '../../auth/signup/widgets/phone_code_picker.dart';
import '../../auth/widgets/customTextField.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_gradientButton.dart';


class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  File? _image;

  // Function to pick an image
  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // Function to show the payment options bottom sheet
  void _showPaymentBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPaymentOptions(),
    );
  }

  Widget _buildPaymentOptions() {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
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
                  color: Color(0xff333333),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Urbanist'
                ),
              ),
              SizedBox(height: 10.h),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildPaymentOption("Credit/Debit Card", "assets/images/credit.png",'/addCard'),
                    _buildPaymentOption("PayPal", "assets/images/paypal.png",''),
                    _buildPaymentOption("Google Pay", "assets/images/googlepay.png",''),
                    _buildPaymentOption("Apple Pay", "assets/images/applepay.png",''),
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
        title: Text(title, style: TextStyle(fontSize: 16.sp, color: Color(0xff666561))),
        trailing: Icon(Icons.arrow_forward_ios, size: 16.sp),
        onTap: () {
          debugPrint("$title Selected");
          Navigator.pop(context); // Close bottom sheet before navigation
          Get.toNamed(routeName); // Navigate to the corresponding route
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 0.05.sh),
              const CustomAppBar(),
              SizedBox(height: 0.04.sh),

              // Title & Profile Upload
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Profile \nsetup",
                    style: TextStyle(
                      fontSize: 38.sp,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                      fontFamily: "PlayfairDisplay",
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60.r,
                      backgroundColor: primaryTextColor,
                      backgroundImage: _image != null ? FileImage(_image!) : null,
                      child: _image == null
                          ? Text(
                        "Upload profile picture",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp, color: Colors.white, fontFamily: 'Urbanist'),
                      )
                          : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Name Field
              CustomTextField(hintText: "Enter your name", icon: Icons.person_outline),
              SizedBox(height: 15.h),

              // Email Field
              CustomTextField(hintText: "Enter your email", icon: Icons.email_outlined),
              SizedBox(height: 15.h),

              // Phone Number Field
              PhoneNumberField(),
              SizedBox(height: 15.h),

              // Date of Birth Field
              CustomTextField(hintText: "Date of Birth", icon: Icons.calendar_today_outlined),
              SizedBox(height: 20.h),

              // Add Payment Method Button (Opens Bottom Sheet)
              CustomGradientButton(
                text: "Add Payment Method",
                showIcon: true,
                onPressed: _showPaymentBottomSheet,
              ),
              SizedBox(height: 20.h),

              // Payment Method Info
              Text(
                "Adding Payment Method is Optional at this stage",
                style: TextStyle(fontSize: 14.sp, color: Colors.black54),
              ),
              SizedBox(height: 0.07.sh),

              // Save & Continue Button
              ThaiMassageButton(
                text: "Save & continue",
                isPrimary: true,
                onPressed: () {
                  Get.toNamed("/logIn"); // Navigate to next step
                },
              ),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }
}
