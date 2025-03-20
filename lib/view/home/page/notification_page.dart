import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thi_massage/themes/colors.dart';
import '../../widgets/custom_appbar.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SecondaryAppBar(title: "Notifications"),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: ListView(
          children: [
            _buildSectionTitle("Today"),
            _buildNotificationItem(
              image: "assets/images/notificationPerson.png",
              name: "Gabriell",
              message: "Gabriell posted a review.",
              time: "2 min ago",
              isUnread: true,
            ),
            _buildNotificationItem(
              image: "assets/images/notificationPerson.png",
              name: "Jenny",
              message: "Jenny sent you a message.",
              time: "10 min ago",
              isUnread: true,
            ),
            _buildSectionTitle("Yesterday"),
            _buildNotificationItem(
              image: "assets/images/notificationPerson.png",
              name: "Gabriell",
              message: "Gabriell booked an instant appointment.",
              time: "23 hours ago",
            ),
            _buildNotificationItem(
              image: "assets/images/notificationPerson.png",
              name: "Jenny",
              message: "Jenny scheduled an appointment for ",
              highlightedText: "1st March.",
              time: "1 day ago",
            ),
            _buildSectionTitle("Older"),
            _buildNotificationItem(
              image: "assets/images/notificationPerson.png",
              name: "Gabriell",
              message: "Gabriell sent you a message.",
              time: "15 Jul, 2024",
            ),
            _buildNotificationItem(
              image: "assets/images/notificationPerson.png",
              name: "Jenny",
              message: "Jenny sent you a message.",
              time: "15 Jul, 2024",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNotificationItem({
    required String image,
    required String name,
    required String message,
    required String time,
    bool isUnread = false,
    String? highlightedText,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 24.r,
            backgroundImage: AssetImage(image),
          ),
          title: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14.sp, color: Colors.black),
              children: [
                TextSpan(text: "$name "),
                TextSpan(text: message),
                if (highlightedText != null)
                  TextSpan(
                    text: highlightedText,
                    style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              time,
              style: TextStyle(fontSize: 12.sp, color: Colors.black54),
            ),
          ),
          trailing: isUnread
              ? Container(
            width: 8.w,
            height: 8.h,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          )
              : null,
        ),
        Divider(height: 16.h, thickness: 1, color: Color(0xffD7D7D7),endIndent: 10,indent: .15.sw,),
      ],
    );
  }
}
