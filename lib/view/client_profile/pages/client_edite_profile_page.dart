import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:thi_massage/api/api_service.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';
import '../../../controller/edit_profile_controller.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final EditProfileController controller = Get.put(EditProfileController());

    return Scaffold(
      appBar: SecondaryAppBar(title: "Edit Profile"),
      body: Obx(
            () => controller.isLoading.value
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
                          child: controller.image.value != null
                              ? Image.file(
                            controller.image.value!,
                            fit: BoxFit.cover,
                            width: 100.r,
                            height: 100.r,
                          )
                              : CachedNetworkImage(
                            imageUrl: '${ApiService.baseUrl}${controller.imageUrl.value}',
                            fit: BoxFit.cover,
                            width: 100.r,
                            height: 100.r,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) {
                              AppLogger.error("Failed to load image: ${ApiService.baseUrl}${controller.imageUrl.value}, Error: $error");
                              return Image.asset(
                                "assets/images/empty_person.png",
                                fit: BoxFit.cover,
                                width: 100.r,
                                height: 100.r,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    if (controller.isEditing.value)
                      GestureDetector(
                        onTap: controller.pickImage,
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
                _buildSectionTitle(controller),
                Divider(color: Color(0xffD0D0D0)),
                SizedBox(height: 8.h),
                _buildProfileField("First name", controller.firstNameController, controller.isEditing.value),
                _buildProfileField("Last name", controller.lastNameController, controller.isEditing.value),
                _buildProfileField("Email", controller.emailController, false), // Email always non-editable
                _buildProfileField("Contact Number", controller.contactController, controller.isEditing.value),
                _buildProfileField("Date of Birth", controller.dobController, controller.isEditing.value),
                if (controller.isEditing.value) ...[
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value ? null : controller.saveProfile,
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
      ),
    );
  }

  Widget _buildSectionTitle(EditProfileController controller) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Profile",
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          IconButton(
            icon: SvgPicture.asset(
              controller.isEditing.value ? "assets/svg/save.svg" : "assets/svg/edit.svg",
              colorFilter: const ColorFilter.mode(Color(0xFFB28D28), BlendMode.srcIn),
            ),
            onPressed: controller.toggleEditMode,
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
          isEditable
              ? Expanded(
            child: TextField(
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
        ],
      ),
    );
  }
}