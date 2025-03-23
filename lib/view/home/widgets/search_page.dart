import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';
import '../../../themes/colors.dart';
import 'filter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecondaryAppBar(title: "Search"),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            // Search Bar with Filter Button
            Row(
              children: [
                SizedBox(
                  width: 0.72.sw,
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: const Color(0xff606060)),
                      hintText: "Search",
                      hintStyle: TextStyle(fontSize: 14.sp, color: Colors.black54),
                      filled: true,
                      fillColor: textFieldColor,
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
                      contentPadding: EdgeInsets.symmetric(vertical: 15.h),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: _openFilterBottomSheet, // Open Filter Bottom Sheet
                  child: Container(
                    width: 50.w,
                    height: 50.h,
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      color: primaryTextColor,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(Icons.tune, color: Colors.white, size: 18.sp),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Therapist List
            ListTile(
              leading: CircleAvatar(
                radius: 25.r,
                backgroundImage: AssetImage("assets/images/fevTherapist2.png"),
              ),
              title: Text(
                "Andrew John",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                "Swedish Massage Therapist",
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
