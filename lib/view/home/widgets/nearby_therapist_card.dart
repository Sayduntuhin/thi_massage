import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import '../../../themes/colors.dart';

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
        print('Navigating to TherapistProfileScreen for $name'); // Debug print
        onTap();
      },
      borderRadius: BorderRadius.circular(15.r),
      child: Stack(
        children: [
          // Content
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
                  SizedBox(
                    height: 10.h,
                  ),
                  // Rating
                  Row(
                    children: [
                      SizedBox(
                        width: 15.w,
                      ),
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
                  // Name
                  Padding(
                    padding: EdgeInsets.only(left: 15.w),
                    child: SizedBox(
                      width: 0.2.sw,
                      child: Text(
                        name,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: "PlayfairDisplay",
                          color: const Color(0xFFB28D28),
                        ),
                      ),
                    ),
                  ),

                  // Therapist or Bookings
                  Container(
                    height: 0.065.sh,
                    width: 0.3.sw,
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
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 8.w,
                            ),
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

          // Therapist image
          Positioned(
            right: 5,
            bottom: 0,
            child: Image.asset(
              image,
              width: 0.4.sw,
              height: 0.25.sh,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: $image'); // Debug print
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
                onPressed: onTap, // Still works for the button
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
          // Favorite button
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

// Carousel for therapist cards
class TherapistCarousel extends StatefulWidget {
  const TherapistCarousel({super.key});

  @override
  State<TherapistCarousel> createState() => _TherapistCarouselState();
}

class _TherapistCarouselState extends State<TherapistCarousel> {
  final List<Map<String, dynamic>> therapists = [
    {
      'image': 'assets/images/therapist_man.png',
      'name': 'Mical Martinez',
      'rating': '4.2',
      'bookings': '102',
      'isFavorite': false,
    },
    {
      'image': 'assets/images/therapist_woman.png',
      'name': 'Sarah Johnson',
      'rating': '4.2',
      'bookings': '',
      'isFavorite': false,
    },
    {
      'image': 'assets/images/therapist_man.png',
      'name': 'Sarah Johnson',
      'rating': '4.5',
      'bookings': '78',
      'isFavorite': false,
    },
    {
      'image': 'assets/images/therapist_woman.png',
      'name': 'David Wilson',
      'rating': '4.8',
      'bookings': '156',
      'isFavorite': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarouselSlider.builder(
          itemCount: therapists.length,
          itemBuilder: (context, index, realIndex) {
            final therapist = therapists[index];
            return TherapistCard(
              image: therapist['image'] as String,
              name: therapist['name'] as String,
              rating: therapist['rating'] as String,
              bookings: therapist['bookings'] as String,
              isFavorite: therapist['isFavorite'] as bool,
              onTap: () {
                // Navigate to TherapistProfileScreen with name and image
                print('Passing arguments: name=${therapist['name']}, image=${therapist['image']}'); // Debug print
                Get.toNamed(
                  "/therapistPage",
                  arguments: {
                    'name': therapist['name'] as String,
                    'image': therapist['image'] as String,
                  },
                );
              },
              onFavoriteTap: () {
                setState(() {
                  therapists[index]['isFavorite'] = !therapists[index]['isFavorite'];
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