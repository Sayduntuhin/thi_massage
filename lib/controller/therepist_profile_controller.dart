import 'package:get/get.dart';
import 'package:thi_massage/api/auth_service.dart';

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
      Get.snackbar('Error', 'Failed to load profile: $e');
    } finally {
      isLoading.value = false;
    }
  }
}