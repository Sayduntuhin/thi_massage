import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NearbyTherapistCard extends StatelessWidget {
  final String image;
  final String name;
  final String rating;
  final String bookings;
  final VoidCallback onTap;

  const NearbyTherapistCard({
    super.key,
    required this.image,
    required this.name,
    required this.rating,
    required this.bookings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.r), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5.r)]),
      child: Row(
        children: [
          Image.asset(image, width: 70.w),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              Text("⭐ $rating  |  $bookings Bookings"),
            ],
          ),
          Spacer(),
          ElevatedButton(onPressed: onTap, child: Text("Book Now")),
        ],
      ),
    );
  }
}
