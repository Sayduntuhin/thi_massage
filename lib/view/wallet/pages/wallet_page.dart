import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../themes/colors.dart';
import '../../home/widgets/promotion_card.dart';
import '../../widgets/payment_options_sheet.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool hasCard = false;

  final List<String> cardImages = [
    'assets/images/card1.png',
    'assets/images/card2.png',
    'assets/images/card3.png',
  ];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Wallet",
          style: TextStyle(
            fontSize: 18.sp,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: hasCard ? _buildCardView() : _buildEmptyCardView(),
      ),
    );
  }

  Widget _buildCardView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Your Cards", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
            GestureDetector(
              onTap: () {
                PaymentOptionsSheet.show(context);
                setState(() => hasCard = true);
    },

              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor),
                ),
                child: Icon(Icons.add, size: 18.sp, color: borderColor),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        CarouselSlider.builder(
          options: CarouselOptions(
            height: 0.2.sh,
            enlargeCenterPage: true,
            initialPage: 1,
            enableInfiniteScroll: false,
            viewportFraction: 0.75,
          ),
          itemCount: cardImages.length,
          itemBuilder: (context, index, realIdx) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.asset(cardImages[index], fit: BoxFit.cover),
            );
          },
        ),
        SizedBox(height: 24.h),
        Text("Your Vouchers", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 12.h),
        PromotionCard(image: "assets/images/promotions.png", discount: "30%", description: "Invite Friend and get 30% OFFon your next booking ", onTap: () {}),

      ],
    );
  }

  Widget _buildEmptyCardView() {
    return InkWell(
      onTap: () {
        PaymentOptionsSheet.show(context);
        setState(() => hasCard = true);
      },
      child: Container(
        width: double.infinity,
        height: 0.2.sh,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xffF1E8CF),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Color(0xff747474),
                  borderRadius: BorderRadius.circular(5.r),
                ),
                child: Icon(Icons.add, color: Colors.white),
              ),
              SizedBox(width: 8.w),
              Text(
                "Add Payment Method",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff666561),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}