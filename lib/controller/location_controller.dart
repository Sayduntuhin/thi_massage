import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../view/widgets/app_logger.dart';

class LocationController extends GetxController {
  var locationName = 'Your location...'.obs;
  var isLoading = true.obs;
  var hasError = false.obs;
  var position = Rxn<Position>(); // Store Position object
  var lastUpdated = Rxn<DateTime>(); // Track when location was last updated

  // Cache for geocoded addresses to avoid redundant API calls
  final Map<String, String> _addressCache = {};

  // Check if cached location is valid (e.g., not older than 5 minutes)
  bool get hasValidLocation {
    if (position.value == null || lastUpdated.value == null) return false;
    final age = DateTime.now().difference(lastUpdated.value!);
    return age.inMinutes < 5; // Consider location valid if less than 5 minutes old
  }

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
      Position newPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      AppLogger.debug('Current position: ${newPosition.latitude}, ${newPosition.longitude}');

      // Update stored position and timestamp
      position.value = newPosition;
      lastUpdated.value = DateTime.now();

      // Reverse geocode
      List<Placemark> placemarks = await placemarkFromCoordinates(
        newPosition.latitude,
        newPosition.longitude,
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

  /// Converts a coordinate string (e.g., "37.421998, -122.084000") to a readable address
  Future<String> getAddressFromCoordinatesString(String coordinateString) async {
    // Check cache first
    if (_addressCache.containsKey(coordinateString)) {
      AppLogger.debug('Returning cached address for $coordinateString: ${_addressCache[coordinateString]}');
      return _addressCache[coordinateString]!;
    }

    try {
      // Parse the coordinate string
      final coords = coordinateString.split(',').map((e) => e.trim()).toList();
      if (coords.length != 2) {
        AppLogger.error('Invalid coordinate format: $coordinateString');
        return 'Invalid address';
      }

      final latitude = double.tryParse(coords[0]);
      final longitude = double.tryParse(coords[1]);
      if (latitude == null || longitude == null) {
        AppLogger.error('Failed to parse coordinates: $coordinateString');
        return 'Invalid address';
      }

      // Reverse geocode
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String address = [
          placemark.street,
          placemark.locality,
          placemark.administrativeArea,
          placemark.postalCode,
          placemark.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        final result = address.isNotEmpty ? address : 'Unknown location';
        _addressCache[coordinateString] = result; // Cache the result
        AppLogger.debug('Geocoded address for $coordinateString: $result');
        return result;
      } else {
        AppLogger.error('No placemarks found for $coordinateString');
        return 'Unknown location';
      }
    } catch (e) {
      AppLogger.error('Error geocoding coordinates $coordinateString: $e');
      return 'Failed to get address';
    }
  }
}