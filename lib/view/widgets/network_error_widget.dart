import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thi_massage/view/widgets/custom_gradientButton.dart';

import 'custom_button.dart';

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const NetworkErrorWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 80.sp,
            color: Colors.grey,
          ),
          SizedBox(height: 20.h),
          Text(
            'No Internet Connection',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'Urbanist',
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Please check your network and try again.',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey,
              fontFamily: 'Urbanist',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          ThaiMassageButton(text: "Refresh", onPressed: onRetry,width: 0.5.sw,)

        ],
      ),
    );
  }
}