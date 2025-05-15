import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

import '../../../themes/colors.dart';
import '../../widgets/app_logger.dart'; // Add this import

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer<GoogleMapController>();
  final LatLng _initialPosition = const LatLng(37.42796133580664, -122.085749655962);
  final LatLng _destinationPosition = const LatLng(37.43796133580664, -122.075749655962); // San Diego position
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  MapType _currentMapType = MapType.normal;
  bool _showTraffic = false;
  BitmapDescriptor? _sourceMarkerIcon;
  BitmapDescriptor? _destinationMarkerIcon;

  @override
  void initState() {
    super.initState();
    _setCustomMarkerIcons();
    _setMarkersAndPolylines();
    AppLogger.debug('LiveTrackingScreen initialized');
  }

  void _setCustomMarkerIcons() async {
    _sourceMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    _destinationMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    if (_markers.isNotEmpty) {
      setState(() {
        _updateMarkers();
      });
    }
  }

  void _setMarkersAndPolylines() {
    // Add source marker
    _markers.add(
      Marker(
        markerId: const MarkerId('source_location'),
        position: _initialPosition,
        infoWindow: const InfoWindow(
          title: 'Hamill Ave',
          snippet: 'Your starting location',
        ),
        icon: _sourceMarkerIcon ?? BitmapDescriptor.defaultMarker,
      ),
    );

    // Add destination marker
    _markers.add(
      Marker(
        markerId: const MarkerId('destination_location'),
        position: _destinationPosition,
        infoWindow: const InfoWindow(
          title: 'San Diego',
          snippet: 'Your destination',
        ),
        icon: _destinationMarkerIcon ?? BitmapDescriptor.defaultMarker,
      ),
    );

    // Add a polyline between source and destination
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
  }

  void _updateMarkers() {
    _markers.clear();
    _setMarkersAndPolylines();
  }

  void _onMapCreated(GoogleMapController controller) {
    try {
      _mapControllerCompleter.complete(controller);
      AppLogger.debug('Google Map created successfully');
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

  // Show both markers in the camera view
  Future<void> _zoomToFitMarkers() async {
    final GoogleMapController controller = await _mapControllerCompleter.future;

    // Calculate bounds that include both markers
    double minLat = _initialPosition.latitude < _destinationPosition.latitude
        ? _initialPosition.latitude : _destinationPosition.latitude;
    double maxLat = _initialPosition.latitude > _destinationPosition.latitude
        ? _initialPosition.latitude : _destinationPosition.latitude;
    double minLng = _initialPosition.longitude < _destinationPosition.longitude
        ? _initialPosition.longitude : _destinationPosition.longitude;
    double maxLng = _initialPosition.longitude > _destinationPosition.longitude
        ? _initialPosition.longitude : _destinationPosition.longitude;

    // Add some padding
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
        50, // Padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Full-screen map
          SizedBox.expand(
            child: GoogleMap(
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

          /// Back button
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
                      icon: Icon(Icons.arrow_back_ios, color: primaryColor, size: 18)
                  )
              ),
            ),
          ),

          /// Map control buttons
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


          /// Navigate button
          Positioned(
            bottom: 280.h,
            left: 0,
            right: 0.2.sh,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.navigation, color: primaryTextColor),
                label: Text("Navigate", style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                ),
              ),
            ),
          ),

          /// Bottom Therapist Card
          Positioned(
            bottom: 150.h,
            left: 0,
            right: 0,
            child: Container(
              height: 0.12.sh,
              padding: EdgeInsets.symmetric(horizontal: 16.w,),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFB28D28), // Gradient start color
                    Color(0xFF8F5E0A), // Gradient end color
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
                      backgroundImage: AssetImage('assets/images/fevTherapist1.png'),
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
                              Text("Mical Martinez", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              SizedBox(width: 4.w),
                              SvgPicture.asset("assets/svg/male.svg"),
                            ],
                          ),
                          Text("Thai Massage Therapist", style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                        ],
                      ),
                    ),
                    SvgPicture.asset("assets/svg/chat_white.svg"),
                    SizedBox(width: 12.w),
                    SvgPicture.asset("assets/svg/phone.svg"),
                  ],
                ),
              ),
            ),
          ),

          /// Bottom Info Card
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
                  // Left side - timeline with dots
                  Column(
                    children: [
                      // Top dot (Estimated time)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.access_time, color: Colors.white, size: 16),
                      ),
                      // Line connecting dots
                      Container(
                        width: 2,
                        height: 40.h,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      // Middle dot (starting point)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                      // Line connecting dots
                      Container(
                        width: 2,
                        height: 25.h,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      // Bottom triangle (destination)
                      Icon(Icons.location_on, color: Colors.black, size: 18),
                    ],
                  ),

                  SizedBox(width: 16.w),

                  // Right side - text information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Estimated time
                        Text("Estimated time", style: TextStyle(fontSize: 13.sp, color: Colors.grey)),
                        Text("28 min", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),

                        SizedBox(height: 14.h),

                        // Starting point
                        Text("Hamill Ave", style: TextStyle(fontSize: 14.sp)),

                        SizedBox(height: 20.h),

                        // Destination
                        Text("San Diego", style: TextStyle(fontSize: 14.sp)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
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
        Icon(Icons.location_pin, color: Color(0xffB48D3C), size: 28.sp),
      ],
    );
  }

  Widget _destinationPin(String label) {
    return Column(
      children: [
        Icon(Icons.location_on, color: Color(0xffB48D3C), size: 30.sp),
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