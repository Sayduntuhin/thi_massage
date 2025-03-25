import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:intl/intl.dart';
import '../../../models/chat_model.dart';

// Chat Detail Screen
class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      text: 'Hi, are you available?',
      isMe: true,
      timestamp: DateTime(2025, 3, 23, 10, 0),
    ),
    ChatMessage(
      id: '2',
      text: 'Hello, yes!',
      isMe: false,
      timestamp: DateTime(2025, 3, 23, 10, 1),
    ),
    ChatMessage(
      id: '3',
      text: 'Voice message (0:45)',
      isMe: true,
      isVoice: true,
      timestamp: DateTime(2025, 3, 23, 10, 5),
    ),
    ChatMessage(
      id: '4',
      text: 'Voice message (0:30)',
      isMe: false,
      isVoice: true,
      timestamp: DateTime(2025, 3, 24, 9, 30),
    ),
    ChatMessage(
      id: '5',
      text: 'Ok!',
      isMe: false,
      timestamp: DateTime(2025, 3, 24, 9, 32),
    ),
    ChatMessage(
      id: '6',
      text: 'Voice message (0:15)',
      isMe: true,
      isVoice: true,
      timestamp: DateTime(2025, 3, 24, 9, 35),
    ),
  ];

  late final String chatImage;
  late final String chatName;
  bool _isTyping = false;
  String? _selectedMessageId; // Track the message whose timestamp is visible

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        _isTyping = _messageController.text.trim().isNotEmpty;
      });
    });
    final arguments = Get.arguments as Map<String, dynamic>?;
    chatImage = arguments?['image'] ?? 'assets/images/therapist.png';
    chatName = arguments?['name'] ?? 'Unknown User';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE dd, yyyy').format(date);
    }
  }

  String _getFormattedTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  void _toggleTimestamp(String messageId) {
    setState(() {
      if (_selectedMessageId == messageId) {
        _selectedMessageId = null; // Hide timestamp if the same message is tapped again
      } else {
        _selectedMessageId = messageId; // Show timestamp for the tapped message
      }
    });
  }

  void _hideTimestamp() {
    setState(() {
      _selectedMessageId = null; // Hide all timestamps
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(chatImage),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chatName,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  "Active now",
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: SvgPicture.asset('assets/svg/phone_with_Color.svg'),
          ),
        ],
        leading:  Padding(
          padding: const EdgeInsets.only(left: 10,top: 5,bottom: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(15.0)),
              border: Border.all(color: buttonBorderColor.withAlpha(60), width: 1.0),
            ),
            child: IconButton(
              icon: Padding(
                padding: EdgeInsets.only(left: 5.w),
                child: Icon(Icons.arrow_back_ios, size: 20.sp, color: primaryButtonColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _hideTimestamp, // Hide timestamp when tapping outside messages
              child: _buildMessageList(),
            ),
          ),
          _messageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final Map<String, List<ChatMessage>> groupedMessages = {};

    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final message in _messages) {
      final date = _getFormattedDate(message.timestamp);
      if (!groupedMessages.containsKey(date)) {
        groupedMessages[date] = [];
      }
      groupedMessages[date]!.add(message);
    }

    final sortedDates = groupedMessages.keys.toList()
      ..sort((a, b) {
        if (a == 'Today') return 1;
        if (b == 'Today') return -1;
        if (a == 'Yesterday') return 1;
        if (b == 'Yesterday') return -1;
        final dateA = DateFormat('EEEE dd, yyyy').parse(a);
        final dateB = DateFormat('EEEE dd, yyyy').parse(b);
        return dateA.compareTo(dateB);
      });

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final date = sortedDates[dateIndex];
        final messagesForDate = groupedMessages[date]!;

        return Column(
          children: [
            _daySeparator(date),
            ...messagesForDate.asMap().entries.map((entry) {
              final index = entry.key;
              final message = entry.value;

              final isLastFromSender = index == messagesForDate.length - 1 ||
                  messagesForDate[index + 1].isMe != message.isMe;

              if (message.isVoice) {
                return _voiceBubble(
                  message,
                  isLastFromSender: isLastFromSender,
                );
              } else {
                return _chatBubble(
                  message.text,
                  isMe: message.isMe,
                  showAvatar: isLastFromSender,
                  timestamp: message.timestamp,
                  messageId: message.id,
                );
              }
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _chatBubble(
      String text, {
        required bool isMe,
        bool showAvatar = false,
        required DateTime timestamp,
        required String messageId,
      }) {
    final isTimestampVisible = _selectedMessageId == messageId;

    if (isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _toggleTimestamp(messageId),
                  child: Container(
                    margin: EdgeInsets.only(top: 8.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffF3EEDF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r),
                        topRight: Radius.circular(16.r),
                        bottomLeft: Radius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ),
                if (isTimestampVisible) ...[
                  SizedBox(height: 4.h),
                  Text(
                    _getFormattedTime(timestamp),
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: Row(
          crossAxisAlignment:
          showAvatar ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (showAvatar)
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18.r,
                    backgroundImage: AssetImage(chatImage),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(width: 36.w),

            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _toggleTimestamp(messageId),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xffE4E4E4),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16.r),
                        topLeft: Radius.circular(16.r),
                        bottomRight: Radius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ),
                if (isTimestampVisible) ...[
                  SizedBox(height: 4.h),
                  Text(
                    _getFormattedTime(timestamp),
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _voiceBubble(
      ChatMessage message, {
        bool isLastFromSender = false,
      }) {
    final isMe = message.isMe;
    final isTimestampVisible = _selectedMessageId == message.id;

    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            isLastFromSender
                ? Stack(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundImage: AssetImage(chatImage),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            )
                : SizedBox(width: 36.w),
          if (!isMe) SizedBox(width: 8.w),

          Column(
            crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _toggleTimestamp(message.id),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xffF3EEDF) : Color(0xffE4E4E4),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40.r),
                      topRight: Radius.circular(40.r),
                      bottomLeft: Radius.circular(isMe ? 40.r : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 40.r),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMe)
                        Image.asset(
                          'assets/images/voice_wave_yellow.png',
                          width: 0.45.sw,
                          height: 20.h,
                          fit: BoxFit.fitWidth,
                        )
                      else
                        Row(
                          children: [
                            SvgPicture.asset("assets/svg/play_button.svg"),
                            SizedBox(width: 6.w),
                            Image.asset(
                              'assets/images/voice_wave_grey.png',
                              width: 0.38.sw,
                              height: 20.h,
                              fit: BoxFit.fitWidth,
                            ),
                          ],
                        ),
                      if (isMe) ...[
                        SizedBox(width: 10.w),
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isTimestampVisible) ...[
                SizedBox(height: 4.h),
                Text(
                  _getFormattedTime(message.timestamp),
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _daySeparator(String date) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Text(
          date,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  Widget _messageInput() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: const Color(0xffF6F6F6),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: "Send Message",
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14.sp),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.image_outlined, color: Colors.grey, size: 20.sp),
                        SizedBox(width: 8.w),
                        Icon(Icons.location_on_outlined, color: Colors.grey, size: 20.sp),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () {
                if (_isTyping) {
                  final text = _messageController.text.trim();
                  if (text.isNotEmpty) {
                    setState(() {
                      _messages.add(ChatMessage(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        text: text,
                        isMe: true,
                        timestamp: DateTime.now(),
                      ));
                      _messageController.clear();
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });
                  }
                } else {
                  setState(() {
                    _messages.add(ChatMessage(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      text: 'Voice message (0:05)',
                      isMe: true,
                      isVoice: true,
                      timestamp: DateTime.now(),
                    ));
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }
              },
              child: Container(
                height: 50.w,
                width: 50.w,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isTyping ? Icons.send : Icons.mic,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}