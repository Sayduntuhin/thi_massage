import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:thi_massage/controller/web_socket_controller.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';
import 'package:thi_massage/view/widgets/network_error_widget.dart';
import '../../../api/api_service.dart';
import '../../../controller/client_home_controller.dart';
import '../../widgets/app_logger.dart';
import '../widgets/category_item.dart';
import '../widgets/category_shimmer.dart';
import '../widgets/nearby_therapist_card.dart';
import '../widgets/notificaton_bell.dart';
import '../widgets/promotion_card.dart';
import '../widgets/therapist_card_shimmer.dart';

class ClientHomeContent extends StatelessWidget {
  const ClientHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final ClientHomeController controller = Get.put(ClientHomeController());
    final WebSocketController webSocketController = Get.find<WebSocketController>();

    return Obx(
          () => controller.hasNetworkError.value
          ? NetworkErrorWidget(onRetry: controller.retryAll)
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
                  controller.isProfileLoading.value
                      ? Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: CircleAvatar(
                      radius: 35.r,
                      backgroundColor: Colors.white,
                    ),
                  )
                      : controller.profileErrorMessage.value != null
                      ?CircleAvatar(
                    radius: 35.r,
                    backgroundImage: const AssetImage('assets/images/profilepic.png'),
                  )
                      : CachedNetworkImage(
                    imageUrl: controller.profileData.value != null &&
                        controller.profileData.value!['image'] != '/media/documents/default.jpg'
                        ? '${ApiService.baseUrl}${controller.profileData.value!['image']}'
                        : 'assets/images/profilepic.png',
                    cacheKey: controller.profileData.value != null &&
                        controller.profileData.value!['image'] != '/media/documents/default.jpg'
                        ? controller.profileData.value!['image'] + DateTime.now().millisecondsSinceEpoch.toString()
                        : null,
                    imageBuilder: (context, imageProvider) => CircleAvatar(
                      radius: 35.r,
                      backgroundImage: imageProvider,
                    ),
                    placeholder: (context, url) => CircleAvatar(
                      radius: 35.r,
                      backgroundColor: Colors.grey[200],
                      child: CircularProgressIndicator(
                        strokeWidth: 3.w,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryTextColor),
                        backgroundColor: Colors.grey[400],
                      ),
                    ),
                    errorWidget: (context, url, error) => CircleAvatar(
                      radius: 35.r,
                      backgroundImage: const AssetImage('assets/images/profilepic.png'),
                    ),
                  ),
                  NotificationBell(
                    notificationCount: 1,
                    svgAssetPath: 'assets/svg/notificationIcon.svg',
                    navigateTo: "/notificationsPage",
                  ),
                ],
              ),
              controller.isProfileLoading.value
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
                  : controller.profileErrorMessage.value != null
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
                "Hello ${controller.getFirstName(controller.profileData.value?['full_name'])}",
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
                  Expanded(
                    child: Text(
                      controller.locationController.locationName.value,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xffA0A0A0),
                        fontFamily: "Urbanist",
                      ),
                    ),
                  ),
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
              controller.isLoading.value
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
                  : controller.errorMessage.value != null
                  ? Center(
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: controller.retryCategories,
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
                  : controller.categories.isEmpty
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
                  itemCount: controller.categories.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: CategoryItem(
                        title: controller.categories[index]['title']!,
                        image: controller.categories[index]['image']!,
                        onTap: () {
                          Get.toNamed('/appointmentPage',
                              arguments: {'massageType': controller.categories[index]['title']});
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
                      ElevatedButton.icon(
                        onPressed: controller.retryTherapists,
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
                    : controller.locationErrorMessage.value != null
                    ? Center(
                  child: Column(
                    children: [
                      if (controller.locationErrorMessage.value!.contains('location services'))
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Geolocator.openLocationSettings();
                            await controller.requestLocationPermission();
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
                          onPressed: controller.retryTherapists,
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
                        onPressed: controller.retryTherapists,
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
      ),
    );
  }
}