import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thi_massage/themes/colors.dart';
import '../widgets/category_item.dart';
import '../widgets/nearby_therapist_card.dart';
import '../widgets/promotion_card.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 50.h),

            // Profile Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 25.r,
                  backgroundImage: AssetImage('assets/images/user_profile.jpg'),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hello Mike", style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: primaryTextColor)),
                    Text("@ 4701 Hamill Avenue, San Diego", style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
                  ],
                ),
                Icon(Icons.notifications, color: Colors.brown),
              ],
            ),
            SizedBox(height: 20.h),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: "Search",
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: 20.h),

            // Categories
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Categories", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                Text("See all", style: TextStyle(fontSize: 14.sp, color: Colors.brown)),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CategoryItem(title: "Thai Massage", image: "assets/images/thai_massage.png"),
                CategoryItem(title: "Swedish Massage", image: "assets/images/swedish_massage.png"),
                CategoryItem(title: "Deep Tissue", image: "assets/images/deep_tissue.png"),
              ],
            ),
            SizedBox(height: 20.h),

            // Nearby Therapists
            Text("Nearby Therapists", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 10.h),
            NearbyTherapistCard(
              image: "assets/images/therapist.png",
              name: "Mical Martinez",
              rating: "4.2",
              bookings: "102",
              onTap: () => debugPrint("Book Now Clicked"),
            ),
            SizedBox(height: 20.h),

            // Promotions
            Text("Promotions", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 10.h),
            PromotionCard(image: "assets/images/promotion.png", discount: "30%", description: "Get 30% OFF", onTap: () {}),
          ],
        ),
      ),
    );
  }
}
