import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:intl/intl.dart';
import '../../../controller/Chat_socket_controller.dart';
import '../../../models/chat_model.dart';
import '../../widgets/app_logger.dart';
import '../../widgets/loading_indicator.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final String clientImage;
  late final int? clientId;
  late final String clientName;
  late final String therapistImage;
  late final int? therapistId;
  late final String therapistName;
  late final String displayName;
  late final String displayImage;
  late final int? displayId;
  bool _isTyping = false;
  String? _selectedMessageId;
  late final ChatWebSocketController _controller;

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments as Map<String, dynamic>?;
    AppLogger.debug('ChatDetailScreen arguments: $arguments');

    clientId = arguments?['client_id'] as int?;
    clientName = arguments?['client_name']?.toString() ?? 'Unknown User';
    clientImage = arguments?['client_image']?.toString() ?? 'assets/images/therapist.png';

    therapistId = arguments?['therapist_user_id'] as int? ?? 1;
    therapistName = arguments?['name']?.toString() ?? 'Therapist';
    therapistImage = arguments?['image']?.toString() ?? 'assets/images/therapist.png';

    if (arguments != null &&
        (arguments.containsKey('therapist_user_id') ||
            arguments.containsKey('name') ||
            arguments.containsKey('image'))) {
      displayId = therapistId;
      displayName = therapistName;
      displayImage = therapistImage;
      AppLogger.debug('Using therapist details for display');
    } else if (arguments != null &&
        (arguments.containsKey('client_id') ||
            arguments.containsKey('client_name') ||
            arguments.containsKey('client_image'))) {
      displayId = clientId;
      displayName = clientName;
      displayImage = clientImage;
      AppLogger.debug('Using client details for display');
    } else {
      displayId = null;
      displayName = 'Unknown User';
      displayImage = 'assets/images/therapist.png';
      AppLogger.debug('Using default details for display');
    }

    AppLogger.debug(
        'clientImage: $clientImage, clientId: $clientId, clientName: $clientName, '
            'therapistImage: $therapistImage, therapistId: $therapistId, therapistName: $therapistName, '
            'displayId: $displayId, displayName: $displayName, displayImage: $displayImage');

    _controller = Get.put(ChatWebSocketController(
      arguments: arguments,
      context: context,
    ));

    _messageController.addListener(() {
      setState(() {
        _isTyping = _messageController.text.trim().isNotEmpty;
      });
    });

    _controller.messages.listen((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
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
        _selectedMessageId = null;
      } else {
        _selectedMessageId = messageId;
      }
    });
  }

  void _hideTimestamp() {
    setState(() {
      _selectedMessageId = null;
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
              radius: 18.r,
              child: ClipOval(
                child: displayImage.startsWith('http')
                    ? CachedNetworkImage(
                  imageUrl: displayImage,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Image.asset(
                    'assets/images/therapist.png',
                    fit: BoxFit.cover,
                  ),
                )
                    : Image.asset(
                  displayImage,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
                Obx(() => Text(
                  _controller.isConnecting.value ? 'Connecting...' : 'Active now',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: _controller.isConnecting.value ? Colors.grey : Colors.green,
                  ),
                )),
              ],
            ),
          ],
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10, top: 5, bottom: 5),
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
              onTap: _hideTimestamp,
              child: Obx(() => _buildMessageList()),
            ),
          ),
          _messageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    AppLogger.debug('Building message list with ${ _controller.messages.length} messages');
    final Map<String, List<ChatMessage>> groupedMessages = {};

    final messages = _controller.messages..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    AppLogger.debug('Messages: ${messages.map((m) => {'id': m.id, 'text': m.text, 'isMe': m.isMe, 'timestamp': m.timestamp.toString()}).toList()}');

    for (final message in messages) {
      final date = _getFormattedDate(message.timestamp);
      if (!groupedMessages.containsKey(date)) {
        groupedMessages[date] = [];
      }
      groupedMessages[date]!.add(message);
    }

    AppLogger.debug('Grouped messages: ${groupedMessages.map((key, value) => MapEntry(key, value.map((m) => {'id': m.id, 'text': m.text}).toList()))}');

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
                  status: message.status,
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
        required MessageStatus status,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          text,
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        SizedBox(width: 8.w),
                        _buildStatusIndicator(status),
                      ],
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
          crossAxisAlignment: showAvatar ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (showAvatar)
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18.r,
                    child: ClipOval(
                      child: displayImage.startsWith('http')
                          ? CachedNetworkImage(
                        imageUrl: displayImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Image.asset(
                          'assets/images/therapist.png',
                          fit: BoxFit.cover,
                        ),
                      )
                          : Image.asset(
                        displayImage,
                        fit: BoxFit.cover,
                      ),
                    ),
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
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            isLastFromSender
                ? Stack(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  child: ClipOval(
                    child: displayImage.startsWith('http')
                        ? CachedNetworkImage(
                      imageUrl: displayImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/images/therapist.png',
                        fit: BoxFit.cover,
                      ),
                    )
                        : Image.asset(
                      displayImage,
                      fit: BoxFit.cover,
                    ),
                  ),
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
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                      if (isMe) ...[
                        SizedBox(width: 8.w),
                        _buildStatusIndicator(message.status),
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

  Widget _buildStatusIndicator(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12.w,
          height: 12.w,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 12.sp,
        );
      case MessageStatus.failed:
        return Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 12.sp,
        );
    }
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
            Obx(() => GestureDetector(
              onTap: () async {
                if (_controller.isConnecting.value) return;
                if (_isTyping) {
                  final text = _messageController.text.trim();
                  if (text.isNotEmpty) {
                    _controller.sendMessage(text);
                    _messageController.clear();
                  }
                } else {
                  _controller.sendMessage('Voice message (0:05)', isVoice: true);
                }
              },
              child: Container(
                height: 50.w,
                width: 50.w,
                decoration: BoxDecoration(
                  color: _controller.isConnecting.value ? Colors.grey : primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isTyping ? Icons.send : Icons.mic,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}