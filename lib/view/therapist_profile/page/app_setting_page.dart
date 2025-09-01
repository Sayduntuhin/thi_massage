import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../../../api/api_service.dart';
import '../../../controller/auth_controller.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/app_logger.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _mainScreenSlideAnimation;
  late Animation<double> _mainScreenScaleAnimation;
  bool _isDrawerOpen = false;
  double _dragStartX = 0;
  Map<String, dynamic>? _therapistProfile;
  bool _isLoadingProfile = true;
  String? _profileErrorMessage;
  final ApiService _apiService = ApiService();
  final AuthController authController = Get.find<AuthController>();
  final _storage = const FlutterSecureStorage();
  String? _selectedDrawerItem;
  bool _notificationSoundEnabled = true; // Default state
  bool _offlineWhenNotInUse = false; // Default state

  @override
  void initState() {
    super.initState();
    _selectedDrawerItem = "App Settings";

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

    // Fetch data and load settings
    _fetchTherapistProfile();
    _loadSettings();
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

  Future<void> _loadSettings() async {
    try {
      final notificationSound = await _storage.read(key: 'notification_sound_enabled');
      final offlineWhenNotInUse = await _storage.read(key: 'offline_when_not_in_use');
      setState(() {
        _notificationSoundEnabled = notificationSound != 'false'; // Default to true if null
        _offlineWhenNotInUse = offlineWhenNotInUse == 'true'; // Default to false if null
      });
    } catch (e) {
      AppLogger.error('Failed to load settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _storage.write(
        key: 'notification_sound_enabled',
        value: _notificationSoundEnabled.toString(),
      );
      await _storage.write(
        key: 'offline_when_not_in_use',
        value: _offlineWhenNotInUse.toString(),
      );
      AppLogger.debug('Settings saved: notification_sound=$_notificationSoundEnabled, offline_when_not_in_use=$_offlineWhenNotInUse');
    } catch (e) {
      AppLogger.error('Failed to save settings: $e');
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
        // Navigate to the route unless it's the current page
        if (route != "/appSettings" || title == "Home") {
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
                  _buildDrawerItem(Icons.home, "Home", "/therapistHomePage"),
                  _buildDrawerItem(Icons.calendar_today, "Availability Settings", "/availabilitySettings"),
                  _buildDrawerItem(Icons.settings, "App Settings", "/appSettings"),
                  _buildDrawerItem(Icons.privacy_tip, "Terms & Privacy Policy", "/termsPrivacy"),
                  _buildDrawerItem(Icons.star_rate, "Reviews & Ratings", "/reviewsRatings"),
                  _buildDrawerItem(Icons.support_agent, "Contact Support", "/contactSupport"),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      try {
                        await  authController.logout();

                      } catch (e) {
                        AppLogger.error('Failed to logout: $e');
                      }
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
                        child: _isLoadingProfile
                            ? Center(
                          child: SizedBox(
                            child: const CircularProgressIndicator(),
                          ),
                        )
                            : _profileErrorMessage != null
                            ? Center(
                          child: SizedBox(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _profileErrorMessage!,
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
                            SecondaryAppBar(
                              title: "App Settings",
                              showBackButton: false,
                              showManuButton:  true,
                              onMenuPressed: toggleDrawer,
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "App Settings",
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    Divider(
                                      color: const Color(0xffD0D0D0),
                                      thickness: 1,
                                    ),
                                    SizedBox(height: 20.h),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "New request notification sound",
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Switch(
                                          value: _notificationSoundEnabled,
                                          onChanged: (value) {
                                            setState(() {
                                              _notificationSoundEnabled = value;
                                            });
                                            _saveSettings();
                                          },
                                          activeColor: primaryButtonColor,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20.h),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Offline when app is not in use",
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Switch(
                                          value: _offlineWhenNotInUse,
                                          onChanged: (value) {
                                            setState(() {
                                              _offlineWhenNotInUse = value;
                                            });
                                            _saveSettings();
                                          },
                                          activeColor: primaryButtonColor,
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