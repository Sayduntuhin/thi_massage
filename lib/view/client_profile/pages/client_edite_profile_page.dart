import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
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

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool isEditing = false;
  File? _image;
  String? _imageUrl;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  // Store initial values to detect changes
  String? initialFirstName;
  String? initialLastName;
  String? initialPhone;
  String? initialDob;
  String? initialImageUrl;

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

    AppLogger.debug("EditProfilePage: userId=$userId, profileId=$profileId");

    if (userId == null) {
      CustomSnackBar.show(context, "User ID missing. Please log in again.", type: ToastificationType.error);
      Get.offAllNamed('/login');
      return;
    }

    fetchProfileData();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    contactController.dispose();
    dobController.dispose();
    super.dispose();
  }

  Future<void> fetchProfileData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.getClientProfile();
      AppLogger.debug("Profile fetched: $response");

      setState(() {
        final fullName = response['full_name'] ?? '';
        final nameParts = fullName.trim().split(' ');
        firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
        lastNameController.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        emailController.text = response['email'] ?? '';
        contactController.text = response['phone'] ?? '';
        dobController.text = response['date_of_birth'] ?? '';

        // Store initial values
        initialFirstName = firstNameController.text;
        initialLastName = lastNameController.text;
        initialPhone = contactController.text;
        initialDob = dobController.text;
        initialImageUrl = _imageUrl;

        _imageUrl = response['image'] != '/api/media/documents/default.jpg' ? response['image'] : null;
        profileId = response['id'];
        userId = response['user'];
        AppLogger.debug("Image URL set: ${ApiService.baseUrl}$_imageUrl");
      });
    } catch (e) {
      String errorMessage = "Something went wrong. Please try again.";
      if (e is NotFoundException) {
        errorMessage = "Profile not found. Please set up your Profile.";
        CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
        Get.toNamed('/profileSetup', arguments: {
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
      AppLogger.error("Fetch Profile error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

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

  Future<void> _saveProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      final apiService = ApiService();

      // Collect edited fields
      final Map<String, dynamic> fields = {};

      // Check if name has changed
      final currentFullName = "${firstNameController.text.trim()} ${lastNameController.text.trim()}".trim();
      final initialFullName = "${initialFirstName ?? ''} ${initialLastName ?? ''}".trim();
      if (currentFullName != initialFullName && currentFullName.isNotEmpty) {
        fields['full_name'] = currentFullName;
      }

      // Check if phone has changed
      if (contactController.text.trim() != initialPhone && contactController.text.trim().isNotEmpty) {
        fields['phone'] = contactController.text.trim();
      }

      // Check if DOB has changed
      if (dobController.text.trim() != initialDob && dobController.text.trim().isNotEmpty) {
        fields['date_of_birth'] = dobController.text.trim();
      }

      // Log fields to be sent
      AppLogger.debug("Fields to update: $fields, Image: ${_image != null}");

      // Only send request if there are changes
      if (fields.isNotEmpty || _image != null) {
        final response = await apiService.updateClientProfile(fields, image: _image);
        AppLogger.info("Profile updated successfully: $response");
        CustomSnackBar.show(context, response['message'] ?? "Profile updated successfully!", type: ToastificationType.success);
      } else {
        AppLogger.info("No changes to update");
        CustomSnackBar.show(context, "No changes made", type: ToastificationType.info);
      }

      setState(() {
        isEditing = false; // Exit edit mode
      });
      await fetchProfileData(); // Refresh client_profile data
    } catch (e) {
      String errorMessage = "Failed to update client_profile. Please try again.";
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecondaryAppBar(title: "Edit Profile"),
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
                        child: _image != null
                            ? Image.file(
                          _image!,
                          fit: BoxFit.cover,
                          width: 100.r,
                          height: 100.r,
                        )
                            : CachedNetworkImage(
                          imageUrl: '${ApiService.baseUrl}$_imageUrl',
                          fit: BoxFit.cover,
                          width: 100.r,
                          height: 100.r,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) {
                            AppLogger.error("Failed to load image: ${ApiService.baseUrl}$_imageUrl, Error: $error");
                            return Image.asset(
                              "assets/images/empty_person.png",
                              fit: BoxFit.cover,
                              width: 100.r,
                              height: 100.r,
                            );
                          },
                        )
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
              _buildSectionTitle("Profile"),
              Divider(color: Color(0xffD0D0D0)),
              SizedBox(height: 8.h),
              _buildProfileField("First name", firstNameController, isEditing),
              _buildProfileField("Last name", lastNameController, isEditing),
              _buildProfileField("Email", emailController, false), // Email always non-editable
              _buildProfileField("Contact Number", contactController, isEditing),
              _buildProfileField("Date of Birth", dobController, isEditing),
              if (isEditing) ...[
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _saveProfile,
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
}