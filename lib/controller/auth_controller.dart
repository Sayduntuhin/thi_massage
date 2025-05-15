import 'package:get/get.dart';
import 'package:thi_massage/api/auth_service.dart';
import 'package:thi_massage/controller/user_type_controller.dart';
import 'package:toastification/toastification.dart';
import '../api/api_service.dart';
import '../routers/app_router.dart';
import '../view/widgets/custom_snackBar.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final UserTypeController _userTypeController = Get.find<UserTypeController>();

  final RxBool isLoggedIn = false.obs;
  final RxString userId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    checkSession();
  }

  Future<void> checkSession() async {
    isLoggedIn.value = await _authService.isSessionValid();
    if (isLoggedIn.value) {
      userId.value = await _authService.getUserId() ?? '';
      try {
        final profile = await _authService.getUserProfile();
        final role = profile['role'] ?? 'client';
        _userTypeController.setUserType(role == 'therapist');
      } catch (e) {
        _userTypeController.setUserType(false);
      }
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _authService.login(email, password);
      isLoggedIn.value = true;
      userId.value = response['profile_data']['user']?.toString() ?? '';
      final role = response['profile_data']['role'] ?? 'client';
      _userTypeController.setUserType(role == 'therapist');
      Get.offAllNamed(Routes.homePage, arguments: {'isTherapist': role == 'therapist'});
      return true;
    } catch (e) {
      isLoggedIn.value = false;
      rethrow; // Propagate the exception
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String role,
  }) async {
    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: role,
      );
      isLoggedIn.value = true;
      userId.value = response['profile_data']?['user']?.toString() ?? '';
      final userRole = response['profile_data']?['role'] ?? role;
      _userTypeController.setUserType(userRole == 'therapist');
      Get.offAllNamed(Routes.profileSetup, arguments: {'isTherapist': userRole == 'therapist'});
      return true;
    } catch (e) {
      isLoggedIn.value = false;
      rethrow; // Propagate the exception
    }
  }

  Future<bool> googleSignIn({required bool isTherapist}) async {
    try {
      final response = await _authService.googleSignIn(isTherapist: isTherapist);
      isLoggedIn.value = true;
      userId.value = response['profile_data']['user']?.toString() ?? '';
      final role = response['profile_data']['role'] ?? (isTherapist ? 'therapist' : 'client');
      _userTypeController.setUserType(role == 'therapist');
      final isFromSignUp = Get.currentRoute == '/signUp';
      Get.offAllNamed(
        isFromSignUp ? Routes.profileSetup : Routes.homePage,
        arguments: {'isTherapist': role == 'therapist'},
      );
      return true;
    } catch (e) {
      isLoggedIn.value = false;
      if (e is PendingApprovalException) {
        CustomSnackBar.show(
          Get.context!,
          e.message,
          type: ToastificationType.warning,
        );
        return false; // Stay on LoginPage
      }
      rethrow;
    }
  }
  Future<bool> facebookSignIn({required bool isTherapist}) async {
    try {
      final response = await _authService.facebookSignIn(isTherapist: isTherapist);
      isLoggedIn.value = true;
      userId.value = response['profile_data']['user']?.toString() ?? '';
      final role = response['profile_data']['role'] ?? (isTherapist ? 'therapist' : 'client');
      _userTypeController.setUserType(role == 'therapist');
      final isFromSignUp = Get.currentRoute == '/signUp';
      Get.offAllNamed(
        isFromSignUp ? Routes.profileSetup : Routes.homePage,
        arguments: {'isTherapist': role == 'therapist'},
      );
      return true;
    } catch (e) {
      isLoggedIn.value = false;
      rethrow; // Propagate the exception
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    isLoggedIn.value = false;
    userId.value = '';
    _userTypeController.resetUserType();
    Get.offAllNamed(Routes.initial);
  }
}