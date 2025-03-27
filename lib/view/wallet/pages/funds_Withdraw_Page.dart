import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_gradientButton.dart';

class FundsWithdrawPage extends StatefulWidget {
  final String selectedBank;

  const FundsWithdrawPage({super.key, required this.selectedBank});

  @override
  State<FundsWithdrawPage> createState() => _FundsWithdrawPageState();
}

class _FundsWithdrawPageState extends State<FundsWithdrawPage> {
  final double availableAmount = 133.5;
  final TextEditingController _amountController = TextEditingController(text: '133.5');

  @override
  Widget build(BuildContext context) {
    // Optionally retrieve from Get.arguments if needed
    // final String selectedBank = Get.arguments['selectedBank'] ?? widget.selectedBank;

    return Scaffold(
      resizeToAvoidBottomInset: false, // Keyboard doesn't resize layout
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Funds Withdraw",
          style: TextStyle(fontSize: 18.sp, color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
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
                // Navigate to change bank if needed (e.g., back to NewPayoutPage)
              },
            ),
            Divider(),

            SizedBox(height: 10.h),
            // Withdrawal Amount
            Text("Withdrawal Amount", style: TextStyle(fontSize: 14.sp, color: Colors.black54)),
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "\$${_amountController.text}",
                  style: TextStyle(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
              ],
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
                    Text("Charges", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4.h),
                    Text("No charges", style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                  ],
                ),
                Text("\$0", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              ],
            ),
            SizedBox(height: 30.h),

            // Transfer Button
            CustomGradientButton(
              text: "Transfer",
              onPressed: () {
                // Handle transfer logic here (e.g., API call)
                debugPrint("Transferring \$${_amountController.text} to ${widget.selectedBank}");
                Get.back(); // Example: Go back after transfer
              },
            ),
          ],
        ),
      ),

      // Custom keyboard style
      bottomSheet: Container(
        color: Colors.grey.shade200,
        padding: EdgeInsets.only(bottom: 10.h),
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: 12,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (context, index) {
            if (index == 9) return const SizedBox(); // Blank space
            if (index == 10) {
              return _buildKeyboardButton("0");
            } else if (index == 11) {
              return _buildKeyboardButton("<", isBackspace: true);
            }
            return _buildKeyboardButton("${index + 1}");
          },
        ),
      ),
    );
  }

  Widget _buildKeyboardButton(String label, {bool isBackspace = false}) {
    return GestureDetector(
      onTap: () {
        if (isBackspace) {
          if (_amountController.text.isNotEmpty) {
            setState(() {
              _amountController.text = _amountController.text.substring(0, _amountController.text.length - 1);
            });
          }
        } else {
          setState(() {
            _amountController.text += label;
          });
        }
      },
      child: Center(
        child: isBackspace
            ? Icon(Icons.backspace_outlined, color: Colors.black54)
            : Text(
          label,
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}