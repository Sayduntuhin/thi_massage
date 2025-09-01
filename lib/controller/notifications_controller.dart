import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../api/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../view/widgets/app_logger.dart';

class NotificationSocketController extends GetxController {
  final ApiService apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  WebSocketChannel? channel;
  var notificationRoomId = Rx<int?>(null);
  var notifications = <Map<String, dynamic>>[].obs;
  var isConnected = false.obs;

  @override
  void onInit() {
    super.onInit();
    _fetchNotificationRoom();
  }

  Future<void> _fetchNotificationRoom() async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) {
        AppLogger.error('No access token found for notification room');
        return;
      }

      final response = await apiService.client.get(
        Uri.parse('${ApiService.baseUrl}/api/notification/get-or-create-room/'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        notificationRoomId.value = data['room_id'] as int?;
        AppLogger.debug('Notification room ID: ${notificationRoomId.value}');
        if (notificationRoomId.value != null) {
          connectWebSocket();
        }
      } else {
        AppLogger.error('Failed to fetch notification room: ${response.body}');
      }
    } catch (e) {
      AppLogger.error('Error fetching notification room: $e');
    }
  }

  void connectWebSocket() {
    if (notificationRoomId.value == null) {
      AppLogger.error('No notification room ID available');
      return;
    }

    try {
      channel = IOWebSocketChannel.connect(
        'ws://backend.thaimassagesnearmeapp.com/ws/notifications/${notificationRoomId.value}/',
      );
      isConnected.value = true;
      AppLogger.debug('WebSocket connected for notifications');

      channel!.stream.listen(
            (message) {
          final data = jsonDecode(message) as Map<String, dynamic>;
          AppLogger.debug('Received WebSocket notification: $data');
          notifications.add(data);
          _showLocalNotification(data);
        },
        onError: (error) {
          AppLogger.error('WebSocket error: $error');
          isConnected.value = false;
        },
        onDone: () {
          AppLogger.debug('WebSocket connection closed');
          isConnected.value = false;
          reconnect();
        },
      );
    } catch (e) {
      AppLogger.error('WebSocket connection error: $e');
      isConnected.value = false;
      reconnect();
    }
  }

  void reconnect() async {
    if (!isConnected.value && notificationRoomId.value != null) {
      AppLogger.debug('Attempting to reconnect WebSocket...');
      await Future.delayed(const Duration(seconds: 5));
      connectWebSocket();
    }
  }

  Future<void> _showLocalNotification(Map<String, dynamic> notification) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'notification_channel_id',
      'Notifications',
      channelDescription: 'App notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await Get.find<FlutterLocalNotificationsPlugin>().show(
      notification['id'] ?? 0,
      'New Notification',
      notification['message'] ?? 'You have a new notification',
      platformDetails,
      payload: jsonEncode(notification),
    );
  }

  @override
  void onClose() {
    channel?.sink.close();
    isConnected.value = false;
    super.onClose();
  }
}