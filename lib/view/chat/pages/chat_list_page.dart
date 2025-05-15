import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../controller/user_type_controller.dart';
import '../../../themes/colors.dart';
import '../../../routers/app_router.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final UserTypeController userTypeController = Get.find<UserTypeController>();

  final List<Map<String, dynamic>> _chatList = [
    {
      'name': 'Smith Mathew',
      'lastMessage': 'Hi, David. Hope you\'re doing...',
      'date': '19 feb',
      'image': 'assets/images/fevTherapist1.png',
      'unreadCount': 2,
    },
    {
      'name': 'Sara Johnson',
      'lastMessage': 'Hi, David. Hope you\'re doing...',
      'date': '18 feb',
      'image': 'assets/images/fevTherapist2.png',
      'unreadCount': 0,
    },
    {
      'name': 'Shakil Khan',
      'lastMessage': 'Hi, David. Hope you\'re doing...',
      'date': '17 feb',
      'image': 'assets/images/fevTherapist3.png',
      'unreadCount': 5,
    },
    {
      'name': 'Bijoy Khan',
      'lastMessage': 'Hi, David. Hope you\'re doing...',
      'date': '16 feb',
      'image': 'assets/images/fevTherapist4.png',
      'unreadCount': 1,
    },
  ];

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
            child: _chatListView(),
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
        return ListTile(
          onTap: () {
            setState(() {
              _chatList[index]['unreadCount'] = 0; // Reset unread count when chat is opened
            });
            // Navigate to ChatDetailScreen with image and name
            Get.toNamed(
              Routes.chatDetailsPage,
              arguments: {
                'image': chat['image'],
                'name': chat['name'],
              },
            );
          },
          leading: CircleAvatar(
            backgroundImage: AssetImage(chat['image']),
          ),
          title: Row(
            children: [
              Text(
                chat['name'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(width: 4.w),
              // Show unread message count if greater than 0
              if (chat['unreadCount'] > 0) ...[
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: primaryButtonColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    chat['unreadCount'].toString(),
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
          subtitle: Text(chat['lastMessage']),
          trailing: Text(
            chat['date'],
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