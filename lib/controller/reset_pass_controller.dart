import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import '../../api/api_service.dart';
import '../../routers/app_router.dart';
import '../view/widgets/app_logger.dart';
import '../view/widgets/custom_snackBar.dart';


class ResetPasswordController extends GetxController {
  var isLoading = false.obs;
  final ApiService _apiService = ApiService();

  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
    required BuildContext context,
  }) async {
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      CustomSnackBar.show(context, 'Please fill in both password fields.', type: ToastificationType.error);
      return;
    }

    if (newPassword != confirmPassword) {
      CustomSnackBar.show(context, 'Passwords do not match.', type: ToastificationType.error);
      return;
    }

    if (newPassword.length < 8) {
      CustomSnackBar.show(context, 'Password must be at least 8 characters long.', type: ToastificationType.error);
      return;
    }

    AppLogger.debug("ResetPassword started with email: $email");

    isLoading.value = true;

    try {
      final response = await _apiService.resetPassword(email, newPassword);
      AppLogger.debug("API response received: $response");

      if (response['message'] == 'Password reset successful.') {
        CustomSnackBar.show(context, 'Password reset successfully!', type: ToastificationType.success);
        Get.offAllNamed(Routes.logIn); // Navigate to login page
      } else {
        CustomSnackBar.show(
          context,
          response['message'] ?? 'Unexpected response from server.',
          type: ToastificationType.error,
        );
      }
    } on BadRequestException catch (e) {
      AppLogger.error("BadRequestException: ${e.message}");
      CustomSnackBar.show(context, e.message, type: ToastificationType.error);
    } on ServerException catch (e) {
      AppLogger.error("ServerException: $e");
      CustomSnackBar.show(context, 'Server error. Please try again later.', type: ToastificationType.error);
    } on NetworkException catch (e) {
      AppLogger.error("NetworkException: $e");
      CustomSnackBar.show(context, 'Check your network connection.', type: ToastificationType.error);
    } on ApiException catch (e) {
      AppLogger.error("ApiException: ${e.message}");
      CustomSnackBar.show(context, e.message, type: ToastificationType.error);
    } catch (e, stackTrace) {
      AppLogger.error("Unexpected error in resetPassword: $e\nStackTrace: $stackTrace");
      CustomSnackBar.show(context, 'An unexpected error occurred: $e', type: ToastificationType.error);
    } finally {
      isLoading.value = false;
      AppLogger.debug("resetPassword completed");
    }
  }
}