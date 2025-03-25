import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/booking/pages/booking_page.dart';
import 'package:thi_massage/view/chat/pages/chat_list_page.dart';
import 'package:thi_massage/view/home/page/therapist_home_page.dart';
import 'package:thi_massage/view/profile/pages/profile_page.dart';
import '../../wallet/pages/wallet_page.dart';
import 'home_content.dart';

class HomeScreen extends StatefulWidget {
  final bool isTherapist;

  const HomeScreen({super.key,required this.isTherapist});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2; // Start with Home selected
  late final NotchBottomBarController _controller;


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
    final List<Widget> _pages = [
      WalletScreen(),
      ChatListScreen(),
      widget.isTherapist ? const TherapistHomePage() : HomeContent(),
      BookingsPage(),
      ProfilePage()
    ];
    return Scaffold(
      body: _pages[_selectedIndex],

      bottomNavigationBar: SizedBox(
        width: 2.sw, // Full width using ScreenUtil
        child: AnimatedNotchBottomBar(
          showTopRadius: true,
          showBottomRadius: true,
          bottomBarWidth: 1.sw, // Ensure the bar fits full screen width
          notchColor: const Color(0xFFB28D28),
          notchBottomBarController: _controller,
          color: buttonNavigationBar,
          showLabel: true,
          kBottomRadius: 30.r, // Adjusted to fit bottom properly
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