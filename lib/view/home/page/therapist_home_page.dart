import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../themes/colors.dart';
import '../widgets/notificaton_bell.dart';
import '../widgets/online_offline_toggle.dart';

class TherapistHomePage extends StatefulWidget {
  const TherapistHomePage({super.key});

  @override
  State<TherapistHomePage> createState() => _TherapistHomePageState();
}

class _TherapistHomePageState extends State<TherapistHomePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _mainScreenSlideAnimation;
  late Animation<double> _mainScreenScaleAnimation;
  bool _isDrawerOpen = false;
  double _dragStartX = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _mainScreenSlideAnimation = Tween<double>(begin: 0.0, end: 250.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _mainScreenScaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set Scaffold background to white
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
                  // Profile
                  CircleAvatar(
                    backgroundImage: const AssetImage("assets/images/profilepic.png"),
                    radius: 40.r,
                  ),
                  SizedBox(height: 12.h),
                  Text("Mical Martinez",
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text("Thai Massage Therapist", style: TextStyle(fontSize: 13.sp, color: Colors.white70)),
                  SizedBox(height: 30.h),

                  // Menu
                  _buildDrawerItem(Icons.calendar_today, "Availability Settings"),
                  _buildDrawerItem(Icons.settings, "App Settings"),
                  _buildDrawerItem(Icons.privacy_tip, "Terms & Privacy Policy"),
                  _buildDrawerItem(Icons.star_rate, "Reviews & Ratings"),
                  _buildDrawerItem(Icons.support_agent, "Contact Support"),
                  const Spacer(),

                  // Logout
                  GestureDetector(
                    onTap: () {
                      // Logout logic
                      Get.offAllNamed('/welcome');
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

            // Main Screen (TherapistHomePage content)
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
                        color: Colors.white, // Ensure the main content has a white background
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: SafeArea(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Bar
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: toggleDrawer, // Toggle drawer on menu icon tap
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
                                        backgroundImage: AssetImage('assets/images/profilepic.png'),
                                      ),
                                      NotificationBell(
                                        notificationCount: 1, // Show notification dot
                                        svgAssetPath: 'assets/svg/notificationIcon.svg',
                                        navigateTo: "/notificationsPage",// Pass your SVG file path
                                      ),

                                    ],
                                  ),
                                  SizedBox(height: 10.h),
                                  // Greeting & Status
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Hello Mical",
                                              style: TextStyle(
                                                  fontSize: 30.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryTextColor)),
                                          Text("Thai Massage Therapist",
                                              style: TextStyle(fontSize: 14.sp, color: Colors.black26)),
                                        ],
                                      ),
                                      OnlineOfflineToggle(
                                        initialOnline: true,
                                        onChanged: (isOnline) {
                                          debugPrint("Therapist is now ${isOnline ? "online" : "offline"}");
                                        },
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20.h),

                                  // Stats
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _statItem("31", "Sessions"),
                                      _statItem("\$1.5k", "Earning"),
                                      _statItem("4", "Booked"),
                                    ],
                                  ),
                                  SizedBox(height: 20.h),

                                  // Appointments
                                  _sectionHeader("Upcoming Appointments", onTap: () {}),
                                  SizedBox(
                                    height: 0.14.sh,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: [
                                        _appointmentCard(
                                          name: "Mike Milan",
                                          date: "2 Mar",
                                          time: "12:00 AM",
                                          service: "Thai Massage",
                                          location: "4761 Hamill Avenue, San Diego",
                                          distance: "3.2",
                                          isMale: true,
                                        ),
                                        _appointmentCard(
                                          name: "Sarah Jones",
                                          date: "5 Mar",
                                          time: "1:00 PM",
                                          service: "Swedish Massage",
                                          location: "Downtown Wellness Spa",
                                          distance: "5.0",
                                          isMale: false,
                                        ),
                                      ],
                                    ),
                                  ),
                                  _sectionHeader("Appointment Requests"),
                                  _appointmentRequestCard(
                                    name: "Mark Milan",
                                    service: "Thai Massage",
                                    day: "21",
                                    month: "Feb",
                                    year: "2025",
                                    time: "12:00 AM",
                                    isFemale: false,
                                  ),
                                  _appointmentRequestCard(
                                    name: "Jennie",
                                    service: "Thai Massage",
                                    day: "21",
                                    month: "Feb",
                                    year: "2025",
                                    time: "12:00 AM",
                                    isFemale: true,
                                  ),
                                ],
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
        Text(value, style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.bold, color: primaryTextColor)),
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

  Widget _appointmentCard({
    required String name,
    required String date,
    required String time,
    required String service,
    required String location,
    required String distance,
    bool isMale = true,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 0.75.sw,
        margin: EdgeInsets.only(right: 12.w),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: const AssetImage("assets/images/profilepic.png"),
                  radius: 24.r,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
                          SizedBox(width: 4.w),
                          Icon(
                            isMale ? Icons.male : Icons.female,
                            size: 16.sp,
                            color: isMale ? Colors.blue : Colors.pink,
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12.sp, color: Colors.grey),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(fontSize: 11.sp, color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.bold, color: const Color(0xffB28D28)),
                    ),
                    SizedBox(height: 6.h),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("$distance km", style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                RichText(
                  text: TextSpan(
                    text: "Service: ",
                    style: TextStyle(fontSize: 12.sp, color: Colors.black54),
                    children: [
                      TextSpan(
                        text: service,
                        style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14.sp, color: Colors.grey),
                    SizedBox(width: 4.w),
                    Text(time, style: TextStyle(fontSize: 12.sp)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _appointmentRequestCard({
    required String name,
    required String service,
    required String day,
    required String month,
    required String year,
    required String time,
    bool isFemale = false,
  }) {
    return Padding(
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
                Text(day,
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white)),
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
                          Text(
                            name,
                            style: TextStyle(
                                fontSize: 13.sp, color: Colors.black87, fontWeight: FontWeight.w500),
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
                              "Accept", const Color(0xFFCBF299), const Color(0xff33993A), const Color(0xFFCBF299)),
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
        // Handle navigation if needed
        toggleDrawer();
      },
    );
  }
}