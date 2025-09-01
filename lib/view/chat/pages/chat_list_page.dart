import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/controller/chat_list_controller.dart';
import 'package:thi_massage/themes/colors.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize ChatListController
    final controller = Get.put(ChatListController());

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
              controller: controller.searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xff606060),
                ),
                hintText: "Search by name",
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
            child: Obx(() => controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : controller.filteredChatList.isEmpty
                ? const Center(child: Text('No chats found'))
                : RefreshIndicator(
              onRefresh: controller.fetchChatList,
              child: _chatListView(controller),
            )),
          ),
        ],
      ),
    );
  }

  Widget _chatListView(ChatListController controller) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      itemCount: controller.filteredChatList.length,
      itemBuilder: (context, index) {
        final chat = controller.filteredChatList[index];
        final profileImage = controller.getProfileImage(chat['profile_image']);
        final latestMessage = chat['latest_message']?.isNotEmpty == true
            ? chat['latest_message']
            : 'No messages yet';
        final latestTimestamp = controller.formatTimestamp(chat['latest_timestamp']);

        return ListTile(
          onTap: () => controller.navigateToChatDetail(index),
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