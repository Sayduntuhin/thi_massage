import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thi_massage/themes/colors.dart';
import 'home_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2; // Start with Home selected
  late final NotchBottomBarController _controller;

  final List<Widget> _pages = [
    Center(child: Text("Wallet Screen", style: TextStyle(fontSize: 18.sp))),
    Center(child: Text("Chat Screen", style: TextStyle(fontSize: 18.sp))),
    const HomeContent(), // Home Page
    Center(child: Text("Bookings Screen", style: TextStyle(fontSize: 18.sp))),
    Center(child: Text("Profile Screen", style: TextStyle(fontSize: 18.sp))),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize the controller with the default selected index
    _controller = NotchBottomBarController(index: _selectedIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      bottomNavigationBar: SizedBox(
        width: 1.sw, // Full width using ScreenUtil
        child: AnimatedNotchBottomBar(
          bottomBarWidth: 1.sw, // Ensure the bar fits full screen width
          notchColor: const Color(0xFFB28D28),
          notchBottomBarController: _controller,
          color: buttonNavigationBar,
          showLabel: true,
          kBottomRadius: 0, // Adjusted to fit bottom properly
          kIconSize: 22.w,
          bottomBarItems: [
            _buildNavItem("assets/images/wallet.png", "Wallet", 0),
            _buildNavItem("assets/images/chat.png", "Chat", 1),
            _buildNavItem("assets/images/home.png", "Home", 2),
            _buildNavItem("assets/images/booking.png", "Bookings", 3),
            _buildNavItem("assets/images/profile.png", "Profile", 4),
          ],
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }

  BottomBarItem _buildNavItem(String iconPath, String label, int index) {
    return BottomBarItem(
      inActiveItem: Image.asset(iconPath, color: const Color(0xFFE4C36C), width: 24.w),
      activeItem: Image.asset(iconPath, width: 24.w),
      itemLabelWidget: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE4C36C),
        ),
      ),
    );
  }
}