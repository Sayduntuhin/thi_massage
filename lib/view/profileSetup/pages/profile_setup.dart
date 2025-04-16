import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../controller/user_controller.dart';
import '../../../themes/colors.dart';
import '../../auth/signup/widgets/phone_code_picker.dart';
import '../../auth/widgets/customTextField.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_gradientButton.dart';
import '../../widgets/payment_options_sheet.dart';
import '../widgets/step_progress_indicator.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  File? _image;

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

  @override
  Widget build(BuildContext context) {
    // Access the UserTypeController
    final UserTypeController userTypeController = Get.find<UserTypeController>();

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
                  // Use Obx to make the title reactive to user type changes
                  Obx(() => Text(
                    "${userTypeController.isTherapist.value ? 'Therapist' : 'Client'} \nProfile Setup",
                    style: TextStyle(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                      fontFamily: "PlayfairDisplay",
                    ),
                  )),
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
                        style: TextStyle(
                            fontSize: 14.sp, color: Colors.white, fontFamily: 'Urbanist'),
                      )
                          : null,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              /// Progress bar (Only for therapist)
              Obx(() {
                if (userTypeController.isTherapist.value) {
                  return Column(
                    children: [
                      SizedBox(height: 20.h),
                      const StepProgressIndicator(currentStep: 1),
                      SizedBox(height: 20.h),
                    ],
                  );
                }
                return const SizedBox.shrink(); // Return empty widget if not a therapist
              }),

              SizedBox(height: 20.h),

              CustomTextField(hintText: "Enter your name", icon: Icons.person_outline),
              SizedBox(height: 15.h),

              CustomTextField(hintText: "Enter your email", icon: Icons.email_outlined),
              SizedBox(height: 15.h),

              PhoneNumberField(),
              SizedBox(height: 15.h),

              CustomTextField(hintText: "Date of Birth", icon: Icons.calendar_today_outlined),
              SizedBox(height: 20.h),

              // Show "Add Payment Method" only for clients (not therapists)
              Obx(() {
                if (!userTypeController.isTherapist.value) {
                  return Column(
                    children: [
                      CustomGradientButton(
                        text: "Add Payment Method",
                        showIcon: true,
                        onPressed: () => PaymentOptionsSheet.show(context),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        "Adding Payment Method is Optional at this stage",
                        style: TextStyle(fontSize: 14.sp, color: Colors.black54),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink(); // Return empty widget if therapist
              }),

              SizedBox(height: 0.07.sh),
              ThaiMassageButton(
                text: "Save & continue",
                isPrimary: true,
                onPressed: () {
                  // Use the controller's isTherapist value to determine navigation
                  if (userTypeController.isTherapist.value) {
                    Get.toNamed("/verifyDocumentsPage");
                  } else {
                    Get.toNamed("/logIn");
                  }
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