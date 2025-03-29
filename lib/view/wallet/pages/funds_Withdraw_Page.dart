import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_gradientButton.dart';

class FundsWithdrawPage extends StatefulWidget {
  final String selectedBank;

  const FundsWithdrawPage({super.key, required this.selectedBank});

  @override
  State<FundsWithdrawPage> createState() => _FundsWithdrawPageState();
}

class _FundsWithdrawPageState extends State<FundsWithdrawPage> {
  final TextEditingController _amountController = TextEditingController(text: '133.5');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SecondaryAppBar(
        title: "Funds Withdraw",
        showBackButton: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),

            // Bank Selector
            Text("Bank", style: TextStyle(fontSize: 14.sp, color: Colors.black54)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(widget.selectedBank, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500)),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to change bank if needed
              },
            ),
            Divider(),

            SizedBox(height: 20.h),

            // Withdrawal Amount (with device keyboard)
            Text("Withdrawal Amount", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 8.h),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.bold, color: primaryTextColor),
              decoration: InputDecoration(
                prefixText: "\$ ",
                border: InputBorder.none,
              ),
            ),
            Divider(),

            SizedBox(height: 20.h),

            // Charges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Charges", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4.h),
                    Text("No charges", style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
                  ],
                ),
                Text("\$0", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 30.h),

            // Transfer Button
            CustomGradientButton(
              text: "Transfer",
              onPressed: () {
                debugPrint("Transferring \$${_amountController.text} to ${widget.selectedBank}");
                Get.toNamed('/paymentHistoryPage'); // Replace with confirmation or API call
              },
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }
}
