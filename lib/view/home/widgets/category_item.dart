import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategoryItem extends StatelessWidget {
  final String title;
  final String image;

  const CategoryItem({super.key, required this.title, required this.image});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 0.3.sw,
          height: 0.12.sh,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r), // Rounded corners
            image: DecorationImage(
              image: AssetImage(image),
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 0.04.sh,
          width: 0.3.sw,
          child: Text(
            title,
            maxLines: 2,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w400,fontFamily: "Urbanist",color: Color(0xff666561)),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
