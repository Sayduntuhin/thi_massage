import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';
import '../../../routers/app_router.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_gradientButton.dart';

class NewPayoutPage extends StatefulWidget {
  const NewPayoutPage({super.key});

  @override
  State<NewPayoutPage> createState() => _NewPayoutPageState();
}

class _NewPayoutPageState extends State<NewPayoutPage> {
  String selectedMethod = 'Bank';
  String? selectedBankName; // To track the selected bank
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController accountTitleController = TextEditingController();

  final List<Map<String, dynamic>> methods = [
    {"label": "Bank", "image": "assets/images/bank.png"},
    {"label": "PayPal", "image": "assets/images/pay_pal.png"},
    {"label": "stripe", "image": "assets/images/strip.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SecondaryAppBar(title: "New Payout", showBackButton: true),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Payment Method Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: methods.map((method) {
                  final isSelected = selectedMethod == method['label'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedMethod = method['label'];
                        selectedBankName = null; // Reset bank selection when method changes
                        accountNumberController.clear();
                        accountTitleController.clear();
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.white,
                        border: Border.all(
                          color: isSelected ? primaryTextColor : Colors.grey.shade300,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: isSelected ? 6 : 2,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          method['icon'] != null
                              ? Icon(
                            method['icon'],
                            color: primaryTextColor,
                            size: 22.sp,
                          )
                              : Image.asset(
                            method['image'],
                            height: 22.h,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            method['label'],
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 30.h),

              /// Add details section
              Text(
                "Add details",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20.h),

              /// Dynamic fields based on method
              if (selectedMethod == "Bank") _buildBankSelector(),
              if (selectedMethod == "PayPal") _buildPayPalField(),
              if (selectedMethod == "stripe") _buildStripeField(),

              /// Show bank details fields if a bank is selected
              if (selectedMethod == "Bank" && selectedBankName != null) ...[
                SizedBox(height: 20.h),
                Text("Account Number/ IBAN", style: TextStyle(fontSize: 14.sp)),
                SizedBox(height: 6.h),
                TextField(
                  controller: accountNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "1234 1234 1234 1234",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: primaryTextColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: primaryTextColor),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text("Account Title", style: TextStyle(fontSize: 14.sp)),
                SizedBox(height: 6.h),
                TextField(
                  controller: accountTitleController,
                  decoration: InputDecoration(
                    hintText: "Enter name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: primaryTextColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide(color: primaryTextColor),
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
                CustomGradientButton(
                  text: "Save",
                  onPressed: () {
                    // Submit bank payout form
                    debugPrint("Bank: $selectedBankName");
                    debugPrint("IBAN: ${accountNumberController.text}");
                    debugPrint("Title: ${accountTitleController.text}");
                    // Add your save logic here (e.g., API call)
                    Get.toNamed(
                      Routes.fundsWithdrawPage,
                      arguments: {'selectedBank': selectedBankName},
                    );// Go back after saving
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Bank",
            style: TextStyle(
                fontSize: 16.sp, fontWeight: FontWeight.w600, color: Color(0xff666561))),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            selectedBankName ?? "Select bank", // Show selected bank name or "Select bank"
            style: TextStyle(fontSize: 13.sp),
          ),
          trailing: Icon(Icons.chevron_right),
          onTap: () {
            _showBankSelectionSheet(context);
          },
        ),
        Divider(),
      ],
    );
  }

  Widget _buildPayPalField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("PayPal Email",
            style: TextStyle(
                fontSize: 16.sp, fontWeight: FontWeight.w600, color: Color(0xff666561))),
        SizedBox(height: 6.h),
        TextField(
          decoration: InputDecoration(
            hintText: "Enter your PayPal email",
            border: UnderlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildStripeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Stripe Account ID",
            style: TextStyle(
                fontSize: 16.sp, fontWeight: FontWeight.w600, color: Color(0xff666561))),
        SizedBox(height: 6.h),
        TextField(
          decoration: InputDecoration(
            hintText: "Enter your Stripe ID",
            border: UnderlineInputBorder(),
          ),
        ),
      ],
    );
  }

  void _showBankSelectionSheet(BuildContext context) {
    final banks = [
      {"name": "Avidbank", "image": "assets/images/avidbank.png"},
      {"name": "BOA", "image": "assets/images/nbc_bank.png"},
      {"name": "CBT", "image": "assets/images/nbc_bank.png"},
      {"name": "NBC", "image": "assets/images/nbc_bank.png"},
      {"name": "Union Bank", "image": "assets/images/nbc_bank.png"},
      {"name": "Home Bank", "image": "assets/images/nbc_bank.png"},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 20.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Field
            TextField(
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
            SizedBox(height: 20.h),

            // Grid of banks
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: banks.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.9,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
              ),
              itemBuilder: (context, index) {
                final bank = banks[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Close the bottom sheet
                    setState(() {
                      selectedBankName = bank["name"]!; // Set the selected bank name
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        height: 90.w,
                        width: 90.w,
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.black, width: .5),
                        ),
                        child: Image.asset(bank["image"]!, fit: BoxFit.contain),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        bank["name"]!,
                        style: TextStyle(fontSize: 12.sp),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}