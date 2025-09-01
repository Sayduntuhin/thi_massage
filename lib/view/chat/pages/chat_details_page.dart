import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../controller/Chat_socket_controller.dart';
import '../../../controller/location_controller.dart';
import '../../../models/chat_model.dart';
import '../../widgets/app_logger.dart';
import '../../widgets/custom_snackbar.dart';
import 'package:toastification/toastification.dart';

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
  final LocationController _locationController = Get.find<LocationController>();
  final RxBool _isSharingLocation = false.obs; // Track location sharing state

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments as Map<String, dynamic>?;
    AppLogger.debug('ChatDetailScreen arguments: $arguments');

    clientId = arguments?['client_id'] as int?;
    clientName = arguments?['client_name']?.toString() ?? 'Unknown User';
    clientImage = arguments?['client_image']?.toString() ?? 'assets/images/therapist.png';

    therapistId = arguments?['therapist_user_id'] != null
        ? int.tryParse(arguments!['therapist_user_id'].toString()) ?? 0
        : 0;
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

    if (therapistId == null || therapistId == 0) {
      CustomSnackBar.show(
        context,
        'Invalid therapist ID. Cannot start chat.',
        type: ToastificationType.error,
      );
      Get.back();
      return;
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

  Future<void> _sendLocationMessage() async {
    if (_controller.isConnecting.value || _isSharingLocation.value) return;

    _isSharingLocation.value = true;
    try {
      // Use cached location if valid, otherwise fetch new location
      if (!_locationController.hasValidLocation) {
        await _locationController.fetchCurrentLocation();
      }

      if (_locationController.hasError.value) {
        AppLogger.error('Location fetch failed: ${_locationController.locationName.value}');
        if (mounted) {
          CustomSnackBar.show(
            context,
            _locationController.locationName.value,
            type: ToastificationType.error,
          );
        }
        return;
      }

      final position = _locationController.position.value;
      if (position == null) {
        AppLogger.error('No position available');
        if (mounted) {
          CustomSnackBar.show(
            context,
            'Failed to get current location',
            type: ToastificationType.error,
          );
        }
        return;
      }

      final coords = '${position.latitude},${position.longitude}';
      final address = _locationController.locationName.value;
      final locationMessage = 'Location: $address\nhttps://maps.google.com/?q=$coords';

      // Show confirmation dialog
      if (mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Share Location'),
            content: Text('Do you want to share your live location?\n\n$address'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Share'),
              ),
            ],
          ),
        );

        if (confirmed != true) {
          AppLogger.debug('Location sharing cancelled by user');
          return;
        }

        _controller.sendMessage(locationMessage);
        AppLogger.debug('Sent location message: $locationMessage');
        CustomSnackBar.show(
          context,
          'Location shared',
          type: ToastificationType.success,
        );
      }
    } catch (e) {
      AppLogger.error('Error sending location: $e');
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to share location: $e',
          type: ToastificationType.error,
        );
      }
    } finally {
      _isSharingLocation.value = false;
    }
  }

  Future<void> _launchLocationUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      AppLogger.error('Could not launch URL: $url');
      if (mounted) {
        CustomSnackBar.show(
          context,
          'Failed to open map',
          type: ToastificationType.error,
        );
      }
    }
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
    AppLogger.debug('Building message list with ${_controller.messages.length} messages');
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

              return _chatBubble(
                message.text,
                isMe: message.isMe,
                showAvatar: isLastFromSender,
                timestamp: message.timestamp,
                messageId: message.id,
                status: message.status,
              );
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
    final isLocationMessage = text.startsWith('Location:');

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: showAvatar ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && showAvatar)
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
            else if (!isMe)
              SizedBox(width: 36.w),
            if (!isMe) SizedBox(width: 8.w),
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: isLocationMessage
                        ? () {
                      final url = text.split('\n').lastWhere((line) => line.startsWith('https://maps.google.com'), orElse: () => '');
                      if (url.isNotEmpty) {
                        _launchLocationUrl(url);
                      }
                    }
                        : () => _toggleTimestamp(messageId),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: 0.7.sw, // Limit bubble width to 70% of screen width
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xffF3EEDF) : Color(0xffE4E4E4),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                          topRight: Radius.circular(16.r),
                          bottomLeft: Radius.circular(isMe ? 16.r : 0),
                          bottomRight: Radius.circular(isMe ? 0 : 16.r),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isLocationMessage)
                            Padding(
                              padding: EdgeInsets.only(right: 8.w),
                              child: Icon(
                                Icons.location_on,
                                color: isMe ? Colors.blue : Colors.grey[600],
                                size: 18.sp,
                              ),
                            ),
                          Flexible(
                            child: Text(
                              text,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: isLocationMessage ? (isMe ? Colors.blue : Colors.grey[800]) : Colors.black,
                                decoration: isLocationMessage ? TextDecoration.underline : TextDecoration.none,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.clip, // Ensure text wraps within constraints
                            ),
                          ),
                          if (isMe) ...[
                            SizedBox(width: 8.w),
                            _buildStatusIndicator(status),
                          ],
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
            ),
            if (isMe) SizedBox(width: 8.w),
          ],
        ),
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
                        /*  Icon(Icons.image_outlined, color: Colors.grey, size: 20.sp),
                        SizedBox(width: 8.w),*/
                        Obx(() => GestureDetector(
                          onTap: _sendLocationMessage,
                          child: _isSharingLocation.value
                              ? SizedBox(
                            width: 20.sp,
                            height: 20.sp,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                            ),
                          )
                              : Icon(
                            Icons.location_on_outlined,
                            color: Colors.grey,
                            size: 20.sp,
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Obx(() => GestureDetector(
              onTap: () {
                if (_controller.isConnecting.value) return;
                final text = _messageController.text.trim();
                if (text.isNotEmpty) {
                  _controller.sendMessage(text);
                  _messageController.clear();
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
                  Icons.send,
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