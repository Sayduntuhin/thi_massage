import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/custom_gradientButton.dart';
import '../../profile/widgets/carve_shap_painter.dart';

class TherapistProfileScreen extends StatefulWidget {
  const TherapistProfileScreen({super.key});

  @override
  State<TherapistProfileScreen> createState() => _TherapistProfileScreenState();
}

class _TherapistProfileScreenState extends State<TherapistProfileScreen> {
  int tabIndex = 0; // 0 for About, 1 for Reviews
  bool isFavorite = false;
  bool showAllReviews = false; // Track whether to show all reviews
  final int initialReviewLimit = 2; // Limit to show initially

  // Retrieve name and image from arguments
  late final String therapistName;
  late final String therapistImage;

  @override
  void initState() {
    super.initState();
    // Get the arguments passed via GetX navigation
    final arguments = Get.arguments as Map<String, dynamic>?;
    print('Arguments received: $arguments'); // Debug print
    therapistName = arguments?['name'] ?? 'Mical Martinez'; // Fallback if not provided
    therapistImage = arguments?['image'] ?? 'assets/images/therapist_man.png'; // Fallback if not provided
    print('Therapist Name: $therapistName'); // Debug print
    print('Therapist Image: $therapistImage'); // Debug print
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      body: Column(
        children: [
          Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24.r),
                bottomRight: Radius.circular(24.r),
              ),
            ),
            child: Stack(
              children: [
                Container(
                  height: 0.45.sh,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: primaryColor,
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: CurveShapePainter(),
                  ),
                ),
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
                              /// Left side: Text Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// Rating
                                    Row(
                                      children: [
                                        Icon(Icons.star, size: 16.sp, color: borderColor),
                                        SizedBox(width: 4.w),
                                        Text(
                                          "4.2",
                                          style: TextStyle(color: borderColor, fontSize: 14.sp),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6.h),

                                    /// Name (Dynamic)
                                    SizedBox(
                                      width: 0.4.sw,
                                      child: Text(
                                        therapistName, // Use dynamic name
                                        style: TextStyle(
                                          fontSize: 30.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: "PlayfairDisplay",
                                        ),
                                      ),
                                    ),

                                    /// Role
                                    Text(
                                      "Therapist",
                                      style: TextStyle(fontSize: 14.sp, color: Colors.white),
                                    ),
                                    SizedBox(height: 16.h),

                                    /// Sessions Info
                                    Text.rich(
                                      TextSpan(
                                        text: "102 ",
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
                                            text: "Since 15 Apr, 2022",
                                            style: TextStyle(fontSize: 12.sp, color: Colors.white70),
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
                  top: 120,
                  bottom: 0,
                  right: -40,
                  left: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50.r),
                    child: Image.asset(
                      therapistImage, // Use dynamic image
                      fit: BoxFit.cover, // Ensure the image fits properly
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error, color: Colors.red); // Show error icon if image fails to load
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
                  // Tab buttons
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

                  // Tab content
                  Expanded(
                    child: tabIndex == 0
                        ? _buildAboutSection()
                        : _buildReviewsSection(),
                  ),

                  // Bottom actions
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Row(
                      children: [
                        // Favorite button
                        Container(
                          width: 50.w,
                          height: 50.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
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
                            },
                          ),
                        ),
                        SizedBox(width: 16.w),

                        // Book appointment button
                        Expanded(
                          child: CustomGradientButton(
                            text: "Book an Appointment",
                            onPressed: () {},
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
          if (index != 1) {
            showAllReviews = false; // Reset showAllReviews when switching away from Reviews tab
          }
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
            "With 3 years of experience in professional massage therapy, I specialize in relieving stress, reducing muscle tension, and promoting overall well-being. My goal is to provide a relaxing and therapeutic experience tailored to each client's needs. Whether you're looking for deep tissue, Swedish, or a soothing relaxation massage, I ensure a comfortable and rejuvenating session every time. Book a session today and let me help you feel your best!",
            style: TextStyle(fontSize: 14.sp, color: Colors.black87, height: 1.5),
          ),
          SizedBox(height: 24.h),

          // Specialties section
          Text(
            "Specialties",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18.sp,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12.h),
          _buildSpecialtiesSection(),
          SizedBox(height: 24.h),

          // Qualifications section
          Text(
            "Qualifications",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12.h),
          _buildQualificationsSection(),
        ],
      ),
    );
  }

  Widget _buildSpecialtiesSection() {
    final specialties = [
      {"name": "Swedish Massage", "highlighted": true},
      {"name": "Trigger Point Therapy", "highlighted": true},
      {"name": "Cupping", "highlighted": true},
      {"name": "Lymphatic Drainage", "highlighted": true},
      {"name": "Aromatherapy", "highlighted": true},
      {"name": "+7 more", "highlighted": false},
    ];

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: specialties.map((specialty) {
        final bool isHighlighted = specialty["highlighted"] as bool;
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
            specialty["name"] as String,
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
    final qualifications = ["A.A.S", "BCTMB", "CESI"];

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
              qualification,
              style: TextStyle(fontSize: 14.sp, color: Colors.black87),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviewsSection() {
    final reviews = [
      {
        'name': 'Sarah M.',
        'rating': 5,
        'time': '25 mins ago',
        'review':
        'Amazing experience! The therapist was professional and very skilled. I felt completely relaxed and refreshed after my session. Will book again!',
      },
      {
        'name': 'David J.',
        'rating': 4,
        'time': '2 days ago',
        'review':
        'Great massage! The pressure was just right, and the therapist was very polite. Only reason for 4 stars is that they arrived 10 minutes late.',
      },
      {
        'name': 'Jane Cooper',
        'rating': 5,
        'time': '2 days ago',
        'review': 'One of the best massages I\'ve ever had! Highly recommended!',
      },
    ];

    // Determine how many reviews to show
    final displayReviews = showAllReviews ? reviews : reviews.take(initialReviewLimit).toList();

    return Column(
      children: [
        Expanded(
          child: reviews.isEmpty
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
                          backgroundImage: const AssetImage('assets/images/review_image_one.png'),
                        ),
                        SizedBox(width: 12.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review['name'] as String,
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
                                      color: i < (review['rating'] as int)
                                          ? Colors.amber
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  review['time'] as String,
                                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.more_vert, color: Colors.grey),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      review['review'] as String,
                      style: TextStyle(fontSize: 14.sp, color: Colors.black87, height: 1.4),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (reviews.isNotEmpty && !showAllReviews && reviews.length > initialReviewLimit)
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