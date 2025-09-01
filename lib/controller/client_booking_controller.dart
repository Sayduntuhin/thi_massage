import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:thi_massage/api/api_service.dart';
import 'package:thi_massage/controller/location_controller.dart';
import 'package:thi_massage/models/therapist_model.dart';
import 'package:thi_massage/view/widgets/custom_snackbar.dart';
import 'package:thi_massage/view/widgets/loading_indicator.dart';
import 'package:thi_massage/routers/app_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:toastification/toastification.dart';
import 'package:thi_massage/controller/coustomer_preferences_controller.dart';

import '../view/widgets/payment_options_sheet.dart';

class ClientBookingController extends GetxController {
  final ApiService apiService = ApiService();
  final LocationController locationController = Get.find<LocationController>();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final CustomerPreferencesController preferencesController =
  Get.find<CustomerPreferencesController>();

  // State variables
  var selectedMessageType = 'Swedish Massage'.obs;
  var hasOwnMassageTable = false.obs;
  var ageRange = const RangeValues(18, 40).obs;
  var selectedDuration = '60 min'.obs;
  var numberOfPeople = 1.obs;
  var isBackToBack = false.obs;
  var location = 'Home'.obs;
  var selectedTherapist = Rx<Therapist?>(null);
  var selectedDateTime = Rx<DateTime?>(null);
  var isScheduleSelected = false.obs;
  var elevatorSelection = Rx<String?>(null);
  var petsSelection = Rx<String?>(null);
  var parkingSelection = Rx<String?>(null);
  var numberOfFloors = ''.obs;
  var selectedAddOns = <String>[].obs;
  var isLoading = false.obs;
  var errorMessage = Rx<String?>(null);
  var messageTypes = <Map<String, dynamic>>[].obs;
  var customerAddress = ''.obs;
  var customerPhoneNumber = ''.obs;
  var providerGenderPreference = 'Any Available'.obs;
  Logger _logger = Logger();

  // Duration options based on number of people
  List<String> get availableDurations {
    if (numberOfPeople.value >= 3) {
      return ['30 min', '45 min', '60 min', '90 min', '120 min'];
    }
    return ['60 min', '90 min', '120 min'];
  }

  // Predefined time slots
  static const List<String> timeSlots = [
    '7:00 AM - 9:00 AM',
    '9:00 AM - 11:00 AM',
    '11:00 AM - 1:00 PM',
    '1:00 PM - 3:00 PM',
    '3:00 PM - 5:00 PM',
    '5:00 PM - 7:00 PM',
    '7:00 PM - 9:00 PM',
    '9:00 PM - 11:00 PM',
  ];

  // Add-ons list as a constant
  static const List<String> addOnsList = [
    'Hot Stone',
    'Aromatherapy Oil',
    'CBD Oil',
    'Scalp & Head Massage',
    'Foot Reflexology',
    'Herbal Compress',
    'Back Walking',
    'Pregnancy Bolster Setup',
    'Foot Soak',
  ];

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments?['therapist'] != null) {
      try {
        selectedTherapist.value = Therapist.fromJson(arguments!['therapist']);
        final therapistRole = arguments['therapist']['role'] as String? ?? 'Swedish Massage';
        fetchMassageTypes(therapistRole: therapistRole);
      } catch (e) {
        errorMessage.value = 'Failed to load therapist data: $e';
      }
    } else {
      fetchMassageTypes();
    }
  }

  Future<void> fetchMassageTypes({String? therapistRole}) async {
    try {
      final massageTypes = await apiService.getMassageTypes();
      final filteredTypes = massageTypes
          .where((type) => type['is_active'] == true)
          .map((type) => <String, dynamic>{
        'title': type['name'] as String,
        'image': type['image'].startsWith('/media') || type['image'].startsWith('/client/media')
            ? '${ApiService.baseUrl}${type['image']}'
            : type['image'] as String,
      })
          .toList();
      messageTypes.value = filteredTypes;
      selectedMessageType.value = therapistRole != null
          ? filteredTypes.firstWhere(
            (type) => type['title'].toLowerCase().contains(therapistRole.toLowerCase()),
        orElse: () => filteredTypes.isNotEmpty
            ? filteredTypes[0]
            : {'title': 'Swedish Massage', 'image': '${ApiService.baseUrl}/media/documents/default2.jpg'},
      )['title'] as String
          : (filteredTypes.isNotEmpty ? filteredTypes[0]['title'] as String : 'Swedish Massage');
    } catch (e) {
      errorMessage.value = e.toString();
      if (e is NetworkException) {
        errorMessage.value = 'Network error: Please check your internet connection.';
      } else if (e is UnauthorizedException) {
        errorMessage.value = 'Authentication failed: Please log in again.';
      } else if (e is ServerException) {
        errorMessage.value = 'Server error: Please try again later.';
      }
      messageTypes.value = [
        {'title': 'Swedish Massage', 'image': '${ApiService.baseUrl}/media/documents/default2.jpg'},
      ];
      if (therapistRole != null &&
          !messageTypes.value.any((type) => type['title'].toLowerCase().contains(therapistRole.toLowerCase()))) {
        messageTypes.value
            .add({'title': therapistRole, 'image': '${ApiService.baseUrl}/media/documents/default2.jpg'});
        selectedMessageType.value = therapistRole;
      } else if (messageTypes.value.isNotEmpty) {
        selectedMessageType.value = messageTypes.value[0]['title'] as String;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createBooking() async {
    isLoading.value = true;
    LoadingManager.showLoading();

    if (selectedTherapist.value == null ||
        (isScheduleSelected.value && selectedDateTime.value == null)) {
      LoadingManager.hideLoading();
      CustomSnackBar.show(Get.context!,
          'Please select a therapist and date/time for scheduled appointments',
          type: ToastificationType.error);
      isLoading.value = false;
      return;
    }

    if (customerAddress.value.isEmpty || customerPhoneNumber.value.isEmpty) {
      LoadingManager.hideLoading();
      CustomSnackBar.show(Get.context!,
          'Please provide customer address and phone number',
          type: ToastificationType.error);
      isLoading.value = false;
      return;
    }

    double? latitude;
    double? longitude;
    try {
      if (locationController.hasValidLocation && locationController.position.value != null) {
        latitude = double.parse(locationController.position.value!.latitude.toStringAsFixed(6));
        longitude = double.parse(locationController.position.value!.longitude.toStringAsFixed(6));
      } else {
        await locationController.fetchCurrentLocation();
        if (!locationController.hasError.value && locationController.position.value != null) {
          latitude = double.parse(locationController.position.value!.latitude.toStringAsFixed(6));
          longitude = double.parse(locationController.position.value!.longitude.toStringAsFixed(6));
        } else {
          LoadingManager.hideLoading();
          CustomSnackBar.show(Get.context!, 'Failed to get location: ${locationController.locationName.value}',
              type: ToastificationType.error);
          isLoading.value = false;
          return;
        }
      }
    } catch (e) {
      LoadingManager.hideLoading();
      CustomSnackBar.show(Get.context!, 'Failed to get location: $e', type: ToastificationType.error);
      isLoading.value = false;
      return;
    }

    final userId = await _storage.read(key: 'user_id');
    if (userId == null) {
      LoadingManager.hideLoading();
      CustomSnackBar.show(Get.context!, 'Please log in to create a booking', type: ToastificationType.error);
      isLoading.value = false;
      return;
    }

    final selectedMessage = messageTypes.value.firstWhere(
          (message) => message['title'] == selectedMessageType.value,
      orElse: () => {'title': 'Swedish Massage', 'image': '${ApiService.baseUrl}/media/documents/default2.jpg'},
    );

    final now = DateTime.now();
    final createdAt =
    isScheduleSelected.value && selectedDateTime.value != null ? selectedDateTime.value! : now.add(Duration(minutes: 30));
    final dateTime = isScheduleSelected.value && selectedDateTime.value != null ? selectedDateTime.value! : now;

    final massageTypeMap = messageTypes.value.asMap().map(
          (_, type) => MapEntry(
        type['title'],
        type['title'].toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^\w_]'), ''),
      ),
    );

    final preferencePayload = {
      if (preferencesController.getAllPreferences()['Preferred Modality']?.isNotEmpty ?? false)
        'preferred_modality': preferencesController.getAllPreferences()['Preferred Modality'],
      if (preferencesController.getAllPreferences()['Preferred Pressure']?.isNotEmpty ?? false)
        'preferred_pressure': preferencesController.getAllPreferences()['Preferred Pressure'],
      if (preferencesController.getAllPreferences()['Reasons for Massage']?.isNotEmpty ?? false)
        'reason_for_massage': preferencesController.getAllPreferences()['Reasons for Massage'],
      if (preferencesController.getAllPreferences()['Moisturizer Preferences']?.isNotEmpty ?? false)
        'moisturizer': preferencesController.getAllPreferences()['Moisturizer Preferences'],
      if (preferencesController.getAllPreferences()['Music Preference']?.isNotEmpty ?? false)
        'music_preference': preferencesController.getAllPreferences()['Music Preference'],
      if (preferencesController.getAllPreferences()['Conversation Preferences']?.isNotEmpty ?? false)
        'conversation_preference': preferencesController.getAllPreferences()['Conversation Preferences'],
      if (preferencesController.getAllPreferences()['Pregnancy (Female customers)']?.isNotEmpty ?? false)
        'pregnancy': preferencesController.getAllPreferences()['Pregnancy (Female customers)'],
    };

    final payload = {
      'name': selectedMessageType.value,
      'age_range_start': ageRange.value.start.round(),
      'age_range_end': ageRange.value.end.round(),
      'massage_preference': isBackToBack.value ? 'back_to_back' : 'single',
      'number_of_people': numberOfPeople.value,
      'duration': int.parse(selectedDuration.value.split(' ')[0]),
      'date_time': dateTime.toUtc().toIso8601String(),
      'location_type': location.value.toLowerCase(),
      'number_of_floors': int.tryParse(numberOfFloors.value) ?? 0,
      'elevator_or_escalator': elevatorSelection.value == 'Yes',
      'parking_type': parkingSelection.value ?? 'None',
      'any_pets': petsSelection.value == 'Yes',
      'massage_type': massageTypeMap[selectedMessageType.value] ?? 'swedish_massage',
      'instant_appointment': !isScheduleSelected.value,
      'created_at': createdAt.toUtc().toIso8601String(),
      'user': int.parse(userId),
      'therapist_input_user_id': selectedTherapist.value!.user,
      'have_own_massage_table': hasOwnMassageTable.value,
      'latitude': latitude,
      'longitude': longitude,
      'customer_address': customerAddress.value,
      'customer_phone_number': customerPhoneNumber.value,
      'provider_gender_preference': providerGenderPreference.value,
      ...preferencePayload,
      'addons': selectedAddOns.toList(),
    };
    try {
      final response = await apiService.createBooking(payload);
      preferencesController.clearPreferences();
      CustomSnackBar.show(Get.context!, 'Booking created successfully!', type: ToastificationType.success);
      await Future.delayed(const Duration(milliseconds: 500));
      LoadingManager.hideLoading();

      PaymentOptionsSheet.show(
        Get.context!,
        creditCardRoute: Routes.appointmentPaymentPage,
        arguments: {
          'image': selectedMessage['image'],
          'name': selectedMessage['title'],
          'dateTime': selectedDateTime.value?.toIso8601String(),
          'elevator': elevatorSelection.value,
          'parking': parkingSelection.value,
          'pets': petsSelection.value,
          'preferences': preferencesController.getAllPreferences(),
          'booking_id': response['id'],
          'therapist_user_id': selectedTherapist.value!.user,
          'therapist_name': selectedTherapist.value!.name,
        },
      );
    } catch (e) {
      LoadingManager.hideLoading();
      String errorMessage = 'An unexpected error occurred';

      _logger.d('Caught exception: $e, Type: ${e.runtimeType}, Message: ${e.toString()}');

      if (e is BadRequestException) {
        _logger.d('BadRequestException message: ${e.message}');
        try {
          final errorBody = jsonDecode(e.message) as Map<String, dynamic>?;
          _logger.d('Decoded error body: $errorBody');
          if (errorBody != null && errorBody.containsKey('error') && errorBody['error'] is String) {
            errorMessage = errorBody['error'];
          } else if (errorBody != null && errorBody.containsKey('age_range') && errorBody['age_range'] is List && errorBody['age_range'].isNotEmpty) {
            errorMessage = errorBody['age_range'][0];
          } else if (errorBody != null && errorBody.isNotEmpty) {
            errorMessage = errorBody.entries.first.value is List
                ? errorBody.entries.first.value[0]
                : errorBody.entries.first.value.toString();
          }
        } catch (parseError) {
          _logger.e('Failed to parse error response: $parseError, Raw message: ${e.message}');
        }
      } else if (e is NetworkException) {
        errorMessage = 'No internet connection. Please check your network and try again';
      } else if (e.toString().contains('Ensure that there are no more than 6 decimal places')) {
        errorMessage = 'Location coordinates are too precise. Please try again';
      } else if (e is UnauthorizedException || e is ForbiddenException) {
        errorMessage = 'Authentication failed. Please log in again';
      } else if (e is ServerException) {
        errorMessage = 'Server error. Please try again later';
      }

      _logger.d('Final error message to show: $errorMessage');
      CustomSnackBar.show(Get.context!, errorMessage, type: ToastificationType.error);
    } finally {
      isLoading.value = false;
    }
  }
}