import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../api/api_service.dart';
import '../../../controller/user_type_controller.dart';
import '../../../themes/colors.dart';
import '../../../routers/app_router.dart';
import 'package:toastification/toastification.dart';

import '../../widgets/app_logger.dart';
import '../../widgets/custom_snackBar.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final UserTypeController userTypeController = Get.find<UserTypeController>();
  final RxList<Map<String, dynamic>> _chatList = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchChatList();
  }

  Future<void> _fetchChatList() async {
    isLoading.value = true;
    try {
      final chatList = await _apiService.fetchChatInbox();
      _chatList.assignAll(chatList);
      AppLogger.debug('Chat list loaded: ${_chatList.length} chats');
    } catch (e) {
      AppLogger.error('Error fetching chat list: $e');
      CustomSnackBar.show(
        context,
        'Error loading chats: $e',
        type: ToastificationType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final parsedDate = DateFormat('dd MMM').parse(timestamp);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(now.year, parsedDate.month, parsedDate.day);

      if (messageDate == today) {
        return 'Today';
      } else {
        return timestamp; // Keep original format (e.g., "16 May")
      }
    } catch (e) {
      AppLogger.debug('Error parsing timestamp $timestamp: $e');
      return timestamp; // Fallback to original
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chat",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xff606060),
                ),
                hintText: "Search",
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black54,
                ),
                filled: true,
                fillColor: textFieldColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  borderSide: BorderSide(
                    color: borderColor.withAlpha(40),
                    width: 1.5.w,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  borderSide: BorderSide(
                    color: borderColor.withAlpha(40),
                    width: 1.5.w,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  borderSide: BorderSide(
                    color: borderColor.withAlpha(40),
                    width: 2.w,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 16.h),
              ),
            ),
          ),
          Expanded(
            child: Obx(() => isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : _chatList.isEmpty
                ? const Center(child: Text('No chats available'))
                : RefreshIndicator(
              onRefresh: _fetchChatList,
              child: _chatListView(),
            )),
          ),
        ],
      ),
    );
  }

  Widget _chatListView() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      itemCount: _chatList.length,
      itemBuilder: (context, index) {
        final chat = _chatList[index];
        final profileImage = chat['profile_image']?.startsWith('/')
            ? '${ApiService.baseUrl}${chat['profile_image']}'
            : chat['profile_image'] ?? 'assets/images/therapist.png';
        final latestMessage = chat['latest_message']?.isNotEmpty == true
            ? chat['latest_message']
            : 'No messages yet';
        final latestTimestamp = _formatTimestamp(chat['latest_timestamp']);

        return ListTile(
          onTap: () {
            _chatList[index]['unread_count'] = 0;
            _chatList.refresh();
            Get.toNamed(
              Routes.chatDetailsPage,
              arguments: {
                'chat_room_id': chat['chat_room_id'],
                'therapist_user_id': chat['user_id'],
                'name': chat['name'],
                'image': profileImage,
              },
            );
          },
          leading: CircleAvatar(
            backgroundImage: profileImage.startsWith('http')
                ? NetworkImage(profileImage)
                : AssetImage('assets/images/therapist.png') as ImageProvider,
          ),
          title: Row(
            children: [
              Text(
                chat['name'] ?? 'Unknown User',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(width: 4.w),
              if ((chat['unread_count'] ?? 0) > 0) ...[
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: primaryButtonColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    chat['unread_count'].toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(latestMessage),
          trailing: Text(
            latestTimestamp,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey,
            ),
          ),
        );
      },
    );
  }
}