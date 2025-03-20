import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: const Color(0xFF8F5E0A), // Background color of bottom nav
      shape: const CircularNotchedRectangle(), // Creates the notch for FAB
      notchMargin: 8.w,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem("assets/images/wallet.png", "Wallet", 0),
            _buildNavItem("assets/images/chat.png", "Chat", 1),
             SizedBox(width: 50.w), // Space for FAB (Floating Action Button)
            _buildNavItem("assets/images/booking.png", "Bookings", 3),
            _buildNavItem("assets/images/profile.png", "Profile", 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String iconPath, String label, int index) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            iconPath,
            width: 24.w,
            color: isSelected ? Colors.white : const Color(0xFFE4C36C),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: isSelected ? Colors.white : const Color(0xFFE4C36C),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
