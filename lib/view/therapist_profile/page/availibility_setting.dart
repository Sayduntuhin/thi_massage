import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../../../api/api_service.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_logger.dart';

class AvailabilitySettingsPage extends StatefulWidget {
  const AvailabilitySettingsPage({super.key});

  @override
  State<AvailabilitySettingsPage> createState() => _AvailabilitySettingsPageState();
}

class _AvailabilitySettingsPageState extends State<AvailabilitySettingsPage>
    with SingleTickerProviderStateMixin {
  bool isAvailable = false;
  String selectedFilter = 'Monday';
  TimeOfDay startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = TimeOfDay(hour: 17, minute: 0);
  bool isEditing = false;
  late AnimationController _animationController;
  late Animation<double> _mainScreenSlideAnimation;
  late Animation<double> _mainScreenScaleAnimation;
  bool _isDrawerOpen = false;
  double _dragStartX = 0;
  Map<String, dynamic>? _therapistProfile;
  bool _isLoadingProfile = true;
  String? _profileErrorMessage;
  bool _isLoadingWorkingHours = true;
  String? _workingHoursErrorMessage;
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  String? _selectedDrawerItem;

  @override
  void initState() {
    super.initState();
    // Set selectedFilter to current day
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    selectedFilter = days[now.weekday - 1]; // Today is Saturday, May 17, 2025
    _selectedDrawerItem = "Availability Settings";

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _mainScreenSlideAnimation = Tween<double>(begin: 0.0, end: 250.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _mainScreenScaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Fetch data
    _fetchWorkingHours();
    _fetchTherapistProfile();
  }

  Future<void> _fetchTherapistProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _profileErrorMessage = null;
    });
    try {
      final profile = await _apiService.getTherapistOwnProfile();
      setState(() {
        _therapistProfile = profile;
        _isLoadingProfile = false;
      });
      AppLogger.debug('Therapist Profile: $profile');
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
        _profileErrorMessage = 'Failed to load profile: $e';
      });
      AppLogger.error('Failed to fetch therapist profile: $e');
    }
  }

  Future<void> _fetchWorkingHours() async {
    setState(() {
      _isLoadingWorkingHours = true;
      _workingHoursErrorMessage = null;
    });
    try {
      final data = await _apiService.getWorkingHours();
      setState(() {
        _updateUIFromApi(data);
        _isLoadingWorkingHours = false;
      });
      AppLogger.debug('Working Hours: $data');
    } catch (e) {
      setState(() {
        _isLoadingWorkingHours = false;
        _workingHoursErrorMessage = 'Failed to load working hours: $e';
      });
      AppLogger.error('Failed to fetch working hours: $e');
    }
  }

  void _updateUIFromApi(Map<String, dynamic> data) {
    final dayLower = selectedFilter.toLowerCase();
    isAvailable = !data['${dayLower}_available'] ?? false;
    if (data['${dayLower}_start'] != null && data['${dayLower}_end'] != null) {
      startTime = _parseTimeOfDay(data['${dayLower}_start']);
      endTime = _parseTimeOfDay(data['${dayLower}_end']);
    } else {
      startTime = TimeOfDay(hour: 9, minute: 0);
      endTime = TimeOfDay(hour: 17, minute: 0);
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    if (!isEditing) return;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  void _toggleEditMode() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  void _saveChanges() async {
    setState(() {
      isEditing = false;
    });
    try {
      final dayLower = selectedFilter.toLowerCase();
      final data = {
        '${dayLower}_available': !isAvailable,
        if (!isAvailable) '${dayLower}_start': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
        if (!isAvailable) '${dayLower}_end': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
      };
      await _apiService.updateWorkingHours(data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Availability settings saved!'),
          backgroundColor: primaryButtonColor,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildDrawerItem(IconData icon, String title, String route) {
    final isSelected = _selectedDrawerItem == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDrawerItem = title;
        });
        toggleDrawer();
        // Only navigate if the route is different from the current page
        if (route != "/availabilitySettings" || title == "Home") {
          Get.offNamed(route);
        }
        AppLogger.debug('Navigating to $route');
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? selectedTabColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
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
                  _buildDrawerItem(Icons.home, "Home", "/therapistHomePage"), // Added Home option
                  _buildDrawerItem(Icons.calendar_today, "Availability Settings", "/availabilitySettings"),
                  _buildDrawerItem(Icons.settings, "App Settings", "/appSettings"),
                  _buildDrawerItem(Icons.privacy_tip, "Terms & Privacy Policy", "/termsPrivacy"),
                  _buildDrawerItem(Icons.star_rate, "Reviews & Ratings", "/reviewsRatings"),
                  _buildDrawerItem(Icons.support_agent, "Contact Support", "/contactSupport"),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      await _storage.delete(key: 'user_id');
                      await _storage.delete(key: 'access_token');
                      Get.offAllNamed('/login');
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
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
                      child: Container(
                        color: Colors.white,
                        child: _isLoadingWorkingHours
                            ? Center(
                          child: SizedBox(
                            child: const CircularProgressIndicator(),
                          ),
                        )
                            : _workingHoursErrorMessage != null
                            ? Center(
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height - 100.h,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _workingHoursErrorMessage!,
                                  style: TextStyle(fontSize: 14.sp, color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 10.h),
                                ElevatedButton.icon(
                                  onPressed: _fetchWorkingHours,
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
                          children: [
                            SecondaryAppBar(
                              title: "Availability Settings",
                              showBackButton: false,
                              onMenuPressed: toggleDrawer,
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Select Day",
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: "Urbanist",
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: _toggleEditMode,
                                            child: SvgPicture.asset(
                                              "assets/svg/edit.svg",
                                              height: 20.h,
                                              width: 20.w,
                                              colorFilter: ColorFilter.mode(
                                                primaryColor,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          'Monday',
                                          'Tuesday',
                                          'Wednesday',
                                          'Thursday',
                                          'Friday',
                                          'Saturday',
                                          'Sunday',
                                        ].map((label) {
                                          final isSelected = selectedFilter == label;
                                          return GestureDetector(
                                            onTap: () {
                                              if (isEditing) {
                                                setState(() {
                                                  selectedFilter = label;
                                                  _fetchWorkingHours(); // Refresh data for new day
                                                });
                                              }
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 22.w, vertical: 10.h),
                                                decoration: BoxDecoration(
                                                  color: isSelected ? primaryTextColor : Colors.white,
                                                  borderRadius: BorderRadius.circular(15.r),
                                                  border: !isSelected
                                                      ? Border.all(color: Colors.white, width: 1.5)
                                                      : null,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black12,
                                                      blurRadius: isSelected ? 0.r : 5.r,
                                                      spreadRadius: isSelected ? 0.r : 1.r,
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  label,
                                                  style: TextStyle(
                                                    color: isSelected ? Colors.white : primaryTextColor,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14.sp,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 10.h),
                                      child: Container(
                                        height: 40.h,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20.r),
                                          border: Border.all(color: const Color(0xFFB28D28)),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: isEditing
                                                      ? () {
                                                    setState(() {
                                                      isAvailable = false;
                                                    });
                                                  }
                                                      : null,
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: !isAvailable
                                                          ? const Color(0xFFB28D28)
                                                          : Colors.transparent,
                                                      borderRadius: BorderRadius.circular(20.r),
                                                    ),
                                                    child: Text(
                                                      "Available",
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight: FontWeight.w500,
                                                        color: !isAvailable
                                                            ? Colors.white
                                                            : const Color(0xFFB28D28),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: isEditing
                                                      ? () {
                                                    setState(() {
                                                      isAvailable = true;
                                                    });
                                                  }
                                                      : null,
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: isAvailable
                                                          ? const Color(0xFFB28D28)
                                                          : Colors.transparent,
                                                      borderRadius: BorderRadius.circular(20.r),
                                                    ),
                                                    child: Text(
                                                      "Unavailable",
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight: FontWeight.w500,
                                                        color: isAvailable
                                                            ? Colors.white
                                                            : const Color(0xFFB28D28),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20.h),
                                    if (isAvailable) ...[
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                                        child: Text(
                                          "You won’t receive any appointment requests for every $selectedFilter.",
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: "Urbanist",
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                    if (!isAvailable) ...[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Start Time",
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: "Urbanist",
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => _selectTime(context, true),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      "${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}",
                                                      style: TextStyle(
                                                        fontSize: 40.sp,
                                                        fontWeight: FontWeight.w700,
                                                        fontFamily: "Urbanist",
                                                        color: isEditing
                                                            ? primaryTextColor
                                                            : Colors.grey,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.only(top: 10.h),
                                                      child: Text(
                                                        "${startTime.hour < 12 ? 'AM' : 'PM'}",
                                                        style: TextStyle(
                                                          fontSize: 18.sp,
                                                          fontWeight: FontWeight.w700,
                                                          fontFamily: "Urbanist",
                                                          color: isEditing
                                                              ? primaryTextColor
                                                              : Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "End Time",
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: "Urbanist",
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: () => _selectTime(context, false),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      "${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}",
                                                      style: TextStyle(
                                                        fontSize: 40.sp,
                                                        fontWeight: FontWeight.w700,
                                                        fontFamily: "Urbanist",
                                                        color: isEditing
                                                            ? primaryTextColor
                                                            : Colors.grey,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.only(top: 10.h),
                                                      child: Text(
                                                        "${endTime.hour < 12 ? 'AM' : 'PM'}",
                                                        style: TextStyle(
                                                          fontSize: 18.sp,
                                                          fontWeight: FontWeight.w700,
                                                          fontFamily: "Urbanist",
                                                          color: isEditing
                                                              ? primaryTextColor
                                                              : Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (isEditing) ...[
                                      Spacer(),
                                      ThaiMassageButton(
                                        text: "Save",
                                        onPressed: _saveChanges,
                                        isPrimary: true,
                                        width: double.infinity,
                                        height: 50.h,
                                        fontsize: 16.sp,
                                        borderRadius: 12.r,
                                        backgroundColor: primaryButtonColor,
                                        textColor: Colors.white,
                                      ),
                                      Spacer(),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
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
}