import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thi_massage/api/api_service.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';
import 'package:thi_massage/view/widgets/custom_snackbar.dart';
import 'package:toastification/toastification.dart';

class TherapistEditPage extends StatefulWidget {
  const TherapistEditPage({super.key});

  @override
  State<TherapistEditPage> createState() => _TherapistEditPageState();
}

class _TherapistEditPageState extends State<TherapistEditPage> {
  bool isEditing = false;
  File? _image;
  String? _imageUrl;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();

  // For techniques
  List<String> selectedTechniques = [];
  List<String> availableTechniques = [
    'Kneading',
    'Aromatherapy',
    'Effleurage',
    'Deep Tissue',
    'Swedish',
    'Hot Stone',
    'Thai Massage',
    'Reflexology'
  ];

  int? userId;
  int? profileId;
  bool isLoading = false;

  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initializeUserId();
  }

  Future<void> _initializeUserId() async {
    final arguments = Get.arguments as Map<String, dynamic>?;
    userId = arguments?['user_id'];
    profileId = arguments?['profile_id'];

    if (userId == null) {
      final storedUserId = await _storage.read(key: 'user_id');
      userId = int.tryParse(storedUserId ?? '');
      AppLogger.debug("Fetched userId from storage: $userId");
    }

    AppLogger.debug("TherapistEditPage: userId=$userId, profileId=$profileId");

    if (userId == null) {
      CustomSnackBar.show(context, "User ID missing. Please log in again.", type: ToastificationType.error);
      Get.offAllNamed('/login');
      return;
    }

    //fetchProfileData();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    contactController.dispose();
    dobController.dispose();
    aboutController.dispose();
    experienceController.dispose();
    super.dispose();
  }

/*  Future<void> fetchProfileData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.getTherapistProfile(userId!);
      AppLogger.debug("Profile fetched: $response");

      setState(() {
        final fullName = response['full_name'] ?? '';
        final nameParts = fullName.trim().split(' ');
        firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
        lastNameController.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        emailController.text = response['email'] ?? '';
        contactController.text = response['phone'] ?? '';
        dobController.text = response['date_of_birth'] ?? '';
        aboutController.text = response['about'] ?? '';
        experienceController.text = response['experience'] ?? '';

        // Parse techniques
        if (response['techniques'] != null && response['techniques'] is List) {
          selectedTechniques = List<String>.from(response['techniques']);
        }

        _imageUrl = response['image'] != '/media/documents/default.jpg' ? response['image'] : null;
        // Adjust image URL if backend doesn't include /api/
        if (_imageUrl != null && !_imageUrl!.startsWith('/api/')) {
          _imageUrl = '/api$_imageUrl';
        }
        profileId = response['id'];
        AppLogger.debug("Image URL set: ${ApiService.baseUrl}$_imageUrl");
      });
    } catch (e) {
      String errorMessage = "Failed to fetch profile. Please try again.";
      if (e is NotFoundException) {
        errorMessage = "Profile not found. Please set up your profile.";
        CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
        Get.toNamed('/therapistProfileSetup', arguments: {
          'user_id': userId,
          'profile_id': profileId,
          'source': 'edit_profile',
        });
      } else if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      } else if (e is UnauthorizedException) {
        errorMessage = "Authentication failed. Please log in again.";
        Get.offAllNamed('/login');
      }
      CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
      AppLogger.error("Fetch profile error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }*/

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _imageUrl = null; // Clear URL since local image is selected
        });
      }
    } catch (e) {
      AppLogger.error("Error picking image: $e");
      CustomSnackBar.show(context, "Failed to pick image.", type: ToastificationType.error);
    }
  }

 /* Future<void> _saveProfile() async {
    if (userId == null || profileId == null) {
      CustomSnackBar.show(context, "User or profile data missing", type: ToastificationType.error);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final apiService = ApiService();
      final fullName = "${firstNameController.text.trim()} ${lastNameController.text.trim()}".trim();
      await apiService.updateTherapistProfile(
        userId!,
        profileId: profileId!,
        image: _image,
        phone: contactController.text.trim().isNotEmpty ? contactController.text.trim() : null,
        dateOfBirth: dobController.text.trim().isNotEmpty ? dobController.text.trim() : null,
        about: aboutController.text.trim().isNotEmpty ? aboutController.text.trim() : null,
        experience: experienceController.text.trim().isNotEmpty ? experienceController.text.trim() : null,
        techniques: selectedTechniques.isNotEmpty ? selectedTechniques : null,
      );

      AppLogger.info("Profile updated successfully");
      CustomSnackBar.show(context, "Profile updated successfully!", type: ToastificationType.success);
      setState(() {
        isEditing = false; // Exit edit mode
      });
      await fetchProfileData(); // Refresh profile data
    } catch (e) {
      String errorMessage = "Failed to update profile. Please try again.";
      if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      } else if (e is UnauthorizedException) {
        errorMessage = "Authentication failed. Please log in again.";
        Get.offAllNamed('/login');
      }
      CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
      AppLogger.error("Profile update error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }*/

  void _toggleTechnique(String technique) {
    setState(() {
      if (selectedTechniques.contains(technique)) {
        selectedTechniques.remove(technique);
      } else {
        selectedTechniques.add(technique);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecondaryAppBar(title: "Edit Profile",showBackButton: false,),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF8B5A2B),
                          Color(0xFFD2B48C),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50.r,
                      backgroundColor: Colors.transparent,
                      child: ClipOval(
                        child: Image(
                          image: _image != null
                              ? FileImage(_image!)
                              : _imageUrl != null
                              ? NetworkImage('${ApiService.baseUrl}$_imageUrl')
                              : AssetImage("assets/images/empty_person.png") as ImageProvider,
                          fit: BoxFit.cover,
                          width: 100.r,
                          height: 100.r,
                          errorBuilder: (context, error, stackTrace) {
                            AppLogger.error("Failed to load image: ${ApiService.baseUrl}$_imageUrl, Error: $error");
                            setState(() {
                              _imageUrl = null; // Clear invalid URL
                            });
                            return Image.asset(
                              "assets/images/profilepic.png",
                              fit: BoxFit.cover,
                              width: 100.r,
                              height: 100.r,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (isEditing)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                        ),
                        child: Icon(Icons.edit, size: 16.sp, color: primaryButtonColor),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20.h),

              // Profile Section
              _buildSectionTitle("Profile"),
              Divider(color: Color(0xffD0D0D0)),
              SizedBox(height: 8.h),
              _buildProfileField("First name", firstNameController, isEditing),
              _buildProfileField("Last name", lastNameController, isEditing),
              _buildProfileField("Email", emailController, isEditing),
              _buildProfileField("Contact Number", contactController, isEditing),
              _buildProfileField("Date of Birth", dobController, isEditing),

              SizedBox(height: 20.h),

              // Account Settings Section
              _buildSectionTitle("Account Settings"),
              Divider(color: Color(0xffD0D0D0)),
              SizedBox(height: 8.h),
              _buildLabelText("About"),
              isEditing
                  ? _buildTextAreaField(aboutController)
                  : _buildAboutText(aboutController.text),
              SizedBox(height: 16.h),
              _buildExperienceField("Experience", experienceController, isEditing),
              SizedBox(height: 16.h),
              _buildTechniquesSection(),

              if (isEditing) ...[
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryButtonColor,
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      "Save Profile",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          IconButton(
            icon: SvgPicture.asset(
              isEditing ? "assets/svg/save.svg" : "assets/svg/edit.svg",
              colorFilter: const ColorFilter.mode(Color(0xFFB28D28), BlendMode.srcIn),
            ),
            onPressed: () {
              setState(() {
                isEditing = !isEditing;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller, bool isEditable) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Color(0xff383535),
            ),
          ),
          SizedBox(
            width: 0.55.sw,
            child: isEditable
                ? TextField(
              controller: controller,
              enabled: isEditable,
              style: TextStyle(fontSize: 14.sp, color: Colors.black),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFFE8ECEF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.black12, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.black12, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.black12, width: 1),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
              ),
            )
                : Align(
              alignment: Alignment.centerRight,
              child: Text(
                controller.text.isEmpty ? '-' : controller.text,
                style: TextStyle(fontSize: 16.sp, color: Colors.black),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceField(String label, TextEditingController controller, bool isEditable) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Color(0xff383535),
            ),
          ),
          SizedBox(
            width: 0.25.sw,
            child: isEditable
                ? TextField(
              controller: controller,
              enabled: isEditable,
              style: TextStyle(fontSize: 14.sp, color: Colors.black),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFFE8ECEF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.black12, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.black12, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.black12, width: 1),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
                suffixText: controller.text.isNotEmpty ? "Years" : "",
              ),
            )
                : Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: Color(0xFFE8ECEF),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                controller.text.isEmpty ? '-' : "${controller.text} Years",
                style: TextStyle(fontSize: 16.sp, color: Colors.black),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelText(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            color: Color(0xff383535),
          ),
        ),
      ),
    );
  }

  Widget _buildTextAreaField(TextEditingController controller) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: TextField(
        controller: controller,
        maxLines: 5,
        style: TextStyle(fontSize: 14.sp, color: Colors.black),
        decoration: InputDecoration(
          filled: true,
          fillColor: Color(0xFFE8ECEF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.black12, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.black12, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.black12, width: 1),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
          hintText: "Tell us about yourself and your massage specialties...",
          hintStyle: TextStyle(color: Colors.black38),
        ),
      ),
    );
  }

  Widget _buildAboutText(String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Color(0xFFE8ECEF),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text.isEmpty ? 'Placeholder' : text,
        style: TextStyle(
          fontSize: 14.sp,
          color: text.isEmpty ? Colors.black38 : Colors.black,
        ),
      ),
    );
  }

  Widget _buildTechniquesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabelText("Techniques"),
        isEditing
            ? _buildEditableTechniques()
            : _buildDisplayTechniques(),
      ],
    );
  }

  Widget _buildEditableTechniques() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: availableTechniques.map((technique) {
        final isSelected = selectedTechniques.contains(technique);
        return GestureDetector(
          onTap: () => _toggleTechnique(technique),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isSelected ? primaryButtonColor : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isSelected ? primaryButtonColor : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Padding(
                    padding: EdgeInsets.only(right: 4.w),
                    child: Icon(Icons.check, size: 16.sp, color: Colors.white),
                  ),
                Text(
                  technique,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDisplayTechniques() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: selectedTechniques.isEmpty
          ? [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            "No techniques selected",
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14.sp,
            ),
          ),
        )
      ]
          : selectedTechniques.map((technique) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            technique,
            style: TextStyle(
              color: Colors.black,
              fontSize: 14.sp,
            ),
          ),
        );
      }).toList(),
    );
  }
}