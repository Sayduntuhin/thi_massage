import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for Clipboard
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../api/api_service.dart';
import '../../../controller/auth_controller.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/app_logger.dart';
import '../../widgets/custom_snackBar.dart';

class TherapistSupportPage extends StatefulWidget {
  const TherapistSupportPage({super.key});

  @override
  State<TherapistSupportPage> createState() => _TherapistSupportPageState();
}

class _TherapistSupportPageState extends State<TherapistSupportPage>
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
  String? _selectedDrawerItem;

  @override
  void initState() {
    super.initState();
    _selectedDrawerItem = "Contact Support";

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

    // Fetch therapist profile for the drawer
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

  void toggleDrawer() {
    if (_isDrawerOpen) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    _isDrawerOpen = !_isDrawerOpen;
  }

  Future<bool> launchPnMail(String schema, String path) async {

    Uri uri = Uri(scheme: schema, path: path);
     return await launchUrl(uri);
  }

  // Function to launch email
  Future<void> _launchEmail() async {
    const String emailAddress = 'team.thaimassagenearme@gmail.com';

    try {
      bool canLaunch = await launchPnMail("mailto", emailAddress);
      bool launched = false;

      if (!canLaunch) {
        final List<Uri> emailUris = [
          // Gmail app intent
          Uri.parse('googlegmail://co?to=$emailAddress'),
          // Generic email intent
          Uri(scheme: 'mailto', path: emailAddress),
          // Gmail web interface
          Uri.parse('https://mail.google.com/mail/?view=cm&fs=1&to=$emailAddress'),
          // Fallback to browser
          Uri.parse('https://gmail.com'),
        ];
        for (Uri uri in emailUris) {
          try {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              launched = true;
              AppLogger.debug('Successfully launched email with URI: $uri');
              break;
            }
          } catch (e) {
            AppLogger.debug('Failed to launch with URI $uri: $e');
            continue;
          }
        }

        if (!launched) {
          // If all else fails, copy email to clipboard and show dialog
          _showEmailDialog();
        }
      }
    } catch (e) {
      _showErrorSnackbar('Error opening email: $e');
      AppLogger.error('Error launching email: $e');
      _showEmailDialog();
    }
  }

  // Show dialog with email address and options
  void _showEmailDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Support'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please contact us at:'),
              const SizedBox(height: 10),
              SelectableText(
                'team.thaimassagenearme@gmail.com',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text('You can copy this email address and paste it into your email app.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _copyEmailToClipboard();
              },
              child: const Text('Copy Email'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Copy email to clipboard
  void _copyEmailToClipboard() async {
    try {
      await Clipboard.setData(const ClipboardData(text: 'team.thaimassagenearme@gmail.com'));
      _showSuccessSnackbar('Email address copied to clipboard!');
    } catch (e) {
      _showErrorSnackbar('Failed to copy email address');
    }
  }

  // Function to launch phone call
  Future<void> _launchPhone() async {
    const String phoneNumber = '+16193217743';

    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        AppLogger.debug('Successfully launched phone dialer');
      } else {
        // Show dialog with phone number if dialer can't be opened
        _showPhoneDialog();
      }
    } catch (e) {
      _showErrorSnackbar('Error making phone call: $e');
      AppLogger.error('Error launching phone: $e');
      _showPhoneDialog();
    }
  }

  // Show dialog with phone number
  void _showPhoneDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Call Support'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please call us at:'),
              const SizedBox(height: 10),
              SelectableText(
                '+1(619)321-7743',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              const Text('You can copy this number and dial it manually.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _copyPhoneToClipboard();
              },
              child: const Text('Copy Number'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Copy phone number to clipboard
  void _copyPhoneToClipboard() async {
    try {
      await Clipboard.setData(const ClipboardData(text: '+1(619)321-7743'));
      _showSuccessSnackbar('Phone number copied to clipboard!');
    } catch (e) {
      _showErrorSnackbar('Failed to copy phone number');
    }
  }

  // Helper function to show error messages
  void _showErrorSnackbar(String message) {
    CustomSnackBar.show(
      context,
      message,
      type: ToastificationType.error,
    );
  }

  // Helper function to show success messages
  void _showSuccessSnackbar(String message) {
    CustomSnackBar.show(
      context,
      message,
      type: ToastificationType.success,
    );
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
        if (route != "/contactSupport" || title == "Home") {
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
                          children: [
                            SecondaryAppBar(
                              title: "Support",
                              showBackButton: false,
                              showManuButton:  true,
                              onMenuPressed: toggleDrawer,
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 30.h),
                                    // Title
                                    Text(
                                      "Support",
                                      style: TextStyle(
                                        fontSize: 28.sp,
                                        fontWeight: FontWeight.bold,
                                        color: primaryTextColor,
                                        fontFamily: "PlayfairDisplay",
                                      ),
                                    ),
                                    SizedBox(height: 5.h),
                                    // Subtitle
                                    Text(
                                      "If you have any query or complaint, \nplease contact,",
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: secounderyTextColor,
                                        fontFamily: "Urbanist",
                                      ),
                                    ),
                                    SizedBox(height: 30.h),
                                    // Email Support
                                    _buildSupportItem(
                                      icon: Icons.email_outlined,
                                      text: "team.thaimassagenearme@gmail.com",
                                      onTap: _launchEmail, // Updated to call _launchEmail
                                    ),
                                    SizedBox(height: 20.h),
                                    // Phone Support
                                    _buildSupportItem(
                                      icon: Icons.phone,
                                      text: "+1(619)321-7743",
                                      onTap: _launchPhone, // Updated to call _launchPhone
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

  Widget _buildSupportItem({required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: boxColor,
              shape: BoxShape.circle,
              border: Border.all(color: secounderyBorderColor.withAlpha(60), width: 1.5.w),
            ),
            child: Icon(icon, color: primaryTextColor, size: 22.sp),
          ),
          SizedBox(width: 10.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: primaryTextColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}