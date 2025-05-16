import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/chat_model.dart';
import '../../api/api_service.dart';
import '../view/widgets/app_logger.dart';
import '../view/widgets/loading_indicator.dart';
import '../view/widgets/custom_snackbar.dart';
import 'package:toastification/toastification.dart';

class ChatWebSocketController extends GetxController {
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isConnecting = true.obs;
  WebSocketChannel? _channel;
  int? _chatRoomId;
  int? _user1Id;
  int? _user2Id;
  int? _currentUserId;
  final _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  final Map<String, dynamic>? arguments;
  final BuildContext? context;

  ChatWebSocketController({this.arguments, this.context});

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeChatRoom();
    });
  }

  Future<void> initializeChatRoom() async {
    isConnecting.value = true;
    LoadingManager.showLoading();

    try {
      AppLogger.debug('Initializing chat room with arguments: $arguments');
      final chatRoomData = await _apiService.initializeChatRoom(arguments);
      AppLogger.debug('Chat room data received: $chatRoomData');
      _chatRoomId = chatRoomData['chatRoomId'] as int?;
      _user1Id = chatRoomData['user1Id'] as int?;
      _user2Id = chatRoomData['user2Id'] as int?;
      _currentUserId = chatRoomData['currentUserId'] as int?;
      final token = chatRoomData['token'] as String;

      await _fetchMessageHistory(token);
      connectWebSocket();
    } catch (e) {
      AppLogger.error('Error initializing chat room: $e');
      if (context != null) {
        CustomSnackBar.show(
          context!,
          'Failed to initialize chat room: $e',
          type: ToastificationType.error,
        );
      }
      isConnecting.value = false;
      LoadingManager.hideLoading();
    }
  }

  Future<void> _fetchMessageHistory(String token) async {
    if (_chatRoomId == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/chat/messages/$_chatRoomId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        AppLogger.debug('Message history: $data');
        final mappedMessages = data.map((msg) {
          final messageText = msg['content']?.toString() ?? '';
          final chatMessage = ChatMessage(
            id: msg['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            text: messageText,
            isMe: (msg['sender'] as int?) == _currentUserId,
            isVoice: messageText.contains('Voice message'),
            timestamp: DateTime.tryParse(msg['timestamp']?.toString() ?? '') ?? DateTime.now(),
            status: MessageStatus.sent,
          );
          return chatMessage;
        }).toList();
        AppLogger.debug('Mapped messages: ${mappedMessages.map((m) => {'id': m.id, 'text': m.text, 'isMe': m.isMe, 'timestamp': m.timestamp.toString()}).toList()}');
        messages.assignAll(mappedMessages);
      } else {
        AppLogger.error('Failed to fetch message history: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('Error fetching message history: $e');
    }
  }

  void connectWebSocket() {
    if (_chatRoomId == null) {
      AppLogger.error('No chat room ID available for WebSocket');
      isConnecting.value = false;
      LoadingManager.hideLoading();
      return;
    }

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://192.168.10.139:3333/ws/chat/$_chatRoomId/'),
      );

      _channel!.stream.listen(
            (message) {
          final data = jsonDecode(message);
          AppLogger.debug('Received WebSocket message: $data');
          final messageText = data['message']?.toString() ?? '';
          final serverMessageId = data['id']?.toString();
          final senderId = data['sender'] as int?;
          final isMe = senderId == _currentUserId;
          final timestamp = DateTime.tryParse(data['timestamp']?.toString() ?? '') ?? DateTime.now();

          // Try to match by client-generated ID
          final existingMessageIndex = serverMessageId != null
              ? messages.indexWhere((m) => m.id == serverMessageId)
              : -1;

          if (existingMessageIndex != -1) {
            AppLogger.debug('Updating existing message ID: $serverMessageId to sent');
            messages[existingMessageIndex] = messages[existingMessageIndex].copyWith(
              status: MessageStatus.sent,
              timestamp: timestamp,
            );
          } else {
            // Fallback: Match by text, sender, and recent timestamp
            final recentMessageIndex = messages.indexWhere(
                  (m) =>
              m.text == messageText &&
                  m.isMe == isMe &&
                  m.timestamp.difference(timestamp).inSeconds.abs() < 5,
            );
            if (recentMessageIndex != -1) {
              AppLogger.debug('Updating recent message with text: $messageText to sent');
              messages[recentMessageIndex] = messages[recentMessageIndex].copyWith(
                id: serverMessageId ?? messages[recentMessageIndex].id,
                status: MessageStatus.sent,
                timestamp: timestamp,
              );
            } else {
              AppLogger.debug('Adding new message: $messageText');
              messages.add(ChatMessage(
                id: serverMessageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
                text: messageText,
                isMe: isMe,
                isVoice: messageText.contains('Voice message'),
                timestamp: timestamp,
                status: MessageStatus.sent,
              ));
            }
          }
          _reconnectAttempts = 0;
        },
        onError: (error) {
          AppLogger.error('WebSocket error: $error');
          if (context != null) {
            CustomSnackBar.show(
              context!,
              'WebSocket connection failed',
              type: ToastificationType.error,
            );
          }
          _attemptReconnect();
        },
        onDone: () {
          AppLogger.debug('WebSocket connection closed');
          _attemptReconnect();
        },
      );
    } catch (e) {
      AppLogger.error('Error connecting to WebSocket: $e');
      if (context != null) {
        CustomSnackBar.show(
          context!,
          'Failed to connect to chat',
          type: ToastificationType.error,
        );
      }
      _attemptReconnect();
    } finally {
      isConnecting.value = false;
      LoadingManager.hideLoading();
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      AppLogger.debug('Reconnecting WebSocket, attempt $_reconnectAttempts');
      Future.delayed(Duration(seconds: 5), connectWebSocket);
    } else {
      AppLogger.error('Max reconnect attempts reached');
      if (context != null) {
        CustomSnackBar.show(
          context!,
          'Unable to reconnect to chat',
          type: ToastificationType.error,
        );
      }
      isConnecting.value = false;
    }
  }

  void sendMessage(String text, {bool isVoice = false}) async {
    if (_channel == null || _chatRoomId == null || _currentUserId == null) {
      AppLogger.error('Cannot send message: Not connected to WebSocket');
      if (context != null) {
        CustomSnackBar.show(
          context!,
          'Not connected to chat',
          type: ToastificationType.error,
        );
      }
      return;
    }

    final receiverId = _currentUserId == _user1Id ? _user2Id : _user1Id;
    if (receiverId == null) {
      AppLogger.error('No receiver ID available');
      if (context != null) {
        CustomSnackBar.show(
          context!,
          'Invalid chat configuration',
          type: ToastificationType.error,
        );
      }
      return;
    }

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final messagePayload = {
      'message': isVoice ? 'Voice message (0:05)' : text,
      'sender': _currentUserId,
      'receiver': receiverId,
      'id': messageId,
    };

    try {
      messages.add(ChatMessage(
        id: messageId,
        text: isVoice ? 'Voice message (0:05)' : text,
        isMe: true,
        isVoice: isVoice,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      ));

      _channel!.sink.add(jsonEncode(messagePayload));
      AppLogger.debug('Sent message: $messagePayload');
    } catch (e) {
      AppLogger.error('Error sending message: $e');
      final failedMessageIndex = messages.indexWhere((m) => m.id == messageId);
      if (failedMessageIndex != -1) {
        messages[failedMessageIndex] = messages[failedMessageIndex].copyWith(
          status: MessageStatus.failed,
        );
      }
      if (context != null) {
        CustomSnackBar.show(
          context!,
          'Failed to send message',
          type: ToastificationType.error,
        );
      }
    }
  }

  @override
  void onClose() {
    _channel?.sink.close();
    super.onClose();
  }
}