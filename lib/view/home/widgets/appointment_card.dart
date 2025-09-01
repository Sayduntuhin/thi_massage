import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thi_massage/api/api_service.dart';

import '../../../themes/colors.dart';
import '../../widgets/app_logger.dart';

final String _baseUrl = ApiService.baseUrl;

Widget appointmentCard({
  required String name,
  required String date,
  required String time,
  required String service,
  required String location,
  required String distance,
  bool isMale = true,
  String? clientImage,
}) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      width: 0.88.sw,
      margin: EdgeInsets.only(right: 12.w),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: clientImage != null && clientImage.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: '$_baseUrl/therapist$clientImage',
                  width: 48.r,
                  height: 48.r,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 48.r,
                    height: 48.r,
                    color: Colors.grey[300],
                  ),
                  errorWidget: (context, url, error) {
                    AppLogger.error(
                        'Failed to load client image: $_baseUrl/therapist$clientImage, error: $error');
                    return Image.asset(
                      "assets/images/profilepic.png",
                      width: 48.r,
                      height: 48.r,
                      fit: BoxFit.cover,
                    );
                  },
                )
                    : Image.asset(
                  "assets/images/profilepic.png",
                  width: 48.r,
                  height: 48.r,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp)),
                        Icon(
                          isMale ? Icons.male : Icons.female,
                          size: 16.sp,
                          color: isMale ? Colors.blue : Colors.pink,
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 12.sp, color: Colors.grey),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                                fontSize: 11.sp, color: Colors.black54),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xffB28D28),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$distance km",
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
              RichText(
                text: TextSpan(
                  text: "Service: ",
                  style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                  children: [
                    TextSpan(
                      text: service,
                      style: TextStyle(
                          color: primaryTextColor,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14.sp, color: Colors.grey),
                  SizedBox(width: 4.w),
                  Text(time, style: TextStyle(fontSize: 12.sp)),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}