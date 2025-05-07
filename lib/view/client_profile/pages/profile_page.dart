import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:thi_massage/api/api_service.dart';
import 'package:thi_massage/controller/user_controller.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';
import 'package:thi_massage/view/widgets/custom_snackbar.dart';
import 'package:toastification/toastification.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? fullName;
  String? email;
  String? imageUrl;
  int? userId;
  int? profileId;
  bool isLoading = false;

  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initializeUserId();
    fetchProfileData();
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

    AppLogger.debug("ProfilePage: userId=$userId, profileId=$profileId");

    if (userId == null) {
      CustomSnackBar.show(context, "User ID missing. Please log in again.", type: ToastificationType.error);
      Get.offAllNamed('/login');
      return;
    }

    fetchProfileData();
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
        fullName = response['full_name'] ?? 'User';
        email = response['email'] ?? '';
        imageUrl = response['image'] != '/therapist/media/documents/default.jpg' ? response['image'] : null;
        profileId = response['id'];
        userId = response['user'];
        AppLogger.debug("Image URL set: ${ApiService.baseUrl}$imageUrl");
      });
    } catch (e) {
      String errorMessage = "Something went wrong. Please try again.";
      if (e is NotFoundException) {
        errorMessage = "Profile not found. Please set up your Profile.";
        CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
        Get.toNamed('/profileSetup', arguments: {
          'user_id': userId,
          'profile_id': profileId,
          'source': 'profile_page',
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

  @override
  Widget build(BuildContext context) {
    final UserTypeController userTypeController = Get.find<UserTypeController>();

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Top profile header with curved bottom
          Container(
            height: 0.35.sh,
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
                // Decorative curved shape
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: CustomPaint(
                    size: Size(1.sw, 80.h),
                    painter: CurveShapePainter(),
                  ),
                ),

                // Profile content - centered
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20.h), // Push content below status bar

                      // Profile image in circle
                      Container(
                        width: 100.w,
                        height: 100.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: imageUrl != null
                                ? NetworkImage('${ApiService.baseUrl}$imageUrl')
                                : const AssetImage('assets/images/empty_person.png') as ImageProvider,
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {
                              AppLogger.error("Failed to load image: ${ApiService.baseUrl}$imageUrl, Error: $exception");
                              setState(() {
                                imageUrl = null; // Clear invalid URL
                              });
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Name with edit icon
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fullName ?? 'User',
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
                                'user_id': userId,
                                'profile_id': profileId,
                              });
                            },
                            child: SvgPicture.asset('assets/svg/edit.svg'),
                          ),
                        ],
                      ),

                      SizedBox(height: 4.h),

                      // Email
                      Text(
                        email ?? '',
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

          // Menu items
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
              ],
            ),
          ),

          const Spacer(),

          // Logout button
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
                  await _storage.delete(key: 'user_id');
                  await _storage.delete(key: 'access_token');
                  Get.offAllNamed('/login');
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
    );
  }

  // Helper method to build menu items
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
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

// Custom painter for the curved decoration at the top
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