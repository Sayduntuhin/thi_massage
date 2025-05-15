import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../api/api_service.dart';
import '../../../controller/web_socket_controller.dart';
import '../../../themes/colors.dart';
import '../../widgets/app_logger.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_snackbar.dart';
import 'filter.dart';
import '../../../routers/app_router.dart';
import 'package:toastification/toastification.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State createState() => _SearchPageState();
}

class _SearchPageState extends State {
  final WebSocketController webSocketController = Get.find<WebSocketController>();
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> therapists = [];
  bool isLoading = false;
  String? errorMessage;
  bool isFiltered = false;

  @override
  void initState() {
    super.initState();
    // Get initial therapists from arguments or WebSocket
    final args = Get.arguments;
    if (args != null && args['therapists'] != null) {
      therapists = List<Map<String, dynamic>>.from(args['therapists']);
    } else {
      therapists = webSocketController.nearbyTherapists;
    }
    AppLogger.debug('Initial Therapists: $therapists');
  }

  // Build image URL
  String _buildImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
      return imageUrl;
    } else if (imageUrl.startsWith('therapist/media') || imageUrl.startsWith('/media')) {
      return '${ApiService.baseUrl}/therapist$imageUrl';
    }
    AppLogger.error('Invalid image URL: $imageUrl, using fallback');
    return 'assets/images/default_therapist.png';
  }

  void _openFilterBottomSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
    if (result != null) {
      setState(() {
        isLoading = true;
        errorMessage = null;
        isFiltered = true;
      });
      _fetchFilteredTherapists(result);
    }
  }

  Future<void> _fetchFilteredTherapists(Map<String, dynamic> filters) async {
    try {
      final therapistsList = await apiService.filterTherapists(
        rating: filters['rating'] as double?,
        minPrice: (filters['minPrice'] as double?)?.toInt(),
        maxPrice: (filters['maxPrice'] as double?)?.toInt(),
        gender: filters['gender'] as String?,
        availability: filters['availability'] as String?,
      );
      setState(() {
        therapists = therapistsList;
        isLoading = false;
        errorMessage = null;
      });
      AppLogger.debug('Filtered Therapists: $therapists');
    } catch (e) {
      String detailedError = 'Failed to load therapists: $e';
      if (e is NetworkException) {
        detailedError = 'Network error: Please check your internet connection.';
      } else if (e is UnauthorizedException) {
        detailedError = 'Authentication failed: Please log in again.';
      } else if (e is ServerException) {
        detailedError = 'Server error: Please try again later.';
      }
      setState(() {
        isLoading = false;
        errorMessage = detailedError;
        therapists = [];
      });
      CustomSnackBar.show(
        context,
        detailedError,
        type: ToastificationType.error,
      );
    }
  }

  // Calculate distance if not provided
  Future<String> _calculateDistance(double therapistLat, double therapistLon) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        therapistLat,
        therapistLon,
      );
      final distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)} km away';
    } catch (e) {
      return 'Unknown distance';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecondaryAppBar(title: "Search"),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            // Search Bar with Filter Button
            Row(
              children: [
                SizedBox(
                  width: 0.72.sw,
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: const Color(0xff606060)),
                      hintText: "Search",
                      hintStyle: TextStyle(fontSize: 14.sp, color: Colors.black54),
                      filled: true,
                      fillColor: textFieldColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide(color: borderColor.withAlpha(40), width: 1.5.w),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide(color: borderColor.withAlpha(40), width: 1.5.w),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        borderSide: BorderSide(color: borderColor.withAlpha(40), width: 2.w),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 15.h),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: _openFilterBottomSheet,
                  child: Container(
                    width: 50.w,
                    height: 50.h,
                    margin: EdgeInsets.only(right: 8.w),
                    decoration: BoxDecoration(
                      color: primaryTextColor,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(Icons.tune, color: Colors.white, size: 18.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            // Therapists Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                isFiltered ? "Filtered Therapists" : "Therapists nearby",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 15.h),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Center(
                child: Text(
                  errorMessage!,
                  style: TextStyle(fontSize: 14.sp, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              )
            else if (therapists.isEmpty)
                Center(
                  child: Text(
                    isFiltered ? 'No therapists match your filters' : 'No therapists found nearby',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                )
              else
                Expanded(
                  child: isFiltered
                      ? ListView.builder(
                    itemCount: therapists.length,
                    itemBuilder: (context, index) {
                      final therapist = therapists[index];
                      return FutureBuilder<String>(
                        future: therapist['distance'] != null
                            ? Future.value('${therapist['distance']} km away')
                            : _calculateDistance(
                          therapist['latitude']?.toDouble() ?? 0.0,
                          therapist['longitude']?.toDouble() ?? 0.0,
                        ),
                        builder: (context, snapshot) {
                          final distance = snapshot.data ?? 'Calculating...';
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 25.r,
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: _buildImageUrl(therapist['image_url']),
                                  placeholder: (context, url) => CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      Image.asset('assets/images/fevTherapist2.png'),
                                  fit: BoxFit.cover,
                                  width: 50.r,
                                  height: 50.r,
                                ),
                              ),
                            ),
                            title: Text(
                              therapist['full_name'] ?? 'Unknown',
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  therapist['specialty'] ?? 'Therapist',
                                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 14.sp),
                                    SizedBox(width: 4.w),
                                    Text(
                                      '${therapist['rating']?.toStringAsFixed(1) ?? 'N/A'}',
                                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                                    ),
                                    SizedBox(width: 8.w),
                                    Icon(Icons.location_on_outlined,
                                        color: primaryTextColor, size: 14.sp),
                                    SizedBox(width: 2.w),
                                    Text(
                                      distance,
                                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              Get.toNamed(
                               "appointmentPage",
                                arguments: {
                                  'therapist': {
                                    'user': therapist['id'],
                                    'name': therapist['full_name'],
                                    'image': _buildImageUrl(therapist['image_url']),
                                    'role': therapist['specialty'] ?? 'Therapist',
                                    'rating': therapist['rating'] ?? 0.0,
                                    'reviewCount': 0, // Adjust if API provides this
                                  },
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  )
                      : SizedBox(
                    height: 0.2.sh,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: therapists.length,
                      itemBuilder: (context, index) {
                        final therapist = therapists[index];
                        return Padding(
                          padding: EdgeInsets.only(right: 12.w),
                          child: FutureBuilder<String>(
                            future: therapist['distance'] != null
                                ? Future.value('${therapist['distance']} km away')
                                : _calculateDistance(
                              therapist['latitude']?.toDouble() ?? 0.0,
                              therapist['longitude']?.toDouble() ?? 0.0,
                            ),
                            builder: (context, snapshot) {
                              final distance = snapshot.data ?? 'Calculating...';
                              return _buildTherapistCard(
                                therapist['full_name'] ?? 'Unknown',
                                _buildImageUrl(therapist['image_url']),
                                distance,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTherapistCard(String name, String imagePath, String distance) {
    return Column(
      children: [
        Container(
          width: 0.3.sw,
          height: 0.3.sw,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.r),
            child: CachedNetworkImage(
              imageUrl: imagePath,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Image.asset(
                'assets/images/fevTherapist1.png',
                fit: BoxFit.cover,
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          name,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined, color: primaryTextColor, size: 15.sp),
            SizedBox(width: 2.w),
            Text(
              distance,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}