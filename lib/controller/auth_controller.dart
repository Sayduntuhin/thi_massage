import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import '../api/api_service.dart';
import '../api/auth_service.dart';
import '../controller/user_type_controller.dart';
import '../routers/app_router.dart';
import '../view/widgets/app_logger.dart';
import '../view/widgets/custom_snackBar.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final UserTypeController userTypeController = Get.find<UserTypeController>();
  final storage = const FlutterSecureStorage();

  final RxBool isLoggedIn = false.obs;
  final RxString userId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    checkSession();
  }

  Future<void> checkSession() async {
    try {
      isLoggedIn.value = await _authService.isSessionValid();
      if (isLoggedIn.value) {
        userId.value = await _authService.getUserId() ?? '';
        if (userId.value.isEmpty) {
          final storedUserId = await storage.read(key: 'user_id');
          userId.value = storedUserId ?? '';
        }
        if (userId.value.isNotEmpty) {
          try {
            final role = await _authService.getUserRole();
            AppLogger.debug("checkSession: Retrieved role: $role");
            try {
              final profile = await _authService.getUserProfile();
              await userTypeController.setUserIds(
                clientId: profile['clientId'],
                therapistId: profile['therapistId'],
                role: role,
              );
            } catch (profileError) {
              userTypeController.setUserType(role == 'therapist');
              AppLogger.warning("checkSession: Profile fetch failed: $profileError");
            }
          } catch (e) {
            userTypeController.setUserType(false);
            AppLogger.error("checkSession: Failed to get role: $e");
          }
        } else {
          isLoggedIn.value = false;
          AppLogger.debug("checkSession: No userId found, session invalid");
        }
      }
    } catch (e) {
      AppLogger.error("checkSession: Error during session check: $e");
      isLoggedIn.value = false;
    }
  }

  Future<bool> login(String email, String password, {required bool isTherapist}) async {
    try {
      final response = await _authService.login(email, password);
      AppLogger.debug("Login response: ${response.keys.toList()}");
      if (response['user_profile'] != null) {
        AppLogger.debug("user_profile keys: ${response['user_profile'].keys.toList()}");
      }
      await _authService.debugStoredData();

      if (response['access'] == null) {
        AppLogger.error("Login: No access token in response");
        throw Exception("Login failed: No access token provided by server.");
      }

      isLoggedIn.value = true;

      String extractedUserId = '';
      if (response['user_profile'] != null && response['user_profile']['user'] != null) {
        extractedUserId = response['user_profile']['user'].toString();
      } else if (response['profile_data'] != null && response['profile_data']['user'] != null) {
        extractedUserId = response['profile_data']['user'].toString();
      }

      userId.value = extractedUserId;
      if (userId.value.isNotEmpty) {
        await storage.write(key: 'user_id', value: userId.value);
      }

      String serverRole = response['user_profile']?['role'] ?? response['profile_data']?['role'] ?? 'client';
      if ((isTherapist && serverRole != 'therapist') || (!isTherapist && serverRole != 'client')) {
        AppLogger.error("Role mismatch: Selected ${isTherapist ? 'therapist' : 'client'}, got $serverRole");
        throw Exception('This email is registered as a $serverRole. Please select the correct role.');
      }

      await userTypeController.setUserIds(
        clientId: response['user_profile']?['clientId'] ?? response['profile_data']?['clientId'],
        therapistId: response['user_profile']?['therapistId'] ?? response['profile_data']?['therapistId'],
        role: serverRole,
      );

      Get.offAllNamed(Routes.homePage, arguments: {'isTherapist': isTherapist});
      AppLogger.debug("Login: userId=${userId.value}, role=$serverRole, isTherapist=$isTherapist");
      return true;
    } catch (e) {
      isLoggedIn.value = false;
      AppLogger.error("Login error: $e");
      rethrow;
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
      AppLogger.debug("SignUp response: ${response.keys.toList()}");
      await _authService.debugStoredData();

      if (response['access'] == null) {
        AppLogger.error("SignUp: No access token in response");
        throw Exception("SignUp failed: No access token provided by server.");
      }

      isLoggedIn.value = true;

      String extractedUserId = '';
      if (response['user_profile'] != null && response['user_profile']['user'] != null) {
        extractedUserId = response['user_profile']['user'].toString();
      } else if (response['profile_data'] != null && response['profile_data']['user'] != null) {
        extractedUserId = response['profile_data']['user'].toString();
      }

      userId.value = extractedUserId;
      if (userId.value.isNotEmpty) {
        await storage.write(key: 'user_id', value: userId.value);
      }

      await userTypeController.setUserIds(
        clientId: response['user_profile']?['clientId'] ?? response['profile_data']?['clientId'],
        therapistId: response['user_profile']?['therapistId'] ?? response['profile_data']?['therapistId'],
        role: role,
      );

      Get.offAllNamed(Routes.profileSetup, arguments: {'isTherapist': role == 'therapist'});
      AppLogger.debug("SignUp: userId=${userId.value}, role=$role");
      return true;
    } catch (e) {
      isLoggedIn.value = false;
      AppLogger.error("SignUp error: $e");
      rethrow;
    }
  }

  Future<bool> googleSignIn({required bool isTherapist}) async {
    try {
      final response = await _authService.googleSignIn(isTherapist: isTherapist);
      AppLogger.debug("GoogleSignIn response: ${response.keys.toList()}");
      await _authService.debugStoredData();

      if (response['access'] == null) {
        AppLogger.error("GoogleSignIn: No access token in response");
        throw Exception("Google Sign-In failed: No access token provided by server.");
      }

      isLoggedIn.value = true;

      String extractedUserId = '';
      if (response['user_profile'] != null && response['user_profile']['user'] != null) {
        extractedUserId = response['user_profile']['user'].toString();
      } else if (response['profile_data'] != null && response['profile_data']['user'] != null) {
        extractedUserId = response['profile_data']['user'].toString();
      }

      userId.value = extractedUserId;
      if (userId.value.isNotEmpty) {
        await storage.write(key: 'user_id', value: userId.value);
      }

      String serverRole = response['user_profile']?['role'] ?? response['profile_data']?['role'] ?? (isTherapist ? 'therapist' : 'client');
      if ((isTherapist && serverRole != 'therapist') || (!isTherapist && serverRole != 'client')) {
        AppLogger.error("Role mismatch: Selected ${isTherapist ? 'therapist' : 'client'}, got $serverRole");
        throw Exception('This email is registered as a $serverRole. Please select the correct role.');
      }

      await userTypeController.setUserIds(
        clientId: response['user_profile']?['clientId'] ?? response['profile_data']?['clientId'],
        therapistId: response['user_profile']?['therapistId'] ?? response['profile_data']?['therapistId'],
        role: serverRole,
      );

      final isFromSignUp = Get.currentRoute == '/signUp';
      Get.offAllNamed(
        isFromSignUp ? Routes.profileSetup : Routes.homePage,
        arguments: {'isTherapist': isTherapist},
      );
      AppLogger.debug("GoogleSignIn: userId=${userId.value}, role=$serverRole, isTherapist=$isTherapist");
      return true;
    } catch (e) {
      isLoggedIn.value = false;
      if (e is PendingApprovalException) {
        CustomSnackBar.show(Get.context!, e.message, type: ToastificationType.warning);
        return false;
      }
      AppLogger.error("GoogleSignIn error: $e");
      rethrow;
    }
  }

  Future<bool> facebookSignIn({required bool isTherapist}) async {
    try {
      final response = await _authService.facebookSignIn(isTherapist: isTherapist);
      AppLogger.debug("FacebookSignIn response: ${response.keys.toList()}");
      await _authService.debugStoredData();

      if (response['access'] == null) {
        AppLogger.error("FacebookSignIn: No access token in response");
        throw Exception("Facebook Sign-In failed: No access token provided by server.");
      }

      isLoggedIn.value = true;

      String extractedUserId = '';
      if (response['user_profile'] != null && response['user_profile']['user'] != null) {
        extractedUserId = response['user_profile']['user'].toString();
      } else if (response['profile_data'] != null && response['profile_data']['user'] != null) {
        extractedUserId = response['profile_data']['user'].toString();
      }

      userId.value = extractedUserId;
      if (userId.value.isNotEmpty) {
        await storage.write(key: 'user_id', value: userId.value);
      }

      String serverRole = response['user_profile']?['role'] ?? response['profile_data']?['role'] ?? (isTherapist ? 'therapist' : 'client');
      if ((isTherapist && serverRole != 'therapist') || (!isTherapist && serverRole != 'client')) {
        AppLogger.error("Role mismatch: Selected ${isTherapist ? 'therapist' : 'client'}, got $serverRole");
        throw Exception('This email is registered as a $serverRole. Please select the correct role.');
      }

      await userTypeController.setUserIds(
        clientId: response['user_profile']?['clientId'] ?? response['profile_data']?['clientId'],
        therapistId: response['user_profile']?['therapistId'] ?? response['profile_data']?['therapistId'],
        role: serverRole,
      );

      final isFromSignUp = Get.currentRoute == '/signUp';
      Get.offAllNamed(
        isFromSignUp ? Routes.profileSetup : Routes.homePage,
        arguments: {'isTherapist': isTherapist},
      );
      AppLogger.debug("FacebookSignIn: userId=${userId.value}, role=$serverRole, isTherapist=$isTherapist");
      return true;
    } catch (e) {
      isLoggedIn.value = false;
      AppLogger.error("FacebookSignIn error: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    await storage.deleteAll();
    isLoggedIn.value = false;
    userId.value = '';
    userTypeController.resetUserType();
    Get.offAllNamed(Routes.initial);
    AppLogger.debug("Logout: All storage cleared, userTypeController reset");
  }
}