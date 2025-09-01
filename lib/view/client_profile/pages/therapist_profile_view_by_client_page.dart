import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';
import 'package:thi_massage/view/widgets/custom_gradientButton.dart';
import 'package:thi_massage/view/widgets/custom_snackBar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:toastification/toastification.dart';
import '../../../api/api_service.dart';

class TherapistProfileScreen extends StatefulWidget {
  const TherapistProfileScreen({super.key});

  @override
  State<TherapistProfileScreen> createState() => _TherapistProfileScreenState();
}

class _TherapistProfileScreenState extends State<TherapistProfileScreen> {
  int tabIndex = 0; // 0 for About, 1 for Reviews
  bool isFavorite = false;
  bool showAllReviews = false;
  final int initialReviewLimit = 2;
  final String baseUrl = ApiService.baseUrl;

  // Therapist and reviews data from API response
  Map<String, dynamic>? therapistData;
  List<dynamic>? reviews;
  String? errorMessage;
  int? therapistId;

  // Utility to clean special characters
  String _cleanString(String input) {
    return input
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u200B', '')
        .replaceAll('\u202F', ' ')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), ' ');
  }

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments as Map<String, dynamic>?;
    AppLogger.debug('TherapistProfileScreen Arguments received: $arguments');

    if (arguments == null || !arguments.containsKey('therapistProfile')) {
      errorMessage = 'Therapist data not found';
      therapistData = null;
      reviews = null;
      therapistId = null;
      AppLogger.error('Invalid arguments: Missing therapistProfile key');
    } else {
      final therapistProfile = arguments['therapistProfile'] as Map<String, dynamic>?;
      if (therapistProfile == null || !therapistProfile.containsKey('therapist')) {
        errorMessage = 'Invalid therapist profile data';
        therapistData = null;
        reviews = null;
        therapistId = null;
        AppLogger.error('Invalid therapistProfile: Missing therapist key');
      } else {
        therapistData = therapistProfile['therapist'] as Map<String, dynamic>?;
        reviews = therapistProfile['reviews'] as List<dynamic>? ?? [];
        therapistId = therapistData?['therapist_user_id'] as int?;

        // Clean reviews data
        reviews = reviews?.map((review) {
          return {
            ...review,
            'time_ago': _cleanString(review['time_ago'] as String? ?? ''),
          };
        }).toList();

        // Validate therapist data with fallback for role
        if (therapistData == null ||
            !therapistData!.containsKey('name') ||
            !therapistData!.containsKey('image') ||
            !therapistData!.containsKey('rating') ||
            !therapistData!.containsKey('sessions') ||
            !therapistData!.containsKey('joined') ||
            !therapistData!.containsKey('about')) {
          errorMessage = 'Invalid therapist data: Missing or empty required fields';
          therapistData = null;
          reviews = null;
          therapistId = null;
          AppLogger.error('Invalid therapist data: Missing or empty required fields in therapist map');
        } else {
          // Ensure role is not null
          therapistData!['role'] = therapistData!['role'] as String? ?? 'Unknown';
        }
      }
    }

    AppLogger.debug('Therapist ID: $therapistId');
    AppLogger.debug('Therapist Data: $therapistData');
    AppLogger.debug('Reviews: $reviews');
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null || therapistData == null || reviews == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        CustomSnackBar.show(context, errorMessage ?? 'Unknown error', type: ToastificationType.error);
      });
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Text(
            errorMessage ?? 'Unknown error',
            style: TextStyle(color: Colors.red, fontSize: 16.sp),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      body: Column(
        children: [
          Container(
            height: 0.5.sh,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24.r),
                bottomRight: Radius.circular(24.r),
              ),
              image: const DecorationImage(
                image: AssetImage("assets/images/img.png"),
                fit: BoxFit.fill,
              ),
            ),
            child: Stack(
              children: [
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50.w,
                          height: 50.h,
                          decoration: BoxDecoration(
                            color: Colors.white38,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: IconButton(
                              onPressed: () => Get.back(),
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Padding(
                          padding: EdgeInsets.only(left: 4.w),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.star, size: 16.sp, color: borderColor),
                                        SizedBox(width: 4.w),
                                        Text(
                                          therapistData!['rating'].toString(),
                                          style: TextStyle(color: borderColor, fontSize: 14.sp),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6.h),
                                    SizedBox(
                                      width: 0.4.sw,
                                      child: Text(
                                        therapistData!['name'],
                                        style: TextStyle(
                                          fontSize: 30.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: "PlayfairDisplay",
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "Therapist",
                                      style: TextStyle(fontSize: 14.sp, color: Colors.white),
                                    ),
                                    SizedBox(height: 18.h),
                                    Text.rich(
                                      TextSpan(
                                        text: "${therapistData!['sessions']} ",
                                        style: TextStyle(
                                          fontSize: 45.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: "Sessions\n",
                                            style: TextStyle(fontSize: 16.sp),
                                          ),
                                          TextSpan(
                                            text: therapistData!['joined'],
                                            style: TextStyle(
                                              fontSize: 15.sp,
                                              color: Colors.white70,
                                              fontWeight: FontWeight.w600,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
                  top: 110,
                  bottom: 41,
                  right: 0,
                  left: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(38.r),
                    child: CachedNetworkImage(
                      imageUrl: '$baseUrl${therapistData!['image']}',
                      fit: BoxFit.fill,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) {
                        AppLogger.error('Image error: $error, URL: $url');
                        return const Icon(Icons.error, color: Colors.red);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildTabButton("About", 0),
                        SizedBox(width: 20.w),
                        _buildTabButton("Reviews", 1),
                      ],
                    ),
                  ),
                  Expanded(
                    child: tabIndex == 0 ? _buildAboutSection() : _buildReviewsSection(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Row(
                      children: [
                        Container(
                          width: 50.w,
                          height: 50.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300, width: 1.5),
                          ),
                          child: IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey,
                              size: 26.sp,
                            ),
                            onPressed: () {
                              setState(() {
                                isFavorite = !isFavorite;
                              });
                              CustomSnackBar.show(
                                context,
                                isFavorite ? 'Added to favorites' : 'Removed from favorites',
                                type: ToastificationType.success,
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: CustomGradientButton(
                            text: "Book an Appointment",
                            onPressed: () {
                              if (therapistId == null) {
                                AppLogger.error('Therapist ID not found');
                                CustomSnackBar.show(
                                  context,
                                  'Therapist ID not found',
                                  type: ToastificationType.error,
                                );
                                return;
                              }
                              Get.toNamed("/appointmentPage", arguments: {
                                'therapistId': therapistId,
                                'therapist': therapistData,
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = tabIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          tabIndex = index;
          if (index != 1) showAllReviews = false;
        });
      },
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        decoration: isSelected
            ? BoxDecoration(
          border: Border.all(color: const Color(0xffB48D3C), width: 1),
          borderRadius: BorderRadius.circular(20.r),
        )
            : BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 1),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: isSelected ? const Color(0xffB48D3C) : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            therapistData!['about'],
            style: TextStyle(fontSize: 14.sp, color: Colors.black87, height: 1.5),
          ),
          SizedBox(height: 24.h),
          Text(
            "Specialties",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18.sp, color: Colors.black),
          ),
          SizedBox(height: 12.h),
          _buildSpecialtiesSection(),
          if (therapistData!.containsKey('qualifications') && (therapistData!['qualifications'] as List?)?.isNotEmpty == true) ...[
            SizedBox(height: 24.h),
            Text(
              "Qualifications",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: Colors.black),
            ),
            SizedBox(height: 12.h),
            _buildQualificationsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecialtiesSection() {
    final role = therapistData!['role'] as String; // Safe cast after null check in initState
    final specialties = [
      {'name': role, 'highlighted': true},
      {'name': '+ More', 'highlighted': false},
    ];

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: specialties.map((specialty) {
        final bool isHighlighted = specialty['highlighted'] as bool;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: isHighlighted ? boxColor : Colors.transparent,
            border: Border.all(
              color: isHighlighted ? const Color(0xffFAE08C1A).withAlpha(50) : Colors.grey.shade300,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            specialty['name'] as String,
            style: TextStyle(
              fontSize: 14.sp,
              color: isHighlighted ? const Color(0xffB48D3C) : Colors.black87,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQualificationsSection() {
    final qualifications = therapistData!['qualifications'] as List<dynamic>? ?? [];

    if (qualifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: qualifications.map((qualification) {
        return Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xffF5F5F5),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              qualification as String,
              style: TextStyle(fontSize: 14.sp, color: Colors.black87),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviewsSection() {
    final displayReviews = showAllReviews ? reviews! : reviews!.take(initialReviewLimit).toList();

    return Column(
      children: [
        Expanded(
          child: reviews!.isEmpty
              ? const Center(
            child: Text(
              "No reviews yet.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
              : ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: displayReviews.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final review = displayReviews[index];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20.r,
                          backgroundImage: CachedNetworkImageProvider(
                            '$baseUrl${review['client_image']}',
                          ),
                          onBackgroundImageError: (exception, stackTrace) {
                            AppLogger.error('Review image error: $exception');
                          },
                        ),
                        SizedBox(width: 12.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review['client_name'],
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Row(
                                  children: List.generate(
                                    5,
                                        (i) => Icon(
                                      Icons.star,
                                      size: 14.sp,
                                      color: i < review['rating'] ? Colors.amber : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  review['time_ago'],
                                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      review['review'],
                      style: TextStyle(fontSize: 14.sp, color: Colors.black87, height: 1.4),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (reviews!.isNotEmpty && !showAllReviews && reviews!.length > initialReviewLimit)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    showAllReviews = true;
                  });
                },
                child: Text(
                  "View all",
                  style: TextStyle(
                    color: const Color(0xffB48D3C),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}