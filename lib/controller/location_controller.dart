import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../view/widgets/app_logger.dart';

class LocationController extends GetxController {
  var locationName = 'Your location...'.obs;
  var isLoading = true.obs;
  var hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCurrentLocation();
  }

  Future<void> fetchCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationName.value = 'Location services disabled';
        hasError.value = true;
        isLoading.value = false;
        AppLogger.error('Location services are disabled');
        return;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          locationName.value = 'Location permission denied';
          hasError.value = true;
          isLoading.value = false;
          AppLogger.error('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        locationName.value = 'Location permission permanently denied';
        hasError.value = true;
        isLoading.value = false;
        AppLogger.error('Location permission permanently denied');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      AppLogger.debug('Current position: ${position.latitude}, ${position.longitude}');

      // Reverse geocode
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String address = [
          placemark.street,
          placemark.locality,
          placemark.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        locationName.value = address.isNotEmpty ? address : 'Unknown location';
        AppLogger.debug('Location name: $address');
      } else {
        locationName.value = 'Unknown location';
        hasError.value = true;
        AppLogger.error('No placemarks found');
      }
    } catch (e) {
      locationName.value = 'Failed to get location';
      hasError.value = true;
      AppLogger.error('Error fetching location: $e');
      if (e.toString().contains('MissingPluginException')) {
        AppLogger.error('Geolocator plugin not initialized. Try rebuilding the app.');
      }
    } finally {
      isLoading.value = false;
    }
  }
}