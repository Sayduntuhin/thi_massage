import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import '../../../routers/app_router.dart';
import '../api/api_service.dart';
import '../view/widgets/custom_snackBar.dart';


class ForgotPasswordController extends GetxController {
  var isLoading = false.obs;
  final ApiService _apiService = ApiService();

  ForgotPasswordController() {
    debugPrint("ForgotPasswordController initialized, _apiService: $_apiService");
  }

  Future<void> resetPassword(String email, BuildContext context) async {
    debugPrint("resetPassword started with email: $email");
    isLoading.value = true;

    try {
      debugPrint("Before calling _apiService.resetPasswordRequest");
      final response = await _apiService.resetPasswordRequest(email);
      debugPrint("API response received: $response");
      if (response['message'] == 'OTP sent to your email.') {
        debugPrint("Navigating to OTP verification");
        Get.toNamed(Routes.otpVerification, arguments: {"email": email, "type": "forgetPassword"});
      } else {
        debugPrint("Unexpected response: ${response['message']}");
        CustomSnackBar.show(
          context,
          response['message'] ?? 'Unexpected response from server.',
          type: ToastificationType.error,
        );
      }
    } on BadRequestException catch (e) {
      debugPrint("BadRequestException: ${e.message}");
      CustomSnackBar.show(context, e.message, type: ToastificationType.error);
    } on UnauthorizedException catch (e) {
      debugPrint("UnauthorizedException: $e");
      CustomSnackBar.show(context, 'Authentication failed.', type: ToastificationType.error);
    } on ForbiddenException catch (e) {
      debugPrint("ForbiddenException: $e");
      CustomSnackBar.show(context, 'Access denied.', type: ToastificationType.error);
    } on NotFoundException catch (e) {
      debugPrint("NotFoundException: $e");
      CustomSnackBar.show(context, 'Reset password endpoint not found.', type: ToastificationType.error);
    } on ServerException catch (e) {
      debugPrint("ServerException: $e");
      CustomSnackBar.show(context, 'Server error. Please try again later.', type: ToastificationType.error);
    } on NetworkException catch (e) {
      debugPrint("NetworkException: $e");
      CustomSnackBar.show(context, 'Check your network connection.', type: ToastificationType.error);
    } on ApiException catch (e) {
      debugPrint("ApiException: ${e.message}");
      CustomSnackBar.show(context, e.message, type: ToastificationType.error);
    } catch (e, stackTrace) {
      debugPrint("Unexpected error in resetPassword: $e\nStackTrace: $stackTrace");
      CustomSnackBar.show(context, 'An unexpected error occurred: $e', type: ToastificationType.error);
    } finally {
      debugPrint("resetPassword completed");
      isLoading.value = false;
    }
  }
}