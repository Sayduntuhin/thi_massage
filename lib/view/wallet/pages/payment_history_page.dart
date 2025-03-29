import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_appbar.dart';

class PayoutHistoryPage extends StatelessWidget {
  const PayoutHistoryPage({super.key});

  final List<Map<String, dynamic>> payouts = const [
    {"amount": 100, "date": "25 Feb, 2025"},
    {"amount": 80, "date": "20 Feb, 2025"},
    {"amount": 120, "date": "15 Feb, 2025"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SecondaryAppBar(
        title: "Payout History",
        showBackButton: true,
      ),
      body: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        itemCount: payouts.length,
        separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final payout = payouts[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              "Funds transfer to AvidBank",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18.sp),
            ),
            subtitle: Text(
              payout["date"],
              style: TextStyle(fontSize: 16.sp, color: Colors.grey),
            ),
            trailing: Text(
              "\$${payout["amount"]}",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
          );
        },
      ),
    );
  }
}
