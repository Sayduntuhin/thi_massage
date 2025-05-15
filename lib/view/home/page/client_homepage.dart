import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../controller/location_controller.dart';
import '../../../controller/user_controller.dart';
import '../../../controller/web_socket_controller.dart';
import '../../../themes/colors.dart';
import '../widgets/category_item.dart';
import '../widgets/category_shimmer.dart';
import '../widgets/nearby_therapist_card.dart';
import '../widgets/notificaton_bell.dart';
import '../widgets/promotion_card.dart';
import '../../widgets/custom_appbar.dart';
import '../../../api/api_service.dart';
import '../../widgets/app_logger.dart';
import '../../widgets/network_error_widget.dart';
import '../widgets/therapist_card_shimmer.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final LocationController locationController = Get.put(LocationController());
  final WebSocketController webSocketController = Get.put(WebSocketController());
  final UserController userController = Get.put(UserController()); // Initialize UserController
  final ApiService apiService = ApiService();
  Map<String, dynamic>? profileData;
  bool isProfileLoading = true;
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;
  String? errorMessage; // For API-related errors (e.g., categories)
  String? profileErrorMessage;
  String? locationErrorMessage; // For location-specific errors
  bool hasNetworkError = false; // Controls NetworkErrorWidget for the entire page

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _requestLocationPermission();
    fetchMassageTypes();
    fetchClientProfile();
    await _fetchAndUpdateLocation();
  }

  Future<void> _requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          locationErrorMessage = 'Please turn on location services in your device settings to find nearby therapists.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        bool? requestPermission = await _showLocationPermissionDialog();
        if (requestPermission != true) {
          setState(() {
            locationErrorMessage = 'Location permission is required to find nearby therapists.';
          });
          return;
        }
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          locationErrorMessage = 'Location permission denied.';
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationErrorMessage = 'Location permission permanently denied. Please enable it in settings.';
        });
        await Geolocator.openAppSettings();
        return;
      }

      setState(() {
        locationErrorMessage = null;
      });
      AppLogger.debug('Location permission granted, fetching location');
      await _fetchAndUpdateLocation();
    } catch (e) {
      AppLogger.error('Error checking/requesting location permission: $e');
      setState(() {
        locationErrorMessage = 'Failed to request location permission: $e';
      });
    }
  }

  Future<bool?> _showLocationPermissionDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs access to your location to find nearby therapists. Please allow location access to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  Future<void> _retry() async {
    setState(() {
      isLoading = true;
      isProfileLoading = true;
      errorMessage = null;
      profileErrorMessage = null;
      locationErrorMessage = null;
      hasNetworkError = false;
    });
    await _requestLocationPermission();
    fetchMassageTypes();
    fetchClientProfile();
    await _fetchAndUpdateLocation();
  }

  Future<void> _retryCategories() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      hasNetworkError = false;
    });
    fetchMassageTypes();
  }

  Future<void> _retryTherapists() async {
    setState(() {
      locationErrorMessage = null;
      hasNetworkError = false;
    });
    webSocketController.isTherapistsLoading.value = true;
    webSocketController.nearbyTherapists.clear();
    webSocketController.errorMessage.value = null;
    AppLogger.debug('Retrying therapists fetch');
    await _fetchAndUpdateLocation();
  }

  Future<void> _fetchAndUpdateLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          locationErrorMessage = permission == LocationPermission.denied
              ? 'Location permission denied.'
              : 'Location permission permanently denied. Please enable it in settings.';
        });
        webSocketController.isTherapistsLoading.value = false;
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          locationErrorMessage = 'Please turn on location services in your device settings to find nearby therapists.';
        });
        webSocketController.isTherapistsLoading.value = false;
        return;
      }

      // Fetch location directly to avoid LocationController issues
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latitude = position.latitude;
      final longitude = position.longitude;
      final locationData = {'latitude': latitude, 'longitude': longitude};
      AppLogger.debug('Sending location to API: $locationData');

      // Update location name for display
      await locationController.fetchCurrentLocation();
      if (locationController.hasError.value) {
        AppLogger.debug('LocationController has error, but proceeding with API call');
      }

      final response = await apiService.updateLocation(locationData);
      AppLogger.debug('Location API Response: $response');

      try {
        await webSocketController.reconnect().timeout(Duration(seconds: 10));
        AppLogger.debug('WebSocket reconnected, therapists: ${webSocketController.nearbyTherapists}');
      } on TimeoutException {
        AppLogger.error('WebSocket reconnect timed out');
        setState(() {
          locationErrorMessage = 'Failed to fetch therapists: Connection timeout';
        });
        webSocketController.isTherapistsLoading.value = false;
      }
    } on NetworkException catch (e) {
      AppLogger.error('Network error updating location: $e');
      setState(() {
        locationErrorMessage = 'No internet connection. Please check your network.';
        hasNetworkError = true;
      });
      webSocketController.isTherapistsLoading.value = false;
    } on BadRequestException catch (e) {
      AppLogger.error('Bad request updating location: $e');
      setState(() {
        locationErrorMessage = 'Invalid location data: $e';
      });
      webSocketController.isTherapistsLoading.value = false;
    } on UnauthorizedException catch (e) {
      AppLogger.error('Unauthorized location update: $e');
      setState(() {
        locationErrorMessage = 'Authentication failed. Please log in again.';
      });
      webSocketController.isTherapistsLoading.value = false;
    } catch (e) {
      AppLogger.error('Error updating location: $e');
      setState(() {
        locationErrorMessage = 'Failed to update location: $e';
      });
      webSocketController.isTherapistsLoading.value = false;
    }
  }

  Future<void> fetchMassageTypes() async {
    try {
      AppLogger.debug('Fetching massage types from ${ApiService.baseUrl}/api/massage-types');
      final massageTypes = await apiService.getMassageTypes();
      AppLogger.debug('Received massage types: $massageTypes');
      setState(() {
        categories = massageTypes
            .where((type) => type['is_active'] == true)
            .map((type) => {
          'title': type['name'] as String,
          'image': type['image'].startsWith('/media')
              ? '${ApiService.baseUrl}${type['image']}'
              : type['image'] as String,
        })
            .toList();
        isLoading = false;
        errorMessage = null;
        hasNetworkError = false;
      });
    } catch (e) {
      AppLogger.error('Failed to fetch massage types: $e');
      setState(() {
        errorMessage = e.toString().contains('NetworkException')
            ? 'No internet connection. Please check your network.'
            : 'Failed to load categories. Please try again.';
        isLoading = false;
        if (e.toString().contains('NetworkException')) {
          hasNetworkError = true;
        }
      });
    }
  }

  Future<void> fetchClientProfile() async {
    try {
      AppLogger.debug('Fetching client profile from ${ApiService.baseUrl}/api/client-profile');
      final data = await apiService.getClientProfile();
      AppLogger.debug('Received client profile: $data');
      // Store client_id and role in UserController
      await userController.setUserIds(
        clientId: data['user'] as int,
        role: 'client', // Assuming HomeContent is for clients
      );
      setState(() {
        profileData = data;
        isProfileLoading = false;
        profileErrorMessage = null;
        hasNetworkError = false;
      });
    } catch (e) {
      AppLogger.error('Failed to fetch client profile: $e');
      setState(() {
        profileErrorMessage = e.toString().contains('NetworkException')
            ? 'No internet connection. Please check your network.'
            : 'Failed to load profile: $e';
        isProfileLoading = false;
        if (e.toString().contains('NetworkException')) {
          hasNetworkError = true;
        }
      });
    }
  }

  String getFirstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'Guest';
    return fullName.trim().split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return hasNetworkError
        ? NetworkErrorWidget(onRetry: _retry)
        : SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 25.h),
            const CustomAppBar(showBackButton: false),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                isProfileLoading
                    ? Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: CircleAvatar(
                    radius: 35.r,
                    backgroundColor: Colors.white,
                  ),
                )
                    : profileErrorMessage != null
                    ? CircleAvatar(
                  radius: 35.r,
                  backgroundImage: const AssetImage('assets/images/profilepic.png'),
                )
                    : CircleAvatar(
                  radius: 35.r,
                  backgroundImage: profileData?['image'] != null &&
                      profileData!['image'] != '/media/documents/default.jpg'
                      ? CachedNetworkImageProvider(
                    '${ApiService.baseUrl}${profileData!['image']}',
                  )
                      : const AssetImage('assets/images/profilepic.png'),
                ),
                NotificationBell(
                  notificationCount: 1,
                  svgAssetPath: 'assets/svg/notificationIcon.svg',
                  navigateTo: "/notificationsPage",
                ),
              ],
            ),
            isProfileLoading
                ? Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 150.w,
                height: 42.sp,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            )
                : profileErrorMessage != null
                ? Text(
              "Hello Guest",
              style: TextStyle(
                fontSize: 42.sp,
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
                fontFamily: "Urbanist",
              ),
            )
                : Text(
              "Hello ${getFirstName(profileData?['full_name'])}",
              style: TextStyle(
                fontSize: 42.sp,
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
                fontFamily: "Urbanist",
              ),
            ),
            Row(
              children: [
                Icon(Icons.location_on, color: const Color(0xffA0A0A0), size: 18.sp),
                Obx(() => Expanded(
                  child: Text(
                    locationController.locationName.value,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xffA0A0A0),
                      fontFamily: "Urbanist",
                    ),
                  ),
                )),
              ],
            ),
            SizedBox(height: 20.h),
            GestureDetector(
              onTap: () {
                Get.toNamed("/searchPage");
              },
              child: AbsorbPointer(
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Color(0xff606060)),
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
                    contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Categories",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: "Urbanist",
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            isLoading
                ? SizedBox(
              height: 0.18.sh,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (context, index) {
                  return const CategoryItemShimmer();
                },
              ),
            )
                : errorMessage != null
                ? Center(
              child: Column(
                children: [
                  Text(
                    errorMessage!,
                    style: TextStyle(fontSize: 14.sp, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10.h),
                  ElevatedButton.icon(
                    onPressed: _retryCategories,
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
            )
                : categories.isEmpty
                ? Center(
              child: Text(
                'No categories available',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
                : SizedBox(
              height: 0.18.sh,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: CategoryItem(
                      title: categories[index]['title']!,
                      image: categories[index]['image']!,
                      onTap: () {
                        Get.toNamed('/appointmentPage',
                            arguments: {'massageType': categories[index]['title']});
                      },
                    ),
                  );
                },
              ),
            ),
            Text(
              "Nearby Therapists",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                fontFamily: "Urbanist",
              ),
            ),
            SizedBox(height: 10.h),
            Obx(() {
              AppLogger.debug('Nearby therapists count: ${webSocketController.nearbyTherapists.length}');
              return webSocketController.isTherapistsLoading.value
                  ? CarouselSlider.builder(
                itemCount: 3,
                itemBuilder: (context, index, realIndex) {
                  return const TherapistCardShimmer();
                },
                options: CarouselOptions(
                  height: 200.h,
                  viewportFraction: 0.8,
                  enableInfiniteScroll: true,
                  autoPlay: false,
                  enlargeCenterPage: true,
                  padEnds: true,
                ),
              )
                  : webSocketController.errorMessage.value != null
                  ? Center(
                child: Column(
                  children: [
                    Text(
                      webSocketController.errorMessage.value!,
                      style: TextStyle(fontSize: 14.sp, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10.h),
                    ElevatedButton.icon(
                      onPressed: _retryTherapists,
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
              )
                  : locationErrorMessage != null
                  ? Center(
                child: Column(
                  children: [
                    Text(
                      locationErrorMessage!,
                      style: TextStyle(fontSize: 14.sp, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10.h),
                    if (locationErrorMessage!.contains('location services'))
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Geolocator.openLocationSettings();
                          await _requestLocationPermission();
                        },
                        icon: const Icon(Icons.settings),
                        label: Text(
                          'Open Location Settings',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _retryTherapists,
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
              )
                  : webSocketController.nearbyTherapists.isEmpty
                  ? Center(
                child: Column(
                  children: [
                    Text(
                      'No therapists found nearby',
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10.h),
                    ElevatedButton.icon(
                      onPressed: _retryTherapists,
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
              )
                  : TherapistCarousel(therapists: webSocketController.nearbyTherapists);
            }),
            SizedBox(height: 20.h),
            Text(
              "Promotions",
              style: TextStyle(
                color: Colors.black,
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                fontFamily: "Urbanist",
              ),
            ),
            SizedBox(height: 10.h),
            PromotionCard(
              image: "assets/images/promotions.png",
              discount: "30%",
              description: "Invite Friend and get 30% OFF on your next booking",
              onTap: () {},
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }
}