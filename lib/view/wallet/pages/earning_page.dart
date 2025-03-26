import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_button.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  String selectedFilter = 'Day'; // Track selected filter

  // Dummy data for display
  final earningsData = {
    'Day': {'amount': 133.5, 'sessions': 2, 'duration': 90, 'earned': 150.0, 'deducted': 16.5},
    'Week': {'amount': 460.0, 'sessions': 8, 'duration': 360, 'earned': 520.0, 'deducted': 60.0},
    'Month': {'amount': 1820.0, 'sessions': 30, 'duration': 1350, 'earned': 2000.0, 'deducted': 180.0},
  };

  @override
  Widget build(BuildContext context) {
    final current = earningsData[selectedFilter]!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Earnings',
          style: TextStyle(
            fontSize: 18.sp,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Toggle buttons (Day, Week, Month)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Day', 'Week', 'Month'].map((label) {
                final isSelected = selectedFilter == label;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedFilter = label;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryTextColor : Colors.white,
                      borderRadius: BorderRadius.circular(15.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: isSelected ? 4.r : 0,
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : primaryTextColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16.h),

            /// Date + Arrows
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chevron_left, size: 26.sp),
                Text(
                  '1 Mar, 2025',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.chevron_right, size: 26.sp),
              ],
            ),
            SizedBox(height: 20.h),

            /// Total earnings and sessions
            Center(
              child: Column(
                children: [
                  Text(
                    '\$${current['amount']}',
                    style: TextStyle(
                      fontSize: 34.sp,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("${current['sessions']}", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                      SizedBox(width: 4.w),
                      Text("Sessions", style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
                      SizedBox(width: 20.w),
                      Text("${current['duration']}", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                      SizedBox(width: 4.w),
                      Text("min", style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
                      SizedBox(width: 4.w),
                      Text("Duration", style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
                    ],
                  )
                ],
              ),
            ),
            SizedBox(height: 30.h),

            /// Earnings Breakdown
            Text("Earned", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 6.h),
            _earningRow("Massage Charges only", "\$${current['earned']}"),
            SizedBox(height: 16.h),
            Text("Deducted", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 6.h),
            _earningRow("Massage Charges only", "\$${current['deducted']}", subText: "(11% Commission)"),
            SizedBox(height: 24.h),

            /// Payout history
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("Payout History", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to payout history
              },
            ),

            const Spacer(),

            /// Withdraw Button
            ThaiMassageButton(
              text: "Withdraw Funds",
              isPrimary: true,
              onPressed: () {
                // Trigger withdrawal
              },
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _earningRow(String title, String amount, {String? subText}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 13.sp, color: Colors.black87)),
            if (subText != null)
              Text(subText, style: TextStyle(fontSize: 11.sp, color: Colors.black45)),
          ],
        ),
        Text(amount, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
