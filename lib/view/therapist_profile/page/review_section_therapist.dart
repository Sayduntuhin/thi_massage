import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:thi_massage/view/widgets/custom_button.dart';
import '../../../api/api_service.dart';
import '../../../controller/auth_controller.dart';
import '../../../themes/colors.dart';

import '../../widgets/app_logger.dart';

class TherapistProfilePage extends StatefulWidget {
  const TherapistProfilePage({super.key});

  @override
  State<TherapistProfilePage> createState() => _TherapistProfilePageState();
}

class _TherapistProfilePageState extends State<TherapistProfilePage>
    with SingleTickerProviderStateMixin {
  bool isFavorite = false;
  bool showAllReviews = false;
  final int initialReviewLimit = 3;
  late AnimationController _animationController;
  late Animation<double> _mainScreenSlideAnimation;
  late Animation<double> _mainScreenScaleAnimation;
  bool _isDrawerOpen = false;
  double _dragStartX = 0;
  Map<String, dynamic>? _therapistProfile;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingProfile = true;
  String? _profileErrorMessage;
  int? _selectedReviewId; // Track the selected review ID for response
  String _responseText = ''; // Store the response text
  final ApiService _apiService = ApiService();
  final AuthController authController = Get.find<AuthController>();
  final _storage = const FlutterSecureStorage();
  String? _selectedDrawerItem;
  final GlobalKey _reviewsListKey = GlobalKey(); // Key to scroll to the reviews list

  List<Map<String, dynamic>> get displayReviews {
    if (showAllReviews) {
      return _reviews;
    } else {
      return _reviews.take(initialReviewLimit).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDrawerItem = "Reviews & Ratings"; // Highlight Reviews & Ratings in drawer

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _mainScreenSlideAnimation = Tween<double>(begin: 0.0, end: 250.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _mainScreenScaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Fetch therapist profile and reviews
    _fetchTherapistData();
  }

  Future<void> _fetchTherapistData() async {
    setState(() {
      _isLoadingProfile = true;
      _profileErrorMessage = null;
    });
    try {
      final data = await _apiService.getTherapistReviews();
      setState(() {
        _therapistProfile = data['therapist'];
        _reviews = List<Map<String, dynamic>>.from(data['reviews'] ?? []);
        _isLoadingProfile = false;
      });
      AppLogger.debug('Therapist Data: $data');
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
        _profileErrorMessage = 'Failed to load data: $e';
      });
      AppLogger.error('Failed to fetch therapist data: $e');
    }
  }

  Future<void> _submitResponse() async {
    if (_selectedReviewId == null || _responseText.isEmpty) return;

    setState(() {
      _isLoadingProfile = true;
      _profileErrorMessage = null;
    });

    try {
      final response = await _apiService.submitReviewResponse(_selectedReviewId!, _responseText);
      setState(() {
        _isLoadingProfile = false;
        final index = _reviews.indexWhere((review) => review['id'] == _selectedReviewId);
        if (index != -1) {
          _reviews[index] = {..._reviews[index], 'response': response['response']};
        }
        _selectedReviewId = null;
        _responseText = '';
      });
      AppLogger.debug('Response submitted: $response');
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
        _profileErrorMessage = 'Failed to submit response: $e';
      });
      AppLogger.error('Failed to submit response: $e');
    }
  }

  void toggleDrawer() {
    if (_isDrawerOpen) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    _isDrawerOpen = !_isDrawerOpen;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildDrawerItem(IconData icon, String title, String route) {
    final isSelected = _selectedDrawerItem == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDrawerItem = title;
        });
        toggleDrawer();
        if (route != "/reviewsRatings" || title == "Home") {
          Get.offNamed(route);
        }
        AppLogger.debug('Navigating to $route');
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? selectedTabColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Allow the screen to resize when the keyboard appears
      backgroundColor: Colors.white,
      body: GestureDetector(
        onHorizontalDragStart: (details) => _dragStartX = details.globalPosition.dx,
        onHorizontalDragUpdate: (details) {
          double delta = details.globalPosition.dx - _dragStartX;
          if (delta > 0 && !_isDrawerOpen) {
            _animationController.value = (delta / 250).clamp(0.0, 1.0);
          } else if (delta < 0 && _isDrawerOpen) {
            _animationController.value = 1.0 + (delta / 250).clamp(-1.0, 0.0);
          }
        },
        onHorizontalDragEnd: (_) {
          if (_animationController.value > 0.5) {
            _animationController.forward();
            _isDrawerOpen = true;
          } else {
            _animationController.reverse();
            _isDrawerOpen = false;
          }
        },
        child: Stack(
          children: [
            // Drawer Layer
            Container(
              color: const Color(0xFFB28D28),
              padding: EdgeInsets.only(left: 24.w, top: 70.h, right: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: _therapistProfile?['image'] != null
                        ? CachedNetworkImageProvider('${ApiService.baseUrl}${_therapistProfile!['image']}')
                        : const AssetImage("assets/images/profilepic.png") as ImageProvider,
                    radius: 40.r,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    _therapistProfile?['name'] ?? 'Therapist Name',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    _therapistProfile?['role'] ?? 'Massage Therapist',
                    style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                  ),
                  SizedBox(height: 30.h),
                  _buildDrawerItem(Icons.home, "Home", "/therapistHomePage"),
                  _buildDrawerItem(Icons.calendar_today, "Availability Settings", "/availabilitySettings"),
                  _buildDrawerItem(Icons.settings, "App Settings", "/appSettings"),
                  _buildDrawerItem(Icons.privacy_tip, "Terms & Privacy Policy", "/termsPrivacy"),
                  _buildDrawerItem(Icons.star_rate, "Reviews & Ratings", "/reviewsRatings"),
                  _buildDrawerItem(Icons.support_agent, "Contact Support", "/contactSupport"),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      try {
                        await authController.logout();
                      } catch (e) {
                        AppLogger.error('Failed to logout: $e');
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.logout, color: Colors.red, size: 18.sp),
                          SizedBox(width: 8.w),
                          Text("Log out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
            // Main Screen
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_mainScreenSlideAnimation.value, 0),
                  child: Transform.scale(
                    scale: _mainScreenScaleAnimation.value,
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(_animationController.value * 25.r),
                        bottomLeft: Radius.circular(_animationController.value * 25.r),
                      ),
                      child: Container(
                        color: Colors.white,
                        child: _isLoadingProfile
                            ? Center(
                          child: SizedBox(
                            child: const CircularProgressIndicator(),
                          ),
                        )
                            : _profileErrorMessage != null
                            ? Center(
                          child: SizedBox(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _profileErrorMessage!,
                                  style: TextStyle(fontSize: 14.sp, color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 10.h),
                                ElevatedButton.icon(
                                  onPressed: _fetchTherapistData,
                                  icon: const Icon(Icons.refresh),
                                  label: Text(
                                    'Retry',
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            : SingleChildScrollView( // Full page scrollable
                          child: Column(
                            children: [
                              // Header with therapist info
                              Container(
                                height: 0.4.sh,
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
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 0.05.sh),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Left side with therapist info
                                              Expanded(
                                                flex: 3,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(height: 0.04.sh),
                                                    Text(
                                                      _therapistProfile?['name'].split(' ').first ?? 'Therapist',
                                                      style: TextStyle(
                                                        fontSize: 32.sp,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                        fontFamily: "PlayfairDisplay",
                                                      ),
                                                    ),
                                                    Text(
                                                      _therapistProfile?['name'].split(' ').length > 1
                                                          ? _therapistProfile!['name'].split(' ').last
                                                          : '',
                                                      style: TextStyle(
                                                        fontSize: 32.sp,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                        fontFamily: "PlayfairDisplay",
                                                      ),
                                                    ),
                                                    Text(
                                                      _therapistProfile?['role'] ?? 'Therapist',
                                                      style: TextStyle(fontSize: 16.sp, color: Colors.white),
                                                    ),
                                                    SizedBox(height: 0.03.sh),
                                                    Text.rich(
                                                      TextSpan(
                                                        text: _therapistProfile?['sessions'].toString() ?? '0',
                                                        style: TextStyle(
                                                          fontSize: 32.sp,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                        children: [
                                                          TextSpan(
                                                            text: " Sessions\n",
                                                            style: TextStyle(fontSize: 16.sp),
                                                          ),
                                                          TextSpan(
                                                            text: _therapistProfile?['joined'] ?? 'Since Unknown',
                                                            style: TextStyle(
                                                              fontSize: 14.sp,
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.normal,
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
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: 105,
                                      bottom: 32,
                                      right: 0,
                                      left: 160,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(38.r),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12.r),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12.r),
                                            child: CachedNetworkImage(
                                              imageUrl: '${ApiService.baseUrl}${_therapistProfile?['image']}',
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Center(child: const CircularProgressIndicator()),
                                              errorWidget: (context, url, error) => Image.asset(
                                                "assets/images/therapist_man.png",
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Reviews and rating section
                              Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(0),
                                    topRight: Radius.circular(0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                                      child: Text(
                                        "Reviews & Rating",
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    // Rating bars
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: reviewCardColor,
                                          borderRadius: BorderRadius.circular(12.r),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.2),
                                              spreadRadius: 1,
                                              blurRadius: 5,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                                          child: Row(
                                            children: [
                                              // Rating bars
                                              Expanded(
                                                flex: 3,
                                                child: Column(
                                                  children: [
                                                    _buildRatingBar(5, 0.7), // Adjust percentages based on API data
                                                    _buildRatingBar(4, 0.5),
                                                    _buildRatingBar(3, 0.2),
                                                    _buildRatingBar(2, 0.1),
                                                    _buildRatingBar(1, 0.05),
                                                  ],
                                                ),
                                              ),
                                              // Average rating display
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      _therapistProfile?['rating'].toString() ?? '0.0',
                                                      style: TextStyle(
                                                        fontSize: 24.sp,
                                                        fontWeight: FontWeight.bold,
                                                        color: const Color(0xFFB48D3C),
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: List.generate(
                                                        5,
                                                            (index) => Icon(
                                                          Icons.star,
                                                          size: 12.sp,
                                                          color: index < (_therapistProfile?['rating']?.round() ?? 0)
                                                              ? starColor
                                                              : Colors.grey.shade300,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: 4.h),
                                                    Text(
                                                      "${_reviews.length} Reviews",
                                                      style: TextStyle(
                                                        fontSize: 12.sp,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    // Reviews list
                                    _buildReviewsList(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(int rating, double percentage) {
    // Note: You may want to calculate the percentage dynamically based on the API data
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          SizedBox(
            width: 15.w,
            child: Text(
              rating.toString(),
              style: TextStyle(
                fontSize: 14.sp,
                color: Color(0xff333333),
              ),
            ),
          ),
          SizedBox(
            width: 15.w,
            child: Icon(
              Icons.star,
              size: 14.sp,
              color: starColor,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: reviewCardColor,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return ListView.separated(
      key: _reviewsListKey, // Assign the global key
      shrinkWrap: true, // Allow the ListView to take only the space it needs
      physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: displayReviews.length + (_reviews.length > initialReviewLimit ? 1 : 0),
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        if (index == displayReviews.length && _reviews.length > initialReviewLimit) {
          // "View all" button
          return Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  showAllReviews = true;
                });
              },
              child: Text(
                "View all",
                style: TextStyle(
                  color: const Color(0xFFB48D3C),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

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
                    backgroundImage: review['client_image'] != null
                        ? CachedNetworkImageProvider('${ApiService.baseUrl}${review['client_image']}')
                        : const AssetImage('assets/images/profilepic.png') as ImageProvider,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
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
                                  color: i < review['rating'] ? starColor : Colors.grey.shade300,
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
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey, size: 20.sp),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.reply),
                              title: const Text('Response'),
                              onTap: () {
                                Navigator.pop(context);
                                setState(() {
                                  _selectedReviewId = review['id'];
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    Scrollable.ensureVisible(
                                      _reviewsListKey.currentContext!,
                                      alignment: 0.5,
                                      duration: const Duration(milliseconds: 300),
                                    );
                                  });
                                });
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.report),
                              title: const Text('Report'),
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                review['review'],
                style: TextStyle(fontSize: 14.sp, color: Colors.black87, height: 1.4),
              ),
              if (_selectedReviewId == review['id'])
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Response',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter your response...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                        maxLines: 3,
                        onChanged: (value) => setState(() => _responseText = value),
                      ),
                      SizedBox(height: 8.h),
                      ThaiMassageButton(
                        text: 'Submit',
                        onPressed: _submitResponse,),

                    ],
                  ),
                ),
              if (review['response'] != null)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    'Response: ${review['response']}',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}