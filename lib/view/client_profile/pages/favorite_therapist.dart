import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:thi_massage/api/api_service.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';
import 'package:thi_massage/view/widgets/custom_snackbar.dart';
import 'package:toastification/toastification.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FavoriteTherapistPage extends StatefulWidget {
  const FavoriteTherapistPage({super.key});

  @override
  State<FavoriteTherapistPage> createState() => _FavoriteTherapistPageState();
}

class _FavoriteTherapistPageState extends State<FavoriteTherapistPage> {
  List<Map<String, dynamic>> therapists = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchFavoriteTherapists();
  }

  Future<void> fetchFavoriteTherapists() async {
    setState(() {
      isLoading = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.getFavoriteTherapists();
      AppLogger.debug("Raw favorite therapists response (count: ${response.length}): $response");

      setState(() {
        therapists = response.map((therapist) {
          // Minimal validation
          if (therapist['id'] == null || therapist['therapist_full_name'] == null) {
            AppLogger.error("Invalid therapist data: $therapist");
            return null;
          }

          // Construct image URL
          String imagePath = therapist['therapist_image']?.toString() ?? '/media/documents/default_profile.jpg';
          String imageUrl;
          if (imagePath.startsWith('/media/')) {
            imageUrl = '${ApiService.baseUrl}/api$imagePath';
          } else if (imagePath.startsWith('/api/media/')) {
            imageUrl = '${ApiService.baseUrl}$imagePath';
          } else {
            imageUrl = '${ApiService.baseUrl}/api/media/documents/default_profile.jpg';
          }

          // Map gender
          final gender = therapist['therapist_gender']?.toString().toLowerCase() ?? 'male';
          final svgPath = gender == 'female' ? 'assets/svg/female.svg' : 'assets/svg/male.svg';
          final genderColor = gender == 'female' ? Colors.pink : Colors.blue;

          AppLogger.debug(
              "Therapist ID: ${therapist['id']}, Name: ${therapist['therapist_full_name']}, Image: $imageUrl, Gender: $gender");

          return {
            'id': therapist['id'],
            'image': imageUrl,
            'name': therapist['therapist_full_name'],
            'specialty': therapist['therapist_massage_type']?.toString() ?? 'Massage Therapist',
            'svgPath': svgPath,
            'genderColor': genderColor,
          };
        }).where((therapist) => therapist != null).cast<Map<String, dynamic>>().toList();

        AppLogger.debug("Mapped therapists (count: ${therapists.length}): $therapists");
      });
    } catch (e) {
      String errorMessage = "Failed to fetch favorite therapists. Please try again.";
      if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      } else if (e is UnauthorizedException) {
        errorMessage = "Authentication failed. Please log in again.";
        Get.offAllNamed('/login');
      }
      CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
      AppLogger.error("Fetch favorite therapists error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecondaryAppBar(title: "Favorite Therapist"),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 0.05.sh),
            // Search Bar
            TextField(
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
                contentPadding: EdgeInsets.symmetric(vertical: 15.h),
              ),
            ),
            SizedBox(height: 20.h),
            // Therapist List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : therapists.isEmpty
                  ? const Center(child: Text("No favorite therapists found"))
                  : ListView.builder(
                key: const ValueKey('therapist_list'),
                itemCount: therapists.length,
                itemBuilder: (context, index) {
                  final therapist = therapists[index];
                  AppLogger.debug(
                      "Rendering therapist ID: ${therapist['id']}, Name: ${therapist['name']}, Image: ${therapist['image']}");
                  return _buildTherapistItem(
                    image: therapist['image']!,
                    name: therapist['name']!,
                    specialty: therapist['specialty']!,
                    svgPath: therapist['svgPath']!,
                    genderColor: therapist['genderColor']!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Therapist Item Widget
  Widget _buildTherapistItem({
    required String image,
    required String name,
    required String specialty,
    required String svgPath,
    required Color genderColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          // Profile Image
          Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 25.r,
                child: CachedNetworkImage(
                  imageUrl: image,
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) {
                    AppLogger.error("Failed to load image: $url, Error: $error");
                    return Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/images/default_therapist.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  width: 18.w,
                  height: 18.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4.r,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.favorite_border,
                      color: const Color(0xffBD3D44),
                      size: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 10.w),
          // Therapist Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    SvgPicture.asset(svgPath, width: 16.w, height: 16.h),
                  ],
                ),
                Text(
                  specialty,
                  style: TextStyle(fontSize: 12.sp, color: secounderyTextColor),
                ),
              ],
            ),
          ),
          // Book Appointment Button
          GestureDetector(
            onTap: () {
              Get.toNamed("/appointmentPage");
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: secounderyBorderColor.withAlpha(60)),
              ),
              child: Text(
                "Book appointment",
                style: TextStyle(fontSize: 10.sp, color: primaryTextColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}