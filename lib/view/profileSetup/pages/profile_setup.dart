import 'dart:io';
import 'package:country_pickers/countries.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import 'package:intl/intl.dart';
import '../../../controller/phone_number_controller.dart';
import '../../../controller/user_controller.dart';
import '../../../themes/colors.dart';
import '../../auth/widgets/customTextField.dart';
import '../../widgets/app_logger.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_gradientButton.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/payment_options_sheet.dart';
import '../widgets/step_progress_indicator.dart';
import '../../../../api/api_service.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  File? _image;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final dobController = TextEditingController();
  final phoneFieldController = PhoneNumberFieldController();
  String? selectedCountryCode;
  bool isSocialSignUp = false;
  int? userId;
  int? profileId;

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments as Map<String, dynamic>?;
    nameController.text = arguments?['full_name'] ?? '';
    emailController.text = arguments?['email'] ?? '';
    phoneController.text = arguments?['phone_number'] ?? '';
    selectedCountryCode = arguments?['country_code'] ?? '+1';
    isSocialSignUp = arguments?['source'] == 'social';
    userId = arguments?['user_id'];
    profileId = arguments?['profile_id'];
    AppLogger.debug(
        "ProfileSetupPage: country_code=$selectedCountryCode, isSocialSignUp=$isSocialSignUp, userId=$userId, profileId=$profileId");
    if (selectedCountryCode != null) {
      final cleanCode = selectedCountryCode!.replaceFirst('+', '');
      final country = countryList.firstWhere(
            (c) => c.phoneCode == cleanCode && (cleanCode == '880' ? c.isoCode == 'BD' : true),
        orElse: () => CountryPickerUtils.getCountryByIsoCode('US'),
      );
      phoneFieldController.selectedCountry = country;
      AppLogger.debug("Selected country: ${country.name}, Phone code: +${country.phoneCode}");
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    dobController.dispose();
    phoneFieldController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      AppLogger.error("Error picking image: $e");
      CustomSnackBar.show(context, "Failed to pick image.", type: ToastificationType.error);
    }
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            scaffoldBackgroundColor: Colors.white,
            dialogBackgroundColor: Colors.white,
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: primaryTextColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
            textTheme: TextTheme(
              headlineMedium: TextStyle(color: primaryTextColor),
              titleLarge: TextStyle(color: primaryTextColor),
              bodyLarge: TextStyle(color: primaryTextColor),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: primaryColor,
              headerForegroundColor: Colors.white,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return Colors.grey;
                }
                return primaryTextColor;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return primaryColor;
                }
                return null;
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return primaryColor;
              }),
              todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return primaryColor;
                }
                return Colors.white;
              }),
              todayBorder: BorderSide.none,
              yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return primaryTextColor;
              }),
              yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return primaryColor;
                }
                return null;
              }),
              dayOverlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return Colors.transparent;
                }
                return primaryColor.withAlpha(50);
              }),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      dobController.text = formattedDate;
    }
  }

  bool validateInputs() {
    // Validate Name
    if (nameController.text.trim().isEmpty) {
      CustomSnackBar.show(context, "Please enter your name", type: ToastificationType.error);
      return false;
    }

    // Validate Email
    if (emailController.text.trim().isEmpty) {
      CustomSnackBar.show(context, "Please enter your email", type: ToastificationType.error);
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim())) {
      CustomSnackBar.show(context, "Please enter a valid email address", type: ToastificationType.error);
      return false;
    }

    // Validate Phone Number
    if (phoneController.text.trim().isEmpty) {
      CustomSnackBar.show(context, "Please enter a phone number", type: ToastificationType.error);
      return false;
    }
    if (!RegExp(r'^[0-9]{7,15}$').hasMatch(phoneController.text.trim())) {
      CustomSnackBar.show(context, "Please enter a valid phone number (7-15 digits)", type: ToastificationType.error);
      return false;
    }

    // Validate Date of Birth
    if (dobController.text.trim().isEmpty) {
      CustomSnackBar.show(context, "Please select your date of birth", type: ToastificationType.error);
      return false;
    }
    try {
      DateTime.parse(dobController.text.trim());
    } catch (e) {
      CustomSnackBar.show(context, "Invalid date format. Please use YYYY-MM-DD", type: ToastificationType.error);
      return false;
    }

    // Validate Image
    if (_image == null) {
      CustomSnackBar.show(context, "Please upload a profile picture", type: ToastificationType.error);
      return false;
    }

    // Validate userId and profileId
    if (userId == null || profileId == null) {
      CustomSnackBar.show(context, "User or profile data missing", type: ToastificationType.error);
      return false;
    }

    return true;
  }

  Future<void> handleSaveAndContinue() async {
    if (!validateInputs()) return;

    LoadingManager.showLoading();

    try {
      final apiService = ApiService();
      final userTypeController = Get.find<UserTypeController>();
      final isTherapist = Get.arguments?['isTherapist'] ?? false;

      final phoneNumber = phoneController.text.trim();
      final response = await apiService.setupClientProfile(
        userId!,
        profileId: profileId!,
        image: _image,
        phone: phoneNumber.isNotEmpty ? phoneNumber : null,
        dateOfBirth: dobController.text.trim(),
      );

      AppLogger.info("Profile updated: ${response.toString()}");

      LoadingManager.hideLoading();

      CustomSnackBar.show(context, "Profile SetUp successfully!", type: ToastificationType.success);

      if (isSocialSignUp && phoneNumber.isNotEmpty) {
        final countryCode = phoneFieldController.getCountryCode();
        Get.toNamed(
          '/homePage',
          arguments: {
            "source": "signup",
            "email": emailController.text.trim(),
            "full_name": nameController.text.trim(),
            "phone_number": phoneNumber,
            "country_code": countryCode,
            "isTherapist": isTherapist,
            "user_id": userId,
            "profile_id": profileId,
          },
        );
      } else {
        if (isTherapist) {
          Get.toNamed("/verifyDocumentsPage");
        } else {
          Get.toNamed("/homePage");
        }
      }
    } catch (e) {
      LoadingManager.hideLoading();

      String errorMessage = "Failed to update profile. Please try again.";
      if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      } else if (e is UnauthorizedException) {
        errorMessage = "Authentication failed. Please log in again.";
      }
      CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
      AppLogger.error("Profile update error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                return const SizedBox.shrink();
              }),
              SizedBox(height: 20.h),
              CustomTextField(
                hintText: "Enter your name",
                icon: Icons.person_outline,
                controller: nameController,
                readOnly: true,
              ),
              SizedBox(height: 15.h),
              CustomTextField(
                hintText: "Enter your email",
                icon: Icons.email_outlined,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
              ),
              SizedBox(height: 15.h),
              PhoneNumberField(
                controller: phoneController,
                phoneFieldController: phoneFieldController,
                initialCountryCode: selectedCountryCode,
                readOnly: !isSocialSignUp,
              ),
              SizedBox(height: 15.h),
              TextField(
                controller: dobController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: "Select Date of Birth",
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.r),
                    borderSide: BorderSide(color: borderColor.withAlpha(40), width: 1.5.w),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.r),
                    borderSide: BorderSide(color: borderColor.withAlpha(40), width: 1.5.w),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.r),
                    borderSide: BorderSide(color: borderColor.withAlpha(40), width: 2.w),
                  ),
                ),
                onTap: _selectDate,
              ),
              SizedBox(height: 20.h),
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
                return const SizedBox.shrink();
              }),
              SizedBox(height: 0.07.sh),
              ThaiMassageButton(
                text: "Save & continue",
                isPrimary: true,
                onPressed: handleSaveAndContinue,
              ),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }
}