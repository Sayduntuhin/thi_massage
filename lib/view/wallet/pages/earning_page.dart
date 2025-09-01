import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:thi_massage/view/widgets/custom_appbar.dart';
import 'package:thi_massage/view/widgets/custom_gradientButton.dart';
import 'package:thi_massage/api/api_service.dart';
import '../../../themes/colors.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  String selectedFilter = 'Day'; // Track selected filter
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> earningsList = [];
  int currentIndex = 0; // Track the current index in earningsList

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchEarningsData();
  }

  Future<void> _fetchEarningsData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await _apiService.getTherapistEarnings(selectedFilter.toLowerCase());
      setState(() {
        earningsList = response;
        // Set currentIndex to the latest available date (e.g., "02 Aug 2025" for Day)
        currentIndex = earningsList.indexWhere((entry) => entry['label'] == _getLatestLabel()) >= 0
            ? earningsList.indexWhere((entry) => entry['label'] == _getLatestLabel())
            : 0;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load earnings: $e';
        isLoading = false;
      });
    }
  }

  String _getLatestLabel() {
    final now = DateTime.now();
    if (selectedFilter == 'Day') {
      return DateFormat('dd MMM yyyy').format(now); // "02 Aug 2025"
    } else if (selectedFilter == 'Week') {
      final start = now.subtract(Duration(days: now.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM').format(end)}'; // "28 Jul - 04 Aug"
    } else {
      return DateFormat('MMMM yyyy').format(now); // "August 2025"
    }
  }

  void _goToPrevious() {
    setState(() {
      currentIndex = currentIndex < earningsList.length - 1 ? currentIndex + 1 : 0;
      // If at the last index, reset to the current date's index if available
      if (currentIndex == earningsList.length - 1) {
        final latestIndex = earningsList.indexWhere((entry) => entry['label'] == _getLatestLabel());
        if (latestIndex >= 0) {
          currentIndex = latestIndex;
        }
      }
    });
  }

  void _goToNext() {
    setState(() {
      currentIndex = currentIndex > 0 ? currentIndex - 1 : earningsList.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentEarnings = earningsList.isNotEmpty ? earningsList[currentIndex] : {
      'label': _getLatestLabel(),
      'earned': 0.0,
      'deducted': 0.0,
      'net': 0.0,
      'sessions': 0,
      'duration_minutes': 0,
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SecondaryAppBar(title: "Earning", showBackButton: false),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(child: Text(errorMessage!, style: TextStyle(fontSize: 16.sp, color: Colors.red)))
            : Column(
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
                      currentIndex = 0; // Reset to first entry on filter change
                      _fetchEarningsData();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryTextColor : Colors.white,
                      borderRadius: BorderRadius.circular(15.r),
                      border: !isSelected ? Border.all(color: Colors.white, width: 1.5) : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: isSelected ? 4.r : 2.r,
                          offset: const Offset(0, 2),
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
            Center(
              child: Column(
                children: [
                  Text(
                    currentEarnings['label'],
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_sharp, size: 40.sp, color: primaryButtonColor),
                        onPressed: earningsList.isNotEmpty ? _goToPrevious : null,
                      ),
                      SizedBox(width: 0.1.sw),
                      Text(
                        '\$${currentEarnings['net']?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(
                          fontSize: 45.sp,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      SizedBox(width: 0.1.sw),
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios, size: 40.sp, color: primaryButtonColor),
                        onPressed: earningsList.isNotEmpty ? _goToNext : null,
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// Sessions
                      Column(
                        children: [
                          Text(
                            "${currentEarnings['sessions'] ?? 0}",
                            style: TextStyle(
                              fontSize: 25.sp,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
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
                              Text(
                                "${currentEarnings['duration_minutes'] ?? 0}",
                                style: TextStyle(
                                  fontSize: 25.sp,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Text("min", style: TextStyle(fontSize: 12.sp, color: primaryTextColor, fontWeight: FontWeight.bold)),
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
            _earningRow("Massage Charges only", "\$${currentEarnings['earned']?.toStringAsFixed(2) ?? '0.00'}"),
            SizedBox(height: 16.h),
            Row(
              children: [
                Text("Deducted", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                SizedBox(width: 4.w),
                Text("(11% Commission)", style: TextStyle(fontSize: 11.sp, color: Colors.black)),
              ],
            ),
            SizedBox(height: 6.h),
            _earningRow("Massage Charges only", "\$${currentEarnings['deducted']?.toStringAsFixed(2) ?? '0.00'}", subText: "(11% Commission)"),
            SizedBox(height: 24.h),

            /// Payout history
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("Payout History", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to payout history
              },
            ),

            const Spacer(),

            /// Withdraw Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
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
            if (subText != null) Text(subText, style: TextStyle(fontSize: 11.sp, color: Colors.black54)),
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
            leading: Image.asset("assets/images/bank.png", width: 30.w),
            title: Text("Direct Bank", style: TextStyle(fontSize: 14.sp)),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // Handle direct bank payout
            },
          ),
          Divider(),

          /// PayPal
          ListTile(
            leading: Image.asset("assets/images/pay_pal.png", width: 40.w),
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
              style: TextStyle(fontSize: 14.sp,
                  color: primaryTextColor,
                  fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Get.toNamed('/newPayoutPage');
            },
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }}