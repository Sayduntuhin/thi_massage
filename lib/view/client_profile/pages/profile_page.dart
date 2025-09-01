import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:thi_massage/api/api_service.dart';
import 'package:thi_massage/controller/auth_controller.dart';
import 'package:thi_massage/controller/user_type_controller.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';
import '../../../controller/edit_profile_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize or find the EditProfileController
    EditProfileController controller;
    try {
      controller = Get.find<EditProfileController>();
    } catch (e) {
      // If controller is not found, initialize it
      controller = Get.put(EditProfileController());
      AppLogger.debug("Initialized new EditProfileController in ProfilePage");
    }
    final AuthController authController = Get.find<AuthController>();
    final UserTypeController userTypeController = Get.find<UserTypeController>();

    return Scaffold(
      body: Obx(
            () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Container(
              height: 0.3.sh,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFB28D28),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40.r),
                  bottomRight: Radius.circular(40.r),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: CustomPaint(
                      size: Size(1.sw, 80.h),
                      painter: CurveShapePainter(),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 20.h),
                        Container(
                          width: 100.w,
                          height: 100.w,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: controller.imageUrl.value != null
                                ? CachedNetworkImage(
                              imageUrl: '${ApiService.baseUrl}${controller.imageUrl.value}',
                              fit: BoxFit.cover,
                              width: 100.w,
                              height: 100.w,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) {
                                AppLogger.error(
                                    "Failed to load image: ${ApiService.baseUrl}${controller.imageUrl.value}, Error: $error");
                                return Image.asset(
                                  'assets/images/empty_person.png',
                                  fit: BoxFit.cover,
                                  width: 100.w,
                                  height: 100.w,
                                );
                              },
                            )
                                : Image.asset(
                              'assets/images/empty_person.png',
                              fit: BoxFit.cover,
                              width: 100.w,
                              height: 100.w,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${controller.firstNameController.text} ${controller.lastNameController.text}'.trim(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            InkWell(
                              onTap: () {
                                Get.toNamed('/editProfile', arguments: {
                                  'user_id': controller.userId,
                                  'profile_id': controller.profileId,
                                });
                              },
                              child: SvgPicture.asset('assets/svg/edit.svg'),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          controller.emailController.text,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  _buildMenuItem(
                    onTap: () {
                      Get.toNamed('/favoriteTherapist');
                    },
                    icon: Icons.favorite_border,
                    title: "Favorite Therapist",
                    iconColor: primaryTextColor,
                  ),
                  _buildMenuItem(
                    onTap: () {
                      Get.toNamed('/inviteFriendPage');
                    },
                    icon: Icons.people_outline,
                    title: "Invite Friends",
                    iconColor: primaryTextColor,
                  ),
                  _buildMenuItem(
                    icon: Icons.support_agent_outlined,
                    title: "Support and FAQs",
                    iconColor: primaryTextColor,
                    onTap: () {
                      Get.toNamed('/supportPage');
                    },
                  ),
                  _buildMenuItem(
                    onTap: () {
                      Get.toNamed('/changePassword');
                    },
                    icon: Icons.lock_outline,
                    title: "Change Password",
                    iconColor: primaryTextColor,
                  ),
                  _buildMenuItem(
                    onTap: () {
                      Get.toNamed('/myRewards');
                    },
                    icon: Icons.card_giftcard,
                    title: "My Rewards",
                    iconColor: primaryTextColor,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              margin: EdgeInsets.all(16.w),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withAlpha(60),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await authController.logout();
                  },
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 15.w),
                        SvgPicture.asset('assets/svg/logout.svg'),
                        SizedBox(width: 8.w),
                        Text(
                          "Log out",
                          style: TextStyle(
                            color: Color(0xff67696F),
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 24.sp,
                ),
                SizedBox(width: 16.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CurveShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(20)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.5, size.height * 1.2, size.width, size.height * 0.6);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}