import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/booking/pages/client_booking_page.dart';
import 'package:thi_massage/view/booking/pages/therapist_booking_page.dart';
import 'package:thi_massage/view/chat/pages/chat_list_page.dart';
import 'package:thi_massage/view/home/page/therapist_home_page.dart';
import 'package:thi_massage/view/wallet/pages/earning_page.dart';
import '../../client_profile/pages/profile_page.dart';
import '../../client_profile/pages/therepist_profile_page.dart';
import '../../wallet/pages/wallet_page.dart';
import 'client_homepage.dart';
import '../../../controller/user_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2; // Start with Home selected
  late final NotchBottomBarController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NotchBottomBarController(index: _selectedIndex);
    // Log initial state
    final userTypeController = Get.find<UserTypeController>();
    final isTherapistArg = Get.arguments?['isTherapist'] ?? false;
    debugPrint('HomeScreen init: userTypeController.isTherapist = ${userTypeController.isTherapist.value}');
    debugPrint('HomeScreen init: Get.arguments[isTherapist] = $isTherapistArg');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get controller and arguments
    final UserTypeController userTypeController = Get.find<UserTypeController>();
    final bool isTherapistArg = Get.arguments?['isTherapist'] ?? false;

    return Scaffold(
      body: Obx(() {
        // Use userTypeController or fallback to Get.arguments
        final isTherapist = userTypeController.isTherapist.value || isTherapistArg;
        debugPrint('HomeScreen build: isTherapist = $isTherapist');

        final List<Widget> _pages = [
          isTherapist ? EarningsPage() : WalletScreen(),
          ChatListScreen(),
          isTherapist ? const TherapistHomePage() : HomeContent(),
          isTherapist ? CalendarPage() : BookingsPage(),
          isTherapist ? TherapistEditPage() : ProfilePage(),
        ];
        return _pages[_selectedIndex];
      }),

      bottomNavigationBar: SizedBox(
        width: 2.sw,
        child: AnimatedNotchBottomBar(
          showTopRadius: true,
          showBottomRadius: true,
          bottomBarWidth: 1.sw,
          notchColor: const Color(0xFFB28D28),
          notchBottomBarController: _controller,
          color: buttonNavigationBar,
          showLabel: true,
          kBottomRadius: 30.r,
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