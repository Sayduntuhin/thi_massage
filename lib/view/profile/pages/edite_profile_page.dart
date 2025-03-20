import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool isEditing = false; // Toggle between View & Edit Mode

  final TextEditingController firstNameController = TextEditingController(text: "Mike");
  final TextEditingController lastNameController = TextEditingController(text: "Milan");
  final TextEditingController emailController = TextEditingController(text: "mike@gmail.com");
  final TextEditingController contactController = TextEditingController(text: "+1 000 1234 567");
  final TextEditingController dobController = TextEditingController(text: "31 Oct, 1999");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecondaryAppBar(title: "Edit Profile"),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image with Gradient Background
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF8B5A2B), // Brown color
                          Color(0xFFD2B48C), // Lighter brown
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50.r,
                      backgroundColor: Colors.transparent,
                      backgroundImage: AssetImage("assets/images/profilepic.png"),
                    ),
                  ),
                    GestureDetector(
                      onTap: () {
                        debugPrint("Change Profile Picture");
                      },
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

              // Profile Info
              _buildSectionTitle("Profile"),
              Divider(color: Color(0xffD0D0D0)),
              SizedBox(height: 8.h),
              _buildProfileField("First name", firstNameController, isEditing),
              _buildProfileField("Last name", lastNameController, isEditing),
              _buildProfileField("Email", emailController, isEditing),
              _buildProfileField("Contact Number", contactController, isEditing),
              _buildProfileField("Date of Birth", dobController, isEditing),
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
              isEditing ? "assets/svg/edit.svg": "assets/svg/edit.svg",
              colorFilter: const ColorFilter.mode(Color(0xFFB28D28), BlendMode.srcIn),
            ),
            onPressed: () {
              setState(() {
                isEditing = !isEditing; // Toggle Editing Mode
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
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Color(0xff383535),
            ),
          ),

          // Input Field or Right-Aligned Text
          SizedBox(
            width: 0.35.sw,
            child: isEditable
                ? TextField(
              controller: controller,
              enabled: isEditable,
              style: TextStyle(fontSize: 14.sp, color: Colors.black),
              textAlign: TextAlign.right, // ✅ Right-align text
              decoration: InputDecoration(
                filled: true,
                fillColor: isEditable ? Color(0xFFE8ECEF) : Colors.transparent, // Grey background in edit mode
                border: isEditable
                    ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.black12, width: 1),
                )
                    : InputBorder.none, // No border in view mode
                enabledBorder: isEditable
                    ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.black12, width: 1),
                )
                    : InputBorder.none,
                focusedBorder: isEditable
                    ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.black12, width: 1),
                )
                    : InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
              ),
            )
                : Align(
              alignment: Alignment.centerRight, // ✅ Align Text to Right in View Mode
              child: Text(
                controller.text,
                style: TextStyle(fontSize: 16.sp, color: Colors.black),
                textAlign: TextAlign.right, // ✅ Right-align text
              ),
            ),
          ),
        ],
      ),
    );
  }
}