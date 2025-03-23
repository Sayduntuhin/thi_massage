import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_appbar.dart';

class FavoriteTherapistPage extends StatelessWidget {
  const FavoriteTherapistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: SecondaryAppBar(title: "Favorite Therapist"),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 0.05.sh),
            // Search Bar
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xff606060)),
                hintText: "Search",
                hintStyle: TextStyle(fontSize: 14.sp, color: Colors.black54),
                filled: true,
                fillColor: textFieldColor, // Background color
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  borderSide: BorderSide(
                      color: borderColor.withAlpha(40), width: 1.5.w),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  borderSide: BorderSide(
                      color: borderColor.withAlpha(40), width: 1.5.w),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  borderSide:
                      BorderSide(color: borderColor.withAlpha(40), width: 2.w),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 15.h),
              ),
            ),

            SizedBox(height: 20.h),

            // Therapist List
            Expanded(
              child: ListView(
                children: [
                  _buildTherapistItem(
                    image: "assets/images/fevTherapist1.png",
                    name: "Mical Martinez",
                    specialty: "Thai Massage Therapist",
                    svgPath: "assets/svg/male.svg",
                    genderColor: Colors.blue,
                  ),
                  _buildTherapistItem(
                    image: "assets/images/fevTherapist2.png",
                    name: "Andrew John",
                    specialty: "Swedish Massage Therapist",
                    svgPath: "assets/svg/male.svg",
                    genderColor: Colors.blue,
                  ),
                  _buildTherapistItem(
                    image: "assets/images/fevTherapist3.png",
                    name: "Tina Bella",
                    specialty: "Thai Massage Therapist",
                    svgPath: "assets/svg/female.svg",
                    genderColor: Colors.pink,
                  ),
                  _buildTherapistItem(
                    image: "assets/images/fevTherapist4.png",
                    name: "Natasha",
                    specialty: "Prenatal Massage Therapist",
                    svgPath: "assets/svg/female.svg",
                    genderColor: Colors.pink,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Therapist Item Widget
  Widget _buildTherapistItem({
    required String image,
    required String name,
    required String specialty,
    required String svgPath,
    required Color genderColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          // Profile Image
        Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // Profile Image
          CircleAvatar(
            radius: 25.r,
            backgroundImage: AssetImage(image),
          ),

          // Favorite (Heart) Icon
          Positioned(

            bottom: -4,
            right: -4,
            child: Container(
              width: 18.w,
              height: 18.h,
              decoration: BoxDecoration(
                color: Colors.white, // Background
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4.r,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.favorite_border,
                  color: Color(0xffBD3D44),
                  size: 14.sp,
                ),
              ),
            ),
          ),
        ],
      ),
          SizedBox(width: 10.w),

          // Therapist Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    SvgPicture.asset(svgPath,width: 16.w,height: 16.h,),

                  ],
                ),
                Text(
                  specialty,
                  style: TextStyle(fontSize: 12.sp, color: secounderyTextColor),
                ),
              ],
            ),
          ),

          // Book Appointment Button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: boxColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: secounderyBorderColor.withAlpha(60)),
            ),
            child: Text(
              "Book appointment",
              style: TextStyle(fontSize: 10.sp, color: primaryTextColor),
            ),
          ),
        ],
      ),
    );
  }
}
