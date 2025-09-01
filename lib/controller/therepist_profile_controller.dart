import 'package:get/get.dart';
import 'package:thi_massage/api/auth_service.dart';
import 'package:thi_massage/api/api_service.dart'; // Import for TokenExpiredException

class TherapistProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final Rx<Map<String, dynamic>> profile = Rx<Map<String, dynamic>>({});
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      final profileData = await _authService.getUserProfile();
      profile.value = profileData;
    } catch (e) {
      if (e is TokenExpiredException) {
        Get.snackbar('Session Expired', 'Your session has expired. Please log in again.');
        await _authService.logout();
        Get.offAllNamed('/login');
      } else {
        Get.snackbar('Error', 'Failed to load profile: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }
}