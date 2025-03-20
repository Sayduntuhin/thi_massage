import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thi_massage/themes/colors.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50.w,
          height: 50.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
            border: Border.all(color: buttonBorderColor.withAlpha(60), width: 1.0),
          ),
          child: IconButton(
            icon: Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: Icon(Icons.arrow_back_ios, size: 24.sp, color: primaryButtonColor),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        Spacer(),
        Center(
          child: Image.asset(
            'assets/images/logo.png',
            width: 0.4.sw,
          ),
        ),
        Spacer(flex: 2,)
      ],
    );
  }
}

