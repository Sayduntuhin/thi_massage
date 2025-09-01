import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thi_massage/api/api_service.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';
import 'package:thi_massage/view/widgets/custom_snackbar.dart';
import 'package:toastification/toastification.dart';

import 'client_home_controller.dart';

class EditProfileController extends GetxController {
  // Reactive state variables
  var isEditing = false.obs;
  var isLoading = false.obs;
  var image = Rxn<File>();
  var imageUrl = Rxn<String>();

  // Text controllers
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  // Initial values to track changes
  String? initialFirstName;
  String? initialLastName;
  String? initialPhone;
  String? initialDob;
  String? initialImageUrl;

  // User and profile IDs
  int? userId;
  int? profileId;

  final _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  @override
  void onInit() {
    super.onInit();
    initializeUserId();
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    contactController.dispose();
    dobController.dispose();
    super.onClose();
  }

  Future<void> initializeUserId() async {
    final arguments = Get.arguments as Map<String, dynamic>?;
    userId = arguments?['user_id'];
    profileId = arguments?['profile_id'];

    if (userId == null) {
      final storedUserId = await _storage.read(key: 'user_id');
      userId = int.tryParse(storedUserId ?? '');
      AppLogger.debug("Fetched userId from storage: $userId");
    }

    AppLogger.debug("EditProfileController: userId=$userId, profileId=$profileId");

    if (userId == null) {
      CustomSnackBar.show(Get.context!, "User ID missing. Please log in again.",
          type: ToastificationType.error);
      Get.offAllNamed('/login');
      return;
    }

    await fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    isLoading.value = true;
    try {
      final response = await _apiService.getClientProfile();
      AppLogger.debug("Profile fetched: $response");

      final fullName = response['full_name'] ?? '';
      final nameParts = fullName.trim().split(' ');
      firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
      lastNameController.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      emailController.text = response['email'] ?? '';
      contactController.text = response['phone'] ?? '';
      dobController.text = response['date_of_birth'] ?? '';

      // Store initial values
      initialFirstName = firstNameController.text;
      initialLastName = lastNameController.text;
      initialPhone = contactController.text;
      initialDob = dobController.text;
      initialImageUrl = imageUrl.value;

      imageUrl.value =
      response['image'] != '/media/documents/default.jpg' ? response['image'] : null;
      profileId = response['id'];
      userId = response['user'];
      AppLogger.debug("Image URL set: ${ApiService.baseUrl}${imageUrl.value}");
    } catch (e) {
      String errorMessage = "Something went wrong. Please try again.";
      if (e is NotFoundException) {
        errorMessage = "Profile not found. Please set up your Profile.";
        CustomSnackBar.show(Get.context!, errorMessage, type: ToastificationType.error);
        Get.toNamed('/profileSetup', arguments: {
          'user_id': userId,
          'profile_id': profileId,
          'source': 'edit_profile',
        });
      } else if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      } else if (e is UnauthorizedException) {
        errorMessage = "Authentication failed. Please log in again.";
        Get.offAllNamed('/login');
      }
      CustomSnackBar.show(Get.context!, errorMessage, type: ToastificationType.error);
      AppLogger.error("Fetch Profile error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        image.value = File(pickedFile.path);
        imageUrl.value = null; // Clear URL since local image is selected
      }
    } catch (e) {
      AppLogger.error("Error picking image: $e");
      CustomSnackBar.show(Get.context!, "Failed to pick image.",
          type: ToastificationType.error);
    }
  }

  Future<void> saveProfile() async {
    isLoading.value = true;
    try {
      final Map<String, dynamic> fields = {};

      // Check if name has changed
      final currentFullName =
      "${firstNameController.text.trim()} ${lastNameController.text.trim()}".trim();
      final initialFullName = "${initialFirstName ?? ''} ${initialLastName ?? ''}".trim();
      if (currentFullName != initialFullName && currentFullName.isNotEmpty) {
        fields['full_name'] = currentFullName;
      }

      // Check if phone has changed
      if (contactController.text.trim() != initialPhone &&
          contactController.text.trim().isNotEmpty) {
        fields['phone'] = contactController.text.trim();
      }

      // Check if DOB has changed
      if (dobController.text.trim() != initialDob &&
          dobController.text.trim().isNotEmpty) {
        fields['date_of_birth'] = dobController.text.trim();
      }

      // Log fields to be sent
      AppLogger.debug("Fields to update: $fields, Image: ${image.value != null}");

      // Only send request if there are changes
      if (fields.isNotEmpty || image.value != null) {
        final response = await _apiService.updateClientProfile(fields, image: image.value);
        AppLogger.info("Profile updated successfully: $response");
        CustomSnackBar.show(Get.context!,
            response['message'] ?? "Profile updated successfully!",
            type: ToastificationType.success);

        // Notify ClientHomeController to refresh profile data
        final ClientHomeController homeController = Get.find<ClientHomeController>();
        await homeController.fetchClientProfile();

        // Clear cached image to ensure the new image loads
        if (image.value != null && response['image'] != null) {
          final imageUrl = '${ApiService.baseUrl}${response['image']}';
          await CachedNetworkImageProvider(imageUrl).evict();
          AppLogger.debug("Cleared cache for image: $imageUrl");
        }
      } else {
        AppLogger.info("No changes to update");
        CustomSnackBar.show(Get.context!, "No changes made",
            type: ToastificationType.info);
      }

      isEditing.value = false; // Exit edit mode
      await fetchProfileData(); // Refresh profile data
    } catch (e) {
      String errorMessage = "Failed to update profile. Please try again.";
      if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      } else if (e is UnauthorizedException) {
        errorMessage = "Authentication failed. Please log in again.";
        Get.offAllNamed('/login');
      }
      CustomSnackBar.show(Get.context!, errorMessage, type: ToastificationType.error);
      AppLogger.error("Profile update error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void toggleEditMode() {
    isEditing.value = !isEditing.value;
  }
}