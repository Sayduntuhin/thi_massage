import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/controller/my_rewards_controller.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';

class MyRewardsScreen extends StatelessWidget {
  const MyRewardsScreen({super.key});

  Widget buildPointItem(Map<String, dynamic> item) {
    final bool isNegative = item['points'] < 0;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: tabColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['title'],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  fontSize: 16.sp,
                ),
              ),
              Text(
                item.containsKey('expired')
                    ? '${item['date']}  ${item['expired']}'
                    : item['date'],
                style: TextStyle(
                  fontSize: 12.sp,
                  color: subTitleColor,
                ),
              ),
            ],
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${isNegative ? '' : '+'}${item['points']}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
                color: isNegative ? Color(0xffF12929) : buttonTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPolicySection() {
    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: buttonTextColor, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                'Point Expiration Policy',
                style: TextStyle(
                  color: buttonTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Points expire 12 months after earning, your next batch of 100 points will expire on January 18, 2026',
            style: TextStyle(color: buttonTextColor, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialize MyRewardsController
    final controller = Get.put(MyRewardsController());
    final tabs = controller.pointsData.keys.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SecondaryAppBar(title: "My Rewards"),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        } else if (controller.errorMessage.value.isNotEmpty) {
          return Center(child: Text(controller.errorMessage.value));
        } else if (controller.pointsData.isEmpty) {
          return Center(child: Text('No data available'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff8F5E0A), Color(0xffB28D28)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Column(
                children: [
                  Text(
                    '🎁 My Balance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${controller.balancePoints.value} Points',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Worth \$${controller.dollarWorth.value.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.only(left: 15.w, bottom: 10.h),
              child: Text(
                "Point History",
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              color: tabColor,
              child: TabBar(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                indicatorSize: TabBarIndicatorSize.tab,
                controller: controller.tabController,
                indicator: BoxDecoration(
                  color: selectedTabsColor,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: notselectedtextColor,
                tabs: tabs.map((tab) => Tab(text: tab)).toList(),
                labelStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                unselectedLabelStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: controller.tabController,
                children: tabs.map((tab) {
                  final items = controller.pointsData[tab]!;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ...items.map(buildPointItem),
                          buildPolicySection(),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      }),
    );
  }
}