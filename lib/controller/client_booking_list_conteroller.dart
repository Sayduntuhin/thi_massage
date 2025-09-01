import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:thi_massage/api/api_service.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';
import 'package:thi_massage/view/widgets/custom_snackbar.dart';
import 'package:toastification/toastification.dart';

class BookingsController extends GetxController {
  // Reactive state variables
  var selectedTab = "All".obs;
  var bookings = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  final ApiService apiService = ApiService();

  @override
  void onInit() {
    super.onInit();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    isLoading.value = true;

    try {
      final response = await apiService.getBookings();
      AppLogger.debug("Raw bookings response (count: ${response.length}): $response");

      bookings.value = response.asMap().entries.map((entry) {
        final index = entry.key;
        final booking = entry.value;

        if (booking['id'] == null || booking['status'] == null) {
          AppLogger.error("Invalid booking at index $index: $booking");
          return null;
        }

        DateTime dateTime;
        try {
          dateTime = DateTime.parse(booking['date_time'] ?? '1970-01-01T00:00:00Z');
        } catch (e) {
          AppLogger.error("Failed to parse date_time for booking ${booking['id']}: $e");
          dateTime = DateTime.now();
        }

        final status = booking['status'];
        final uiStatus = status == 'complete'
            ? 'Completed'
            : status == 'pending'
            ? 'Pending'
            : status == 'cancelled'
            ? 'Cancelled'
            : 'Upcoming';

        AppLogger.debug("Booking ID: ${booking['id']}, Status: $status, Mapped to: $uiStatus");

        return {
          'id': booking['id'],
          'date': DateFormat('dd MMM').format(dateTime),
          'year': DateFormat('yyyy').format(dateTime),
          'time': DateFormat('hh:mm a').format(dateTime),
          'title': booking['name']?.toString() ?? 'Massage',
          'therapist': booking['therapist_full_name']?.toString() ?? 'Unknown',
          'therapist_id': booking['therapist_user_id'] ?? 0,
          'status': uiStatus,
        };
      }).where((booking) => booking != null).cast<Map<String, dynamic>>().toList();

      AppLogger.debug("Mapped bookings (count: ${bookings.length}): $bookings");
    } catch (e) {
      String errorMessage = "Failed to fetch bookings. Please try again.";
      if (e is BadRequestException) {
        errorMessage = e.message;
      } else if (e is NetworkException) {
        errorMessage = "No internet connection.";
      } else if (e is UnauthorizedException) {
        errorMessage = "Authentication failed. Please log in again.";
        Get.offAllNamed('/login');
      }
      CustomSnackBar.show(Get.context!, errorMessage, type: ToastificationType.error);
      AppLogger.error("Fetch bookings error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void setSelectedTab(String tab) {
    selectedTab.value = tab;
  }

  List<Map<String, dynamic>> get filteredBookings {
    if (selectedTab.value == "All") {
      return bookings;
    } else if (selectedTab.value == "Completed") {
      return bookings.where((b) => b['status'] == "Completed").toList();
    } else if (selectedTab.value == "Pending") {
      return bookings.where((b) => b['status'] == "Pending").toList();
    } else if (selectedTab.value == "Upcoming") {
      return bookings.where((b) => b['status'] == "Upcoming").toList();
    } else if (selectedTab.value == "Cancelled") {
      return bookings.where((b) => b['status'] == "Cancelled").toList();
    }
    return [];
  }
}