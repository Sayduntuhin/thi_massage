import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../controller/location_controller.dart';
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

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final LocationController locationController = Get.put(LocationController());
  final WebSocketController webSocketController = Get.put(WebSocketController());
  final ApiService apiService = ApiService();
  Map<String, dynamic>? profileData;
  bool isProfileLoading = true;
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;
  String? errorMessage;
  String? profileErrorMessage;

  @override
  void initState() {
    super.initState();
    fetchMassageTypes();
    fetchClientProfile();
    _fetchAndUpdateLocation();
  }

  Future<void> _fetchAndUpdateLocation() async {
    try {
      await locationController.fetchCurrentLocation();
      if (!locationController.hasError.value) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final latitude = position.latitude;
        final longitude = position.longitude;
        AppLogger.debug('Fetched location: Lat=$latitude, Lon=$longitude');

        final response = await apiService.updateLocation({
          'latitude': latitude,
          'longitude': longitude,
        });
        AppLogger.debug('Location Update Response: ${response['message']}');

        // Reconnect WebSocket to refresh nearby therapists
        webSocketController.reconnect();
      } else {
        setState(() {
          errorMessage = locationController.locationName.value;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to update location: $e';
      });
      AppLogger.error('Error updating location: $e');
    }
  }

  Future<void> fetchMassageTypes() async {
    try {
      final massageTypes = await apiService.getMassageTypes();
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
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().contains('NetworkException')
            ? 'No internet connection. Please check your network.'
            : 'Failed to load massage types: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchClientProfile() async {
    try {
      final data = await apiService.getClientProfile();
      setState(() {
        profileData = data;
        isProfileLoading = false;
      });
    } catch (e) {
      setState(() {
        profileErrorMessage = e.toString().contains('NetworkException')
            ? 'No internet connection. Please check your network.'
            : 'Failed to load profile: $e';
        isProfileLoading = false;
      });
    }
  }

  String getFirstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'Guest';
    return fullName.trim().split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                Obx(() => Text(
                  locationController.locationName.value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xffA0A0A0),
                    fontFamily: "Urbanist",
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
                Text(
                  "see all",
                  style: TextStyle(fontSize: 14.sp, color: primaryTextColor),
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
              child: Text(
                errorMessage!,
                style: TextStyle(fontSize: 14.sp, color: Colors.red),
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
            Obx(() => webSocketController.isTherapistsLoading.value
                ? const CategoryItemShimmer()
                : webSocketController.errorMessage.value != null
                ? Center(
              child: Text(
                webSocketController.errorMessage.value!,
                style: TextStyle(fontSize: 14.sp, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            )
                : webSocketController.nearbyTherapists.isEmpty
                ? Center(
              child: Text(
                'No therapists found nearby',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
                : TherapistCarousel(therapists: webSocketController.nearbyTherapists)),
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