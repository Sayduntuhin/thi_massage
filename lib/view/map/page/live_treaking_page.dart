import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../api/api_service.dart';
import '../../../themes/colors.dart';
import '../../widgets/app_logger.dart';
import '../../../controller/user_type_controller.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer<GoogleMapController>();
  LatLng _initialPosition = const LatLng(0, 0);
  LatLng _destinationPosition = const LatLng(0, 0);
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  MapType _currentMapType = MapType.normal;
  bool _showTraffic = false;
  BitmapDescriptor? _sourceMarkerIcon;
  BitmapDescriptor? _destinationMarkerIcon;
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _errorMessage = '';
  String _personName = '';
  String _personRole = '';
  String? _personImage;
  String _estimatedTime = '';
  String _startLocation = '';
  String _endLocation = '';
  bool _isTherapist = false;
  Map<String, dynamic>? _navigationData;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    final arguments = Get.arguments;
    if (arguments != null) {
      AppLogger.debug('LiveTrackingScreen arguments: $arguments');
    } else {
      AppLogger.debug('LiveTrackingScreen received no arguments');
      setState(() {
        _isLoading = false;
        _errorMessage = 'No booking ID provided';
      });
      return;
    }

    try {
      final userTypeController = Get.find<UserTypeController>();
      _isTherapist = userTypeController.isTherapist.value;
      AppLogger.debug('User Type: ${userTypeController.role.value.isNotEmpty ? userTypeController.role.value : (_isTherapist ? 'therapist' : 'client')}');
      AppLogger.debug('Client ID: ${userTypeController.clientId.value}');
      AppLogger.debug('Therapist ID: ${userTypeController.therapistId.value}');
      AppLogger.debug('Has Selected User Type: ${userTypeController.hasSelectedUserType.value}');
    } catch (e) {
      AppLogger.error('Error accessing UserTypeController: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'User type not available';
      });
      return;
    }

    final bookingId = arguments['booking_id'] as int?;
    if (bookingId != null) {
      try {
        final data = await _apiService.getNavigationData(bookingId, _isTherapist);
        setState(() {
          _updateNavigationData(data);
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        AppLogger.error('Failed to fetch navigation data: $e');
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No booking ID provided';
      });
      AppLogger.error('No booking ID provided in arguments');
    }

    _setCustomMarkerIcons();
    AppLogger.debug('LiveTrackingScreen initialized');
  }

  void _updateNavigationData(Map<String, dynamic> data) {
    _navigationData = data;

    if (_isTherapist) {
      final client = data['client'] as Map<String, dynamic>;
      _personName = client['name'] ?? 'Unknown Client';
      _personRole = 'Client';
      _personImage = client['image'];
    } else {
      final therapist = data['therapist'] as Map<String, dynamic>;
      _personName = therapist['name'] ?? 'Unknown Therapist';
      _personRole = therapist['role'] ?? 'Therapist';
      _personImage = therapist['image'];
    }

    final route = data['route'] as Map<String, dynamic>;
    _estimatedTime = route['estimated_time'] ?? 'Unknown';
    _startLocation = route['start_location'] ?? 'Unknown';
    _endLocation = route['end_location'] ?? 'Unknown';
    _initialPosition = LatLng(
      (route['start_coords']['lat'] as num?)?.toDouble() ?? 0.0,
      (route['start_coords']['lng'] as num?)?.toDouble() ?? 0.0,
    );
    _destinationPosition = LatLng(
      (route['end_coords']['lat'] as num?)?.toDouble() ?? 0.0,
      (route['end_coords']['lng'] as num?)?.toDouble() ?? 0.0,
    );

    _setMarkersAndPolylines();
  }

  void _setCustomMarkerIcons() async {
    _sourceMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    _destinationMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    if (_markers.isNotEmpty) {
      setState(() {
        _setMarkersAndPolylines();
      });
    }
  }

  void _setMarkersAndPolylines() {
    _markers.clear();
    _polylines.clear();

    _markers.add(
      Marker(
        markerId: const MarkerId('source_location'),
        position: _initialPosition,
        infoWindow: InfoWindow(
          title: _startLocation.isNotEmpty ? _startLocation.split(',')[0] : 'Start',
          snippet: 'Starting location',
        ),
        icon: _sourceMarkerIcon ?? BitmapDescriptor.defaultMarker,
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('destination_location'),
        position: _destinationPosition,
        infoWindow: InfoWindow(
          title: _endLocation.isNotEmpty ? _endLocation.split(',')[0] : 'Destination',
          snippet: 'Destination',
        ),
        icon: _destinationMarkerIcon ?? BitmapDescriptor.defaultMarker,
      ),
    );

    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_initialPosition, _destinationPosition],
        color: const Color(0xffB48D3C),
        width: 5,
        patterns: [
          PatternItem.dash(20),
          PatternItem.gap(10),
        ],
      ),
    );

    if (_initialPosition != const LatLng(0, 0) && _destinationPosition != const LatLng(0, 0)) {
      _zoomToFitMarkers();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    try {
      _mapControllerCompleter.complete(controller);
      AppLogger.debug('Google Map created successfully');
      if (!_isLoading && _errorMessage.isEmpty) {
        _zoomToFitMarkers();
      }
    } catch (e) {
      AppLogger.error('Error creating Google Map: $e');
    }
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

  Future<void> _goToLocation(LatLng position) async {
    final GoogleMapController controller = await _mapControllerCompleter.future;
    final CameraPosition newPosition = CameraPosition(
      target: position,
      zoom: 15,
    );
    await controller.animateCamera(CameraUpdate.newCameraPosition(newPosition));
  }

  Future<void> _zoomToFitMarkers() async {
    final GoogleMapController controller = await _mapControllerCompleter.future;

    double minLat = _initialPosition.latitude < _destinationPosition.latitude
        ? _initialPosition.latitude
        : _destinationPosition.latitude;
    double maxLat = _initialPosition.latitude > _destinationPosition.latitude
        ? _initialPosition.latitude
        : _destinationPosition.latitude;
    double minLng = _initialPosition.longitude < _destinationPosition.longitude
        ? _initialPosition.longitude
        : _destinationPosition.longitude;
    double maxLng = _initialPosition.longitude > _destinationPosition.longitude
        ? _initialPosition.longitude
        : _destinationPosition.longitude;

    minLat -= 0.01;
    maxLat += 0.01;
    minLng -= 0.01;
    maxLng += 0.01;

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(child: Text('Error: $_errorMessage'))
                : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 13,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              trafficEnabled: _showTraffic,
              mapType: _currentMapType,
              onTap: (LatLng position) {
                AppLogger.debug('Map tapped at: $position');
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Container(
                width: 30.w,
                height: 35.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5.r)],
                ),
                child: IconButton(
                  onPressed: Get.back,
                  icon: Icon(Icons.arrow_back_ios, color: primaryColor, size: 18),
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 100,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "mapTypeButton",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _onMapTypeButtonPressed,
                  child: Icon(
                    _currentMapType == MapType.normal ? Icons.satellite_alt : Icons.map,
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
                SizedBox(height: 5.h),
                FloatingActionButton(
                  heroTag: "fitButton",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _zoomToFitMarkers,
                  child: Icon(
                    Icons.fit_screen,
                    color: primaryColor,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 280.h,
            left: 0,
            right: 0.2.sh,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.navigation, color: primaryTextColor),
                label: Text(
                  "Navigate",
                  style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                ),
              ),
            ),
          ),
          if (!_isLoading && _errorMessage.isEmpty)
            Positioned(
              bottom: 150.h,
              left: 0,
              right: 0,
              child: Container(
                height: 0.12.sh,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFB28D28),
                      Color(0xFF8F5E0A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5.r)],
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: 0.02.sh),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundImage: _personImage != null
                            ? _isTherapist ? NetworkImage('${ApiService.baseUrl}/$_personImage') : NetworkImage('${ApiService.baseUrl}/therapist$_personImage')
                            : const AssetImage('assets/images/fevTherapist1.png') as ImageProvider,
                        radius: 24.r,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _personName,
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(width: 4.w),
                                SvgPicture.asset("assets/svg/male.svg"),
                              ],
                            ),
                            Text(
                              _personRole,
                              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {

                          Get.toNamed('/chatDetailsPage', arguments: {
                            _isTherapist ? "client_id" :'therapist_user_id' : _isTherapist ? _navigationData!['client']['id'] : _navigationData!['therapist']['id'],
                            _isTherapist ? "client_name" : 'name': _personName,
                            _isTherapist ? 'client_image' : 'image' : _isTherapist ? '${ApiService.baseUrl}/${_personImage}' :  NetworkImage('${ApiService.baseUrl}/therapist$_personImage'),
                          }

                          );

                        },
                        child: SvgPicture.asset("assets/svg/chat_white.svg"),
                      ),
                      SizedBox(width: 12.w),
                      GestureDetector(
                        onTap: () {
                          // Implement phone call using phone number
                        },
                        child: SvgPicture.asset("assets/svg/phone.svg"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!_isLoading && _errorMessage.isEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 30.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5.r)],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.access_time, color: Colors.white, size: 16),
                        ),
                        Container(
                          width: 2,
                          height: 40.h,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 25.h,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        Icon(Icons.location_on, color: Colors.black, size: 18),
                      ],
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Estimated time",
                            style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                          ),
                          Text(
                            _estimatedTime,
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 14.h),
                          Text(
                            _startLocation.isNotEmpty ? _startLocation.split(',')[0] : 'Unknown',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            _endLocation.isNotEmpty ? _endLocation.split(',')[0] : 'Unknown',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mapPin(String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Text(label, style: TextStyle(fontSize: 12.sp)),
        ),
        Icon(Icons.location_pin, color: const Color(0xffB48D3C), size: 28.sp),
      ],
    );
  }

  Widget _destinationPin(String label) {
    return Column(
      children: [
        Icon(Icons.location_on, color: const Color(0xffB48D3C), size: 30.sp),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Text(label, style: TextStyle(fontSize: 12.sp)),
        ),
      ],
    );
  }
}