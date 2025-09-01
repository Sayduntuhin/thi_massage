import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../api/api_service.dart';
import '../../../themes/colors.dart';
import '../../widgets/app_logger.dart';
import '../../../controller/user_type_controller.dart';
import '../../widgets/custom_appbar.dart';

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
  String _distance = ''; // Added distance field
  String _startLocation = '';
  String _endLocation = '';
  bool _isTherapist = false;
  Map<String, dynamic>? _navigationData;
  Timer? _refreshTimer; // Added timer for periodic updates

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _startPeriodicUpdates(); // Start periodic updates for live tracking
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Cancel timer when disposing
    super.dispose();
  }

  void _startPeriodicUpdates() {
    // Refresh every 30 seconds for live tracking
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isLoading && _errorMessage.isEmpty) {
        _refreshNavigationData();
      }
    });
  }

  Future<void> _refreshNavigationData() async {
    final arguments = Get.arguments;
    final bookingId = arguments?['booking_id'] as int?;

    if (bookingId != null) {
      try {
        final data = await _apiService.getNavigationData(bookingId, _isTherapist);
        setState(() {
          _updateNavigationData(data);
        });
        AppLogger.debug('Navigation data refreshed');
      } catch (e) {
        AppLogger.error('Failed to refresh navigation data: $e');
      }
    }
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
    _distance = route['distance'] ?? 'Unknown'; // Extract distance
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
    _sourceMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
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
        color: const Color(0xff4285F4), // Google Maps blue color
        width: 6,
        patterns: [],
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
        100,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecondaryAppBar(title:"Track order", showBackButton: true),
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



          // Distance and time info card (prominent like in the image)
          if (!_isLoading && _errorMessage.isEmpty)
            Positioned(
              top: 100.h,
              left: 16.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _distance,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      _estimatedTime,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Map control buttons
          Positioned(
            right: 16.w,
            top: 100.h,
            child: Column(
              children: [
                _buildMapControlButton(
                  heroTag: "refreshButton",
                  icon: Icons.refresh,
                  onPressed: _refreshNavigationData,
                ),
                SizedBox(height: 8.h),
                _buildMapControlButton(
                  heroTag: "mapTypeButton",
                  icon: _currentMapType == MapType.normal ? Icons.satellite_alt : Icons.map,
                  onPressed: _onMapTypeButtonPressed,
                ),
                SizedBox(height: 8.h),
                _buildMapControlButton(
                  heroTag: "trafficButton",
                  icon: Icons.traffic,
                  onPressed: _onTrafficButtonPressed,
                  isActive: _showTraffic,
                ),
                SizedBox(height: 8.h),
                _buildMapControlButton(
                  heroTag: "fitButton",
                  icon: Icons.fit_screen,
                  onPressed: _zoomToFitMarkers,
                ),
              ],
            ),
          ),

          // Navigate button
          Positioned(
            bottom: 280.h,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_initialPosition == const LatLng(0, 0) || _destinationPosition == const LatLng(0, 0)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid start or destination coordinates')),
                    );
                    return;
                  }

                  final String geoUrl =
                      'geo:${_initialPosition.latitude},${_initialPosition.longitude}'
                      '?q=${_destinationPosition.latitude},${_destinationPosition.longitude}';
                  final Uri url = Uri.parse(geoUrl);

                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    final String googleMapsUrl =
                        'https://www.google.com/maps/dir/?api=1'
                        '&origin=${_initialPosition.latitude},${_initialPosition.longitude}'
                        '&destination=${_destinationPosition.latitude},${_destinationPosition.longitude}'
                        '&travelmode=driving';
                    final Uri fallbackUrl = Uri.parse(googleMapsUrl);

                    if (await canLaunchUrl(fallbackUrl)) {
                      await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
                    } else {
                      AppLogger.error('Could not launch navigation');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open navigation app')),
                      );
                    }
                  }
                },
                icon: Icon(Icons.navigation, color: Colors.white),
                label: Text(
                  "Navigate",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4285F4),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
              ),
            ),
          ),

          // Person info card
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
                        radius: 24.r,
                        child: ClipOval(
                          child: _personImage != null
                              ? CachedNetworkImage(
                            imageUrl: _isTherapist
                                ? '${ApiService.baseUrl}/$_personImage'
                                : '${ApiService.baseUrl}/therapist$_personImage',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/images/fevTherapist1.png',
                              fit: BoxFit.cover,
                            ),
                          )
                              : Image.asset(
                            'assets/images/fevTherapist1.png',
                            fit: BoxFit.cover,
                          ),
                        ),
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
                            _isTherapist ? "client_id" : 'therapist_user_id' : _isTherapist ? _navigationData!['client']['id'] : _navigationData!['therapist']['id'],
                            _isTherapist ? "client_name" : 'name': _personName,
                            _isTherapist ? 'client_image' : 'image' : _isTherapist ? '${ApiService.baseUrl}/$_personImage' : '${ApiService.baseUrl}/therapist$_personImage',
                          });
                        },
                        child: SvgPicture.asset("assets/svg/chat_white.svg"),
                      ),
                      SizedBox(width: 12.w),
                    ],
                  ),
                ),
              ),
            ),

          // Route details bottom panel
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
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.my_location, color: Colors.white, size: 16),
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
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 25.h,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        Icon(Icons.location_on, color: Colors.red, size: 18),
                      ],
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Distance: $_distance",
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              Text(
                                "ETA: $_estimatedTime",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            _startLocation.isNotEmpty ? _startLocation.split(',')[0] : 'Unknown',
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            _endLocation.isNotEmpty ? _endLocation.split(',')[0] : 'Unknown',
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
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

  Widget _buildMapControlButton({
    required String heroTag,
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isActive ? primaryColor : Colors.grey[700],
          size: 18,
        ),
      ),
    );
  }
}