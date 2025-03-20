import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top profile header with curved bottom
          Container(
            height: 260.h,
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
                          image: const DecorationImage(
                            image: AssetImage('assets/images/profilepic.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Name with edit icon
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Mike Milian",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          InkWell(
                              onTap: (){
                                Get.toNamed('/editProfile');
                              },
                              child: SvgPicture.asset('assets/svg/edit.svg'))
                        ],
                      ),

                      SizedBox(height: 4.h),

                      // Email
                      Text(
                        "mike@gmail.com",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
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
                  icon: Icons.favorite_border,
                  title: "Favorite Therapist",
                  iconColor: const Color(0xFFB28D28),
                ),

                _buildMenuItem(
                  onTap: (){
                    Get.toNamed('/inviteFriendPage');
                  },
                  icon: Icons.people_outline,
                  title: "Invite Friends",
                  iconColor: const Color(0xFFB28D28),
                ),

                _buildMenuItem(
                  icon: Icons.support_agent_outlined,
                  title: "Support and FAQs",
                  iconColor: const Color(0xFFB28D28),
                ),

                _buildMenuItem(
                  onTap: (){Get.toNamed('/changePassword');},
                  icon: Icons.lock_outline,
                  title: "Change Password",
                  iconColor: const Color(0xFFB28D28),
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
                onTap: () {
                  // Handle logout
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
      decoration: BoxDecoration(
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
    path.quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.2,
        size.width,
        size.height * 0.6
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}