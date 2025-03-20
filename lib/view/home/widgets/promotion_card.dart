import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class PromotionCard extends StatelessWidget {
  final String image;
  final String discount;
  final String description;
  final VoidCallback onTap;

  const PromotionCard({
    super.key,
    required this.image,
    required this.discount,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 0.2.sh,
      child: Row(
        children: [
          // Left section - Text and button
          Expanded(
            flex: 5,
            child: Padding(
              padding:  EdgeInsets.only(top: 10.h),
              child: Container(
                height: 0.2.sh, // ✅ Left container height is shorter
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      spreadRadius: 0.5,
                      blurRadius: 10.0,
                    ),
                  ],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10.r),
                    bottomLeft: Radius.circular(10.r),)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Discount text with gold color
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: discount,
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFB28D28),
                              fontFamily: "PlayfairDisplay",
                            ),
                          ),
                          TextSpan(
                            text: " Discount",
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFB28D28),
                              fontFamily: "PlayfairDisplay",
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6.h),
                    // Description text
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.black54,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 6.h),

                    // Invite button
                    SizedBox(
                      width: 0.3.sw,
                      height: 0.025.sh,
                      child: ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8F5E0A),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Invite Now",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            fontFamily: "Urbanist",
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right section - Image and overlay
          Expanded(
            flex: 6,
            child: Container(
              height: 0.2.sh, // ✅ Right container is taller
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10.r),
                  bottomRight: Radius.circular(10.r),
                  topLeft: Radius.circular(10.r),
                ),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFB28D28), // Gold
                    Color(0xFF8F5E0A), // Brownish shade
                  ],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
              ),
              child: Stack(
                children: [
                  // Decorative curved lines
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CurvedLinesPainter(),
                    ),
                  ),
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20.r),
                      bottomRight: Radius.circular(20.r),
                    ),
                    child: Image.asset(
                      image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// Custom painter for the curved lines on the right section
class CurvedLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw several curved lines
    for (int i = 0; i < 5; i++) {
      final path = Path();
      final startY = size.height * 0.1 + (i * size.height * 0.2);

      path.moveTo(0, startY);
      path.quadraticBezierTo(
          size.width * 0.6,
          startY + (i % 2 == 0 ? 20 : -20),
          size.width,
          startY
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
