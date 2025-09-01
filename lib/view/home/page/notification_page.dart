import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../api/api_service.dart';
import '../../../controller/notifications_controller.dart';
import '../../../themes/colors.dart';
import '../../widgets/app_logger.dart';
import '../../widgets/custom_appbar.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ApiService apiService = ApiService();
  final NotificationSocketController notificationSocketController = Get.find<NotificationSocketController>();
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if (notificationSocketController.notificationRoomId.value == null) {
      setState(() {
        errorMessage = 'Notification room not found';
        isLoading = false;
      });
      return;
    }

    try {
      final fetchedNotifications = await apiService.getNotificationMessages(notificationSocketController.notificationRoomId.value!);
      setState(() {
        notifications = fetchedNotifications;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      AppLogger.error('Error fetching notifications: $e');
      setState(() {
        errorMessage = 'Failed to load notifications: $e';
        isLoading = false;
      });
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupNotificationsByDate() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var notification in notifications) {
      final createdAt = DateTime.parse(notification['created_at']);
      final dateKey = _getDateKey(createdAt, today, yesterday);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(notification);
    }

    return grouped;
  }

  String _getDateKey(DateTime createdAt, DateTime today, DateTime yesterday) {
    final notificationDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM dd, yyyy').format(createdAt);
    }
  }

  String _formatTime(String createdAt) {
    final dateTime = DateTime.parse(createdAt);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('MMMM dd, yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SecondaryAppBar(title: "Notifications"),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage!, style: TextStyle(fontSize: 14.sp, color: Colors.red)),
              SizedBox(height: 10.h),
              ElevatedButton(
                onPressed: _fetchNotifications,
                child: Text('Retry', style: TextStyle(fontSize: 14.sp)),
              ),
            ],
          ),
        )
            : notifications.isEmpty
            ? Center(child: Text('No notifications available', style: TextStyle(fontSize: 14.sp)))
            : ListView(
          children: _groupNotificationsByDate().entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(entry.key),
                ...entry.value.map((notification) {
                  final messageParts = _splitMessage(notification['message']);
                  return _buildNotificationItem(
                    image: "assets/images/notificationPerson.png",
                    name: messageParts['name'] ?? 'User',
                    message: messageParts['message'] ?? notification['message'],
                    time: _formatTime(notification['created_at']),
                    isUnread: !notification['is_read'],
                    highlightedText: messageParts['highlightedText'],
                  );
                }).toList(),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Map<String, String?> _splitMessage(String message) {
    final parts = message.split(' scheduled an appointment for ');
    if (parts.length == 2) {
      return {
        'name': parts[0],
        'message': 'scheduled an appointment for',
        'highlightedText': parts[1],
      };
    }
    return {'name': null, 'message': message, 'highlightedText': null};
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
        Divider(height: 16.h, thickness: 1, color: const Color(0xffD7D7D7), endIndent: 10, indent: 0.15.sw),
      ],
    );
  }
}