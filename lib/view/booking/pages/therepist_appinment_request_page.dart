import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../../themes/colors.dart';
import '../../widgets/app_logger.dart'; // Add this import

class AppointmentRequestPage extends StatefulWidget {
  const AppointmentRequestPage({super.key});

  @override
  State<AppointmentRequestPage> createState() => _AppointmentRequestPageState();
}

class _AppointmentRequestPageState extends State<AppointmentRequestPage> with SingleTickerProviderStateMixin {
  bool _isAccepted = false;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  final Completer<GoogleMapController> _mapControllerCompleter = Completer<GoogleMapController>();
  final LatLng _initialPosition = const LatLng(37.42796133580664, -122.085749655962);
  final Set<Marker> _markers = {};
  MapType _currentMapType = MapType.normal;
  bool _showTraffic = false;
  BitmapDescriptor? _customMarkerIcon;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0.6).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _setCustomMarkerIcon();
    _setInitialMarker();
    AppLogger.debug('AppointmentRequestPage initialized');
  }

  void _setCustomMarkerIcon() async {
    _customMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    if (_markers.isNotEmpty) {
      setState(() {
        _updateMarkers();
      });
    }
  }

  void _setInitialMarker() {
    _markers.add(
      Marker(
        markerId: const MarkerId('massage_location'),
        position: _initialPosition,
        infoWindow: const InfoWindow(
          title: 'Hamill Ave',
          snippet: 'Massage Appointment Location',
        ),
        icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarker,
        onTap: () {
          _showLocationInfoDialog();
        },
      ),
    );
  }

  void _updateMarkers() {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('massage_location'),
        position: _initialPosition,
        infoWindow: const InfoWindow(
          title: 'Hamill Ave',
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
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hamill Ave'),
              SizedBox(height: 8),
              Text('This is where your appointment will take place.'),
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
      'Launching navigation to Hamill Ave...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _mapControllerCompleter.future.then((controller) => controller.dispose());
    super.dispose();
  }

  void _acceptAppointment() {
    setState(() {
      _isAccepted = true;
    });
    _progressController.forward();
  }

  void _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal ? MapType.satellite : MapType.normal;
    });
  }

  void _onTrafficButtonPressed() {
    setState(() {
      _showTraffic = !_showTraffic;
    });
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
    final GoogleMapController controller = await _mapControllerCompleter.future;
    final CameraPosition newPosition = CameraPosition(
      target: position,
      zoom: 18,
      tilt: 50.0,
    );
    await controller.animateCamera(CameraUpdate.newCameraPosition(newPosition));
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
            child: Column(
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
                      SizedBox(
                        width: 0.45.sw,
                        child: Text(
                          "Thai Massage",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: "PlayfairDisplay",
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 0.45.sw,
                        child: Text(
                          "Single at Home",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            fontFamily: "Urbanist",
                          ),
                        ),
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
                            backgroundImage: const AssetImage("assets/images/profilepic.png"),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Mike Milan",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Icon(Icons.male, size: 16.sp, color: Colors.blue),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 14.sp),
                                    SizedBox(width: 2.w),
                                    Text(
                                      "4.2 (200+) Past Customer",
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
                              Get.toNamed("/chatDetailsPage");
                            },
                            child: SvgPicture.asset(
                              "assets/svg/chat.svg",
                              height: 40.h,
                              width: 40.w,
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
                              _statusButton("Reject", Colors.transparent, Colors.red, Colors.red),
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
                    Get.toNamed("/customerPreferencesPage");
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
                              Get.toNamed('/liveTrackingPage');
                            },
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 10.h),
                              height: 150.h,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
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
                                      right: 10,
                                      top: 10,
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
                                              size: 18,
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
                                              size: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      right: 10,
                                      bottom: 10,
                                      child: FloatingActionButton(
                                        heroTag: "zoomButton",
                                        mini: true,
                                        backgroundColor: Colors.white,
                                        onPressed: () => _goToLocation(_initialPosition),
                                        child: Icon(
                                          Icons.center_focus_strong,
                                          color: primaryColor,
                                          size: 18,
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
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 5,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          "Hamill Ave",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
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
                                  Text("Duration", style: TextStyle(fontSize: 14.sp)),
                                  Text(
                                    "60 min",
                                    style: TextStyle(
                                      color: primaryTextColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13.sp,
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
                                        borderRadius: BorderRadius.circular(4.r),
                                        child: LinearProgressIndicator(
                                          value: _progressAnimation.value,
                                          backgroundColor: Colors.grey.shade300,
                                          valueColor: AlwaysStoppedAnimation<Color>(primaryTextColor),
                                          minHeight: 10.h,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("0 min", style: TextStyle(fontSize: 12.sp)),
                                          Text("120 min", style: TextStyle(fontSize: 12.sp)),
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
                                _locationRow("Venue", "House"),
                                _locationRow("Number of floors", "2"),
                                _locationRow("Elevator/Escalator", "NO"),
                                _locationRow("Massage table", "NO"),
                                _locationRow("Parking", "Yes. Street Parking"),
                                _locationRow("Pet", "Yes. Cat"),
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
          Positioned(
            bottom: .72.sh,
            left: 0.55.sw,
            right: 0.08.sw,
            top: 0.165.sh,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x668f5e0a),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(15.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          "assets/svg/calander.svg",
                          height: 25.h,
                          width: 25.w,
                        ),
                        SizedBox(width: 5.w),
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
                              "20 July, 2024",
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
                    SizedBox(height: 5.h),
                    Row(
                      children: [
                        SvgPicture.asset(
                          "assets/svg/time.svg",
                          height: 25.h,
                          width: 25.w,
                        ),
                        SizedBox(width: 5.w),
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
                              "11:00 am",
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

  Widget _locationRow(String key, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: TextStyle(fontSize: 13.sp, color: Colors.black54)),
          Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}