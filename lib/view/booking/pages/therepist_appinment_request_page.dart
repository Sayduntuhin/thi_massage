import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../../api/api_service.dart';
import '../../../controller/location_controller.dart';
import '../../../themes/colors.dart';
import '../../widgets/app_logger.dart';
import '../../widgets/custom_snackbar.dart';
import 'package:toastification/toastification.dart';
import '../../widgets/loading_indicator.dart'; // Added for LoadingManager

class AppointmentRequestPage extends StatefulWidget {
  const AppointmentRequestPage({super.key});

  @override
  State<AppointmentRequestPage> createState() => _AppointmentRequestPageState();
}

class _AppointmentRequestPageState extends State<AppointmentRequestPage> with SingleTickerProviderStateMixin {
  late bool _isAccepted = false;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  final Completer<GoogleMapController> _mapControllerCompleter = Completer<GoogleMapController>();
  LatLng _initialPosition = const LatLng(37.421998, -122.084); // Default fallback
  final Set<Marker> _markers = {};
  MapType _currentMapType = MapType.normal;
  bool _showTraffic = false;
  BitmapDescriptor? _customMarkerIcon;
  final ApiService _apiService = ApiService();
  final LocationController _locationController = Get.find<LocationController>();
  Map<String, dynamic>? _bookingDetails;
  bool _isLoading = true;
  String? _errorMessage;
  String? _locationName;
  final String _baseurl = ApiService.baseUrl; // Replace with your base URL

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _setCustomMarkerIcon();
    _fetchBookingDetails();
    AppLogger.debug('AppointmentRequestPage initialized');
  }

  Future<void> _fetchBookingDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final arguments = Get.arguments;
      final bookingId = arguments['booking_id'];
      if (bookingId == null) {
        throw Exception('Booking ID is missing');
      }
      AppLogger.debug('Fetching booking details for booking_id: $bookingId');
      final details = await _apiService.getBookingDetailsbByTherapist(bookingId);
      final latitude = details['map']?['latitude']?.toDouble();
      final longitude = details['map']?['longitude']?.toDouble();
      if (latitude == null || longitude == null) {
        throw Exception('Invalid location data in response');
      }
      final coords = '$latitude,$longitude';
      final address = await _locationController.getAddressFromCoordinatesString(coords);
      setState(() {
        _bookingDetails = details;
        _initialPosition = LatLng(latitude, longitude);
        _locationName = address;
        _isLoading = false;
        // Set progress animation based on duration_minutes
        final duration = (details['duration_minutes']?.toDouble() ?? 60) / 120;
        _progressAnimation = Tween<double>(begin: 0, end: duration).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
        );
        _progressController.forward(); // Start animation immediately
        _updateMarkers();
      });
      await _goToLocation(_initialPosition);
      AppLogger.debug('Booking details fetched: $details');
      AppLogger.debug('Location name: $address');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load booking details: $e';
      });
      CustomSnackBar.show(
        context,
        _errorMessage!,
        type: ToastificationType.error,
      );
      AppLogger.error('Error fetching booking details: $e');
    }
  }

  void _setCustomMarkerIcon() async {
    _customMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    if (_markers.isNotEmpty) {
      setState(() {
        _updateMarkers();
      });
    }
  }

  void _updateMarkers() {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('massage_location'),
        position: _initialPosition,
        infoWindow: InfoWindow(
          title: _locationName ?? 'Appointment Location',
          snippet: 'Massage Appointment Location',
        ),
        icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarker,
        onTap: () {
          _showLocationInfoDialog();
        },
      ),
    );
  }

  void _showLocationInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Appointment Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_locationName ?? 'Unknown Location'),
              SizedBox(height: 8.h),
              const Text('This is where your appointment will take place.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchNavigation();
              },
              child: const Text('Navigate'),
            ),
          ],
        );
      },
    );
  }

  void _launchNavigation() {
    Get.snackbar(
      'Navigation',
      'Launching navigation to ${_locationName ?? "appointment location"}...',
      snackPosition: SnackPosition.BOTTOM,
    );
    AppLogger.debug('Launching navigation to: $_initialPosition');
  }

  Future<void> _acceptAppointment() async {
    try {
      final bookingId = Get.arguments['booking_id'];
      if (bookingId == null) {
        throw Exception('Booking ID is missing');
      }
      LoadingManager.showLoading();
      AppLogger.debug('Accepting appointment for booking_id: $bookingId');
      final response = await _apiService.updateBookingStatus(bookingId, 'accepted');
      LoadingManager.hideLoading();
      if (response['message'] == 'Appointment accepted successfully.') {
        setState(() {
          _isAccepted = true;
        });
        CustomSnackBar.show(
          context,
          'Appointment accepted',
          type: ToastificationType.success,
        );
        AppLogger.debug('Appointment $bookingId accepted');
      } else {
        throw Exception('Unexpected response: ${response['message']}');
      }
    } catch (e) {
      LoadingManager.hideLoading();
      CustomSnackBar.show(
        context,
        'Failed to accept appointment: $e',
        type: ToastificationType.error,
      );
      AppLogger.error('Error accepting appointment: $e');
    }
  }

  Future<void> _rejectAppointment() async {
    try {
      final bookingId = Get.arguments['booking_id'];
      if (bookingId == null) {
        throw Exception('Booking ID is missing');
      }
      LoadingManager.showLoading();
      AppLogger.debug('Rejecting appointment for booking_id: $bookingId');
      final response = await _apiService.updateBookingStatus(bookingId, 'rejected');
      LoadingManager.hideLoading();
      if (response['message'] == 'Appointment rejected successfully.') {
        CustomSnackBar.show(
          context,
          'Appointment rejected',
          type: ToastificationType.info,
        );
        Get.back();
        AppLogger.debug('Appointment $bookingId rejected');
      } else {
        throw Exception('Unexpected response: ${response['message']}');
      }
    } catch (e) {
      LoadingManager.hideLoading();
      CustomSnackBar.show(
        context,
        'Failed to reject appointment: $e',
        type: ToastificationType.error,
      );
      AppLogger.error('Error rejecting appointment: $e');
    }
  }

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal ? MapType.satellite : MapType.normal;
    });
    AppLogger.debug('Map type changed to: $_currentMapType');
  }

  void _onTrafficButtonPressed() {
    setState(() {
      _showTraffic = !_showTraffic;
    });
    AppLogger.debug('Traffic layer toggled: $_showTraffic');
  }

  void _onMapCreated(GoogleMapController controller) {
    try {
      _mapControllerCompleter.complete(controller);
      AppLogger.debug('Google Map created successfully');
    } catch (e) {
      AppLogger.error('Error creating Google Map: $e');
      _showMapErrorDialog();
    }
  }

  void _showMapErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Map Error'),
          content: const Text('There was an error loading the map. Please check your API key configuration.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _goToLocation(LatLng position) async {
    try {
      final GoogleMapController controller = await _mapControllerCompleter.future;
      final CameraPosition newPosition = CameraPosition(
        target: position,
        zoom: 15,
        tilt: 50.0,
      );
      await controller.animateCamera(CameraUpdate.newCameraPosition(newPosition));
      AppLogger.debug('Map camera moved to: $position');
    } catch (e) {
      AppLogger.error('Error moving map camera: $e');
    }
  }

  String _formatSessionType(String? sessionType) {
    if (sessionType == null) return 'Single at Home';
    return sessionType.replaceAll('_', ' ');
  }

  @override
  void dispose() {
    _progressController.dispose();
    _mapControllerCompleter.future.then((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            height: 0.36.sh,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.png"),
                fit: BoxFit.fill,
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 16.h),
                  Text(
                    'Loading appointment details...',
                    style: TextStyle(fontSize: 16.sp, color: Colors.black54),
                  ),
                ],
              ),
            )
                : _errorMessage != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48.sp),
                  SizedBox(height: 16.h),
                  Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 16.sp, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: _fetchBookingDetails,
                    icon: const Icon(Icons.refresh),
                    label: Text('Retry', style: TextStyle(fontSize: 16.sp)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ],
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.035.sh),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 25.sp),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    _bookingDetails?['massage_type'] ?? 'Thai Massage',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 40.sp,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: "PlayfairDisplay",
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    _formatSessionType(_bookingDetails?['session_type']),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: "Urbanist",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              margin: EdgeInsets.only(left: 12.w, top: 8.h),
                              decoration: BoxDecoration(
                                color: const Color(0x668f5e0a),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(12.r),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          "assets/svg/calander.svg",
                                          height: 20.h,
                                          width: 20.w,
                                        ),
                                        SizedBox(width: 8.w),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Date Schedule",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              _bookingDetails?['date_scheduled'] ?? 'N/A',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          "assets/svg/time.svg",
                                          height: 20.h,
                                          width: 20.w,
                                        ),
                                        SizedBox(width: 8.w),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Time Scheduled",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              _bookingDetails?['time_scheduled'] ?? 'N/A',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.05.sh),
                      Text(
                        "Client",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: "Urbanist",
                        ),
                      ),
                      SizedBox(height: 0.01.sh),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24.r,
                            backgroundImage: _bookingDetails?['client']?['image'] != null
                                ? NetworkImage(
                                '$_baseurl/client${_bookingDetails!['client']['image']}')
                                : const AssetImage("assets/images/profilepic.png") as ImageProvider,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _bookingDetails?['client']?['name'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Icon(
                                      _bookingDetails?['client']?['gender'] == 'male'
                                          ? Icons.male
                                          : Icons.female,
                                      size: 16.sp,
                                      color: _bookingDetails?['client']?['gender'] == 'male'
                                          ? Colors.blue
                                          : Colors.purple,
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 14.sp),
                                    SizedBox(width: 2.w),
                                    Text(
                                      _bookingDetails?['client']?['is_returning'] == true
                                          ? 'Returning Customer'
                                          : 'New Customer',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _isAccepted
                              ? GestureDetector(
                            onTap: () {
                              Get.toNamed("/chatDetailsPage",
                                arguments: {
                                  'client_id': _bookingDetails?['client']?['client_id'],
                                  'client_name': _bookingDetails?['client']?['name'] ?? 'Unknown',
                                  'client_image': _bookingDetails?['client']?['image'] != null
                                      ? '$_baseurl/client${_bookingDetails!['client']['image']}'
                                      : null,
                                },
                              );
                            },
                            child: SvgPicture.asset(
                              "assets/svg/chat.svg",
                              height: 40.h,
                              width: 40.w,
                              colorFilter: ColorFilter.mode(
                                primaryColor,
                                BlendMode.srcIn,
                              ),
                            ),
                          )
                              : Row(
                            children: [
                              GestureDetector(
                                onTap: _acceptAppointment,
                                child: _statusButton(
                                  "Accept",
                                  const Color(0xFFCBF299),
                                  const Color(0xff33993A),
                                  const Color(0xFFCBF299),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              GestureDetector(
                                onTap: _rejectAppointment,
                                child: _statusButton(
                                  "Reject",
                                  Colors.transparent,
                                  Colors.red,
                                  Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 0.01.sh),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Get.toNamed(
                      "/customerPreferencesPage",
                      arguments: {'preferences': _bookingDetails?['preferences']},
                    );
                  },
                  child: Container(
                    height: 0.05.sh,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5.r)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 16.w),
                          child: Text(
                            "Customer Preferences",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 16.w),
                          child: Icon(Icons.arrow_forward_ios, size: 20.sp, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Get.toNamed('/liveTrackingPage',arguments: {
                                'booking_id': Get.arguments['booking_id'],
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 10.h),
                              height: 150.h,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(50),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16.r),
                                child: Stack(
                                  children: [
                                    GoogleMap(
                                      onMapCreated: _onMapCreated,
                                      initialCameraPosition: CameraPosition(
                                        target: _initialPosition,
                                        zoom: 15,
                                      ),
                                      markers: _markers,
                                      myLocationEnabled: false,
                                      zoomControlsEnabled: false,
                                      mapToolbarEnabled: false,
                                      trafficEnabled: _showTraffic,
                                      mapType: _currentMapType,
                                      onTap: (LatLng position) {
                                        AppLogger.debug('Map tapped at: $position');
                                      },
                                    ),
                                    Positioned(
                                      right: 10.w,
                                      top: 10.h,
                                      child: Column(
                                        children: [
                                          FloatingActionButton(
                                            heroTag: "mapTypeButton",
                                            mini: true,
                                            backgroundColor: Colors.white,
                                            onPressed: _onMapTypeButtonPressed,
                                            child: Icon(
                                              _currentMapType == MapType.normal
                                                  ? Icons.satellite_alt
                                                  : Icons.map,
                                              color: primaryColor,
                                              size: 18.sp,
                                            ),
                                          ),
                                          SizedBox(height: 5.h),
                                          FloatingActionButton(
                                            heroTag: "trafficButton",
                                            mini: true,
                                            backgroundColor: Colors.white,
                                            onPressed: _onTrafficButtonPressed,
                                            child: Icon(
                                              Icons.traffic,
                                              color: _showTraffic ? primaryColor : Colors.grey,
                                              size: 18.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      right: 10.w,
                                      bottom: 10.h,
                                      child: FloatingActionButton(
                                        heroTag: "zoomButton",
                                        mini: true,
                                        backgroundColor: Colors.white,
                                        onPressed: () => _goToLocation(_initialPosition),
                                        child: Icon(
                                          Icons.center_focus_strong,
                                          color: primaryColor,
                                          size: 18.sp,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 10.h,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                                        margin: EdgeInsets.symmetric(horizontal: 40.w),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20.r),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(50),
                                              blurRadius: 5,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          _locationName ?? 'Loading location...',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Duration",
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "${_bookingDetails?['duration_minutes'] ?? 60} min",
                                    style: TextStyle(
                                      color: primaryTextColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, child) {
                                  return Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6.r),
                                        child: LinearProgressIndicator(
                                          value: _progressAnimation.value,
                                          backgroundColor: Colors.grey.shade200,
                                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                          minHeight: 10.h,
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "0 min",
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          Text(
                                            "120 min",
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Container(
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: const Color(0xffFFFDF5),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: const Color(0xffF3E1B9)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _locationRow("Venue", _bookingDetails?['location']?['venue'] ?? 'Unknown'),
                                _locationRow(
                                  "Number of floors",
                                  _bookingDetails?['location']?['number_of_floors']?.toString() ?? 'N/A',
                                ),
                                _locationRow(
                                  "Elevator/Escalator",
                                  _bookingDetails?['location']?['elevator_or_escalator'] == true ? 'Yes' : 'No',
                                ),
                                _locationRow(
                                  "Massage table",
                                  _bookingDetails?['location']?['massage_table'] == true ? 'Yes' : 'No',
                                ),
                                _locationRow(
                                  "Parking",
                                  _bookingDetails?['location']?['parking'] ?? 'None',
                                ),
                                _locationRow(
                                  "Pet",
                                  _bookingDetails?['location']?['pet'] == true ? 'Yes' : 'No',
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusButton(String label, Color color, Color textColor, Color borderColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _locationRow(String key, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}