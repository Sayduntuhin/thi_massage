import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import '../../../themes/colors.dart';
import '../../../api/api_service.dart';

class TherapistCard extends StatelessWidget {
  final String image;
  final String name;
  final String rating;
  final String bookings;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const TherapistCard({
    super.key,
    required this.image,
    required this.name,
    required this.rating,
    required this.bookings,
    this.isFavorite = false,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        print('Navigating to TherapistProfileScreen for $name');
        onTap();
      },
      borderRadius: BorderRadius.circular(15.r),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 25.h, bottom: 0.h),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xffB28D28).withAlpha(40),
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      SizedBox(width: 15.w),
                      Icon(Icons.star, size: 16.sp, color: Colors.black),
                      SizedBox(width: 4.w),
                      Text(
                        rating,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 15.w),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 0.25.sw,
                        minWidth: min(0.2.sw, 0.25.sw),
                      ),
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: "PlayfairDisplay",
                          color: const Color(0xFFB28D28),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 0.065.sh,
                    constraints: BoxConstraints(
                      maxWidth: 0.35.sw,
                      minWidth: min(0.3.sw, 0.35.sw),
                    ),
                    margin: EdgeInsets.only(top: 6.h),
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    decoration: BoxDecoration(
                      color: primaryButtonColor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8.r),
                        bottomRight: Radius.circular(8.r),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(width: 8.w),
                            Text(
                              bookings,
                              style: TextStyle(
                                fontSize: 20.sp,
                                color: Colors.white,
                                fontFamily: 'Urbanist',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 2.w, top: 4.h),
                              child: Text(
                                "Bookings",
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                        Text(
                          "Since 15 Apr, 2022",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 5,
            bottom: 0,
            child: Image.network(
              image,
              width: 0.4.sw,
              height: 0.25.sh,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: $image');
                return const Icon(Icons.error, color: Colors.red);
              },
            ),
          ),
          Positioned(
            right: 30,
            bottom: 20,
            child: SizedBox(
              height: 0.028.sh,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFB28D28),
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
                child: Text(
                  "Book now",
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ),
          ),
          Positioned(
            top: 30.h,
            right: 15.w,
            child: InkWell(
              onTap: onFavoriteTap,
              child: Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xfFFAE08C).withAlpha(100)),
                ),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? const Color(0xffBD3D44) : const Color(0xffBD3D44),
                  size: 20.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TherapistCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> therapists;

  const TherapistCarousel({super.key, required this.therapists});

  @override
  State<TherapistCarousel> createState() => _TherapistCarouselState();
}

class _TherapistCarouselState extends State<TherapistCarousel> {
  late List<Map<String, dynamic>> _therapists;

  @override
  void initState() {
    super.initState();
    // Initialize therapists with isFavorite flag
    _therapists = widget.therapists.map((therapist) {
      return {
        ...therapist,
        'isFavorite': therapist['isFavorite'] ?? false,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_therapists.isEmpty) {
      return Center(
        child: Text(
          'No nearby therapists found',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarouselSlider.builder(
          itemCount: _therapists.length,
          itemBuilder: (context, index, realIndex) {
            final therapist = _therapists[index];
            return TherapistCard(
              image: therapist['image_url'].startsWith('/media')
                  ? '${ApiService.baseUrl}${therapist['image_url']}'
                  : therapist['image_url'],
              name: therapist['full_name'] as String,
              rating: therapist['average_rating'].toStringAsFixed(1),
              bookings: therapist['total_completed_bookings'].toString(),
              isFavorite: therapist['isFavorite'] as bool,
              onTap: () {
                print('Navigating to therapistPage for ${therapist['full_name']}');
                Get.toNamed(
                  "/therapistPage",
                  arguments: {
                    'therapist_user_id': therapist['therapist_user_id'],
                    'name': therapist['full_name'],
                    'image': therapist['image_url'].startsWith('/media')
                        ? '${ApiService.baseUrl}${therapist['image_url']}'
                        : therapist['image_url'],
                  },
                );
              },
              onFavoriteTap: () {
                setState(() {
                  _therapists[index]['isFavorite'] = !(_therapists[index]['isFavorite'] as bool);
                });
              },
            );
          },
          options: CarouselOptions(
            height: 200.h,
            viewportFraction: 0.85,
            enableInfiniteScroll: true,
            autoPlay: false,
            enlargeCenterPage: true,
            padEnds: true,
          ),
        ),
      ],
    );
  }
}