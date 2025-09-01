import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:thi_massage/api/api_service.dart';
import 'package:thi_massage/controller/location_controller.dart';
import 'package:thi_massage/controller/notifications_controller.dart';
import 'package:thi_massage/controller/user_type_controller.dart';
import 'package:thi_massage/controller/web_socket_controller.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';

class ClientHomeController extends GetxController {
  // Reactive state variables
  var isProfileLoading = true.obs;
  var isLoading = true.obs; // For categories
  var profileData = Rxn<Map<String, dynamic>>();
  var categories = <Map<String, dynamic>>[].obs;
  var profileErrorMessage = Rxn<String>();
  var locationErrorMessage = Rxn<String>();
  var errorMessage = Rxn<String>();
  var hasNetworkError = false.obs;

  // Controllers
  final LocationController locationController = Get.find<LocationController>();
  final WebSocketController webSocketController = Get.find<WebSocketController>();
  final UserTypeController userController = Get.find<UserTypeController>();
  final NotificationSocketController notificationSocketController = Get.find<NotificationSocketController>();
  final ApiService apiService = ApiService();

  @override
  void onInit() {
    super.onInit();
    initializeApp();
  }

  Future<void> initializeApp() async {
    await requestLocationPermission();
    fetchMassageTypes();
    fetchClientProfile();
    await fetchAndUpdateLocation();
  }

  Future<void> requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationErrorMessage.value = 'Please turn on location services in your device settings to find nearby therapists.';
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        bool? requestPermission = await showLocationPermissionDialog();
        if (requestPermission != true) {
          locationErrorMessage.value = 'Location permission is required to find nearby therapists.';
          return;
        }
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        locationErrorMessage.value = 'Location permission denied.';
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        locationErrorMessage.value = 'Location permission permanently denied. Please enable it in settings.';
        await Geolocator.openAppSettings();
        return;
      }

      locationErrorMessage.value = null;
      AppLogger.debug('Location permission granted, fetching location');
      await fetchAndUpdateLocation();
    } catch (e) {
      AppLogger.error('Error checking/requesting location permission: $e');
      locationErrorMessage.value = 'Failed to request location permission: $e';
    }
  }

  Future<bool?> showLocationPermissionDialog() {
    return showDialog<bool>(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs access to your location to find nearby therapists. Please allow location access to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  Future<void> retryAll() async {
    isLoading.value = true;
    isProfileLoading.value = true;
    errorMessage.value = null;
    profileErrorMessage.value = null;
    locationErrorMessage.value = null;
    hasNetworkError.value = false;
    await requestLocationPermission();
    fetchMassageTypes();
    fetchClientProfile();
    await fetchAndUpdateLocation();
  }

  Future<void> retryCategories() async {
    isLoading.value = true;
    errorMessage.value = null;
    hasNetworkError.value = false;
    fetchMassageTypes();
  }

  Future<void> retryTherapists() async {
    locationErrorMessage.value = null;
    hasNetworkError.value = false;
    webSocketController.isTherapistsLoading.value = true;
    webSocketController.nearbyTherapists.clear();
    webSocketController.errorMessage.value = null;
    AppLogger.debug('Retrying therapists fetch');
    await fetchAndUpdateLocation();
  }

  Future<void> fetchAndUpdateLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        locationErrorMessage.value = permission == LocationPermission.denied
            ? 'Location permission denied.'
            : 'Location permission permanently denied. Please enable it in settings.';
        webSocketController.isTherapistsLoading.value = false;
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationErrorMessage.value = 'Please turn on location services in your device settings to find nearby therapists.';
        webSocketController.isTherapistsLoading.value = false;
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latitude = position.latitude;
      final longitude = position.longitude;
      final locationData = {'latitude': latitude, 'longitude': longitude};
      AppLogger.debug('Sending location to API: $locationData');

      await locationController.fetchCurrentLocation();
      if (locationController.hasError.value) {
        AppLogger.debug('LocationController has error, but proceeding with API call');
      }

      final response = await apiService.updateLocation(locationData);
      AppLogger.debug('Location API Response: $response');

      try {
        await webSocketController.reconnect().timeout(Duration(seconds: 10));
        AppLogger.debug('WebSocket reconnected, therapists: ${webSocketController.nearbyTherapists}');
      } on TimeoutException {
        AppLogger.error('WebSocket reconnect timed out');
        locationErrorMessage.value = 'Failed to fetch therapists: Connection timeout';
        webSocketController.isTherapistsLoading.value = false;
      }
    } on NetworkException catch (e) {
      AppLogger.error('Network error updating location: $e');
      locationErrorMessage.value = 'No internet connection. Please check your network.';
      hasNetworkError.value = true;
      webSocketController.isTherapistsLoading.value = false;
    } on BadRequestException catch (e) {
      AppLogger.error('Bad request updating location: $e');
      locationErrorMessage.value = 'Invalid location data: $e';
      webSocketController.isTherapistsLoading.value = false;
    } on UnauthorizedException catch (e) {
      AppLogger.error('Unauthorized location update: $e');
      locationErrorMessage.value = 'Authentication failed. Please log in again.';
      webSocketController.isTherapistsLoading.value = false;
    } catch (e) {
      AppLogger.error('Error updating location: $e');
      locationErrorMessage.value = 'Failed to update location: $e';
      webSocketController.isTherapistsLoading.value = false;
    }
  }

  Future<void> fetchMassageTypes() async {
    try {
      AppLogger.debug('Fetching massage types from ${ApiService.baseUrl}/api/massage-types');
      final massageTypes = await apiService.getMassageTypes();
      AppLogger.debug('Received massage types: $massageTypes');

      final massageTypesList = massageTypes as List<dynamic>;
      categories.value = massageTypesList
          .where((type) => type is Map<String, dynamic> && type['is_active'] == true)
          .map((type) {
        final typeMap = type as Map<String, dynamic>;
        return {
          'title': typeMap['name'] as String,
          'image': typeMap['image'].toString().startsWith('/media')
              ? '${ApiService.baseUrl}${typeMap['image']}'
              : typeMap['image'] as String,
        };
      }).toList();
      isLoading.value = false;
      errorMessage.value = null;
      hasNetworkError.value = false;
    } catch (e) {
      AppLogger.error('Failed to fetch massage types: $e');
      errorMessage.value = e.toString().contains('NetworkException')
          ? 'No internet connection. Please check your network.'
          : 'Failed to load categories. Please try again.';
      isLoading.value = false;
      if (e.toString().contains('NetworkException')) {
        hasNetworkError.value = true;
      }
    }
  }

  Future<void> fetchClientProfile() async {
    try {
      AppLogger.debug('Fetching client profile from ${ApiService.baseUrl}/api/client-profile');
      final data = await apiService.getClientProfile();
      AppLogger.debug('Received client profile: $data');

      await userController.setUserIds(
        clientId: data['user'] as int,
        role: 'client',
      );
      profileData.value = data;
      isProfileLoading.value = false;
      profileErrorMessage.value = null;
      hasNetworkError.value = false;
    } catch (e) {
      AppLogger.error('Failed to fetch client profile: $e');
      profileErrorMessage.value = e.toString().contains('NetworkException')
          ? 'No internet connection. Please check your network.'
          : 'Failed to load profile: $e';
      isProfileLoading.value = false;
      if (e.toString().contains('NetworkException')) {
        hasNetworkError.value = true;
      }
    }
  }

  String getFirstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'Guest';
    return fullName.trim().split(' ').first;
  }
}