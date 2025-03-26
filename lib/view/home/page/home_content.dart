import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';
import '../../../themes/colors.dart';
import '../widgets/category_item.dart';
import '../widgets/nearby_therapist_card.dart';
import '../widgets/notificaton_bell.dart';
import '../widgets/promotion_card.dart';

class HomeContent extends StatelessWidget {
   HomeContent({super.key});
  final List<Map<String, String>> categories = [
    {"title": "Thai Massage", "image": "assets/images/thi_massage.png"},
    {"title": "Swedish Massage", "image": "assets/images/swedish.png"},
    {"title": "Deep Tissue", "image": "assets/images/deep.png"},
    {"title": "Hot Stone", "image": "assets/images/thi_massage.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 25.h),
            CustomAppBar(showBackButton: false),
            SizedBox(height: 10.h),
            // Profile Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 35.r,
                  backgroundImage: AssetImage('assets/images/profilepic.png'),
                ),
                NotificationBell(
                  notificationCount: 1, // Show notification dot
                  svgAssetPath: 'assets/svg/notificationIcon.svg',
                  navigateTo: "/notificationsPage",// Pass your SVG file path
                ),

              ],
            ),
            Text(
              "Hello Mike",
              style: TextStyle(
                  fontSize: 42.sp,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                  fontFamily: "Urbanist"
              ),
            ),
            Row(
              children: [
                Icon(Icons.location_on, color: Color(0xffA0A0A0), size: 18.sp),
                Text(
                  "4761 Hamill Avenue, San Diego",
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Color(0xffA0A0A0),
                      fontFamily: "Urbanist"
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Search Bar
            GestureDetector(
            onTap: () {
              Get.toNamed("/searchPage");
            },
            child: AbsorbPointer( // Prevents user input in TextField
              child: TextField(
                readOnly: true, // Ensure it's read-only
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: const Color(0xff606060)),
                  hintText: "Search",
                  hintStyle: TextStyle(fontSize: 14.sp, color: Colors.black54),
                  filled: true,
                  fillColor: textFieldColor, // Background color
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    borderSide: BorderSide(color: borderColor.withAlpha(40), width: 1.5.w),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    borderSide: BorderSide(color: borderColor.withAlpha(40), width: 1.5.w),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    borderSide: BorderSide(color: borderColor.withAlpha(40), width: 2.w),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                ),
              ),
            ),
          ),
            SizedBox(height: 20.h),

            // Categories
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Categories", style: TextStyle(color:Colors.black,fontSize: 18.sp, fontWeight: FontWeight.w500,fontFamily: "Urbanist")),
                Text("see all", style: TextStyle(fontSize: 14.sp, color: primaryTextColor)),
              ],
            ),
            SizedBox(height: 10.h),
            SizedBox(
            height: 0.18.sh,
            child: ListView.builder(
              scrollDirection: Axis.horizontal, // ✅ Enable horizontal scrolling
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: CategoryItem(
                    title: categories[index]["title"]!,
                    image: categories[index]["image"]!,
                  ),
                );
              },
            ),
          ),



            // Nearby Therapists
            Text("Nearby Therapists", style: TextStyle(color:Colors.black,fontSize: 18.sp, fontWeight: FontWeight.w500,fontFamily: "Urbanist")),
            SizedBox(height: 10.h),
            TherapistCarousel(),
            SizedBox(height: 20.h),

            // Promotions
            Text("Promotions", style: TextStyle(color:Colors.black,fontSize: 18.sp, fontWeight: FontWeight.w500,fontFamily: "Urbanist")),
            SizedBox(height: 10.h),
            PromotionCard(image: "assets/images/promotions.png", discount: "30%", description: "Invite Friend and get 30% OFFon your next booking ", onTap: () {}),
            SizedBox(height: 10.h),

          ],
        ),
      ),
    );
  }
}
