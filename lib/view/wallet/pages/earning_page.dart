import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/view/widgets/custom_gradientButton.dart';
import '../../../themes/colors.dart';
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
                      border: !isSelected ? Border.all(color: Colors.white, width: 1.5) : null, // White border for unselected
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: isSelected ? 4.r : 2.r, // Shadow for both states, smaller for unselected
                          offset: const Offset(0, 2), // Optional: Add offset for better shadow visibility
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

            /// Total earnings and sessions
            Center(
              child:/// Total earnings and sessions (Formatted as per your image)
              Column(
                children: [
                  Text(
                    '1 Mar, 2025',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_ios_sharp, size: 40.sp, color: primaryButtonColor),
                      SizedBox(width: 0.1.sw),
                      Text(
                        '\$${current['amount']}',
                        style: TextStyle(
                          fontSize: 50.sp,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      SizedBox(width: 0.1.sw),
                      Icon(Icons.arrow_forward_ios, size: 40.sp, color: primaryButtonColor),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// Sessions
                      Column(
                        children: [
                          Text("${current['sessions']}",
                              style: TextStyle(
                                fontSize: 25.sp,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              )),
                          SizedBox(height: 2.h),
                          Text("Sessions", style: TextStyle(fontSize: 18.sp, color: Colors.black54)),
                        ],
                      ),
                      SizedBox(width: 40.w),

                      /// Duration
                      Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("${current['duration']}",
                                  style: TextStyle(
                                    fontSize: 25.sp,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTextColor,
                                  )),
                              SizedBox(width: 2.w),
                              Text("min", style: TextStyle(fontSize: 12.sp, color: primaryTextColor,fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text("Duration", style: TextStyle(fontSize: 18.sp, color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

            ),
            SizedBox(height: 30.h),

            /// Earnings Breakdown
            Text("Earned", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 6.h),
            _earningRow("Massage Charges only", "\$${current['earned']}"),
            SizedBox(height: 16.h),
            Row(
              children: [
                Text("Deducted", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                SizedBox(width: 4.w),
                Text("(11% Commission)", style: TextStyle(fontSize: 11.sp, color: Colors.black)),
              ],
            ),
            SizedBox(height: 6.h),
            _earningRow("Massage Charges only", "\$${current['deducted']}", subText: "(11% Commission)"),
            SizedBox(height: 24.h),

            /// Payout history
            ListTile(
              contentPadding: EdgeInsets.zero,
              title:Text("Payout History", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),

              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to payout history
              },
            ),

            const Spacer(),

            /// Withdraw Button
            Padding(
              padding:  EdgeInsets.symmetric(horizontal: 20.w),
              child: CustomGradientButton(
                text: "Withdraw Funds",
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                    ),
                    backgroundColor: Colors.white,
                    builder: (_) => _buildPayoutBottomSheet(),
                  );
                },

              ),
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
            Text(title, style: TextStyle(fontSize: 14.sp, color: Colors.black54)),

          ],
        ),
        Text(amount, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
      ],
    );
  }
  Widget _buildPayoutBottomSheet() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Select Payout",
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20.h),

          /// Direct Bank
          ListTile(
            leading: Image.asset("assets/images/bank.png", width: 30.w), // Make sure this asset exists
            title: Text("Direct Bank", style: TextStyle(fontSize: 14.sp)),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Handle direct bank payout
            },
          ),
          Divider(),

          /// PayPal
          ListTile(
            leading: Image.asset("assets/images/pay_pal.png", width: 40.w), // Make sure this asset exists
            title: Text("PayPal", style: TextStyle(fontSize: 14.sp)),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Handle PayPal payout
            },
          ),
          Divider(),

          /// Add New
          ListTile(
            leading: Icon(Icons.add_circle_outline, color: primaryTextColor),
            title: Text(
              "Add new payout",
              style: TextStyle(fontSize: 14.sp, color: primaryTextColor, fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Get.toNamed('/newPayoutPage');
            },
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

}
