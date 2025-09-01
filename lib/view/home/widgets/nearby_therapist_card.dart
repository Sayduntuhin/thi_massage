import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../themes/colors.dart';
import '../../../api/api_service.dart';
import '../../widgets/app_logger.dart';
import '../../widgets/custom_snackBar.dart';
import 'package:toastification/toastification.dart';

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
        AppLogger.debug('Navigating to TherapistProfileScreen for $name');
        onTap();
      },
      borderRadius: BorderRadius.circular(15.r),
      child: Stack(
        clipBehavior: Clip.none,
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
                            const Spacer(),
                          ],
                        ),
                        Text(
                          "Since ${DateTime.now().year}",
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
            right: 0,
            bottom: 0,
            child: CachedNetworkImage(
              imageUrl: image,
              width: 0.5.sw,
              height: 0.25.sh,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) {
                AppLogger.error('Error loading image: $url, error: $error');
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
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    // Initialize therapists with isFavorite flag based on is_love
    _therapists = widget.therapists.map((therapist) {
      return {
        ...therapist,
        'isFavorite': therapist['is_love'] ?? false,
      };
    }).toList();
    AppLogger.debug('TherapistCarousel initialized with ${_therapists.length} therapists: $_therapists');
  }

  String _buildImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
      return imageUrl;
    } else if (imageUrl.startsWith('therapist/media') || imageUrl.startsWith('/media')) {
      return '${ApiService.baseUrl}/therapist$imageUrl';
    }
    AppLogger.error('Invalid image URL: $imageUrl, using fallback');
    return 'assets/images/default_therapist.png';
  }

  Future<void> _navigateToTherapistProfile(BuildContext context, int therapistId, String therapistName) async {
    try {
      AppLogger.debug('Fetching therapist profile for ID: $therapistId');
      final therapistProfile = await _apiService.getTherapistProfileforBooking(therapistId);
      AppLogger.debug('Therapist profile fetched: $therapistProfile');
      // Add therapistId to therapistProfile
      final updatedProfile = {
        ...therapistProfile,
        'therapist': {
          ...therapistProfile['therapist'] as Map<String, dynamic>,
          'therapist_user_id': therapistId,
        },
      };
      Get.toNamed(
        "/therapistPage",
        arguments: {
          'therapistProfile': updatedProfile,
        },
      );
    } catch (e) {
      AppLogger.error('Error fetching therapist profile for $therapistName: $e');
      CustomSnackBar.show(
        context,
        'Failed to load therapist profile: $e',
        type: ToastificationType.error,
      );
    }
  }

  Future<int?> _getClientId() async {
    final userIdStr = await _storage.read(key: 'user_id');
    if (userIdStr == null) {
      AppLogger.error('No user ID found in storage');
      return null;
    }
    final clientId = int.tryParse(userIdStr);
    if (clientId == null) {
      AppLogger.error('Invalid user ID format: $userIdStr');
      return null;
    }
    return clientId;
  }

  Future<void> _toggleFavorite(int index, int therapistId, String therapistName) async {
    try {
      final clientId = await _getClientId();
      if (clientId == null) {
        CustomSnackBar.show(
          context,
          'Please log in to manage favorites',
          type: ToastificationType.error,
        );
        return;
      }

      final isCurrentlyFavorite = _therapists[index]['isFavorite'] as bool;

      if (isCurrentlyFavorite) {
        // Remove from favorites
        await _apiService.removeFavoriteTherapist(therapistId);
        setState(() {
          _therapists[index]['isFavorite'] = false;
        });
        CustomSnackBar.show(
          context,
          '$therapistName removed from favorites',
          type: ToastificationType.success,
        );
      } else {
        // Add to favorites
        await _apiService.addFavoriteTherapist(therapistId);
        setState(() {
          _therapists[index]['isFavorite'] = true;
        });
        CustomSnackBar.show(
          context,
          '$therapistName added to favorites',
          type: ToastificationType.success,
        );
      }
    } catch (e) {
      AppLogger.error('Error toggling favorite for $therapistName: $e');
      CustomSnackBar.show(
        context,
        'Failed to update favorite status: $e',
        type: ToastificationType.error,
      );
    }
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
            final imageUrl = _buildImageUrl(therapist['image_url'] as String? ?? '');
            final therapistId = therapist['therapist_user_id'] as int?;
            final therapistName = therapist['full_name'] as String? ?? 'Unknown';

            return TherapistCard(
              image: imageUrl,
              name: therapistName,
              rating: (therapist['average_rating'] as num?)?.toStringAsFixed(1) ?? '0.0',
              bookings: (therapist['total_completed_bookings'] as num?)?.toString() ?? '0',
              isFavorite: therapist['isFavorite'] as bool,
              onTap: () {
                if (therapistId != null) {
                  _navigateToTherapistProfile(context, therapistId, therapistName);
                } else {
                  AppLogger.error('Therapist ID is null for $therapistName');
                  CustomSnackBar.show(
                    context,
                    'Therapist ID not found',
                    type: ToastificationType.error,
                  );
                }
              },
              onFavoriteTap: () {
                if (therapistId != null) {
                  _toggleFavorite(index, therapistId, therapistName);
                } else {
                  AppLogger.error('Therapist ID is null for $therapistName');
                  CustomSnackBar.show(
                    context,
                    'Therapist ID not found',
                    type: ToastificationType.error,
                  );
                }
              },
            );
          },
          options: CarouselOptions(
            viewportFraction: 0.8,
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