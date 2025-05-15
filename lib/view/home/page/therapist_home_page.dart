import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../../api/api_service.dart';
import '../../../controller/location_controller.dart';
import '../../../themes/colors.dart';
import '../widgets/appointment_card.dart';
import '../widgets/notificaton_bell.dart';
import '../widgets/online_offline_toggle.dart';
import '../../widgets/app_logger.dart';
import '../../widgets/custom_snackbar.dart';
import 'package:toastification/toastification.dart';
import '../widgets/shimmer_loading_for_therapist_home.dart';

class TherapistHomePage extends StatefulWidget {
  const TherapistHomePage({super.key});

  @override
  State<TherapistHomePage> createState() => _TherapistHomePageState();
}

class _TherapistHomePageState extends State<TherapistHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _mainScreenSlideAnimation;
  late Animation<double> _mainScreenScaleAnimation;
  bool _isDrawerOpen = false;
  double _dragStartX = 0;
  final ApiService _apiService = ApiService();
  final LocationController _locationController = Get.put(LocationController());
  Map<String, dynamic>? _therapistProfile;
  bool _isLoading = true;
  String? _errorMessage;
  String? _locationErrorMessage;
  List<Map<String, dynamic>> _upcomingAppointments = [];
  bool _isAppointmentsLoading = true;
  String? _appointmentsErrorMessage;
  List<Map<String, dynamic>> _appointmentRequests = [];
  bool _isAppointmentRequestsLoading = true;
  String? _appointmentRequestsErrorMessage;
  Map<String, String> _geocodedAddresses = {};
  bool _isUpdatingAvailability = false;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _mainScreenSlideAnimation = Tween<double>(begin: 0.0, end: 250.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _mainScreenScaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _fetchTherapistProfile();
    await _requestLocationPermission();
    await _fetchLocation();
    await _fetchUpcomingAppointments();
    await _fetchAppointmentRequests();
  }

  Future<void> _fetchTherapistProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await _apiService.getTherapistOwnProfile();
      setState(() {
        _therapistProfile = profile;
        _isLoading = false;
      });
      AppLogger.debug('Therapist Profile: $profile');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load profile: $e';
      });
      CustomSnackBar.show(context, _errorMessage!, type: ToastificationType.error);
      AppLogger.error('Failed to fetch therapist profile: $e');
    }
  }

  Future<void> _fetchUpcomingAppointments() async {
    setState(() {
      _isAppointmentsLoading = true;
      _appointmentsErrorMessage = null;
      _geocodedAddresses.clear();
    });
    try {
      final appointments = await _apiService.getUpcomingAppointments();
      for (var appointment in appointments) {
        final address = appointment['address']?.toString() ?? 'N/A';
        if (address != 'N/A' && !_geocodedAddresses.containsKey(address)) {
          final geocodedAddress =
          await _locationController.getAddressFromCoordinatesString(address);
          _geocodedAddresses[address] = geocodedAddress;
        }
      }
      setState(() {
        _upcomingAppointments = appointments;
        _isAppointmentsLoading = false;
      });
      AppLogger.debug('Upcoming Appointments: $appointments');
      AppLogger.debug('Geocoded Addresses: $_geocodedAddresses');
    } catch (e) {
      setState(() {
        _isAppointmentsLoading = false;
        _appointmentsErrorMessage = 'Failed to load appointments: $e';
      });
      CustomSnackBar.show(context, _appointmentsErrorMessage!, type: ToastificationType.error);
      AppLogger.error('Failed to fetch upcoming appointments: $e');
    }
  }

  Future<void> _fetchAppointmentRequests() async {
    setState(() {
      _isAppointmentRequestsLoading = true;
      _appointmentRequestsErrorMessage = null;
    });
    try {
      final requests = await _apiService.getAppointmentRequests();
      setState(() {
        _appointmentRequests = requests;
        _isAppointmentRequestsLoading = false;
      });
      AppLogger.debug('Appointment Requests: $requests');
    } catch (e) {
      setState(() {
        _isAppointmentRequestsLoading = false;
        _appointmentRequestsErrorMessage = 'Failed to load appointment requests: $e';
      });
      CustomSnackBar.show(context, _appointmentRequestsErrorMessage!, type: ToastificationType.error);
      AppLogger.error('Failed to fetch appointment requests: $e');
    }
  }

  Future<void> _updateAvailability(bool isOnline) async {
    setState(() {
      _isUpdatingAvailability = true;
    });
    try {
      await _apiService.updateTherapistAvailability(isOnline);
      setState(() {
        _therapistProfile?['availability'] = isOnline;
        _isUpdatingAvailability = false;
      });
      CustomSnackBar.show(
        context,
        'You are now ${isOnline ? "Online" : "Offline"}',
        type: isOnline ? ToastificationType.success : ToastificationType.error,
      );
      AppLogger.debug('Therapist availability updated to: $isOnline');
    } catch (e) {
      setState(() {
        _isUpdatingAvailability = false;
      });
      CustomSnackBar.show(
        context,
        'Failed to update availability: $e',
        type: ToastificationType.error,
      );
      AppLogger.error('Failed to update availability: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationErrorMessage = 'Please turn on location services in your device settings.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        bool? requestPermission = await _showLocationPermissionDialog();
        if (requestPermission != true) {
          setState(() {
            _locationErrorMessage = 'Location permission is required to display your location.';
          });
          return;
        }
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _locationErrorMessage = 'Location permission denied.';
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationErrorMessage = 'Location permission permanently denied. Please enable it in settings.';
        });
        await Geolocator.openAppSettings();
        return;
      }

      setState(() {
        _locationErrorMessage = null;
      });
      AppLogger.debug('Location permission granted');
    } catch (e) {
      AppLogger.error('Error checking/requesting location permission: $e');
      setState(() {
        _locationErrorMessage = 'Failed to request location permission: $e';
      });
    }
  }

  Future<bool?> _showLocationPermissionDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs access to your location to display your current location. Please allow location access to continue.',
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

  Future<void> _fetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationErrorMessage = permission == LocationPermission.denied
              ? 'Location permission denied.'
              : 'Location permission permanently denied. Please enable it in settings.';
        });
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationErrorMessage = 'Please turn on location services in your device settings.';
        });
        return;
      }

      // Fetch location directly with Geolocator
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latitude = position.latitude;
      final longitude = position.longitude;
      final locationData = {'latitude': latitude, 'longitude': longitude};

      // Update location name for display
      await _locationController.fetchCurrentLocation();
      if (_locationController.hasError.value) {
        AppLogger.debug('LocationController has error, but proceeding with API call');
      }

      try {
        await _apiService.updateLocation(locationData);
        setState(() {
          _therapistProfile?['latitude'] = latitude.toString();
          _therapistProfile?['longitude'] = longitude.toString();
          _locationErrorMessage = null;
        });
        AppLogger.debug('Profile updated with latitude: $latitude, longitude: $longitude');
      } catch (e) {
        setState(() {
          _locationErrorMessage = 'Failed to update location in profile: $e';
        });
        CustomSnackBar.show(
          context,
          _locationErrorMessage!,
          type: ToastificationType.error,
        );
        AppLogger.error('Failed to update profile location: $e');
      }
    } catch (e) {
      AppLogger.error('Error fetching location: $e');
      setState(() {
        _locationErrorMessage = 'Failed to fetch location: $e';
      });
    }
  }

  void toggleDrawer() {
    if (_isDrawerOpen) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    _isDrawerOpen = !_isDrawerOpen;
  }

  Map<String, String> _parseDate(String dateStr) {
    try {
      final cleanedDate = dateStr.replaceAll(',', '');
      final parts = cleanedDate.split(' ');
      if (parts.length != 3) {
        throw Exception('Invalid date format: $dateStr');
      }
      final day = parts[0];
      final month = parts[1];
      final year = parts[2];
      return {
        'day': day,
        'month': month,
        'year': year,
      };
    } catch (e) {
      AppLogger.error('Failed to parse date: $dateStr, error: $e');
      final now = DateTime.now();
      return {
        'day': now.day.toString(),
        'month': _monthName(now.month),
        'year': now.year.toString(),
      };
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onHorizontalDragStart: (details) => _dragStartX = details.globalPosition.dx,
        onHorizontalDragUpdate: (details) {
          double delta = details.globalPosition.dx - _dragStartX;
          if (delta > 0 && !_isDrawerOpen) {
            _animationController.value = (delta / 250).clamp(0.0, 1.0);
          } else if (delta < 0 && _isDrawerOpen) {
            _animationController.value = 1.0 + (delta / 250).clamp(-1.0, 0.0);
          }
        },
        onHorizontalDragEnd: (_) {
          if (_animationController.value > 0.5) {
            _animationController.forward();
            _isDrawerOpen = true;
          } else {
            _animationController.reverse();
            _isDrawerOpen = false;
          }
        },
        child: Stack(
          children: [
            // Drawer Layer
            Container(
              color: const Color(0xFFB28D28),
              padding: EdgeInsets.only(left: 24.w, top: 70.h, right: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: _therapistProfile?['image'] != null
                        ? NetworkImage(_therapistProfile!['image'])
                        : const AssetImage("assets/images/profilepic.png") as ImageProvider,
                    radius: 40.r,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    _therapistProfile?['full_name'] ?? 'Therapist Name',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    _therapistProfile?['assign_role'] ?? 'Massage Therapist',
                    style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                  ),
                  SizedBox(height: 30.h),
                  _buildDrawerItem(Icons.calendar_today, "Availability Settings"),
                  _buildDrawerItem(Icons.settings, "App Settings"),
                  _buildDrawerItem(Icons.privacy_tip, "Terms & Privacy Policy"),
                  _buildDrawerItem(Icons.star_rate, "Reviews & Ratings"),
                  _buildDrawerItem(Icons.support_agent, "Contact Support"),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Get.offAllNamed('/welcome');
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: GestureDetector(
                        onTap: () async {
                          await _storage.delete(key: 'user_id');
                          await _storage.delete(key: 'access_token');
                          Get.offAllNamed('/login');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout, color: Colors.red, size: 18.sp),
                            SizedBox(width: 8.w),
                            Text("Log out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
            // Main Screen
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_mainScreenSlideAnimation.value, 0),
                  child: Transform.scale(
                    scale: _mainScreenScaleAnimation.value,
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(_animationController.value * 25.r),
                        bottomLeft: Radius.circular(_animationController.value * 25.r),
                      ),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height,
                        child: Container(
                          color: Colors.white,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: SafeArea(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: _isLoading
                                    ? Center(
                                  child: SizedBox(
                                    height: MediaQuery.of(context).size.height - 100.h,
                                    child: const Center(child: CircularProgressIndicator()),
                                  ),
                                )
                                    : _errorMessage != null
                                    ? Center(
                                  child: SizedBox(
                                    height: MediaQuery.of(context).size.height - 100.h,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _errorMessage!,
                                          style: TextStyle(fontSize: 14.sp, color: Colors.red),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 10.h),
                                        ElevatedButton.icon(
                                          onPressed: _fetchTherapistProfile,
                                          icon: const Icon(Icons.refresh),
                                          label: Text(
                                            'Retry',
                                            style: TextStyle(fontSize: 14.sp),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10.r),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                    : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: toggleDrawer,
                                          child: Container(
                                            width: 30.w,
                                            height: 30.h,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8.r),
                                              border: Border.all(color: secounderyBorderColor.withAlpha(80)),
                                            ),
                                            child: Icon(
                                              Icons.menu,
                                              size: 24.sp,
                                              color: secounderyBorderColor,
                                            ),
                                          ),
                                        ),
                                        Image.asset("assets/images/logo.png", width: 0.4.sw),
                                        SizedBox(width: 20.w),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        CircleAvatar(
                                          radius: 35.r,
                                          backgroundImage: _therapistProfile?['image'] != null
                                              ? NetworkImage(_therapistProfile!['image'])
                                              : const AssetImage("assets/images/profilepic.png")
                                          as ImageProvider,
                                        ),
                                        NotificationBell(
                                          notificationCount: 1,
                                          svgAssetPath: 'assets/svg/notificationIcon.svg',
                                          navigateTo: "/notificationsPage",
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10.h),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  "Hello ${_therapistProfile?['full_name']?.split(' ')[0] ?? 'Therapist'}",
                                                  style: TextStyle(
                                                    fontSize: 30.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: primaryTextColor,
                                                  ),
                                                ),
                                                SizedBox(width: 0.15.sw),
                                                _isUpdatingAvailability
                                                    ? SizedBox(
                                                  width: 24.w,
                                                  height: 24.h,
                                                  child: CircularProgressIndicator(strokeWidth: 2.w),
                                                )
                                                    : OnlineOfflineToggle(
                                                  initialOnline:
                                                  _therapistProfile?['availability'] ?? false,
                                                  onChanged: (isOnline) async {
                                                    await _updateAvailability(isOnline);
                                                  },
                                                ),
                                              ],
                                            ),
                                            Text(
                                              _therapistProfile?['assign_role'] ?? 'Massage Therapist',
                                              style: TextStyle(fontSize: 14.sp, color: Colors.black26),
                                            ),
                                            Row(
                                              children: [
                                                Icon(Icons.location_on,
                                                    color: const Color(0xffA0A0A0), size: 18.sp),
                                                SizedBox(width: 4.w),
                                                Obx(() => SizedBox(
                                                  width: 0.8.sw,
                                                  height: 20.h,
                                                  child: Text(
                                                    _locationErrorMessage ??
                                                        _locationController.locationName.value,
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      fontWeight: FontWeight.w400,
                                                      color: const Color(0xffA0A0A0),
                                                      fontFamily: "Urbanist",
                                                    ),
                                                  ),
                                                )),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (_locationErrorMessage != null) ...[
                                      SizedBox(height: 10.h),
                                      Center(
                                        child: ElevatedButton.icon(
                                          onPressed: _locationErrorMessage!.contains('location services')
                                              ? () async {
                                            await Geolocator.openLocationSettings();
                                            await _requestLocationPermission();
                                            await _fetchLocation();
                                          }
                                              : _fetchLocation,
                                          icon: const Icon(Icons.refresh),
                                          label: Text(
                                            _locationErrorMessage!.contains('location services')
                                                ? 'Open Location Settings'
                                                : 'Retry',
                                            style: TextStyle(fontSize: 14.sp),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10.r),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: 20.h),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _statItem(
                                          _therapistProfile?['total_sessions']?.toString() ?? '0',
                                          "Sessions",
                                        ),
                                        _statItem(
                                          "\$${_therapistProfile?['total_earning'] ?? '0.00'}",
                                          "Earning",
                                        ),
                                        _statItem(
                                          _therapistProfile?['total_booked']?.toString() ?? '0',
                                          "Booked",
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20.h),
                                    _sectionHeader("Upcoming Appointments", onTap: () {}),
                                    SizedBox(
                                      height: 0.14.sh,
                                      child: _isAppointmentsLoading
                                          ? ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: 3,
                                        itemBuilder: (context, index) => const AppointmentCardShimmer(),
                                      )
                                          : _appointmentsErrorMessage != null
                                          ? Center(
                                        child: Column(
                                          children: [
                                            Text(
                                              _appointmentsErrorMessage!,
                                              style: TextStyle(fontSize: 14.sp, color: Colors.red),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: 10.h),
                                            ElevatedButton.icon(
                                              onPressed: _fetchUpcomingAppointments,
                                              icon: const Icon(Icons.refresh),
                                              label: Text(
                                                'Retry',
                                                style: TextStyle(fontSize: 14.sp),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 20.w, vertical: 10.h),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10.r),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                          : _upcomingAppointments.isEmpty
                                          ? Center(
                                        child: Text(
                                          'No upcoming appointments',
                                          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                          : ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _upcomingAppointments.length,
                                        itemBuilder: (context, index) {
                                          final appointment = _upcomingAppointments[index];
                                          final rawAddress =
                                              appointment['address']?.toString() ?? 'N/A';
                                          final geocodedAddress =
                                              _geocodedAddresses[rawAddress] ?? rawAddress;
                                          return appointmentCard(
                                            name: appointment['client_name'] ?? 'Unknown',
                                            date: appointment['date'] ?? 'N/A',
                                            time: appointment['time'] ?? 'N/A',
                                            service: appointment['specility'] ?? 'N/A',
                                            location: geocodedAddress,
                                            distance: appointment['distance'].toString(),
                                            isMale: appointment['client_gender'] == 'male',
                                            clientImage: appointment['client_image'],
                                          );
                                        },
                                      ),
                                    ),
                                    _sectionHeader("Appointment Requests", onTap: () {}),
                                    _isAppointmentRequestsLoading
                                        ? ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: 2,
                                      itemBuilder: (context, index) =>
                                      const AppointmentRequestCardShimmer(),
                                    )
                                        : _appointmentRequestsErrorMessage != null
                                        ? Center(
                                      child: Column(
                                        children: [
                                          Text(
                                            _appointmentRequestsErrorMessage!,
                                            style: TextStyle(fontSize: 14.sp, color: Colors.red),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 10.h),
                                          ElevatedButton.icon(
                                            onPressed: _fetchAppointmentRequests,
                                            icon: const Icon(Icons.refresh),
                                            label: Text(
                                              'Retry',
                                              style: TextStyle(fontSize: 14.sp),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 20.w, vertical: 10.h),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10.r),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                        : _appointmentRequests.isEmpty
                                        ? Center(
                                      child: Text(
                                        'No appointment requests',
                                        style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                        : ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _appointmentRequests.length,
                                      itemBuilder: (context, index) {
                                        final request = _appointmentRequests[index];
                                        final dateParts = _parseDate(request['date'] ?? 'N/A');
                                        return _appointmentRequestCard(
                                          index: index, // Pass the index parameter
                                          name: request['client_name'] ?? 'Unknown',
                                          service: request['specility'] ?? 'N/A',
                                          day: dateParts['day']!,
                                          month: dateParts['month']!,
                                          year: dateParts['year']!,
                                          time: request['time'] ?? 'N/A',
                                          isFemale: request['client_gender'] != 'male',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.bold, color: primaryTextColor),
        ),
        Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.black54)),
      ],
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
          if (onTap != null)
            GestureDetector(
              onTap: onTap,
              child: Text("see all", style: TextStyle(fontSize: 14.sp, color: primaryTextColor)),
            ),
        ],
      ),
    );
  }

  Widget _appointmentRequestCard({
    required int index, // Add index parameter
    required String name,
    required String service,
    required String day,
    required String month,
    required String year,
    required String time,
    bool isFemale = false,
  }) {
    final request = _appointmentRequests[index]; // Use the passed index
    return GestureDetector(
      onTap: () {
        Get.toNamed('/appointmentRequestPage', arguments: {
          'booking_id': request['Booking_id'], // Pass booking_id
          'client_name': request['client_name'] ?? 'Unknown',
          'client_image': request['client_image'],
          'client_gender': request['client_gender'] ?? 'male',
        });
        AppLogger.debug('Navigating to appointmentRequestPage with booking_id: ${request['id']}');
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            Container(
              height: 0.1.sh,
              width: 0.18.sw,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFB28D28),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  bottomLeft: Radius.circular(12.r),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(month, style: TextStyle(fontSize: 14.sp, color: Colors.white)),
                  Text(year, style: TextStyle(fontSize: 10.sp, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: Container(
                height: 0.1.sh,
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12.r),
                    bottomRight: Radius.circular(12.r),
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(2, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service,
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16.sp, color: Colors.black45),
                            SizedBox(width: 4.w),
                            Text(time, style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 0.2.sw,
                              height: 0.02.sh,
                              child: Text(
                                overflow: TextOverflow.ellipsis,
                                name,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              isFemale ? Icons.female : Icons.male,
                              color: isFemale ? Colors.purple : Colors.blue,
                              size: 16.sp,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _statusButton(
                              "Accept",
                              const Color(0xFFCBF299),
                              const Color(0xff33993A),
                              const Color(0xFFCBF299),
                            ),
                            SizedBox(width: 6.w),
                            _statusButton("Reject", Colors.transparent, Colors.red, Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusButton(String label, Color color, Color textcolor, Color borderColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(color: textcolor, fontSize: 12.sp, fontWeight: FontWeight.w500),
      ),
    );
  }
  Widget _buildDrawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 20.sp),
      title: Text(title, style: TextStyle(color: Colors.white, fontSize: 14.sp)),
      contentPadding: EdgeInsets.zero,
      onTap: () {
        toggleDrawer();
      },
    );
  }
}